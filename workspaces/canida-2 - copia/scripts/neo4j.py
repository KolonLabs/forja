#!/usr/bin/env python3
"""Neo4j helper — proyecto relationship graph.

Manages the relationship graph for a proyecto. Qdrant holds the semantic/vector
data; Neo4j holds the live relationship graph (who is related to whom, how).
The graph is the present truth — no temporal metadata, no versioning.
Relationships change when the narrative changes.

The graph is maintained in real time by the entidades agent and the director.
The cronista reads it for auditing but never writes to it.

Requirements:
  pip install neo4j

Usage:
  python3 scripts/neo4j.py init
  python3 scripts/neo4j.py upsert-relationship --proyecto SLUG --from-stable-id A --to-stable-id B --from-tipo personaje --to-tipo personaje --type PAREJA_DE --rol casado_con
  python3 scripts/neo4j.py delete-relationship --proyecto SLUG --from-stable-id A --to-stable-id B --from-tipo personaje --to-tipo personaje --type PAREJA_DE [--rol casado_con]
  python3 scripts/neo4j.py query-relationships --proyecto SLUG --stable-id A --tipo personaje
  python3 scripts/neo4j.py export --proyecto SLUG --output FILE
  python3 scripts/neo4j.py import --proyecto SLUG --input FILE

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

_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path = [p for p in sys.path if os.path.abspath(p) != _SCRIPT_DIR]

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
        "amor", "ternura", "deseo", "amistad", "admiracion", "alianza",
        "odio", "miedo", "obsesion", "resentimiento", "enemistad", "rivalidad",
    },
    "ACCION_SOBRE": {
        "catalizador_de", "traiciona", "perdona", "ayuda", "protege", "chantajea",
        "secuestra", "ataca", "envenena", "engaña",
    },
}

ALL_VALID_TYPES: Set[str] = CROSS_ENTITY_TYPES | set(PERSON_PERSON_TYPES.keys())

ENTITY_LABELS: dict = {
    "personaje": "Personaje",
    "lugar": "Lugar",
    "objeto": "Objeto",
    "animal": "Animal",
    "ser_sobrenatural": "SerSobrenatural",
    "hilo": "Hilo",
    "organizacion": "Organizacion",
    "arco": "Arco",
    "evento": "Evento",
    "grupo": "Grupo",
}


# ── Database connection ───────────────────────────────────────────────────────

_driver = None


def get_driver():
    global _driver
    if _driver is None:
        _driver = GraphDatabase.driver(
            NEO4J_URL,
            auth=basic_auth(NEO4J_USER, NEO4J_PASSWORD),
            notifications_disabled_classifications=["UNRECOGNIZED"],
        )
    return _driver


def close_driver():
    global _driver
    if _driver is not None:
        _driver.close()
        _driver = None


# ── Validation ───────────────────────────────────────────────────────────────

def label_for_type(tipo: str) -> str:
    """Get the Neo4j label for an entity type."""
    return ENTITY_LABELS.get(tipo, "Entity")


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
        if rol:
            print(
                f"Error: cross-entity type '{type_}' does not take --rol "
                f"(type itself is the meaning).",
                file=sys.stderr,
            )
            sys.exit(1)


# ── Commands ────────────────────────────────────────────────────────────────

def cmd_init(_args):
    """Create constraints and indexes for the graph."""
    driver = get_driver()
    with driver.session() as session:
        # One unique constraint on (proyecto, stable_id) for Entity nodes
        session.run(
            "CREATE CONSTRAINT entity_stable_id IF NOT EXISTS "
            "FOR (n:Entity) REQUIRE (n.proyecto, n.stable_id) IS UNIQUE"
        )
        print("  constraint entity_stable_id created")

        # Index on proyecto for each label (fast filtering)
        for label in ENTITY_LABELS.values():
            try:
                session.run(
                    f"CREATE INDEX {label.lower()}_proyecto IF NOT EXISTS "
                    f"FOR (n:{label}) ON (n.proyecto)"
                )
            except Exception:
                pass

        # Index on relationship properties for common filters
        for rel_type in ALL_VALID_TYPES:
            try:
                session.run(
                    f"CREATE INDEX rel_{rel_type.lower()}_proyecto IF NOT EXISTS "
                    f"FOR ()-[r:{rel_type}]-() ON (r.proyecto)"
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

    from_label = label_for_type(args.from_tipo)
    to_label = label_for_type(args.to_tipo)

    driver = get_driver()
    with driver.session() as session:
        session.run(
            f"MERGE (a:Entity:{from_label} {{stable_id: $from_stable_id, proyecto: $proyecto}}) "
            f"MERGE (b:Entity:{to_label} {{stable_id: $to_stable_id, proyecto: $proyecto}})",
            from_stable_id=args.from_stable_id,
            to_stable_id=args.to_stable_id,
            proyecto=args.proyecto,
        )

        rel_props = {}
        if args.rol:
            rel_props["rol"] = args.rol

        set_clause_parts = []
        params = {
            "from_stable_id": args.from_stable_id,
            "to_stable_id": args.to_stable_id,
            "proyecto": args.proyecto,
        }
        for k, v in rel_props.items():
            set_clause_parts.append(f"r.{k} = ${k}")
            params[k] = v
        # Always set proyecto on the relationship for filtering
        set_clause_parts.append("r.proyecto = $proyecto")

        set_clause = ", ".join(set_clause_parts)
        on_create = f"ON CREATE SET {set_clause}" if set_clause else ""
        on_match = f"ON MATCH SET {set_clause}" if set_clause else ""

        # For person-person types, include rol in the MERGE match for idempotency
        rol_match = " AND r.rol = $rol" if args.rol and args.type in PERSON_PERSON_TYPES else ""

        query = (
            f"MATCH (a:{from_label} {{stable_id: $from_stable_id, proyecto: $proyecto}}) "
            f"MATCH (b:{to_label} {{stable_id: $to_stable_id, proyecto: $proyecto}}) "
            f"MERGE (a)-[r:{args.type}{{proyecto: $proyecto}}]->(b) "
            f"{on_create} {on_match}"
        )
        session.run(query, **params)

    rol_str = f" rol={args.rol}" if args.rol else ""
    print(f"upserted  {args.proyecto}  ({args.from_stable_id})-[:{args.type}{rol_str}]->({args.to_stable_id})")


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
    label = label_for_type(args.tipo)
    driver = get_driver()
    with driver.session() as session:
        result = session.run(
            f"MATCH (n:{label} {{stable_id: $stable_id, proyecto: $proyecto}})-[r]-(other) "
            "RETURN type(r) AS type, "
            "coalesce(r.rol, null) AS rol, "
            "other.stable_id AS other_id, "
            "[lab IN labels(other) WHERE lab <> 'Entity'] AS other_labels "
            "ORDER BY type(r), r.rol",
            stable_id=args.stable_id, proyecto=args.proyecto,
        )
        output = [_record_to_relationship(r, include_other_labels=True) for r in result]
    print(json.dumps(output, ensure_ascii=False, indent=2))


def cmd_delete_relationship(args):
    """Delete a specific relationship between two entities.
    Validates type and rol before executing."""
    validate_type_and_rol(args.type, args.rol)

    from_label = label_for_type(args.from_tipo)
    to_label = label_for_type(args.to_tipo)

    driver = get_driver()
    with driver.session() as session:
        query = (
            f"MATCH (a:{from_label} {{stable_id: $from_stable_id, proyecto: $proyecto}})"
            f"-[r:{args.type}]->"
            f"(b:{to_label} {{stable_id: $to_stable_id, proyecto: $proyecto}}) "
        )
        if args.rol:
            query += "WHERE r.rol = $rol "
        query += "DELETE r"

        params = {
            "from_stable_id": args.from_stable_id,
            "to_stable_id": args.to_stable_id,
            "proyecto": args.proyecto,
        }
        if args.rol:
            params["rol"] = args.rol
        result = session.run(query, **params)
        count = result.consume().counters.relationships_deleted

    rol_str = f" rol={args.rol}" if args.rol else ""
    print(f"deleted  {args.proyecto}  ({args.from_stable_id})-[:{args.type}{rol_str}]->({args.to_stable_id})  ({count} relationship(s))")


def cmd_export(args):
    """Dump all relationships for a proyecto to a JSON file."""
    driver = get_driver()
    with driver.session() as session:
        result = session.run(
            "MATCH (a)-[r]->(b) "
            "WHERE r.proyecto = $proyecto "
            "RETURN a.stable_id AS from_id, "
            "[lab IN labels(a) WHERE lab <> 'Entity'] AS from_labels, "
            "type(r) AS type, r.rol AS rol, "
            "b.stable_id AS to_id, "
            "[lab IN labels(b) WHERE lab <> 'Entity'] AS to_labels",
            proyecto=args.proyecto,
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
        "proyecto":       args.proyecto,
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
        print(f"exported  {args.proyecto}  →  {args.output}  ({len(relationships)} relationships)")


def cmd_import(args):
    """Restore relationships from a JSON file produced by `export`.

    Validates each type/rol against the vocabulary; if any is not in the spec,
    the import fails with a clear error (caller can decide to update the spec
    and re-import).
    """
    with open(args.input, encoding="utf-8") as f:
        backup = json.load(f)

    if backup.get("proyecto") != args.proyecto:
        print(
            f"Warning: backup proyecto='{backup.get('proyecto')}' != target='{args.proyecto}'. "
            f"Proceeding with target.",
            file=sys.stderr,
        )

    relationships = backup.get("relationships", [])
    imported = 0
    skipped = 0
    for rel in relationships:
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

        from_label = rel.get("from_type") or "Entity"
        to_label = rel.get("to_type") or "Entity"

        rel_props = {"proyecto": args.proyecto}
        if rel.get("rol"):
            rel_props["rol"] = rel["rol"]

        set_clause_parts = []
        params = {
            "from_id": rel["from_id"],
            "to_id":   rel["to_id"],
            "proyecto":  args.proyecto,
        }
        for k, v in rel_props.items():
            if k == "proyecto":
                continue
            set_clause_parts.append(f"r.{k} = ${k}")
            params[k] = v

        set_clause = ", ".join(set_clause_parts)
        on_create = f"ON CREATE SET {set_clause}" if set_clause else ""
        on_match = f"ON MATCH SET {set_clause}" if set_clause else ""

        query = (
            f"MERGE (a:Entity:{from_label} {{stable_id: $from_id, proyecto: $proyecto}}) "
            f"MERGE (b:Entity:{to_label} {{stable_id: $to_id, proyecto: $proyecto}}) "
            f"MERGE (a)-[r:{rel['type']}]->(b) "
            f"{on_create} {on_match}"
        )

        driver = get_driver()
        with driver.session() as session:
            session.run(query, **params)
        imported += 1

    print(f"imported  {args.proyecto}  {imported} relationships ({skipped} skipped)")


# ── CLI ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Neo4j helper — proyecto relationship graph",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("init", help="Create constraints and indexes for the graph")

    p = sub.add_parser("upsert-relationship", help="Create or update a relationship")
    p.add_argument("--proyecto", required=True, help="Proyecto slug")
    p.add_argument("--from-stable-id", required=True, help="From entity stable ID")
    p.add_argument("--to-stable-id", required=True, help="To entity stable ID")
    p.add_argument("--from-tipo", required=True,
                   help="From entity type (personaje, lugar, objeto, animal, ser_sobrenatural, hilo, organizacion, arco, evento, grupo)")
    p.add_argument("--to-tipo", required=True,
                   help="To entity type (personaje, lugar, objeto, animal, ser_sobrenatural, hilo, organizacion, arco, evento, grupo)")
    p.add_argument("--type", required=True,
                   help="Relationship type (e.g. PAREJA_DE, FAMILIA_DE, SENTIMIENTO_HACIA, ACCION_SOBRE, VIVE_EN, POSEE)")
    p.add_argument("--rol",
                   help="Rol (required for person-person types, e.g. casado_con, traiciona, madre)")

    p = sub.add_parser("delete-relationship", help="Delete a relationship between two entities")
    p.add_argument("--proyecto", required=True, help="Proyecto slug")
    p.add_argument("--from-stable-id", required=True, help="From entity stable ID")
    p.add_argument("--to-stable-id", required=True, help="To entity stable ID")
    p.add_argument("--from-tipo", required=True,
                   help="From entity type (personaje, lugar, objeto, animal, ser_sobrenatural, hilo, organizacion, arco, evento, grupo)")
    p.add_argument("--to-tipo", required=True,
                   help="To entity type (personaje, lugar, objeto, animal, ser_sobrenatural, hilo, organizacion, arco, evento, grupo)")
    p.add_argument("--type", required=True,
                   help="Relationship type to delete")
    p.add_argument("--rol",
                   help="Rol to match (optional; if omitted, all relationships of type are deleted)")

    p = sub.add_parser("query-relationships", help="Get all relationships for an entity")
    p.add_argument("--proyecto", required=True, help="Proyecto slug")
    p.add_argument("--stable-id", required=True, help="Entity stable ID")
    p.add_argument("--tipo", required=True,
                   help="Entity type (personaje, lugar, objeto, animal, ser_sobrenatural, hilo, organizacion, arco, evento, grupo)")

    p = sub.add_parser("export", help="Backup all relationships for a proyecto to a JSON file")
    p.add_argument("--proyecto", required=True, help="Proyecto slug")
    p.add_argument("--output", required=True, help="Output file path (- for stdout)")

    p = sub.add_parser("import", help="Restore relationships from a JSON file")
    p.add_argument("--proyecto", required=True, help="Proyecto slug")
    p.add_argument("--input", required=True, help="Input file path (from 'export')")

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
