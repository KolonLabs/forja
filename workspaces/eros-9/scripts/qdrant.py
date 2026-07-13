#!/usr/bin/env python3
"""Qdrant helper — proyecto writing system.

Manages beat, summary and entity vectors in Qdrant using intfloat/multilingual-e5-large.
All IDs are UUID v5 derived deterministically from stable identifiers.

Summaries (L2/L3/L4) live exclusively in Qdrant — there is no Markdown fallback.
This script is the only way to read or write them.

Requirements:
  pip install fastembed

Usage:
  python3 scripts/qdrant.py init
  python3 scripts/qdrant.py upsert-beat  --proyecto SLUG --beat STABLE_ID --accion TEXT [options]
  python3 scripts/qdrant.py update-beat  --proyecto SLUG --beat STABLE_ID [--accion TEXT] [...]
  python3 scripts/qdrant.py enrich-beat  --proyecto SLUG --beat STABLE_ID --narrative TEXT
  python3 scripts/qdrant.py upsert-summary --proyecto SLUG --nivel L1|L2|L3|L4 --id STABLE_ID --texto TEXT [options]
  python3 scripts/qdrant.py query        --proyecto SLUG --text TEXT [--limit N]
  python3 scripts/qdrant.py query-chapters-by-beat --proyecto SLUG --text TEXT [options]
  python3 scripts/qdrant.py query-l2-recent       --proyecto SLUG --current-id STABLE_ID [--last K]
  python3 scripts/qdrant.py query-l3              --proyecto SLUG [--arco arco-XX]
  python3 scripts/qdrant.py query-l4-current      --proyecto SLUG
  python3 scripts/qdrant.py export   --proyecto SLUG --output FILE
  python3 scripts/qdrant.py import   --proyecto SLUG --input FILE

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

def make_point_id(stable_id: str) -> str:
    """Deterministic UUID v5 from stable_id."""
    return str(uuid.uuid5(uuid.NAMESPACE_URL, stable_id))


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
            ("proyecto",   "keyword"),
            ("stable_id",  "keyword"),
            ("parent_id",  "keyword"),
            ("fichas",     "keyword"),
        ],
        "summaries": [
            ("proyecto",   "keyword"),
            ("stable_id",  "keyword"),
            ("nivel",      "keyword"),
            ("parent_id",  "keyword"),
            ("fichas",     "keyword"),
        ],
        "entidades": [
            ("proyecto",   "keyword"),
            ("stable_id",  "keyword"),
            ("tipo",       "keyword"),
            ("tags",       "keyword"),
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

    Each ficha is a string: the stable entity ID.
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
        print("Error: --fichas must be a JSON array of strings (entity stable IDs)", file=sys.stderr)
        sys.exit(1)
    for f in fichas:
        if not isinstance(f, str):
            print(f"Error: each ficha must be a string (entity stable ID), got: {f!r}", file=sys.stderr)
            sys.exit(1)
    return fichas


def resolve_fichas(fichas: list) -> list:
    """Resolve entity stable IDs to their UUID8s."""
    return [make_point_id(f) for f in fichas]


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

    fichas = resolve_fichas(read_fichas(args.fichas, args.fichas_file))
    point_id = make_point_id(args.beat)
    vector = embed(accion)

    payload = {
        "proyecto":       args.proyecto,
        "stable_id":      args.beat,
        "seq":            args.seq or 0,
        "parent_id":      make_point_id(args.parent_id),
        "accion":         accion,
        "tono":           args.tono or "",
        "extension":      args.extension or "MEDIA",
        "fichas":         fichas,
        "narrative_text": None,
        "vector_source":  "guion",
    }

    qdrant("PUT", "/collections/beats/points?wait=true", {
        "points": [{"id": point_id, "vector": vector, "payload": payload}],
    })
    print(f"upserted  beats  {args.proyecto}:{args.beat} (parent={args.parent_id})  [{point_id}]")


def cmd_update_beat(args):
    """Patch structural fields. Re-embeds with new accion only if beat has no narrative yet."""
    point_id = make_point_id(args.beat)
    accion = read_text(args.accion, args.accion_file)

    update = {}
    if accion:               update["accion"]    = accion
    if args.tono:            update["tono"]      = args.tono
    if args.extension:       update["extension"] = args.extension
    if args.parent_id:       update["parent_id"] = make_point_id(args.parent_id)
    if args.seq is not None: update["seq"]       = args.seq
    if args.fichas or args.fichas_file:
        update["fichas"] = resolve_fichas(read_fichas(args.fichas, args.fichas_file))

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
        print(f"updated + re-embedded  beats  {args.proyecto}:{args.beat}")
    else:
        print(f"updated  beats  {args.proyecto}:{args.beat}")


def cmd_enrich_beat(args):
    """Add/update narrative_text and re-embed with it (accion field preserved)."""
    narrative = read_text(args.narrative, args.narrative_file)
    if not narrative:
        print("Error: --narrative or --narrative-file is required", file=sys.stderr)
        sys.exit(1)

    point_id = make_point_id(args.beat)
    vector = embed(narrative)

    payload_update = {
        "narrative_text": narrative,
        "has_narrative":  True,
        "vector_source":  "narrativa",
    }
    if args.fichas or args.fichas_file:
        payload_update["fichas"] = resolve_fichas(read_fichas(args.fichas, args.fichas_file))
    if args.seq is not None:
        payload_update["seq"] = args.seq

    qdrant("POST", "/collections/beats/points/payload?wait=true", {
        "points": [point_id],
        "payload": payload_update,
    })
    qdrant("PUT", "/collections/beats/points/vectors?wait=true", {
        "points": [{"id": point_id, "vector": vector}],
    })
    print(f"enriched  beats  {args.proyecto}:{args.beat}")


def cmd_upsert_summary(args):
    summary_text = read_text(args.texto, args.texto_file)
    if not summary_text:
        print("Error: --texto or --texto-file is required", file=sys.stderr)
        sys.exit(1)

    if not args.id:
        print("Error: --id is required (stable ID for the summary)", file=sys.stderr)
        sys.exit(1)

    fichas = resolve_fichas(read_fichas(args.fichas, args.fichas_file))
    point_id = make_point_id(args.id)
    vector = embed(summary_text)

    payload = {
        "proyecto":   args.proyecto,
        "stable_id":  args.id,
        "seq":        args.seq or 0,
        "nivel":      args.nivel,
        "parent_id":  make_point_id(args.parent_id) if args.parent_id else "",
        "texto":      summary_text,
        "fichas":     fichas,
    }
    if args.hilo:
        payload["hilo"] = args.hilo

    qdrant("PUT", "/collections/summaries/points?wait=true", {
        "points": [{"id": point_id, "vector": vector, "payload": payload}],
    })
    print(f"upserted  summaries  {args.proyecto}:{args.nivel}:{args.id} (parent={args.parent_id or '—'})  [{point_id}]")


def cmd_query(args):
    """Semantic search on beats collection, scoped to one proyecto."""
    query_text = read_text(args.text, args.text_file)
    if not query_text:
        print("Error: --text or --text-file is required", file=sys.stderr)
        sys.exit(1)

    vector = embed(query_text)

    must = [{"key": "proyecto", "match": {"value": args.proyecto}}]

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
            "ref":            f"{p.get('parent_id')}:{p.get('stable_id')}",
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
    must = [{"key": "proyecto", "match": {"value": args.proyecto}}]
    body = {
        "vector":       vector,
        "limit":        args.top_beats,
        "with_payload": True,
        "filter":       {"must": must},
    }

    result = qdrant("POST", "/collections/beats/points/search", body)

    # Keep best score per scene (parent_id of the beat, which is a UUID8)
    best_by_scene = {}  # scene_uuid -> {score}
    for hit in result.get("result", []):
        score = hit.get("score", 0)
        if score < args.min_score:
            continue
        p = hit.get("payload", {})
        scene_uuid = p.get("parent_id", "")
        if not scene_uuid:
            continue
        if scene_uuid not in best_by_scene or score > best_by_scene[scene_uuid]["score"]:
            best_by_scene[scene_uuid] = {"score": score}

    if not best_by_scene:
        print("[]")
        return

    # Stage 2a — fetch the scenes (by UUID8) to get their parent_id (the chapter UUID8)
    scene_uuids = list(best_by_scene.keys())
    scenes_result = qdrant("POST", "/collections/summaries/points", {
        "ids": scene_uuids,
        "with_payload": True,
    })
    scene_to_chapter = {}  # scene_uuid -> chapter_uuid
    for pt in scenes_result.get("result", []):
        p = pt.get("payload", {})
        if p.get("nivel") == "L1":
            chapter_uuid = p.get("parent_id", "")
            if chapter_uuid:
                scene_to_chapter[pt["id"]] = chapter_uuid

    # Keep best score per chapter
    best_by_chapter = {}  # chapter_uuid -> score
    for scene_uuid, info in best_by_scene.items():
        chapter_uuid = scene_to_chapter.get(scene_uuid, "")
        if not chapter_uuid:
            continue
        if chapter_uuid not in best_by_chapter or info["score"] > best_by_chapter[chapter_uuid]:
            best_by_chapter[chapter_uuid] = info["score"]

    # Sort by score descending, take top N chapters
    top_chapters = sorted(best_by_chapter.items(), key=lambda x: x[1], reverse=True)
    top_chapters = top_chapters[:args.top_chapters]

    # Stage 2b — fetch L2 summary for each chapter (by UUID8)
    output = []
    for chapter_uuid, score in top_chapters:
        summary_result = qdrant("POST", "/collections/summaries/points", {
            "ids": [chapter_uuid], "with_payload": True,
        })
        points = summary_result.get("result", [])
        if not points or not points[0].get("payload"):
            continue

        p = points[0]["payload"]
        output.append({
            "chapter_stable_id": p.get("stable_id", ""),
            "chapter_uuid":      chapter_uuid,
            "beat_score":        round(score, 3),
            "l2_texto":          p.get("texto", ""),
            "source":            "qdrant",
        })

    print(json.dumps(output, ensure_ascii=False, indent=2))


# ── Summary queries ───────────────────────────────────────────────────────────

def _query_summaries(proyecto: str, nivel: str, stable_id: str = None) -> list:
    """Low-level: fetch summary points by filters. Returns list of payloads."""
    must = [
        {"key": "proyecto", "match": {"value": proyecto}},
        {"key": "nivel",    "match": {"value": nivel}},
    ]
    if stable_id is not None:
        must.append({"key": "stable_id", "match": {"value": stable_id}})

    body = {
        "filter":       {"must": must},
        "limit":        100,
        "with_payload": True,
        "with_vector":  False,
    }
    result = qdrant("POST", "/collections/summaries/points/scroll", body)
    return [p.get("payload", {}) for p in result.get("result", {}).get("points", [])]


def cmd_query_l2_recent(args):
    """Get the last K L2 (chapter) summaries for a proyecto, before the current one.

    Queries L2 entries whose parent_id is an L3 (acto), then orders by seq desc.
    Excludes the current chapter. Supports multi-hilo via --hilo filter.
    """
    must = [
        {"key": "proyecto", "match": {"value": args.proyecto}},
        {"key": "nivel",    "match": {"value": "L2"}},
    ]
    if args.hilo:
        must.append({"key": "hilo", "match": {"value": args.hilo}})

    body = {
        "filter":       {"must": must},
        "limit":        1000,
        "with_payload": True,
        "with_vector":  False,
    }
    result = qdrant("POST", "/collections/summaries/points/scroll", body)
    payloads = [p.get("payload", {}) for p in result.get("result", {}).get("points", [])]

    # Filter by parent_id being an L3 (acto) — meaning it belongs to a known act.
    # Since all L2 have parent_id = an L3, the basic filter is sufficient.

    # Sort by seq desc (numeric, not lexicographic)
    payloads.sort(key=lambda p: p.get("seq", 0), reverse=True)

    output = []
    for p in payloads:
        if p.get("stable_id", "") == args.current_id:
            continue
        output.append({
            "stable_id":  p.get("stable_id", ""),
            "seq":        p.get("seq", 0),
            "parent_id":  p.get("parent_id", ""),
            "hilo":       p.get("hilo", ""),
            "texto":      p.get("texto", ""),
        })
        if len(output) >= args.last:
            break

    print(json.dumps(output, ensure_ascii=False, indent=2))


def cmd_query_l3(args):
    """Get L3 summaries (closed arcs) for a proyecto.

    By default: all closed arcs, sorted by stable_id asc.
    With --arco: a specific arc (e.g., 'arc-la-promesa'). Returns single object or {}.
    """
    if args.arco:
        payloads = _query_summaries(args.proyecto, "L3", stable_id=args.arco)
        if not payloads:
            print("{}")
            return
        p = payloads[0]
        print(json.dumps({
            "stable_id":  p.get("stable_id", ""),
            "parent_id":  p.get("parent_id", ""),
            "texto":      p.get("texto", ""),
        }, ensure_ascii=False, indent=2))
    else:
        payloads = _query_summaries(args.proyecto, "L3")
        payloads.sort(key=lambda p: p.get("stable_id", ""))
        output = [
            {
                "stable_id":  p.get("stable_id", ""),
                "parent_id":  p.get("parent_id", ""),
                "texto":      p.get("texto", ""),
            }
            for p in payloads
        ]
        print(json.dumps(output, ensure_ascii=False, indent=2))


def cmd_query_l4_current(args):
    """Get the L4 global summary for a proyecto. Returns empty object if none."""
    payloads = _query_summaries(args.proyecto, "L4", stable_id="global")
    if not payloads:
        print("{}")
        return
    p = payloads[0]
    print(json.dumps({
        "stable_id":  p.get("stable_id", ""),
        "parent_id":  p.get("parent_id", ""),
        "texto":      p.get("texto", ""),
    }, ensure_ascii=False, indent=2))


# ── Position-based queries (L1/L2/L3/L4) ─────────────────────────────────────

def _query_summaries_by_position(proyecto: str, nivel: str, parent_id: str = "",
                                 hilo: str = "", seq: int = None) -> list:
    """Fetch summary points by (proyecto, nivel, parent_id, seq[, hilo]).

    parent_id is a STABLE ID of the parent node, resolved to UUID8 internally.
    hilo is an optional filter for multi-hilo novels.
    seq is optional: if given, returns the specific point; if None, returns all siblings.
    """
    must = [
        {"key": "proyecto",  "match": {"value": proyecto}},
        {"key": "nivel",     "match": {"value": nivel}},
    ]
    if parent_id:
        must.append({"key": "parent_id", "match": {"value": make_point_id(parent_id)}})
    if hilo:
        must.append({"key": "hilo", "match": {"value": hilo}})
    if seq is not None:
        must.append({"key": "seq", "match": {"value": seq}})

    body = {
        "filter":       {"must": must},
        "limit":        100,
        "with_payload": True,
        "with_vector":  False,
    }
    result = qdrant("POST", "/collections/summaries/points/scroll", body)
    return [p.get("payload", {}) for p in result.get("result", {}).get("points", [])]


def cmd_query_summary_by_position(args):
    """Find a summary by (nivel, parent_id, seq[, hilo]).

    Example: find the L1 (scene) with seq=3 under the chapter with stable_id='C_005'.
    """
    payloads = _query_summaries_by_position(
        args.proyecto, args.nivel,
        parent_id=args.parent_id or "",
        hilo=args.hilo or "",
        seq=args.seq,
    )
    if not payloads:
        print("[]")
        return
    for p in payloads:
        p.pop("proyecto", None)
    print(json.dumps(payloads, ensure_ascii=False, indent=2))


def cmd_upsert_summary_by_position(args):
    """Idempotent upsert: find by (nivel, parent_id, seq[, hilo]) and update, or create.

    If a summary exists at that position, update its texto. If not, create with new stable_id.
    """
    texto = read_text(args.texto, args.texto_file)
    if not texto:
        print("Error: --texto or --texto-file is required", file=sys.stderr)
        sys.exit(1)
    if not args.parent_id and args.nivel != "L4":
        print("Error: --parent-id is required (except for L4)", file=sys.stderr)
        sys.exit(1)

    existing = _query_summaries_by_position(
        args.proyecto, args.nivel,
        parent_id=args.parent_id,
        hilo=args.hilo or "",
        seq=args.seq or 0,
    )

    fichas = resolve_fichas(read_fichas(args.fichas, args.fichas_file))

    if existing:
        stable_id = existing[0].get("stable_id", "")
        point_id = make_point_id(stable_id)
        payload = existing[0].copy()
        payload["texto"] = texto
        payload["fichas"] = fichas
        qdrant("POST", "/collections/summaries/points/payload?wait=true", {
            "points": [point_id], "payload": payload,
        })
        print(f"updated  summaries  {args.proyecto}:{args.nivel}:{stable_id}  [{point_id}]")
    else:
        stable_id = str(uuid.uuid4().hex[:8])
        point_id = make_point_id(stable_id)
        vector = embed(texto)
        payload = {
            "proyecto":   args.proyecto,
            "stable_id":  stable_id,
            "seq":        args.seq or 0,
            "nivel":      args.nivel,
            "parent_id":  make_point_id(args.parent_id),
            "texto":      texto,
            "fichas":     fichas,
        }
        if args.hilo:
            payload["hilo"] = args.hilo
        qdrant("PUT", "/collections/summaries/points?wait=true", {
            "points": [{"id": point_id, "vector": vector, "payload": payload}],
        })
        print(f"created  summaries  {args.proyecto}:{args.nivel}:{stable_id}  [{point_id}]")


def cmd_renumber_siblings(args):
    """Renumber all siblings of (parent_id, nivel) that have seq >= from_seq.

    direction='up' increments each by step (used when inserting in the middle).
    direction='down' decrements each by step (used when removing from the middle).

    Collection is selected by nivel:
    - L1/L2/L3/L4 -> summaries
    - L0/beat    -> beats

    Does NOT touch children of siblings — only their own seq.
    """
    collection = "beats" if args.nivel in ("L0", "beat") else "summaries"
    must = [
        {"key": "proyecto",  "match": {"value": args.proyecto}},
        {"key": "seq",       "range": {"gte": args.from_seq}},
    ]
    if collection == "summaries":
        must.append({"key": "nivel", "match": {"value": args.nivel}})
    if args.parent_id:
        must.append({"key": "parent_id", "match": {"value": make_point_id(args.parent_id)}})
    if args.hilo:
        must.append({"key": "hilo", "match": {"value": args.hilo}})

    body = {
        "filter":       {"must": must},
        "limit":        10000,
        "with_payload": True,
    }
    result = qdrant("POST", f"/collections/{collection}/points/scroll", body)
    points = result.get("result", {}).get("points", [])
    if not points:
        print(f"No siblings to renumber in {collection}.")
        return

    step = args.step if args.step is not None else (1 if args.direction == "up" else -1)
    if step == 0:
        step = 1 if args.direction == "up" else -1

    for pt in points:
        p = pt.get("payload", {})
        new_seq = p.get("seq", 0) + step
        qdrant("POST", f"/collections/{collection}/points/payload?wait=true", {
            "points": [pt["id"]],
            "payload": {"seq": new_seq},
        })

    print(f"renumbered  {len(points)} siblings  {args.proyecto}:{args.nivel}  "
          f"(collection={collection}, direction={args.direction}, step={step}, from_seq={args.from_seq})")


# ── Entity commands ───────────────────────────────────────────────────────────

ENTITY_VALID_TIPOS = {
    "personaje", "lugar", "objeto", "animal",
    "ser_sobrenatural", "hilo", "organizacion", "arco", "evento", "grupo",
}


def _validate_entity_payload(args, partial: bool = False) -> dict:
    """Validate entity fields and return the payload to write.

    partial=True allows some fields to be missing (for update-entity).
    Returns dict with all fields. Raises SystemExit on validation error.
    """
    payload = {}
    if not partial or args.stable_id is not None:
        if not args.stable_id:
            if not partial:
                print("Error: --stable-id is required", file=sys.stderr)
                sys.exit(1)
        else:
            payload["stable_id"] = args.stable_id
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

    if args.slug is not None:
        payload["slug"] = args.slug

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
    point_id = make_point_id(payload["stable_id"])
    text_to_embed = payload.get("fijo") or payload.get("nombre", "")
    vector = embed(text_to_embed) if text_to_embed else [0.0] * VECTOR_DIM

    payload["proyecto"] = args.proyecto

    qdrant("PUT", "/collections/entidades/points?wait=true", {
        "points": [{"id": point_id, "vector": vector, "payload": payload}],
    })
    print(f"upserted  entidades  {args.proyecto}:{payload['stable_id']}  [{point_id}]")


def cmd_update_entity(args):
    """Patch specific fields of an entity. Vector is recomputed only if --fijo is provided."""
    payload = _validate_entity_payload(args, partial=True)
    if not payload:
        print("Nothing to update — provide at least one field to change.", file=sys.stderr)
        sys.exit(1)

    payload["proyecto"] = args.proyecto
    point_id = make_point_id(args.stable_id)

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
    print(f"updated  entidades  {args.proyecto}:{args.stable_id}")


def cmd_query_entity(args):
    """Fetch a single entity by its stable ID. Returns object or {} if not found."""
    point_id = make_point_id(args.stable_id)
    result = qdrant("POST", "/collections/entidades/points", {
        "ids": [point_id], "with_payload": True, "with_vector": False,
    })
    points = result.get("result", [])
    if not points or not points[0].get("payload"):
        print("{}")
        return
    p = points[0]["payload"]
    p.pop("proyecto", None)
    print(json.dumps(p, ensure_ascii=False, indent=2))


def cmd_query_entities(args):
    """List entities of a proyecto, with optional filters."""
    must = [{"key": "proyecto", "match": {"value": args.proyecto}}]
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
    payloads.sort(key=lambda p: (p.get("tipo", ""), p.get("stable_id", "")))

    for p in payloads:
        p.pop("proyecto", None)
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

    must = [{"key": "proyecto", "match": {"value": args.proyecto}}]
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
            "stable_id": p.get("stable_id", ""),
            "tipo":      p.get("tipo", ""),
            "nombre":    p.get("nombre", ""),
            "tags":      p.get("tags", []),
            "score":     round(hit.get("score", 0), 3),
        })
    print(json.dumps(output, ensure_ascii=False, indent=2))


# ── Backup ─────────────────────────────────────────────────────────────────────

def cmd_export(args):
    """Dump all beats and summaries for a proyecto to a JSON file.

    Use this for backup. The resulting file can be re-imported with 'import'
    if Qdrant is lost.
    """
    body = {
        "filter":       {"must": [{"key": "proyecto", "match": {"value": args.proyecto}}]},
        "limit":        10000,
        "with_payload": True,
        "with_vector":  True,
    }
    beats     = qdrant("POST", "/collections/beats/points/scroll",     body)
    summaries = qdrant("POST", "/collections/summaries/points/scroll", body)
    entities  = qdrant("POST", "/collections/entidades/points/scroll",  body)

    backup = {
        "proyecto":          args.proyecto,
        "exported_at":       datetime.datetime.utcnow().isoformat() + "Z",
        "beats_count":       len(beats.get("result", {}).get("points", [])),
        "summaries_count":   len(summaries.get("result", {}).get("points", [])),
        "entidades_count":   len(entities.get("result", {}).get("points", [])),
        "beats":             beats.get("result", {}).get("points", []),
        "summaries":         summaries.get("result", {}).get("points", []),
        "entidades":         entities.get("result", {}).get("points", []),
    }

    if args.output == "-":
        json.dump(backup, sys.stdout, ensure_ascii=False, indent=2)
        print()
    else:
        with open(args.output, "w", encoding="utf-8") as f:
            json.dump(backup, f, ensure_ascii=False, indent=2)
        print(f"exported  {args.proyecto}  →  {args.output}  "
              f"({backup['beats_count']} beats, {backup['summaries_count']} summaries)")


def cmd_import(args):
    """Restore beats and summaries from a JSON file produced by 'export'."""
    with open(args.input, encoding="utf-8") as f:
        backup = json.load(f)

    if backup.get("proyecto") != args.proyecto:
        print(f"Warning: backup proyecto='{backup.get('proyecto')}' != "
              f"target='{args.proyecto}'. Proceeding anyway.", file=sys.stderr)

    for collection, key in [("beats", "beats"), ("summaries", "summaries"), ("entidades", "entidades")]:
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
        description="Qdrant helper — proyecto writing system",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("init", help="Create collections and payload indexes")

    def beat_id_args(p, parent_required=True):
        p.add_argument("--proyecto",  required=True, help="Proyecto slug")
        p.add_argument("--beat",      required=True, help="Beat stable ID (UUID8)")
        p.add_argument("--seq",       type=int, help="Sequence number (local to parent)")
        if parent_required:
            p.add_argument("--parent-id", required=True, help="Parent stable ID (scene UUID8)")
        else:
            p.add_argument("--parent-id", help="Parent stable ID (only set when moving beat)")

    p = sub.add_parser("upsert-beat", help="Create or replace a beat entry. Flags: --proyecto --beat --parent-id --seq --accion [--tono] [--extension] [--fichas]")
    beat_id_args(p)
    p.add_argument("--accion",      help="Beat action text (inline)")
    p.add_argument("--accion-file", help="File with action text (- = stdin)")
    p.add_argument("--tono")
    p.add_argument("--extension", choices=["BREVE", "MEDIA", "EXTENSA"])
    p.add_argument("--fichas",        help='JSON array of entity stable IDs, e.g. \'["a1b2c3d4","e5f6g7h8"]\'')
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
    p.add_argument("--proyecto",  required=True)
    p.add_argument("--nivel",     required=True, choices=["L1", "L2", "L3", "L4"])
    p.add_argument("--id",        required=True, help="Summary stable ID: E_NNN (L1), C_NNN (L2), A_NNN (L3), global (L4)")
    p.add_argument("--parent-id", help="Parent stable ID")
    p.add_argument("--seq",       type=int, help="Sequence number")
    p.add_argument("--hilo",      help="Hilo stable ID (multi-hilo only, for L1/L3)")
    p.add_argument("--texto")
    p.add_argument("--texto-file")
    p.add_argument("--fichas",        help="JSON array of entity stable IDs")
    p.add_argument("--fichas-file",   help="File with --fichas JSON (- = stdin)")

    p = sub.add_parser("query", help="Semantic search on beats collection")
    p.add_argument("--proyecto", required=True)
    p.add_argument("--text",      help="Query text (inline)")
    p.add_argument("--text-file", help="File with query text")
    p.add_argument("--limit", type=int, default=5)

    p = sub.add_parser(
        "query-chapters-by-beat",
        help="Two-stage: beat search → unique chapters → L2 summaries (recommended for memoria)",
    )
    p.add_argument("--proyecto", required=True)
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
    p.add_argument("--proyecto",   required=True)
    p.add_argument("--current-id", required=True, help="Current chapter stable ID (L2s with this id are excluded)")
    p.add_argument("--last",       type=int, default=3, help="How many recent L2s to retrieve (default 3)")
    p.add_argument("--hilo",       help="Hilo stable ID (multi-hilo only)")

    p = sub.add_parser(
        "query-l3",
        help="Get L3 summaries for closed arcs (all, or one specific --arco)",
    )
    p.add_argument("--proyecto", required=True)
    p.add_argument("--arco",   help="Specific arc stable ID, e.g. arco-01 (returns single object or {})")

    p = sub.add_parser(
        "query-l4-current",
        help="Get the L4 global summary for a proyecto (stable_id=global)",
    )
    p.add_argument("--proyecto", required=True)

    p = sub.add_parser("query-summary-by-position",
        help="Find a summary by (nivel, parent_id, seq[, hilo]). Use stable_id for parent_id, not UUID8.")
    p.add_argument("--proyecto",  required=True)
    p.add_argument("--nivel",     required=True, choices=["L1", "L2", "L3", "L4"])
    p.add_argument("--parent-id", help="Parent stable ID (e.g. 'C_005' for an L1, 'global' for L2)")
    p.add_argument("--seq",       type=int, help="Local sequence number under parent")
    p.add_argument("--hilo",      help="Hilo stable ID (multi-hilo only)")

    p = sub.add_parser("upsert-summary-by-position",
        help="Idempotent: find by (nivel, parent_id, seq[, hilo]) and update, or create with new stable_id")
    p.add_argument("--proyecto",  required=True)
    p.add_argument("--nivel",     required=True, choices=["L1", "L2", "L3", "L4"])
    p.add_argument("--parent-id", required=True, help="Parent stable ID")
    p.add_argument("--seq",       type=int, help="Local sequence number under parent")
    p.add_argument("--texto",     help="Summary text (inline)")
    p.add_argument("--texto-file", help="File with summary text (- = stdin)")
    p.add_argument("--hilo",      help="Hilo stable ID (multi-hilo only)")
    p.add_argument("--fichas",     help="JSON array of entity stable IDs")
    p.add_argument("--fichas-file",help="File with --fichas JSON (- = stdin)")

    p = sub.add_parser("renumber-siblings",
        help="Shift seq of all siblings with seq >= from_seq. Used after insert/delete.")
    p.add_argument("--proyecto",  required=True)
    p.add_argument("--nivel",     required=True, choices=["L1", "L2", "L3", "L4"])
    p.add_argument("--parent-id", help="Parent stable ID (only renumber siblings of this parent)")
    p.add_argument("--from-seq",  type=int, required=True, help="Shift from this seq onwards")
    p.add_argument("--direction", required=True, choices=["up", "down"], help="up=+step, down=-step")
    p.add_argument("--step",      type=int, default=1, help="Shift amount (default 1)")
    p.add_argument("--hilo",      help="Hilo stable ID (multi-hilo only)")

    p = sub.add_parser("export", help="Backup beats + summaries for a proyecto to a JSON file")
    p.add_argument("--proyecto", required=True)
    p.add_argument("--output",   required=True, help="Output file path (- for stdout)")

    p = sub.add_parser("import", help="Restore beats + summaries from a JSON file")
    p.add_argument("--proyecto", required=True)
    p.add_argument("--input",    required=True, help="Input file path (from 'export')")

    def entity_common(p):
        p.add_argument("--proyecto", required=True, help="Proyecto slug")

    p = sub.add_parser("upsert-entity", help="Create or replace an entity (personaje, lugar, hilo, etc.)")
    entity_common(p)
    p.add_argument("--stable-id", required=True, help="Entity stable ID, e.g. per-ana-lopez")
    p.add_argument("--tipo",      required=True, choices=sorted(ENTITY_VALID_TIPOS))
    p.add_argument("--nombre",    required=True)
    p.add_argument("--slug",      help="Entity slug")
    p.add_argument("--tags",      help="Comma-separated tags for filtering (e.g. 'muerto,villano')")
    p.add_argument("--fijo",          help="Inmutable description (inline)")
    p.add_argument("--fijo-file",     help="Inmutable description from file (- = stdin)")
    p.add_argument("--dinamico",      help="Current state (inline)")
    p.add_argument("--dinamico-file", help="Current state from file (- = stdin)")

    p = sub.add_parser("update-entity", help="Patch specific fields of an entity")
    entity_common(p)
    p.add_argument("--stable-id",     required=True)
    p.add_argument("--tipo",          choices=sorted(ENTITY_VALID_TIPOS))
    p.add_argument("--nombre")
    p.add_argument("--slug")
    p.add_argument("--tags")
    p.add_argument("--fijo")
    p.add_argument("--fijo-file")
    p.add_argument("--dinamico",          help="Current state (updated by cronista)")
    p.add_argument("--dinamico-file",     help="Current state from file (- = stdin)")

    p = sub.add_parser("query-entity", help="Fetch a single entity by its stable ID")
    entity_common(p)
    p.add_argument("--stable-id", required=True)

    p = sub.add_parser("query-entities", help="List entities of a proyecto, with optional filters")
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
        "query-summary-by-position":  cmd_query_summary_by_position,
        "upsert-summary-by-position": cmd_upsert_summary_by_position,
        "renumber-siblings":          cmd_renumber_siblings,
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
