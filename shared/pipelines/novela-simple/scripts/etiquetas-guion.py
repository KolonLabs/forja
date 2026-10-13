#!/usr/bin/env python3
"""Etiquetas visuales de beats y escenas en los guiones de novela (ADR 0033).

uso: python -X utf8 scripts/etiquetas-guion.py [--simular] [--tabla]

Cada beat lleva delante una etiqueta `B_NNNN · ` y cada escena, justo después de su
marcador, un encabezado `### E_NNNN — <nombre>`. Son solo para leer y conversar
(«cambia el B_0012», «entre B_0015 y B_0022»): la identidad es el stable_id y nunca
se guardan en Qdrant ni en Neo4j. Este script las inserta donde falten y las
renumera correlativas en orden de lectura; es idempotente.

Ámbitos, cada uno numerado desde 1:
- capitulos/cap-NN-*/guion.md, en orden de capítulo: numeración de la novela.
- hilos/<hilo>/cap-NN*/guion.md (multi-hilo), un ámbito por hilo.

Referencias:
- Parejas `B_NNNN · <stable_id>` / `E_NNNN · <stable_id>` en las notas para revisión
  humana (`notas*.md` de los capítulos del ámbito) y en las notas del propio guion: se
  actualizan solas según el stable_id; las que apuntan a uno que ya no existe se
  devuelven como huérfanas. La forma invertida con un stable_id del guion
  («`a7d3f1c8` (B_0219)», «a7d3f1c8 [B_0219]») se convierte en la canónica.
- Etiquetas sueltas (sin stable_id) de una etiqueta que ha cambiado, en cualquier
  Markdown de la obra salvo prosa, documentos del pipeline, `docs/` y `referencias/`: no se
  tocan (pueden ser historial o citar otra obra) y se devuelven en `referencias` con su
  etiqueta nueva y su stable_id, para que el modelo las revise en ese momento.
- En archivos para el modelo (contexto, cola_d, fichas) se cita solo el stable_id.

`--tabla` añade la tabla completa de etiquetas antiguas y nuevas. No modifica el
marcador, el stable_id, el [seq] ni el texto del beat.
"""

import argparse
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parent.parent
ID = r"[A-Za-z0-9][A-Za-z0-9_-]*"
MARKER = re.compile(rf"^<!-- ESCENA ({ID}): ([^\r\n<>|]+?)(?:[ \t]*\|[ \t]*hilo:[ \t]*{ID})?[ \t]*-->[ \t]*$")
BEAT = re.compile(rf"^(?P<pre>[ \t]*(?:[-*][ \t]+)?)(?P<estado>[⬜\U0001f504✅])[ \t]+"
                  rf"(?:(?P<etq>B_\d+)[ \t]*·[ \t]*)?(?P<id>{ID})(?P<resto>[ \t]+\[[1-9][0-9]*\].*)$")
ENCABEZADO = re.compile(r"^###[ \t]+(?P<etq>E_\d+)[ \t]+—[ \t]+.*$")
# En un rango «B_0006 · e8b3c5f7-B_0008 · …» el guion no forma parte del stable_id.
PAREJA = re.compile(r"\b(?P<tipo>[BE])_\d+(?P<sep>[ \t]*·[ \t]*)(?P<id>[A-Za-z0-9](?:[A-Za-z0-9_]|-(?![BE]_\d))*)")
INVERTIDA = re.compile(r"`?(?P<id>[A-Za-z0-9][A-Za-z0-9_-]*)`?[ \t]*[(\[](?P<tipo>[BE])_\d+[)\]]")
SUELTA = re.compile(r"\b[BE]_\d+\b(?![ \t]*·)")
FENCE = re.compile(r"^[ \t]*(`{3,}|~{3,})")
SIN_REFERENCIAS = {".git", ".opencode", ".claude", "node_modules", "publicacion", "referencias", ".forja-transaccion", "docs"}
DOCUMENTOS_PIPELINE = {"AGENTS.md", "CLAUDE.md", "GUIA.md", "PIPELINE.md", "ORQUESTACION.md"}
PROSA = {"draft.md", "capitulo.md", "novela.md"}


def numero(path):
    m = re.match(r"cap-(\d+)", path.parent.name)
    return int(m.group(1)) if m else 0


def ambitos(root):
    grupos = []
    caps = sorted((root / "capitulos").glob("cap-*/guion.md"), key=numero)
    if caps:
        grupos.append(("capitulos", caps))
    for hilo in sorted(p for p in (root / "hilos").glob("*") if p.is_dir()):
        guiones = sorted(hilo.glob("cap-*/guion.md"), key=numero)
        if guiones:
            grupos.append((f"hilos/{hilo.name}", guiones))
    return grupos


def etiquetar(texto, b, e, mapa=None, antes=None):
    """Devuelve (texto nuevo, siguiente B, siguiente E).

    Llena mapa[stable_id] = etiqueta nueva y antes[stable_id] = etiqueta que tenía.
    """
    mapa = {} if mapa is None else mapa
    antes = {} if antes is None else antes
    nl = "\r\n" if "\r\n" in texto else "\n"
    salida = []
    fence, pendiente, escena = None, None, None

    def cerrar_escena():
        nonlocal e
        mapa[escena] = f"E_{e:04d}"
        encabezado = f"### E_{e:04d} — {pendiente}"
        e += 1
        return encabezado

    for linea in texto.split(nl):
        if fence:
            if FENCE.match(linea) and linea.strip().startswith(fence):
                fence = None
            salida.append(linea)
            continue
        f = FENCE.match(linea)
        if f:
            fence = f.group(1)[0] * 3
            salida.append(linea)
            continue
        if pendiente is not None:
            if not linea.strip():
                salida.append(linea)
                continue
            encabezado_viejo = ENCABEZADO.match(linea)
            if encabezado_viejo:
                antes[escena] = encabezado_viejo["etq"]
            encabezado = cerrar_escena()
            pendiente = None
            if encabezado_viejo:
                salida.append(encabezado)
                continue
            # Sin encabezado: se inserta tras el marcador, antes de las líneas en blanco ya añadidas.
            blancos = []
            while salida and not salida[-1].strip():
                blancos.append(salida.pop())
            salida.extend([encabezado, *blancos] if blancos else [encabezado, ""])
        m = MARKER.match(linea)
        if m:
            salida.append(linea)
            escena, pendiente = m.group(1), m.group(2).strip()
            continue
        m = BEAT.match(linea)
        if m:
            if m["etq"]:
                antes[m["id"]] = m["etq"]
            mapa[m["id"]] = f"B_{b:04d}"
            salida.append(f"{m['pre']}{m['estado']} B_{b:04d} · {m['id']}{m['resto']}")
            b += 1
            continue
        salida.append(linea)
    if pendiente is not None:  # marcador al final del archivo
        salida.append(cerrar_escena())
    return nl.join(salida), b, e


def refrescar_parejas(texto, mapa, huerfanas, origen):
    def invertida(m):
        # «`a7d3f1c8` (B_0219)» o «a7d3f1c8 [B_0219]» con un stable_id conocido → pareja canónica.
        etiqueta = mapa.get(m["id"])
        if etiqueta is None or etiqueta[0] != m["tipo"]:
            return m.group(0)
        return f"{etiqueta} · {m['id']}"

    def cambio(m):
        etiqueta = mapa.get(m["id"])
        if etiqueta is None or etiqueta[0] != m["tipo"]:
            huerfanas.append(f"{origen}: {m.group(0)}")
            return m.group(0)
        return f"{etiqueta}{m['sep']}{m['id']}"
    return PAREJA.sub(cambio, INVERTIDA.sub(invertida, texto))


def archivos_de_referencia(root, nombre):
    """Markdown del ámbito (y de la raíz de la obra) donde puede haber etiquetas sueltas."""
    otros = {"capitulos", "hilos"}
    for path in sorted(root.rglob("*.md")):
        partes = path.relative_to(root).parts
        if (SIN_REFERENCIAS & set(partes) or path.name in PROSA or path.name.startswith("escena-")
                or (len(partes) == 1 and path.name in DOCUMENTOS_PIPELINE)):
            continue
        if partes[0] in otros and "/".join(partes[:len(nombre.split("/"))]) != nombre:
            continue
        yield path


def buscar_referencias(root, nombre, cambios, textos):
    """Etiquetas sueltas que han cambiado: [{archivo, linea, etiqueta, ahora, stable_id, texto}].

    `textos` trae el contenido resultante de los archivos que el script reescribe (también al simular).
    """
    encontradas = []
    for path in archivos_de_referencia(root, nombre):
        es_guion = path.name == "guion.md"
        contenido = textos[path] if path in textos else path.read_text(encoding="utf-8-sig")
        for n, linea in enumerate(contenido.splitlines(), 1):
            if es_guion and (BEAT.match(linea) or ENCABEZADO.match(linea)):
                continue
            for m in SUELTA.finditer(linea):
                for nueva, sid in cambios.get(m.group(0), []):
                    encontradas.append({"archivo": path.relative_to(root).as_posix(), "linea": n,
                                        "etiqueta": m.group(0), "ahora": nueva, "stable_id": sid,
                                        "texto": linea.strip()[:200]})
    return encontradas


def leer(path):
    crudo = path.read_bytes()
    return crudo.decode("utf-8-sig"), crudo.startswith(b"\xef\xbb\xbf")


def escribir(path, texto, bom):
    path.write_bytes((b"\xef\xbb\xbf" if bom else b"") + texto.encode("utf-8"))


def run(root, simular, tabla=False):
    resultado = []
    for nombre, guiones in ambitos(root):
        b = e = 1
        cambiados, mapa, antes, huerfanas, textos = [], {}, {}, [], {}
        # Primera pasada: etiquetas de los guiones. Segunda: parejas en notas y en las notas del
        # propio guion, con el mapa completo del ámbito (una nota puede citar otro capítulo).
        originales = {}
        for path in guiones:
            originales[path] = leer(path)
            textos[path], b, e = etiquetar(originales[path][0], b, e, mapa, antes)
        for path in sorted({n for g in guiones for n in g.parent.glob("notas*.md")}):
            originales[path] = leer(path)
            textos[path] = originales[path][0]
        for path, (texto, bom) in originales.items():
            textos[path] = refrescar_parejas(textos[path], mapa, huerfanas, path.relative_to(root).as_posix())
            if textos[path] != texto:
                cambiados.append(path.relative_to(root).as_posix())
                if not simular:
                    escribir(path, textos[path], bom)
        cambios = {}
        for sid, vieja in antes.items():
            if mapa.get(sid) != vieja:
                cambios.setdefault(vieja, []).append((mapa.get(sid), sid))
        ambito = {"ambito": nombre, "guiones": len(guiones), "beats": b - 1, "escenas": e - 1,
                  "renumeradas": sum(len(v) for v in cambios.values()),
                  "nuevas": sum(1 for sid in mapa if sid not in antes),
                  "cambiados": cambiados, "parejas_huerfanas": huerfanas,
                  "referencias": buscar_referencias(root, nombre, cambios, textos) if cambios else []}
        if tabla:
            ambito["tabla"] = [{"antes": v, "ahora": n, "stable_id": s} for v, l in sorted(cambios.items()) for n, s in l]
        resultado.append(ambito)
    salida = {"estado": "simulado" if simular else "ok", "ambitos": resultado}
    if any(a["referencias"] for a in resultado):
        salida["siguiente_paso"] = ("Revisa cada referencia ahora: en notas para revisión humana cámbiala por la pareja "
                                    "«ahora · stable_id»; en archivos para el modelo, por el stable_id; si cita otra obra "
                                    "o es historial que deba conservarse, déjala.")
    return salida


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--simular", action="store_true", help="Informa sin escribir")
    parser.add_argument("--tabla", action="store_true", help="Incluye la tabla completa antes → ahora")
    parser.add_argument("--obra", default=str(ROOT), help=argparse.SUPPRESS)
    args = parser.parse_args(argv)
    try:
        print(json.dumps(run(Path(args.obra), args.simular, args.tabla), ensure_ascii=False))
    except (OSError, ValueError) as error:
        print(json.dumps({"estado": "error", "error": str(error)}, ensure_ascii=False), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
