#!/usr/bin/env python3
"""Qdrant helper — novel writing system.

Manages beat and summary vectors in Qdrant using intfloat/multilingual-e5-large.
All IDs are UUID v5 derived deterministically from logical keys.

Summaries (L2/L3/L4) live exclusively in Qdrant — there is no Markdown fallback.
This script is the only way to read or write them.

Requirements:
  pip install fastembed

Usage:
  python3 scripts/qdrant.py init
  python3 scripts/qdrant.py upsert-beat  --novela SLUG --cap cap-XX --beat B_YY --accion TEXT [options]
  python3 scripts/qdrant.py update-beat  --novela SLUG --cap cap-XX --beat B_YY [--accion TEXT] [...]
  python3 scripts/qdrant.py enrich-beat  --novela SLUG --cap cap-XX --beat B_YY --narrative TEXT
  python3 scripts/qdrant.py upsert-summary --novela SLUG --nivel L1|L2|L3|L4 --id ID --texto TEXT [options]
  python3 scripts/qdrant.py query        --novela SLUG --text TEXT [--limit N]
  python3 scripts/qdrant.py query-chapters-by-beat --novela SLUG --text TEXT [options]
  python3 scripts/qdrant.py query-l2-recent       --novela SLUG --cap-num N [--last K]
  python3 scripts/qdrant.py query-l3              --novela SLUG [--arco arco-XX]
  python3 scripts/qdrant.py query-l4-current      --novela SLUG
  python3 scripts/qdrant.py export   --novela SLUG --output FILE
  python3 scripts/qdrant.py import   --novela SLUG --input FILE

Long texts can be passed via file: --accion-file PATH, --narrative-file PATH, --texto-file PATH
Use - as PATH to read from stdin.
"""

import argparse
import datetime
import json
import os
import sys
import uuid
import urllib.request
import urllib.error
from typing import Optional, List

QDRANT_URL = os.environ.get("QDRANT_URL", "http://localhost:6333")
EMBED_MODEL = "intfloat/multilingual-e5-large"
VECTOR_DIM = 1024

_embedding_model = None


# ── Embedding ─────────────────────────────────────────────────────────────────

def get_model():
    global _embedding_model
    if _embedding_model is None:
        from fastembed import TextEmbedding
        _embedding_model = TextEmbedding(EMBED_MODEL)
    return _embedding_model


def embed(text: str) -> List[float]:
    return next(get_model().embed([text])).tolist()


# ── ID generation ─────────────────────────────────────────────────────────────

def make_beat_id(novela: str, beat: str) -> str:
    """Deterministic UUID v5 from '{novela}:{beat}'.

    Beat IDs (B_0001) are globally unique and immutable.
    The chapter a beat belongs to can change; the UUID is stable.
    """
    return str(uuid.uuid5(uuid.NAMESPACE_URL, f"{novela}:{beat}"))


def make_summary_id(novela: str, nivel: str, summary_id: str) -> str:
    """Deterministic UUID v5 from '{novela}:{nivel}:{summary_id}'.

    Summary IDs are stable (C_121 for L2, A_001 for L3, global for L4).
    Chapter numbering changes don't affect the UUID.
    """
    return str(uuid.uuid5(uuid.NAMESPACE_URL, f"{novela}:{nivel}:{summary_id}"))


def make_entity_id(novela: str, entity_id: str) -> str:
    """Deterministic UUID v5 from '{novela}:entidad:{entity_id}'.

    The entity_id is the stable ID like 'per-ana-lopez' (includes the tipo prefix).
    The UUID is for the Qdrant point; the entity_id is the stable identifier
    stored in the payload.id field.
    """
    return str(uuid.uuid5(uuid.NAMESPACE_URL, f"{novela}:entidad:{entity_id}"))


def cap_num(cap_id: str) -> int:
    """'cap-03' → 3, 'cap-03-titulo' → 3, anything else → 0."""
    for part in cap_id.split("-")[1:]:
        try:
            return int(part)
        except ValueError:
            continue
    return 0


# ── Qdrant REST ───────────────────────────────────────────────────────────────

def qdrant(method: str, path: str, data: dict = None) -> dict:
    url = f"{QDRANT_URL}{path}"
    body = json.dumps(data).encode("utf-8") if data is not None else None
    req = urllib.request.Request(
        url, data=body, method=method.upper(),
        headers={"Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        msg = e.read().decode("utf-8", errors="replace")
        print(f"HTTP {e.code} {method.upper()} {path}: {msg}", file=sys.stderr)
        sys.exit(1)
    except urllib.error.URLError as e:
        print(f"Connection error ({QDRANT_URL}): {e.reason}", file=sys.stderr)
        sys.exit(1)


def collection_exists(name: str) -> bool:
    url = f"{QDRANT_URL}/collections/{name}"
    req = urllib.request.Request(url, method="GET")
    try:
        with urllib.request.urlopen(req):
            return True
    except urllib.error.HTTPError as e:
        return e.code != 404
    except urllib.error.URLError:
        return False


def create_collection(name: str):
    qdrant("PUT", f"/collections/{name}", {
        "vectors": {"size": VECTOR_DIM, "distance": "Cosine"},
    })
    indexes = {
        "beats": [
            ("novela_slug", "keyword"),
            ("parent_id",   "keyword"),
            ("fichas",      "keyword"),
        ],
        "summaries": [
            ("novela_slug", "keyword"),
            ("nivel",       "keyword"),
            ("parent_id",   "keyword"),
            ("fichas",      "keyword"),
        ],
        "entidades": [
            ("novela_slug", "keyword"),
            ("id",          "keyword"),
            ("tipo",        "keyword"),
            ("tags",        "keyword"),
        ],
    }
    for field, schema in indexes.get(name, []):
        qdrant("PUT", f"/collections/{name}/index", {
            "field_name": field, "field_schema": schema,
        })


def get_existing_payload(point_id: str, collection: str = "beats") -> Optional[dict]:
    result = qdrant("POST", f"/collections/{collection}/points", {
        "ids": [point_id], "with_payload": True,
    })
    points = result.get("result", [])
    return points[0].get("payload", {}) if points else None


# ── Text argument helpers ──────────────────────────────────────────────────────

def read_text(value: Optional[str], file_path: Optional[str]) -> Optional[str]:
    if file_path:
        if file_path == "-":
            return sys.stdin.read()
        with open(file_path, encoding="utf-8") as f:
            return f.read()
    return value


def read_fichas(value: Optional[str], file_path: Optional[str]) -> list:
    """Parse fichas from JSON inline (--fichas '[...]') or from a file.

    Each ficha is a string: the stable entity ID like "per-ana-lopez".
    The tipo (personaje, lugar, hilo, etc.) is derivable from the ID prefix.
    Returns [] if neither is provided.
    """
    raw = read_text(value, file_path)
    if not raw:
        return []
    try:
        fichas = json.loads(raw)
    except json.JSONDecodeError as e:
        print(f"Error: --fichas is not valid JSON: {e}", file=sys.stderr)
        sys.exit(1)
    if not isinstance(fichas, list):
        print("Error: --fichas must be a JSON array of strings (entity IDs)", file=sys.stderr)
        sys.exit(1)
    for f in fichas:
        if not isinstance(f, str):
            print(f"Error: each ficha must be a string (entity ID), got: {f!r}", file=sys.stderr)
            sys.exit(1)
    return fichas


# ── Commands ──────────────────────────────────────────────────────────────────

def cmd_init(_args):
    for name in ("beats", "summaries", "entidades"):
        if collection_exists(name):
            print(f"  {name}: already exists — skipped")
        else:
            create_collection(name)
            print(f"  {name}: created")
    print("Init complete.")


def cmd_upsert_beat(args):
    accion = read_text(args.accion, args.accion_file)
    if not accion:
        print("Error: --accion or --accion-file is required", file=sys.stderr)
        sys.exit(1)

    fichas = read_fichas(args.fichas, args.fichas_file)
    point_id = make_beat_id(args.novela, args.beat)
    vector = embed(accion)

    payload = {
        "novela_slug":   args.novela,
        "id":            args.beat,
        "parent_id":     args.parent_id,
        "accion":        accion,
        "tono":          args.tono or "",
        "extension":     args.extension or "MEDIA",
        "fichas":        fichas,
        "narrative_text": None,
        "vector_source": "guion",
        "cap":           args.cap,
        "hilo":          args.hilo or "",
    }

    qdrant("PUT", "/collections/beats/points?wait=true", {
        "points": [{"id": point_id, "vector": vector, "payload": payload}],
    })
    print(f"upserted  beats  {args.novela}:{args.beat} (parent={args.parent_id})  [{point_id}]")


def cmd_update_beat(args):
    """Patch structural fields. Re-embeds with new accion only if beat has no narrative yet."""
    point_id = make_beat_id(args.novela, args.beat)
    accion = read_text(args.accion, args.accion_file)

    update = {}
    if accion:            update["accion"]    = accion
    if args.tono:         update["tono"]      = args.tono
    if args.extension:    update["extension"] = args.extension
    if args.parent_id:    update["parent_id"] = args.parent_id
    if args.cap:          update["cap"]       = args.cap
    if args.hilo:         update["hilo"]      = args.hilo
    if args.fichas or args.fichas_file:
        update["fichas"] = read_fichas(args.fichas, args.fichas_file)

    if not update:
        print("Nothing to update — provide at least one field to change.", file=sys.stderr)
        sys.exit(1)

    # Decide re-embed strategy BEFORE touching Qdrant
    should_reembed = False
    if accion:
        existing = get_existing_payload(point_id)
        if existing is not None and not existing.get("has_narrative", False):
            should_reembed = True

    qdrant("POST", "/collections/beats/points/payload?wait=true", {
        "points": [point_id], "payload": update,
    })

    if should_reembed:
        vector = embed(accion)
        qdrant("PUT", "/collections/beats/points/vectors?wait=true", {
            "points": [{"id": point_id, "vector": vector}],
        })
        print(f"updated + re-embedded  beats  {args.novela}:{args.beat}")
    else:
        print(f"updated  beats  {args.novela}:{args.beat}")


def cmd_enrich_beat(args):
    """Add/update narrative_text and re-embed with it (accion field preserved)."""
    narrative = read_text(args.narrative, args.narrative_file)
    if not narrative:
        print("Error: --narrative or --narrative-file is required", file=sys.stderr)
        sys.exit(1)

    point_id = make_beat_id(args.novela, args.beat)
    vector = embed(narrative)

    payload_update = {
        "narrative_text": narrative,
        "has_narrative":  True,
        "vector_source":  "narrativa",
    }
    if args.fichas or args.fichas_file:
        payload_update["fichas"] = read_fichas(args.fichas, args.fichas_file)
    if args.cap:
        payload_update["cap"] = args.cap
    if args.hilo:
        payload_update["hilo"] = args.hilo

    qdrant("POST", "/collections/beats/points/payload?wait=true", {
        "points": [point_id],
        "payload": payload_update,
    })
    qdrant("PUT", "/collections/beats/points/vectors?wait=true", {
        "points": [{"id": point_id, "vector": vector}],
    })
    print(f"enriched  beats  {args.novela}:{args.beat}")


def cmd_upsert_summary(args):
    summary_text = read_text(args.texto, args.texto_file)
    if not summary_text:
        print("Error: --texto or --texto-file is required", file=sys.stderr)
        sys.exit(1)

    if not args.title:
        print("Error: --title is required (scene name for L1, chapter title for L2, arc name for L3, novel title for L4)", file=sys.stderr)
        sys.exit(1)

    if not args.id:
        print("Error: --id is required (e.g. E_001 for L1, C_121 for L2, A_001 for L3, global for L4)", file=sys.stderr)
        sys.exit(1)

    fichas = read_fichas(args.fichas, args.fichas_file)
    point_id = make_summary_id(args.novela, args.nivel, args.id)
    vector = embed(summary_text)

    payload = {
        "novela_slug": args.novela,
        "nivel":       args.nivel,
        "id":          args.id,
        "parent_id":   args.parent_id or "",
        "title":       args.title,
        "fichas":      fichas,
        "summary":     summary_text,
        "hilo":        args.hilo or "",
        "cap":         args.cap or "",
    }

    qdrant("PUT", "/collections/summaries/points?wait=true", {
        "points": [{"id": point_id, "vector": vector, "payload": payload}],
    })
    print(f"upserted  summaries  {args.novela}:{args.nivel}:{args.id} (parent={args.parent_id or '—'})  [{point_id}]")


def cmd_query(args):
    """Semantic search on beats collection, scoped to one novel."""
    query_text = read_text(args.text, args.text_file)
    if not query_text:
        print("Error: --text or --text-file is required", file=sys.stderr)
        sys.exit(1)

    vector = embed(query_text)

    must = [{"key": "novela_slug", "match": {"value": args.novela}}]

    body = {
        "vector":       vector,
        "limit":        args.limit,
        "with_payload": True,
        "filter":       {"must": must},
    }

    result = qdrant("POST", "/collections/beats/points/search", body)

    output = []
    for hit in result.get("result", []):
        p = hit.get("payload", {})
        text = p.get("narrative_text") or p.get("accion", "")
        output.append({
            "ref":            f"{p.get('parent_id')}:{p.get('id')}",
            "score":          round(hit.get("score", 0), 3),
            "has_narrative":  bool(p.get("narrative_text")),
            "tono":           p.get("tono", ""),
            "fichas":         p.get("fichas", []),
            "text":         text[:300] + "…" if len(text) > 300 else text,
        })

    print(json.dumps(output, ensure_ascii=False, indent=2))


def cmd_query_chapters_by_beat(args):
    """Two-stage retrieval: beat semantic search → unique chapters → L2 summaries.

    Stage 1: search 'beats' collection semantically.
    Stage 2: deduplicate by chapter (derived via beat.parent_id → scene → scene.parent_id),
             fetch L2 from 'summaries' collection.
    Only chapters with beat score >= min_score are included.
    Chapters where no L2 is found are silently skipped.
    """
    query_text = read_text(args.text, args.text_file)
    if not query_text:
        print("Error: --text or --text-file is required", file=sys.stderr)
        sys.exit(1)

    vector = embed(query_text)

    # Stage 1 — semantic search on beats
    must = [{"key": "novela_slug", "match": {"value": args.novela}}]
    body = {
        "vector":       vector,
        "limit":        args.top_beats,
        "with_payload": True,
        "filter":       {"must": must},
    }

    result = qdrant("POST", "/collections/beats/points/search", body)

    # Keep best score per scene (parent_id of the beat)
    best_by_scene = {}  # scene_id -> {score, beat_count}
    for hit in result.get("result", []):
        score = hit.get("score", 0)
        if score < args.min_score:
            continue
        p = hit.get("payload", {})
        scene_id = p.get("parent_id", "")
        if not scene_id:
            continue
        if scene_id not in best_by_scene or score > best_by_scene[scene_id]["score"]:
            best_by_scene[scene_id] = {"score": score}

    if not best_by_scene:
        print("[]")
        return

    # Stage 2a — fetch the scenes to get their parent_id (the chapter)
    scene_ids = list(best_by_scene.keys())
    scenes_result = qdrant("POST", "/collections/summaries/points", {
        "ids": [make_summary_id(args.novela, "L1", sid) for sid in scene_ids],
        "with_payload": True,
    })
    scene_to_chapter = {}
    for pt in scenes_result.get("result", []):
        p = pt.get("payload", {})
        if p.get("nivel") == "L1":
            scene_to_chapter[p.get("id", "")] = p.get("parent_id", "")

    # Keep best score per chapter
    best_by_chapter = {}  # chapter_id -> score
    for scene_id, info in best_by_scene.items():
        chapter = scene_to_chapter.get(scene_id, "")
        if not chapter:
            continue
        if chapter not in best_by_chapter or info["score"] > best_by_chapter[chapter]:
            best_by_chapter[chapter] = info["score"]

    # Sort by score descending, take top N chapters
    top_chapters = sorted(best_by_chapter.items(), key=lambda x: x[1], reverse=True)
    top_chapters = top_chapters[:args.top_chapters]

    # Stage 2b — fetch L2 summary for each chapter
    output = []
    for chapter_id, score in top_chapters:
        summary_result = qdrant("POST", "/collections/summaries/points", {
            "ids": [make_summary_id(args.novela, "L2", chapter_id)], "with_payload": True,
        })
        points = summary_result.get("result", [])
        if not points or not points[0].get("payload"):
            continue

        p = points[0]["payload"]
        output.append({
            "chapter_id": chapter_id,
            "title":      p.get("title", ""),
            "beat_score": round(score, 3),
            "l2_summary": p.get("summary", ""),
            "source":     "qdrant",
        })

    print(json.dumps(output, ensure_ascii=False, indent=2))


# ── Summary queries ───────────────────────────────────────────────────────────

def _query_summaries(novela: str, nivel: str, summary_id: str = None) -> list:
    """Low-level: fetch summary points by filters. Returns list of payloads."""
    must = [
        {"key": "novela_slug", "match": {"value": novela}},
        {"key": "nivel",       "match": {"value": nivel}},
    ]
    if summary_id is not None:
        must.append({"key": "id", "match": {"value": summary_id}})

    body = {
        "filter":       {"must": must},
        "limit":        100,
        "with_payload": True,
        "with_vector":  False,
    }
    result = qdrant("POST", "/collections/summaries/points/scroll", body)
    return [p.get("payload", {}) for p in result.get("result", {}).get("points", [])]


def cmd_query_l2_recent(args):
    """Get the last K L2 summaries for a novela, before the current one.

    Sort by id desc (lexicographic on 'C_NNN' = numeric on NNN), take the first K
    excluding the current chapter. Suitable for novelas with up to 999 chapters.
    """
    payloads = _query_summaries(args.novela, "L2")
    payloads.sort(key=lambda p: p.get("id", ""), reverse=True)

    output = []
    for p in payloads:
        if p.get("id", "") == args.current_id:
            continue
        output.append({
            "id":      p.get("id", ""),
            "title":   p.get("title", ""),
            "summary": p.get("summary", ""),
            "parent_id": p.get("parent_id", ""),
        })
        if len(output) >= args.last:
            break

    print(json.dumps(output, ensure_ascii=False, indent=2))


def cmd_query_l3(args):
    """Get L3 summaries (closed arcs) for a novela.

    By default: all closed arcs, sorted by cap_num asc.
    With --arco: a specific arc (e.g., 'arc-la-promesa'). Returns single object or [].
    The 'current' arc is determined by the agent from the L2 payload of the
    chapter being written — it queries for the L3 of that specific arco.
    """
    if args.arco:
        payloads = _query_summaries(args.novela, "L3", summary_id=args.arco)
        if not payloads:
            print("{}")
            return
        p = payloads[0]
        print(json.dumps({
            "id":        p.get("id", ""),
            "title":     p.get("title", ""),
            "parent_id": p.get("parent_id", ""),
            "summary":   p.get("summary", ""),
        }, ensure_ascii=False, indent=2))
    else:
        payloads = _query_summaries(args.novela, "L3")
        payloads.sort(key=lambda p: p.get("id", ""))
        output = [
            {
                "id":        p.get("id", ""),
                "title":     p.get("title", ""),
                "parent_id": p.get("parent_id", ""),
                "summary":   p.get("summary", ""),
            }
            for p in payloads
        ]
        print(json.dumps(output, ensure_ascii=False, indent=2))


def cmd_query_l4_current(args):
    """Get the L4 global summary for a novela. Returns empty object if none."""
    payloads = _query_summaries(args.novela, "L4", summary_id="global")
    if not payloads:
        print("{}")
        return
    p = payloads[0]
    print(json.dumps({
        "id":        p.get("id", ""),
        "title":     p.get("title", ""),
        "parent_id": p.get("parent_id", ""),
        "summary":   p.get("summary", ""),
    }, ensure_ascii=False, indent=2))


# ── Entity commands ───────────────────────────────────────────────────────────

ENTITY_VALID_TIPOS = {
    "personaje", "lugar", "objeto", "animal",
    "hilo", "organizacion", "arcos", "evento",
}


def _validate_entity_payload(args, partial: bool = False) -> dict:
    """Validate entity fields and return the payload to write.

    partial=True allows some fields to be missing (for update-entity).
    Returns dict with all fields. Raises SystemExit on validation error.
    """
    payload = {}
    if not partial or args.id is not None:
        if not args.id:
            if not partial:
                print("Error: --id is required", file=sys.stderr)
                sys.exit(1)
        else:
            payload["id"] = args.id
    if args.tipo is not None:
        if args.tipo not in ENTITY_VALID_TIPOS:
            print(f"Error: --tipo must be one of {sorted(ENTITY_VALID_TIPOS)}", file=sys.stderr)
            sys.exit(1)
        payload["tipo"] = args.tipo
    elif not partial:
        print("Error: --tipo is required", file=sys.stderr)
        sys.exit(1)

    if not partial or args.nombre is not None:
        if not args.nombre:
            if not partial:
                print("Error: --nombre is required", file=sys.stderr)
                sys.exit(1)
        else:
            payload["nombre"] = args.nombre

    if args.tags is not None:
        payload["tags"] = [t.strip() for t in args.tags.split(",") if t.strip()]
    elif not partial:
        payload["tags"] = []

    if args.fijo is not None or args.fijo_file is not None:
        fijo = read_text(args.fijo, args.fijo_file)
        if not fijo and not partial:
            print("Error: --fijo/--fijo-file is required (or pass empty to leave empty)", file=sys.stderr)
            sys.exit(1)
        payload["fijo"] = fijo or ""

    if args.dinamico is not None or args.dinamico_file is not None:
        dinamico = read_text(args.dinamico, args.dinamico_file)
        if dinamico is not None:
            payload["dinamico"] = dinamico

    return payload


def cmd_upsert_entity(args):
    """Create or replace an entity in the 'entidades' collection.

    The vector is computed from the FIJO description (or nombre+fijo if FIJO empty).
    """
    payload = _validate_entity_payload(args, partial=False)
    point_id = make_entity_id(args.novela, payload["id"])
    text_to_embed = payload.get("fijo") or payload.get("nombre", "")
    vector = embed(text_to_embed) if text_to_embed else [0.0] * VECTOR_DIM

    payload["novela_slug"] = args.novela

    qdrant("PUT", "/collections/entidades/points?wait=true", {
        "points": [{"id": point_id, "vector": vector, "payload": payload}],
    })
    print(f"upserted  entidades  {args.novela}:{payload['id']}  [{point_id}]")


def cmd_update_entity(args):
    """Patch specific fields of an entity. Vector is recomputed only if --fijo is provided."""
    payload = _validate_entity_payload(args, partial=True)
    if not payload:
        print("Nothing to update — provide at least one field to change.", file=sys.stderr)
        sys.exit(1)

    payload["novela_slug"] = args.novela
    point_id = make_entity_id(args.novela, args.id)

    # Re-embed only if FIJO changed
    if "fijo" in payload:
        text_to_embed = payload["fijo"] or payload.get("nombre", "")
        vector = embed(text_to_embed) if text_to_embed else [0.0] * VECTOR_DIM
        qdrant("PUT", "/collections/entidades/points/vectors?wait=true", {
            "points": [{"id": point_id, "vector": vector}],
        })

    qdrant("POST", "/collections/entidades/points/payload?wait=true", {
        "points": [point_id],
        "payload": payload,
    })
    print(f"updated  entidades  {args.novela}:{args.id}")


def cmd_query_entity(args):
    """Fetch a single entity by its stable ID. Returns object or {} if not found."""
    point_id = make_entity_id(args.novela, args.id)
    result = qdrant("POST", "/collections/entidades/points", {
        "ids": [point_id], "with_payload": True, "with_vector": False,
    })
    points = result.get("result", [])
    if not points or not points[0].get("payload"):
        print("{}")
        return
    p = points[0]["payload"]
    p.pop("novela_slug", None)
    print(json.dumps(p, ensure_ascii=False, indent=2))


def cmd_query_entities(args):
    """List entities of a novela, with optional filters."""
    must = [{"key": "novela_slug", "match": {"value": args.novela}}]
    if args.tipo:
        must.append({"key": "tipo", "match": {"value": args.tipo}})
    if args.tag:
        must.append({"key": "tags", "match": {"value": args.tag}})

    body = {
        "filter":       {"must": must},
        "limit":        args.limit,
        "with_payload": True,
        "with_vector":  False,
    }
    result = qdrant("POST", "/collections/entidades/points/scroll", body)
    payloads = [p.get("payload", {}) for p in result.get("result", {}).get("points", [])]
    payloads.sort(key=lambda p: (p.get("tipo", ""), p.get("id", "")))

    for p in payloads:
        p.pop("novela_slug", None)
        p.pop("fijo", None)
        p.pop("dinamico", None)
    print(json.dumps(payloads, ensure_ascii=False, indent=2))


def cmd_query_entities_by_text(args):
    """Semantic search on entity FIJO descriptions."""
    text = read_text(args.text, args.text_file)
    if not text:
        print("Error: --text or --text-file is required", file=sys.stderr)
        sys.exit(1)
    vector = embed(text)

    must = [{"key": "novela_slug", "match": {"value": args.novela}}]
    if args.tipo:
        must.append({"key": "tipo", "match": {"value": args.tipo}})

    body = {
        "vector":       vector,
        "limit":        args.limit,
        "with_payload": True,
        "filter":       {"must": must},
    }
    result = qdrant("POST", "/collections/entidades/points/search", body)
    output = []
    for hit in result.get("result", []):
        p = hit.get("payload", {})
        output.append({
            "id":     p.get("id", ""),
            "tipo":   p.get("tipo", ""),
            "nombre": p.get("nombre", ""),
            "tags":   p.get("tags", []),
            "score":  round(hit.get("score", 0), 3),
        })
    print(json.dumps(output, ensure_ascii=False, indent=2))


# ── Backup ─────────────────────────────────────────────────────────────────────

def cmd_export(args):
    """Dump all beats and summaries for a novela to a JSON file.

    Use this for backup. The resulting file can be re-imported with 'import'
    if Qdrant is lost.
    """
    body = {
        "filter":       {"must": [{"key": "novela_slug", "match": {"value": args.novela}}]},
        "limit":        10000,
        "with_payload": True,
        "with_vector":  True,
    }
    beats = qdrant("POST", "/collections/beats/points/scroll", body)
    summaries = qdrant("POST", "/collections/summaries/points/scroll", body)

    backup = {
        "novela":       args.novela,
        "exported_at":  __import__("datetime").datetime.utcnow().isoformat() + "Z",
        "beats_count":  len(beats.get("result", {}).get("points", [])),
        "summaries_count": len(summaries.get("result", {}).get("points", [])),
        "beats":        beats.get("result", {}).get("points", []),
        "summaries":    summaries.get("result", {}).get("points", []),
    }

    if args.output == "-":
        json.dump(backup, sys.stdout, ensure_ascii=False, indent=2)
        print()
    else:
        with open(args.output, "w", encoding="utf-8") as f:
            json.dump(backup, f, ensure_ascii=False, indent=2)
        print(f"exported  {args.novela}  →  {args.output}  "
              f"({backup['beats_count']} beats, {backup['summaries_count']} summaries)")


def cmd_import(args):
    """Restore beats and summaries from a JSON file produced by 'export'."""
    with open(args.input, encoding="utf-8") as f:
        backup = json.load(f)

    if backup.get("novela") != args.novela:
        print(f"Warning: backup novela='{backup.get('novela')}' != "
              f"target='{args.novela}'. Proceeding anyway.", file=sys.stderr)

    for collection, key in [("beats", "beats"), ("summaries", "summaries")]:
        points = backup.get(key, [])
        if not points:
            continue
        # Restore in chunks of 100 to avoid request size limits
        for i in range(0, len(points), 100):
            chunk = points[i:i+100]
            qdrant("PUT", f"/collections/{collection}/points?wait=true", {
                "points": chunk,
            })
        print(f"imported  {collection}  {len(points)} points from {args.input}")


# ── CLI ───────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Qdrant helper — novel writing system",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("init", help="Create collections and payload indexes")

    def beat_id_args(p, parent_required=True):
        p.add_argument("--novela", required=True, help="Novel slug (from estado.json)")
        p.add_argument("--beat",   required=True, help="Beat ID, e.g. B_0005")
        p.add_argument("--cap",    help="Chapter this beat belongs to (e.g. cap-03). Display field, can change.")
        p.add_argument("--hilo",   help="Thread ID this beat belongs to (e.g. hilo-sumer)")
        if parent_required:
            p.add_argument("--parent-id", required=True, help="Parent scene ID, e.g. E_001")
        else:
            p.add_argument("--parent-id", help="Parent scene ID (optional, only set when moving beat)")

    p = sub.add_parser("upsert-beat", help="Create or replace a beat entry with embedding")
    beat_id_args(p)
    p.add_argument("--accion",      help="Beat action text (inline)")
    p.add_argument("--accion-file", help="File with action text (- = stdin)")
    p.add_argument("--tono")
    p.add_argument("--extension", choices=["BREVE", "MEDIA", "EXTENSA"])
    p.add_argument("--fichas",        help='JSON array of entity IDs (e.g. \'["per-ana-lopez","lug-casa-ana"]\')')
    p.add_argument("--fichas-file",   help="File with --fichas JSON (- = stdin)")

    p = sub.add_parser("update-beat", help="Patch structural fields; re-embeds if accion changes and no narrative yet")
    beat_id_args(p, parent_required=False)
    p.add_argument("--accion")
    p.add_argument("--accion-file")
    p.add_argument("--tono")
    p.add_argument("--extension", choices=["BREVE", "MEDIA", "EXTENSA"])
    p.add_argument("--fichas")
    p.add_argument("--fichas-file")

    p = sub.add_parser("enrich-beat", help="Add narrative_text and re-embed; accion preserved")
    beat_id_args(p)
    p.add_argument("--narrative",      help="Narrative text (inline)")
    p.add_argument("--narrative-file", help="File with narrative text (- = stdin)")
    p.add_argument("--fichas",         help="Optional: also patch the fichas[] array")
    p.add_argument("--fichas-file",    help="File with --fichas JSON (- = stdin)")

    p = sub.add_parser("upsert-summary", help="Create or replace a summary entry (L1/L2/L3/L4)")
    p.add_argument("--novela",    required=True)
    p.add_argument("--nivel",     required=True, choices=["L1", "L2", "L3", "L4"])
    p.add_argument("--id",        required=True, help="Summary ID: E_NNN (L1), C_NNN (L2), A_NNN (L3), global (L4)")
    p.add_argument("--parent-id", help="Parent ID: C_NNN (L1), A_NNN (L2), empty for L3/L4")
    p.add_argument("--texto")
    p.add_argument("--texto-file")
    p.add_argument("--title",     required=True, help="Scene name (L1), chapter title (L2), arc name (L3), novel title (L4)")
    p.add_argument("--fichas",        help="JSON array of entity IDs")
    p.add_argument("--fichas-file",   help="File with --fichas JSON (- = stdin)")
    p.add_argument("--hilo",          help="Thread ID this summary belongs to (e.g. hilo-sumer)")
    p.add_argument("--cap",           help="Chapter display ID (e.g. cap-03)")

    p = sub.add_parser("query", help="Semantic search on beats collection")
    p.add_argument("--novela", required=True)
    p.add_argument("--text",      help="Query text (inline)")
    p.add_argument("--text-file", help="File with query text")
    p.add_argument("--limit", type=int, default=5)

    p = sub.add_parser(
        "query-chapters-by-beat",
        help="Two-stage: beat search → unique chapters → L2 summaries (recommended for memoria)",
    )
    p.add_argument("--novela", required=True)
    p.add_argument("--text",      help="Query text (inline)")
    p.add_argument("--text-file", help="File with query text")
    p.add_argument(
        "--exclude-from", type=int,
        help="Exclude beats with cap_num >= N (pass current_cap - 3)",
    )
    p.add_argument("--top-beats",    type=int,   default=8,    help="Beat candidates for initial search (default 8)")
    p.add_argument("--top-chapters", type=int,   default=3,    help="Max unique chapters to return (default 3)")
    p.add_argument("--min-score",    type=float, default=0.75, help="Min beat cosine score to include a chapter (default 0.75)")

    p = sub.add_parser(
        "query-l2-recent",
        help="Get the last K L2 summaries before the current chapter",
    )
    p.add_argument("--novela",     required=True)
    p.add_argument("--current-id", required=True, help="Current chapter ID (L2s with this id are excluded)")
    p.add_argument("--last",       type=int, default=3, help="How many recent L2s to retrieve (default 3)")

    p = sub.add_parser(
        "query-l3",
        help="Get L3 summaries for closed arcs (all, or one specific --arco)",
    )
    p.add_argument("--novela", required=True)
    p.add_argument("--arco",   help="Specific arc ID, e.g. arco-01 (returns single object or {})")

    p = sub.add_parser(
        "query-l4-current",
        help="Get the L4 global summary for a novela (cap_id=global)",
    )
    p.add_argument("--novela", required=True)

    p = sub.add_parser("export", help="Backup beats + summaries for a novela to a JSON file")
    p.add_argument("--novela",  required=True)
    p.add_argument("--output",  required=True, help="Output file path (- for stdout)")

    p = sub.add_parser("import", help="Restore beats + summaries from a JSON file")
    p.add_argument("--novela", required=True)
    p.add_argument("--input",  required=True, help="Input file path (from 'export')")

    def entity_common(p):
        p.add_argument("--novela", required=True, help="Novel slug (from estado.json)")

    p = sub.add_parser("upsert-entity", help="Create or replace an entity (personaje, lugar, hilo, etc.)")
    entity_common(p)
    p.add_argument("--id",        required=True, help="Entity ID, e.g. per-ana-lopez")
    p.add_argument("--tipo",      required=True, choices=sorted(ENTITY_VALID_TIPOS))
    p.add_argument("--nombre",    required=True)
    p.add_argument("--tags",      help="Comma-separated tags for filtering (e.g. 'muerto,villano')")
    p.add_argument("--fijo",          help="Inmutable description (inline)")
    p.add_argument("--fijo-file",     help="Inmutable description from file (- = stdin)")
    p.add_argument("--dinamico",      help="Current state (inline)")
    p.add_argument("--dinamico-file", help="Current state from file (- = stdin)")

    p = sub.add_parser("update-entity", help="Patch specific fields of an entity")
    entity_common(p)
    p.add_argument("--id",            required=True)
    p.add_argument("--tipo",          choices=sorted(ENTITY_VALID_TIPOS))
    p.add_argument("--nombre")
    p.add_argument("--tags")
    p.add_argument("--fijo")
    p.add_argument("--fijo-file")
    p.add_argument("--dinamico",          help="Current state (updated by cronista)")
    p.add_argument("--dinamico-file",     help="Current state from file (- = stdin)")

    p = sub.add_parser("query-entity", help="Fetch a single entity by its stable ID")
    entity_common(p)
    p.add_argument("--id", required=True)

    p = sub.add_parser("query-entities", help="List entities of a novela, with optional filters")
    entity_common(p)
    p.add_argument("--tipo",  choices=sorted(ENTITY_VALID_TIPOS))
    p.add_argument("--tag",   help="Filter by single tag (e.g. 'muerto', 'villano')")
    p.add_argument("--limit", type=int, default=100)

    p = sub.add_parser("query-entities-by-text", help="Semantic search on entity FIJO descriptions")
    entity_common(p)
    p.add_argument("--text",      help="Query text (inline)")
    p.add_argument("--text-file", help="File with query text (- = stdin)")
    p.add_argument("--tipo",      choices=sorted(ENTITY_VALID_TIPOS))
    p.add_argument("--limit",     type=int, default=5)

    args = parser.parse_args()

    {
        "init":                       cmd_init,
        "upsert-beat":                cmd_upsert_beat,
        "update-beat":                cmd_update_beat,
        "enrich-beat":                cmd_enrich_beat,
        "upsert-summary":             cmd_upsert_summary,
        "query":                      cmd_query,
        "query-chapters-by-beat":     cmd_query_chapters_by_beat,
        "query-l2-recent":            cmd_query_l2_recent,
        "query-l3":                   cmd_query_l3,
        "query-l4-current":           cmd_query_l4_current,
        "export":                     cmd_export,
        "import":                     cmd_import,
        "upsert-entity":              cmd_upsert_entity,
        "update-entity":              cmd_update_entity,
        "query-entity":               cmd_query_entity,
        "query-entities":             cmd_query_entities,
        "query-entities-by-text":     cmd_query_entities_by_text,
    }[args.command](args)


if __name__ == "__main__":
    main()
