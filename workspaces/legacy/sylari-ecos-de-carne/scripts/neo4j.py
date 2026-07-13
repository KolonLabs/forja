#!/usr/bin/env python3
"""Neo4j helper — novel relationship graph.

Manages the relationship graph for a novel. Qdrant holds the semantic/vector
data; Neo4j holds the live relationship graph (who is related to whom, how).
The graph is the present truth — no temporal metadata, no versioning.
Relationships change when the narrative changes.

The graph is maintained in real time by the entidades agent and the director.
The cronista reads it for auditing but never writes to it.

Requirements:
  pip install neo4j

Usage:
  python3 scripts/neo4j.py init
  python3 scripts/neo4j.py upsert-relationship --novela SLUG --from per-A --to per-B --type PAREJA_DE --rol casado_con
  python3 scripts/neo4j.py delete-relationship --novela SLUG --from per-A --to per-B --type PAREJA_DE [--rol casado_con]
  python3 scripts/neo4j.py query-relationships --novela SLUG --entity per-A
  python3 scripts/neo4j.py export --novela SLUG --output FILE
  python3 scripts/neo4j.py import --novela SLUG --input FILE

Environment:
  NEO4J_URL      default: bolt://localhost:7687
  NEO4J_USER     default: neo4j
  NEO4J_PASSWORD default: devpassword
"""

import argparse
import datetime
import json
import os
import sys
import warnings
from typing import Optional, List, Set

# When invoked as `python scripts/neo4j.py`, Python prepends the script's
# own directory to sys.path — which shadows the real `neo4j` PyPI package
# with this file. Strip the script's dir so the import resolves to site-packages.
_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path = [p for p in sys.path if os.path.abspath(p) != _SCRIPT_DIR]

# Neo4j 5.x emits "unknown property key" notifications when a query asks
# for properties that don't exist on a relationship. Harmless for our use
# case (relationships are created lazily with all properties), but noisy.
# Silence them to keep CLI output clean.
warnings.filterwarnings("ignore", message=r".*unknown property key.*")

try:
    from neo4j import GraphDatabase, basic_auth
except ImportError:
    print("Error: neo4j driver not installed. Run: pip install neo4j", file=sys.stderr)
    sys.exit(1)


NEO4J_URL = os.environ.get("NEO4J_URL", "bolt://localhost:7687")
NEO4J_USER = os.environ.get("NEO4J_USER", "neo4j")
NEO4J_PASSWORD = os.environ.get("NEO4J_PASSWORD", "devpassword")


# ── Vocabulary ───────────────────────────────────────────────────────────────

# Cross-entity types: persona↔lugar, persona↔objeto, etc.
# These don't have a "rol" — the type itself is the meaning.
CROSS_ENTITY_TYPES: Set[str] = {
    # Persona ↔ Lugar
    "VIVE_EN", "VIVIO_EN", "TRABAJA_EN", "FRECUENTA",
    "EVITA", "ENCUENTRO_EN", "ENCERRADA_EN",
    # Persona ↔ Objeto
    "POSEE", "PERTENECIO_A", "BUSCA", "ENCUENTRA",
    "PERDIO", "ROBO", "REGALO_A", "SIMBOLIZA",
    # Persona ↔ Animal
    "DUENO_DE", "CUIDA_DE",
    # Persona ↔ Organización
    "MIEMBRO_DE", "EX_MIEMBRO_DE", "LIDERA", "FUNDÓ",
    # Persona ↔ Hilo
    "IMPLICADO_EN", "TESTIGO_DE", "CULPABLE_DE", "DESCUBRIO",
    "INTENTA_RESOLVER",
    # Persona ↔ Evento
    "PARTICIPO_EN", "ORGANIZO", "VICTIMA_DE", "PERPETRO",
    # Lugar ↔ Evento
    "EVENTO_EN",
}

# Person-person types: each has a closed set of "rol" values.
# The script validates both type and rol; if either is not in the vocabulary,
# the script rejects and the cronista pauses to notify the user.
PERSON_PERSON_TYPES: dict = {
    "PAREJA_DE": {
        "marido", "esposa", "novio", "novia", "amante",
        "ex_marido", "ex_esposa", "ex_novio", "ex_novia", "ex_amante",
    },
    "FAMILIA_DE": {
        "padre", "madre", "hijo", "hija", "hermano", "hermana",
        "abuelo", "abuela", "nieto", "nieta",
        "tío", "tía", "sobrino", "sobrina",
        "primo", "prima",
        "suegro", "suegra", "yerno", "nuera", "cuñado", "cuñada",
        "padrastro", "madrastra", "hijastro", "hijastra",
    },
    "SENTIMIENTO_HACIA": {
        # Positivos
        "amor", "ternura", "deseo", "amistad", "admiracion", "alianza",
        # Negativos
        "odio", "miedo", "obsesion", "resentimiento", "enemistad", "rivalidad",
    },
    "ACCION_SOBRE": {
        "catalizador_de", "traiciona", "perdona", "ayuda", "protege", "chantajea",
        "secuestra", "ataca", "envenena", "engaña",
    },
}

ALL_VALID_TYPES: Set[str] = CROSS_ENTITY_TYPES | set(PERSON_PERSON_TYPES.keys())

# Map entity ID prefix → Neo4j label
ENTITY_LABELS: dict = {
    "per-": "Personaje",
    "lug-": "Lugar",
    "obj-": "Objeto",
    "ani-": "Animal",
    "hilo-": "Hilo",
    "org-": "Organizacion",
    "arc-": "Arco",
    "eve-": "Evento",
}


# ── Database connection ───────────────────────────────────────────────────────

_driver = None


def get_driver():
    global _driver
    if _driver is None:
        _driver = GraphDatabase.driver(
            NEO4J_URL,
            auth=basic_auth(NEO4J_USER, NEO4J_PASSWORD),
            # Silence "unknown property key" warnings when we ask for relationship
            # properties that haven't been set yet (e.g. `hasta` is null on a fresh
            # rel). Classification "UNRECOGNIZED" covers those.
            notifications_disabled_classifications=["UNRECOGNIZED"],
        )
    return _driver


def close_driver():
    global _driver
    if _driver is not None:
        _driver.close()
        _driver = None


# ── Validation ───────────────────────────────────────────────────────────────

def label_for_id(entity_id: str) -> str:
    """Get the Neo4j label for an entity ID based on its prefix."""
    for prefix, label in ENTITY_LABELS.items():
        if entity_id.startswith(prefix):
            return label
    return "Entity"


def validate_type_and_rol(type_: str, rol: Optional[str]) -> None:
    """Validate that the type is in vocabulary and rol is valid for that type.

    Raises SystemExit with a clear error if not. The cronista should catch
    this output and notify the user.
    """
    if type_ not in ALL_VALID_TYPES:
        print(
            f"Error: unknown relationship type '{type_}'.",
            file=sys.stderr,
        )
        print(
            f"  Valid types ({len(ALL_VALID_TYPES)}):",
            file=sys.stderr,
        )
        for t in sorted(ALL_VALID_TYPES):
            print(f"    {t}", file=sys.stderr)
        print(
            f"  → The cronista must pause and notify the user. "
            f"The user decides whether to add '{type_}' to the vocabulary.",
            file=sys.stderr,
        )
        sys.exit(1)

    if type_ in PERSON_PERSON_TYPES:
        if not rol:
            print(
                f"Error: type '{type_}' requires --rol.",
                file=sys.stderr,
            )
            print(
                f"  Valid roles: {sorted(PERSON_PERSON_TYPES[type_])}",
                file=sys.stderr,
            )
            sys.exit(1)
        if rol not in PERSON_PERSON_TYPES[type_]:
            print(
                f"Error: rol '{rol}' is not valid for type '{type_}'.",
                file=sys.stderr,
            )
            print(
                f"  Valid roles: {sorted(PERSON_PERSON_TYPES[type_])}",
                file=sys.stderr,
            )
            print(
                f"  → The cronista must pause and notify the user. "
                f"The user decides whether to add '{rol}' to the vocabulary.",
                file=sys.stderr,
            )
            sys.exit(1)
    else:
        # Cross-entity type: rol should not be provided
        if rol:
            print(
                f"Error: cross-entity type '{type_}' does not take --rol "
                f"(type itself is the meaning).",
                file=sys.stderr,
            )
            sys.exit(1)


# ── Commands ────────────────────────────────────────────────────────────────

def cmd_init(_args):
    """Create constraints for entity IDs per (label, novela) and a novela index."""
    driver = get_driver()
    with driver.session() as session:
        for prefix, label in ENTITY_LABELS.items():
            try:
                session.run(
                    f"CREATE CONSTRAINT {label.lower()}_id_novela IF NOT EXISTS "
                    f"FOR (n:{label}) REQUIRE (n.novela, n.id) IS UNIQUE"
                )
                print(f"  constraint {label.lower()}_id_novela created")
            except Exception as e:
                # Neo4j 5+ supports this; older versions may need different syntax
                print(f"  {label}: {e}")

        # Index on novela for fast filtering (across all node labels)
        for label in set(ENTITY_LABELS.values()) | {"Entity"}:
            try:
                session.run(
                    f"CREATE INDEX {label.lower()}_novela IF NOT EXISTS "
                    f"FOR (n:{label}) ON (n.novela)"
                )
            except Exception:
                pass  # already exists or syntax issue, ignore

        # Index on relationship properties for common filters
        for rel_type in ALL_VALID_TYPES:
            try:
                session.run(
                    f"CREATE INDEX rel_{rel_type.lower()}_novela IF NOT EXISTS "
                    f"FOR ()-[r:{rel_type}]-() ON (r.novela)"
                )
            except Exception:
                pass

    print("init complete")


def cmd_upsert_relationship(args):
    """Create or update a relationship between two entities.

    Cross-entity types (VIVE_EN, POSEE, etc.) don't take --rol.
    Person-person types (PAREJA_DE, FAMILIA_DE, SENTIMIENTO_HACIA, ACCION_SOBRE) take --rol.
    """
    validate_type_and_rol(args.type, args.rol)

    from_label = label_for_id(args.from_id)
    to_label = label_for_id(args.to_id)

    driver = get_driver()
    with driver.session() as session:
        # Ensure both nodes exist (idempotent)
        session.run(
            f"MERGE (a:{from_label} {{id: $from_id, novela: $novela}}) "
            f"MERGE (b:{to_label} {{id: $to_id, novela: $novela}})",
            from_id=args.from_id, to_id=args.to_id, novela=args.novela,
        )

        # Build the relationship properties
        rel_props = {"novela": args.novela}
        if args.rol:
            rel_props["rol"] = args.rol

        # Set all properties on both create and match (idempotent upsert)
        set_clause_parts = []
        params = {"from_id": args.from_id, "to_id": args.to_id, "novela": args.novela}
        for k, v in rel_props.items():
            if k == "novela":
                continue  # already in MATCH
            set_clause_parts.append(f"r.{k} = ${k}")
            params[k] = v

        set_clause = ", ".join(set_clause_parts)
        on_create = f"ON CREATE SET {set_clause}" if set_clause else ""
        on_match = f"ON MATCH SET {set_clause}" if set_clause else ""

        query = (
            f"MATCH (a:{from_label} {{id: $from_id, novela: $novela}}) "
            f"MATCH (b:{to_label} {{id: $to_id, novela: $novela}}) "
            f"MERGE (a)-[r:{args.type}]->(b) "
            f"{on_create} {on_match}"
        )
        session.run(query, **params)

    rol_str = f" rol={args.rol}" if args.rol else ""
    print(f"upserted  {args.novela}  ({args.from_id})-[:{args.type}{rol_str}]->({args.to_id})")


def _record_to_relationship(record, include_other_labels: bool = False) -> dict:
    """Convert a Neo4j record to a JSON-friendly dict."""
    out = {
        "type":     record["type"],
        "rol":      record.get("rol"),
        "other_id": record["other_id"],
    }
    if include_other_labels and "other_labels" in record:
        out["other_type"] = record["other_labels"][0] if record["other_labels"] else None
    return out


def cmd_query_relationships(args):
    """Get all relationships for an entity (incoming + outgoing)."""
    driver = get_driver()
    with driver.session() as session:
        result = session.run(
            "MATCH (n {id: $entity, novela: $novela})-[r]-(other) "
            "RETURN type(r) AS type, "
            "coalesce(r.rol, null) AS rol, "
            "other.id AS other_id, labels(other) AS other_labels "
            "ORDER BY type(r), r.rol",
            entity=args.entity, novela=args.novela,
        )
        output = [_record_to_relationship(r, include_other_labels=True) for r in result]
    print(json.dumps(output, ensure_ascii=False, indent=2))


def cmd_delete_relationship(args):
    """Delete a specific relationship between two entities."""
    from_label = label_for_id(args.from_id)
    to_label = label_for_id(args.to_id)

    driver = get_driver()
    with driver.session() as session:
        query = (
            f"MATCH (a:{from_label} {{id: $from_id, novela: $novela}})"
            f"-[r:{args.type}]->"
            f"(b:{to_label} {{id: $to_id, novela: $novela}}) "
        )
        if args.rol:
            query += "WHERE r.rol = $rol "
        query += "DELETE r"

        params = {"from_id": args.from_id, "to_id": args.to_id, "novela": args.novela}
        if args.rol:
            params["rol"] = args.rol
        result = session.run(query, **params)
        count = result.consume().counters.relationships_deleted

    rol_str = f" rol={args.rol}" if args.rol else ""
    print(f"deleted  {args.novela}  ({args.from_id})-[:{args.type}{rol_str}]->({args.to_id})  ({count} relationship(s))")


def cmd_export(args):
    """Dump all relationships for a novela to a JSON file."""
    driver = get_driver()
    with driver.session() as session:
        result = session.run(
            "MATCH (a)-[r]->(b) "
            "WHERE r.novela = $novela "
            "RETURN a.id AS from_id, labels(a) AS from_labels, "
            "type(r) AS type, r.rol AS rol, "
            "b.id AS to_id, labels(b) AS to_labels",
            novela=args.novela,
        )
        relationships = []
        for r in result:
            relationships.append({
                "from_id":   r["from_id"],
                "from_type": r["from_labels"][0] if r["from_labels"] else None,
                "type":      r["type"],
                "rol":       r["rol"],
                "to_id":     r["to_id"],
                "to_type":   r["to_labels"][0] if r["to_labels"] else None,
            })

    backup = {
        "novela":       args.novela,
        "exported_at":  datetime.datetime.utcnow().isoformat() + "Z",
        "count":        len(relationships),
        "relationships": relationships,
    }

    if args.output == "-":
        json.dump(backup, sys.stdout, ensure_ascii=False, indent=2)
        print()
    else:
        with open(args.output, "w", encoding="utf-8") as f:
            json.dump(backup, f, ensure_ascii=False, indent=2)
        print(f"exported  {args.novela}  →  {args.output}  ({len(relationships)} relationships)")


def cmd_import(args):
    """Restore relationships from a JSON file produced by `export`.

    Validates each type/rol against the vocabulary; if any is not in the spec,
    the import fails with a clear error (caller can decide to update the spec
    and re-import).
    """
    with open(args.input, encoding="utf-8") as f:
        backup = json.load(f)

    if backup.get("novela") != args.novela:
        print(
            f"Warning: backup novela='{backup.get('novela')}' != target='{args.novela}'. "
            f"Proceeding with target.",
            file=sys.stderr,
        )

    relationships = backup.get("relationships", [])
    imported = 0
    skipped = 0
    for rel in relationships:
        # Validate vocabulary
        try:
            validate_type_and_rol(rel["type"], rel.get("rol"))
        except SystemExit as e:
            print(
                f"  skipped: {rel.get('from_id')} -[:{rel['type']}"
                f"{' {rol='+rel['rol']+'}' if rel.get('rol') else ''}]-> "
                f"{rel.get('to_id')}: vocabulary check failed",
                file=sys.stderr,
            )
            skipped += 1
            continue

        from_label = rel.get("from_type") or label_for_id(rel["from_id"])
        to_label = rel.get("to_type") or label_for_id(rel["to_id"])

        rel_props = {"novela": args.novela}
        if rel.get("rol"):
            rel_props["rol"] = rel["rol"]

        set_clause_parts = []
        params = {
            "from_id": rel["from_id"],
            "to_id":   rel["to_id"],
            "novela":  args.novela,
        }
        for k, v in rel_props.items():
            if k == "novela":
                continue
            set_clause_parts.append(f"r.{k} = ${k}")
            params[k] = v

        set_clause = ", ".join(set_clause_parts)
        on_create = f"ON CREATE SET {set_clause}" if set_clause else ""
        on_match = f"ON MATCH SET {set_clause}" if set_clause else ""

        query = (
            f"MERGE (a:{from_label} {{id: $from_id, novela: $novela}}) "
            f"MERGE (b:{to_label} {{id: $to_id, novela: $novela}}) "
            f"MERGE (a)-[r:{rel['type']}]->(b) "
            f"{on_create} {on_match}"
        )

        driver = get_driver()
        with driver.session() as session:
            session.run(query, **params)
        imported += 1

    print(f"imported  {args.novela}  {imported} relationships ({skipped} skipped)")


# ── CLI ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Neo4j helper — novel relationship graph",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("init", help="Create constraints and indexes for the graph")

    p = sub.add_parser("upsert-relationship", help="Create or update a relationship")
    p.add_argument("--novela", required=True, help="Novel slug")
    p.add_argument("--from",  dest="from_id", required=True, help="From entity ID")
    p.add_argument("--to",    dest="to_id",   required=True, help="To entity ID")
    p.add_argument("--type",  required=True,
                   help="Relationship type (e.g. PAREJA_DE, FAMILIA_DE, SENTIMIENTO_HACIA, ACCION_SOBRE, VIVE_EN, POSEE)")
    p.add_argument("--rol",
                   help="Rol (required for person-person types, e.g. casado_con, traiciona, madre)")

    p = sub.add_parser("delete-relationship", help="Delete a relationship between two entities")
    p.add_argument("--novela", required=True, help="Novel slug")
    p.add_argument("--from",  dest="from_id", required=True, help="From entity ID")
    p.add_argument("--to",    dest="to_id",   required=True, help="To entity ID")
    p.add_argument("--type",  required=True,
                   help="Relationship type to delete")
    p.add_argument("--rol",
                   help="Rol to match (optional; if omitted, all relationships of type are deleted)")

    p = sub.add_parser("query-relationships", help="Get all relationships for an entity")
    p.add_argument("--novela", required=True)
    p.add_argument("--entity", required=True, help="Entity ID")

    p = sub.add_parser("export", help="Backup all relationships for a novela to a JSON file")
    p.add_argument("--novela", required=True)
    p.add_argument("--output", required=True, help="Output file path (- for stdout)")

    p = sub.add_parser("import", help="Restore relationships from a JSON file")
    p.add_argument("--novela", required=True)
    p.add_argument("--input",  required=True, help="Input file path (from 'export')")

    args = parser.parse_args()

    commands = {
        "init":                      cmd_init,
        "upsert-relationship":       cmd_upsert_relationship,
        "delete-relationship":       cmd_delete_relationship,
        "query-relationships":       cmd_query_relationships,
        "export":                    cmd_export,
        "import":                    cmd_import,
    }

    try:
        commands[args.command](args)
    finally:
        close_driver()


if __name__ == "__main__":
    main()
