#!/usr/bin/env python3
"""Persistencia mecanica de una escena completa, sin orquestacion.

preparar --capitulo capitulos/cap-NN-slug --escena SID --entrada archivo --finish stop
aceptar --capitulo capitulos/cap-NN-slug --escena SID --revision '<JSON>'
sincronizar --capitulo capitulos/cap-NN-slug --escena SID --revision '<JSON>'

Revision (JSON inline): objeto con escena_stable_id (string), candidato_sha256
(64 hex minusculas), estado (literal "aprobado"), incidencias (lista de objetos).
Cada incidencia debe tener gravedad="opcional"; cualquier otro valor bloquea.
Se permiten campos adicionales tanto en la revision como en sus incidencias.

La entrada es UTF-8 sin BOM. Solo se normalizan CRLF/CR a LF y se agrega LF
final si falta; no se recorta ni reescribe la prosa. Para vectores se excluyen
marcador, headings y lineas vacias de separacion en los extremos de cada cuerpo.
Se rechazan estructuras Markdown adicionales y etiquetas conocidas de metatexto;
esto no sustituye la revision editorial de notas indistinguibles de la prosa.
El marcador admite el sufijo `| hilo: <stable_id>` (multi-hilo); si el guion lo
declara, el candidato debe conservarlo identico. Entradas: dentro del workspace
o del temporal del sistema (`FORJA_TEMP` o el temporal del usuario); nunca otro
workspace. Las rutas relativas se resuelven respecto a este workspace.

sincronizar fija narrative_text, vector_source="narrativa" y has_narrative=true,
como cmd_enrich_beat. Conserva los campos estructurales y fichas. Los cambios de
texto/origen se envian en un PUT de vectores+payload; si solo falta el flag true,
se repara mediante un POST de payload para todos esos puntos, sin embeddings.
Ambos lotes usan wait=true y readback final de todos los payloads. La salida
beats_actualizados cuenta puntos distintos modificados, incluidas reparaciones
del flag; un reintento ya sincronizado devuelve 0 y no carga el modelo.

No hay transaccion disco+Qdrant. Serializar operaciones sobre el mismo capitulo
y escrituras remotas de estos beats: el backend no ofrece CAS en este contrato.
Tampoco hay transaccion entre el lote de vectores y la reparacion de flags;
si falla el segundo, el reintento solo procesa los puntos aun pendientes.
Un fallo remoto deja draft aceptado y candidato disponibles para reintentar.
No modifica guion, config, fichas, summaries ni Neo4j.
"""

import argparse
from datetime import datetime, timezone
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import sys
import tempfile


ROOT = Path(__file__).resolve().parent.parent
TEMP_ROOT = (Path(os.environ["FORJA_TEMP"]) if os.environ.get("FORJA_TEMP")
             else Path(tempfile.gettempdir()) / "opencode").resolve()
_spec = importlib.util.spec_from_file_location("persistir_qdrant", Path(__file__).with_name("qdrant.py"))
backend = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(backend)
ID = r"[A-Za-z0-9][A-Za-z0-9_-]*"
MARKER = re.compile(rf"<!-- ESCENA ({ID}): ([^\r\n<>|]+?)(?:[ \t]*\|[ \t]*hilo:[ \t]*({ID}))?[ \t]*-->[ \t]*\r?$")
BEAT = re.compile(rf"(?:[-*][ \t]+)?[\u2b1c\U0001f504\u2705][ \t]+({ID})[ \t]+\[([1-9][0-9]*)\][ \t]+(.+)")
HEADING = re.compile(rf"##[ \t]+({ID})[ \t]+\[([1-9][0-9]*)\](?:[ \t]+\S[^\r\n]*)?[ \t]*$")
META = re.compile(
    r"(?im)^[ \t]*(?:[-*>_\[]+[ \t]*)?(?:"
    r"notas?(?:[ \t]+(?:del?|para(?:[ \t]+el)?))[ \t]+(?:escritor|autor|director|revision|revisi\u00f3n)\b"
    r"|(?:nota|notas|resumen|comentario|comentarios|observaciones|metadatos|pendiente|TODO)[ \t]*:"
    r"|fin[ \t]+(?:de[ \t]+(?:la[ \t]+)?)?escena\b"
    r"|(?:aqu[i\u00ed][ \t]+(?:tienes|est[a\u00e1])|como[ \t]+(?:IA|modelo))\b"
    r"|(?:continuar[a\u00e1]|continuar|continuaci[o\u00f3]n)[ \t]*[.:]?[ \t]*$)"
)
REVIEW_SCHEMA = {
    "escena_stable_id": "SID",
    "candidato_sha256": "64 caracteres hexadecimales en minusculas",
    "estado": "aprobado",
    "incidencias": [{"gravedad": "opcional"}],
}


def confined(value, base, managed=False):
    """Resolver antes de leer; tambien protege archivos internos enlazados."""
    path = Path(value)
    if ".." in path.parts:
        raise ValueError("Traversal no permitido")
    path = path if path.is_absolute() else ROOT / path
    if managed and path.is_symlink():
        raise ValueError("Un archivo administrado no puede ser un symlink")
    resolved = path.resolve()
    if not resolved.is_relative_to(base.resolve()) or resolved == base.resolve():
        raise ValueError("Ruta fuera del ambito permitido")
    return resolved


def scene_markers(text):
    markers = []
    offset = 0
    for line in text.splitlines(keepends=True):
        match = MARKER.fullmatch(line.rstrip("\n"))
        if match:
            if not match[2].strip():
                raise ValueError("Marcador sin nombre de escena")
            markers.append((match[1], match[3] or "", offset, offset + len(line)))
        elif "<!-- ESCENA" in line:
            raise ValueError("Marcador de escena malformado")
        offset += len(line)
    if len({m[0] for m in markers}) != len(markers):
        raise ValueError("Marcador de escena duplicado")
    return markers


def read_guion(path):
    # Los ejemplos cercados no son beats ni escenas reales del guion.
    lines = []
    fence = None
    for line in path.read_text(encoding="utf-8-sig").splitlines(keepends=True):
        match = re.match(r"^[ \t]*(`{3,}|~{3,})(.*)$", line.rstrip("\n"))
        if fence:
            if match and match[1][0] == fence[0] and len(match[1]) >= len(fence) and not match[2].strip():
                fence = None
            lines.append("\n")
        elif match:
            fence = match[1]
            lines.append("\n")
        else:
            lines.append(line)
    if fence:
        raise ValueError("Fence sin cerrar en guion")
    text = "".join(lines)
    markers = scene_markers(text)
    scenes = {}
    ids = set()
    for index, (sid, hilo, _, start) in enumerate(markers):
        end = markers[index + 1][2] if index + 1 < len(markers) else len(text)
        beats = []
        for line in text[start:end].splitlines():
            line = line.strip()
            match = BEAT.fullmatch(line)
            if not match:
                if re.match(r"^(?:[-*][ \t]+)?[\u2b1c\U0001f504\u2705]", line):
                    raise ValueError("Beat malformado en guion")
                continue
            bid, seq = match[1], int(match[2])
            if not match[3].lstrip("-\u2014\u2013 \t").strip():
                raise ValueError("Beat sin accion en guion")
            if bid in ids or (beats and seq <= beats[-1][1]):
                raise ValueError("IDs duplicados u orden/seq invalido en guion")
            ids.add(bid)
            beats.append((bid, seq))
        scenes[sid] = {"beats": beats, "hilo": hilo}
    return scenes


def validate_candidate(data, sid, expected, expected_hilo=""):
    text = data.decode("utf-8")
    markers = scene_markers(text)
    if (len(markers) != 1 or markers[0][0] != sid or markers[0][1] != expected_hilo
            or markers[0][2] != 0):
        raise ValueError("Se exige un unico marcador inicial de la escena solicitada")
    if not expected:
        raise ValueError("Escena sin beats reales en guion")
    content = text[markers[0][3]:]
    if ("<!--" in content or "-->" in content or "```" in content or "~~~" in content
            or re.search(r"<\/?(?:think|analysis|final)\b|<\|", content, re.I)
            or META.search(content)):
        raise ValueError("Notas, metatexto o fences no permitidos")
    headings = []
    offset = markers[0][3]
    for line in content.splitlines(keepends=True):
        match = HEADING.fullmatch(line.rstrip("\r\n"))
        if match:
            headings.append((match[1], int(match[2]), offset, offset + len(line)))
        elif re.match(r"^[ \t]*(?:#|>|[-*+][ \t]+|[0-9]+[.)][ \t]+|\||[-*_]{3,}[ \t]*$)", line):
            raise ValueError("Heading malformado o estructura extra en candidato")
        if any(ord(c) < 32 and c not in "\n\r\t" for c in line):
            raise ValueError("Caracter de control no permitido")
        offset += len(line)
    if [(h[0], h[1]) for h in headings] != expected:
        raise ValueError("IDs, orden o seq no coinciden con la escena completa del guion")
    if text[markers[0][3]:headings[0][2]].strip():
        raise ValueError("Texto fuera de los cuerpos de beats")
    bodies = []
    for index, (bid, seq, _, start) in enumerate(headings):
        end = headings[index + 1][2] if index + 1 < len(headings) else len(text)
        body = text[start:end].strip("\r\n")
        if not body.strip():
            raise ValueError("Cuerpo vacio")
        bodies.append((bid, seq, body))
    return bodies


def atomic_write(path, data, backup=False):
    old = path.read_bytes() if path.exists() else None
    if old == data:
        return False
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(dir=path.parent, prefix=".persistir-", delete=False) as stream:
            temporary = Path(stream.name)
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
        if backup and old is not None:
            stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
            with path.with_name(f"{path.name}.{stamp}.bak").open("xb") as stream:
                stream.write(old)
                stream.flush()
                os.fsync(stream.fileno())
        os.replace(temporary, path)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)
    return True


def synchronize(proyecto, sid, bodies):
    expected = {backend.make_point_id(bid): (bid, seq, body) for bid, seq, body in bodies}

    def retrieve():
        response = backend.qdrant("POST", "/collections/beats/points", {
            "ids": list(expected), "with_payload": True, "with_vector": False,
        })
        if response.get("status") != "ok" or not isinstance(response.get("result"), list):
            raise ValueError("Retrieve Qdrant no confirmado")
        points = response["result"]
        found = {}
        for point in points:
            pid, payload = point.get("id"), point.get("payload")
            if pid not in expected or pid in found or not isinstance(payload, dict):
                raise ValueError("Respuesta Qdrant con identidad inesperada o duplicada")
            bid, seq, _ = expected[pid]
            if (payload.get("stable_id") != bid or payload.get("proyecto") != proyecto
                    or payload.get("parent_id") != backend.make_point_id(sid)
                    or type(payload.get("seq")) is not int or payload["seq"] != seq):
                raise ValueError("Punto con proyecto, stable_id, parent_id o seq incorrecto")
            found[pid] = payload
        if found.keys() != expected.keys():
            raise ValueError("Faltan puntos; no se recrean beats")
        return found

    payloads = retrieve()
    changed, flags = [], []
    for pid, (_, _, body) in expected.items():
        if (payloads[pid].get("narrative_text") != body
                or payloads[pid].get("vector_source") != "narrativa"):
            changed.append(pid)
        elif payloads[pid].get("has_narrative") is not True:
            flags.append(pid)
    if not changed and not flags:
        return 0
    writes = []
    if changed:
        vectors = list(backend.get_model().embed([expected[pid][2] for pid in changed]))
        if len(vectors) != len(changed):
            raise ValueError("Embedding devolvio un lote incompleto")
        points = []
        for pid, vector in zip(changed, vectors):
            payload = dict(payloads[pid], narrative_text=expected[pid][2],
                           vector_source="narrativa", has_narrative=True)
            points.append({"id": pid, "payload": payload, "vector": vector.tolist()})
        writes.append(("PUT", "/collections/beats/points?wait=true", {"points": points}))
    if flags:
        writes.append(("POST", "/collections/beats/points/payload?wait=true", {
            "points": flags, "payload": {"has_narrative": True},
        }))
    for method, path, data in writes:
        response = backend.qdrant(method, path, data)
        if response.get("status") != "ok" or response.get("result", {}).get("status") != "completed":
            raise ValueError("Escritura Qdrant no confirmada; reintentar sincronizar")
    confirmed = retrieve()
    for pid, (_, _, body) in expected.items():
        if (confirmed[pid].get("has_narrative") is not True
                or confirmed[pid] != dict(payloads[pid], narrative_text=body,
                                          vector_source="narrativa", has_narrative=True)):
            raise ValueError("Readback Qdrant no coincide; reintentar sincronizar")
    return len(changed) + len(flags)


def run(args):
    if not re.fullmatch(ID, args.escena):
        raise ValueError("stable_id de escena invalido")
    if args.command == "preparar" and args.finish != "stop":
        raise ValueError("Solo finish=stop permite preparar una escena completa")
    config = json.loads(confined(ROOT / "config.json", ROOT).read_text(encoding="utf-8-sig"))
    proyecto = config.get("slug")
    if not isinstance(proyecto, str) or not proyecto.strip():
        raise ValueError("config.json debe declarar slug")
    chapters = confined(ROOT / "capitulos", ROOT)
    chapter = confined(args.capitulo, chapters)
    if not chapter.is_dir():
        raise ValueError("El capitulo debe ser un directorio existente")
    scenes = read_guion(confined(chapter / "guion.md", chapter))
    if args.escena not in scenes:
        raise ValueError("Escena ausente del guion")
    scene = scenes[args.escena]
    pending = confined(chapter / f"escena-{args.escena}.pendiente.md", chapter, managed=True)
    result = {"proyecto": proyecto, "escena_stable_id": args.escena,
              "beat_stable_ids": [bid for bid, _ in scene["beats"]]}
    if args.command == "preparar":
        try:
            source = confined(args.entrada, ROOT)
        except ValueError:
            source = confined(args.entrada, TEMP_ROOT)
        # Evitar que la evidencia sea tambien un archivo administrado por el CLI.
        if source in (pending, chapter / "draft.md", chapter / "guion.md", ROOT / "config.json"):
            raise ValueError("La entrada debe ser un archivo independiente")
        raw = source.read_bytes()
        text = raw.decode("utf-8").replace("\r\n", "\n").replace("\r", "\n")
        if text and not text.endswith("\n"):
            text += "\n"
        candidate = text.encode("utf-8")
        validate_candidate(candidate, args.escena, scene["beats"], scene["hilo"])
        result.update(estado="pendiente", candidato_sha256=hashlib.sha256(candidate).hexdigest(),
                      candidato=str(pending), normalizacion="CRLF/CR a LF; LF final si falta",
                      normalizado=raw != candidate, cambio=atomic_write(pending, candidate))
        return result

    review = json.loads(args.revision)
    if (not isinstance(review, dict) or review.get("escena_stable_id") != args.escena
            or review.get("estado") != "aprobado"
            or not isinstance(review.get("candidato_sha256"), str)
            or not re.fullmatch(r"[0-9a-f]{64}", review["candidato_sha256"])
            or not isinstance(review.get("incidencias"), list)
            or any(not isinstance(item, dict) or item.get("gravedad") != "opcional"
                   for item in review["incidencias"])):
        raise ValueError("Revision bloqueante o invalida. Esquema: " + json.dumps(REVIEW_SCHEMA))
    candidate = pending.read_bytes()
    digest = hashlib.sha256(candidate).hexdigest()
    if review["candidato_sha256"] != digest:
        raise ValueError("Hash de revision obsoleto: no coincide con el candidato")
    bodies = validate_candidate(candidate, args.escena, scene["beats"], scene["hilo"])
    if b"\r" in candidate or not candidate.endswith(b"\n"):
        raise ValueError("Candidato no normalizado; ejecutar preparar")
    result["candidato_sha256"] = digest
    draft = confined(chapter / "draft.md", chapter, managed=True)
    original = draft.read_bytes() if draft.exists() else b""
    text = original.decode("utf-8")
    markers = scene_markers(text)
    order = list(scenes)
    positions = [order.index(sid) for sid, _, _, _ in markers if sid in scenes]
    if len(positions) != len(markers) or positions != sorted(positions):
        raise ValueError("Draft con escenas ajenas o desordenadas; no se modifica")
    start = end = len(text)
    accepted = False
    for index, (sid, _, offset, _) in enumerate(markers):
        if sid == args.escena:
            start = offset
            end = markers[index + 1][2] if index + 1 < len(markers) else len(text)
            accepted = text[start:end].encode("utf-8") == candidate
            break
        if order.index(sid) > order.index(args.escena):
            start = end = offset
            break
    if args.command == "aceptar":
        prefix = text[:start]
        separator = "\n" if prefix and not prefix.endswith("\n") else ""
        updated = (prefix + separator).encode("utf-8") + candidate + text[end:].encode("utf-8")
        result.update(estado="aceptado", cambio=atomic_write(draft, updated, backup=True))
    else:
        if not accepted:
            raise ValueError("La escena del draft no es exactamente el candidato revisado")
        count = synchronize(proyecto, args.escena, bodies)
        result.update(estado="sincronizado", beats_actualizados=count, cambio=bool(count))
    return result


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    commands = parser.add_subparsers(dest="command", required=True)
    for command in ("preparar", "aceptar", "sincronizar"):
        sub = commands.add_parser(command)
        sub.add_argument("--capitulo", required=True)
        sub.add_argument("--escena", required=True)
        if command == "preparar":
            sub.add_argument("--entrada", required=True)
            sub.add_argument("--finish", required=True, choices=["stop"])
        else:
            sub.add_argument("--revision", required=True, help="Objeto JSON inline; esquema en --help global")
    args = parser.parse_args(argv)
    try:
        print(json.dumps(run(args), ensure_ascii=True))
    except (ValueError, OSError, RuntimeError) as error:
        print(json.dumps({"estado": "error", "error": str(error)}, ensure_ascii=True), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
