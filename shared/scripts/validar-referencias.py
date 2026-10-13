#!/usr/bin/env python3
"""Valida referencias/ de una obra (ADR 0032). No modifica nada.

uso: python -X utf8 scripts/validar-referencias.py [--obra RUTA] [--archivo referencias/x.md]
                                                   [--fuente RUTA] [--json]

Comprueba en cada referencia: Markdown con cabecera (titulo, tipo, origen, fecha,
proposito), tipo valido (canon-previo, documentacion, guia-previa) y tamano
manejable. En canon-previo, que cada hecho (vineta) lleve cita
`[cap. N: «fragmento»]` de 3 a 25 palabras y que declare fuente_sha256.

Con --fuente (archivo o carpeta de Markdown de la obra previa) verifica ademas
los canon-previo: que cada fragmento citado existe (en el capitulo citado si un
archivo de la fuente lleva ese numero), que la referencia no copia la fuente y
que fuente_sha256 coincide con la fuente actual.

En la obra comprueba las fichas con `## Canon heredado` (su dossier existe y es
canon-previo) y avisa de nombres de fichas de personaje que coinciden con
personajes de un canon-previo sin ser heredados ni estar en colisiones_aceptadas.

Errores: exit 1. Avisos: no bloquean.
"""

import argparse
import hashlib
import json
from pathlib import Path
import re
import sys
import unicodedata

TIPOS = {"canon-previo", "documentacion", "guia-previa"}
CAMPOS = ("titulo", "tipo", "origen", "fecha", "proposito")
MAX_PALABRAS_ARCHIVO = 6000
MAX_PALABRAS_SECCION = 1500
CITA = re.compile(r"\[cap\.\s*(\d+)\s*:\s*«([^»]+)»\]")
VINETA = re.compile(r"^\s*[-*]\s+(.+)$")
TEJA = 10            # palabras por fragmento al buscar copia de la fuente
MAX_COPIA = 0.15     # proporcion de fragmentos de la referencia presentes en la fuente
NO_NOMBRE = {"dra", "dr", "don", "dona", "sr", "sra", "senor", "senora", "el", "la", "los", "las",
             "de", "del", "y", "familia", "los"}


def palabras(texto):
    texto = unicodedata.normalize("NFKD", texto)
    texto = "".join(c for c in texto if not unicodedata.combining(c)).lower()
    return re.findall(r"\w+", texto)


def limpiar_fuente(texto):
    texto = re.sub(r"(?s)\A---\n.*?\n---\n", "", texto.replace("\r\n", "\n"))
    return re.sub(r"(?s)<!--.*?-->", " ", texto)


def cabecera(texto):
    texto = texto.replace("\r\n", "\n")
    m = re.match(r"(?s)\A---\n(.*?)\n---\n?", texto)
    if not m:
        return None, texto
    campos = {}
    for linea in m.group(1).splitlines():
        linea = re.sub(r"\s+#.*$", "", linea)
        if ":" in linea:
            clave, valor = linea.split(":", 1)
            valor = valor.strip()
            if valor.startswith("[") and valor.endswith("]"):
                valor = [v.strip().strip("'\"") for v in valor[1:-1].split(",") if v.strip()]
            campos[clave.strip()] = valor
    return campos, texto[m.end():]


def cargar_fuente(ruta):
    ruta = Path(ruta)
    archivos = [ruta] if ruta.is_file() else sorted(
        p for p in ruta.rglob("*.md") if not p.name.startswith("_"))
    if not archivos:
        raise ValueError(f"La fuente no contiene Markdown: {ruta}")
    digest = hashlib.sha256()
    capitulos, todo = {}, []
    for archivo in archivos:
        crudo = archivo.read_bytes().replace(b"\r\n", b"\n")
        digest.update(archivo.name.encode("utf-8") + b"\0" + crudo)
        texto = " ".join(palabras(limpiar_fuente(crudo.decode("utf-8", "replace"))))
        todo.append(texto)
        numero = re.search(r"(\d+)", archivo.stem)
        if numero and ruta.is_dir():
            capitulos.setdefault(int(numero.group(1)), []).append(texto)
    completo = " ".join(todo)
    seq = completo.split()
    tejas = {" ".join(seq[i:i + TEJA]) for i in range(max(0, len(seq) - TEJA + 1))}
    return {"sha256": digest.hexdigest(), "texto": f" {completo} ", "tejas": tejas,
            "capitulos": {n: f" {' '.join(t)} " for n, t in capitulos.items()}}


def hash_fuente(ruta):
    return cargar_fuente(ruta)["sha256"]


def secciones(cuerpo):
    actual, partes = "(inicio)", {}
    for linea in cuerpo.splitlines():
        if linea.startswith("## "):
            actual = linea[3:].strip()
        partes.setdefault(actual, []).append(linea)
    return {k: len(palabras("\n".join(v))) for k, v in partes.items()}


def personajes_dossier(cuerpo):
    nombres, dentro = [], False
    for linea in cuerpo.splitlines():
        if linea.startswith("## "):
            dentro = linea[3:].strip().lower().startswith("personajes")
        elif dentro and linea.startswith("### "):
            nombres.append(linea[4:].strip())
    return nombres


def validar_referencia(path, obra, fuente, hallazgos):
    rel = path.relative_to(obra).as_posix()

    def anota(nivel, mensaje):
        hallazgos.append({"nivel": nivel, "archivo": rel, "mensaje": mensaje})

    if path.suffix.lower() != ".md":
        anota("error", "no es Markdown: conviértelo a .md o sácalo de referencias/")
        return None
    campos, cuerpo = cabecera(path.read_text(encoding="utf-8-sig"))
    if campos is None:
        anota("error", "falta la cabecera (--- titulo, tipo, origen, fecha, proposito ---)")
        return None
    for campo in CAMPOS:
        if not campos.get(campo):
            anota("error", f"falta el campo de cabecera '{campo}'")
    tipo = campos.get("tipo")
    if tipo and tipo not in TIPOS:
        anota("error", f"tipo '{tipo}' no válido (canon-previo, documentacion, guia-previa)")
    total = len(palabras(cuerpo))
    if total > MAX_PALABRAS_ARCHIVO:
        anota("error", f"{total} palabras: supera {MAX_PALABRAS_ARCHIVO}; divídela o resúmela por temas")
    for nombre, n in secciones(cuerpo).items():
        if n > MAX_PALABRAS_SECCION:
            anota("aviso", f"la sección «{nombre}» tiene {n} palabras: no cabe como pasaje (≈{MAX_PALABRAS_SECCION})")
    if tipo != "canon-previo":
        return {"tipo": tipo, "campos": campos, "cuerpo": cuerpo}

    if not campos.get("fuente_sha256"):
        anota("error", "canon-previo sin fuente_sha256 de la fuente usada")
    en_bloque, citas = False, []
    for numero, linea in enumerate(cuerpo.splitlines(), 1):
        if linea.strip().startswith("```"):
            en_bloque = not en_bloque
        m = VINETA.match(linea)
        if en_bloque or not m or m.group(1).rstrip().endswith(":"):
            continue
        encontradas = CITA.findall(linea)
        if not encontradas:
            anota("error", f"hecho sin cita [cap. N: «…»] (línea {numero} del cuerpo): {m.group(1)[:80]}")
        for cap, frag in encontradas:
            n = len(palabras(frag))
            if not 3 <= n <= 25:
                anota("error", f"cita de {n} palabras en cap. {cap} (debe tener de 3 a 25): «{frag[:60]}»")
            citas.append((int(cap), frag, numero))
    if fuente:
        if campos.get("fuente_sha256") and campos["fuente_sha256"] != fuente["sha256"]:
            anota("aviso", "la fuente ha cambiado desde que se generó el dossier (fuente_sha256 distinto): revísalo")
        for cap, frag, numero in citas:
            buscado = f" {' '.join(palabras(frag))} "
            if buscado not in fuente["texto"]:
                anota("error", f"cita inexistente en la fuente (cap. {cap}, línea {numero}): «{frag[:70]}»")
            elif cap in fuente["capitulos"] and buscado not in fuente["capitulos"][cap]:
                anota("error", f"la cita existe pero no en el cap. {cap} (línea {numero}): «{frag[:70]}»")
        propio = palabras(CITA.sub(" ", cuerpo))
        tejas = [" ".join(propio[i:i + TEJA]) for i in range(max(0, len(propio) - TEJA + 1))]
        copiadas = sum(1 for t in tejas if t in fuente["tejas"])
        if tejas and copiadas >= 3 and copiadas / len(tejas) > MAX_COPIA:
            anota("error", f"copia la fuente: {copiadas} de {len(tejas)} fragmentos de {TEJA} palabras son literales")
    return {"tipo": tipo, "campos": campos, "cuerpo": cuerpo}


def validar_obra(obra, archivo=None, fuente_ruta=None):
    obra = Path(obra).resolve()
    carpeta = obra / "referencias"
    hallazgos = []
    fuente = cargar_fuente(fuente_ruta) if fuente_ruta else None
    rutas = [obra / archivo] if archivo else (sorted(p for p in carpeta.rglob("*") if p.is_file())
                                              if carpeta.is_dir() else [])
    refs = {}
    for path in rutas:
        datos = validar_referencia(path, obra, fuente, hallazgos)
        if datos:
            refs[path.relative_to(obra).as_posix()] = datos

    dossiers = {r: d for r, d in refs.items() if d["tipo"] == "canon-previo"}
    if archivo:  # para fichas y nombres hacen falta todos los dossiers
        for path in sorted(carpeta.glob("*.md")) if carpeta.is_dir() else []:
            rel = path.relative_to(obra).as_posix()
            if rel not in refs:
                campos, cuerpo = cabecera(path.read_text(encoding="utf-8-sig"))
                if campos and campos.get("tipo") == "canon-previo":
                    dossiers[rel] = {"campos": campos, "cuerpo": cuerpo}

    heredados = set()
    for ficha in sorted((obra / "fichas").glob("*.md")) if (obra / "fichas").is_dir() else []:
        texto = ficha.read_text(encoding="utf-8-sig")
        if "## Canon heredado" not in texto:
            continue
        heredados.add(ficha.stem)
        origen = re.search(r"referencias/[^`\s)]+\.md", texto.split("## Canon heredado", 1)[1])
        rel = ficha.relative_to(obra).as_posix()
        if not origen:
            hallazgos.append({"nivel": "error", "archivo": rel,
                              "mensaje": "Canon heredado sin dossier de origen (referencias/<dossier>.md)"})
        elif origen.group(0) not in dossiers:
            hallazgos.append({"nivel": "error", "archivo": rel,
                              "mensaje": f"Canon heredado apunta a {origen.group(0)}, que no existe o no es canon-previo"})

    for rel, datos in dossiers.items():
        aceptadas = {p for n in datos["campos"].get("colisiones_aceptadas") or [] for p in palabras(n)}
        previos = {}
        for nombre in personajes_dossier(datos["cuerpo"]):
            for p in palabras(nombre):
                if len(p) >= 3 and p not in NO_NOMBRE:
                    previos.setdefault(p, nombre)
        for ficha in sorted((obra / "fichas").glob("personaje*.md")) if (obra / "fichas").is_dir() else []:
            if ficha.stem in heredados:
                continue
            for p in palabras(ficha.stem.split("_", 1)[-1].replace("-", " ")):
                if p in previos and p not in aceptadas:
                    hallazgos.append({"nivel": "aviso", "archivo": ficha.relative_to(obra).as_posix(),
                                      "mensaje": f"«{p}» coincide con «{previos[p]}» de {rel}: renombra, hereda "
                                                 "la ficha o añádelo a colisiones_aceptadas"})
    return hallazgos, sorted(refs)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--obra", default=str(Path(__file__).resolve().parent.parent))
    parser.add_argument("--archivo", help="Valida solo esta referencia (ruta relativa a la obra)")
    parser.add_argument("--fuente", help="Texto de la obra previa para verificar los canon-previo")
    parser.add_argument("--hash-fuente", action="store_true", help="Imprime el sha256 de --fuente y termina")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)
    try:
        if args.hash_fuente:
            if not args.fuente:
                raise ValueError("--hash-fuente requiere --fuente")
            print(hash_fuente(args.fuente))
            return 0
        hallazgos, revisadas = validar_obra(args.obra, args.archivo, args.fuente)
    except (OSError, ValueError) as error:
        print(json.dumps({"estado": "error", "error": str(error)}, ensure_ascii=False), file=sys.stderr)
        return 1
    errores = [h for h in hallazgos if h["nivel"] == "error"]
    if args.json:
        print(json.dumps({"estado": "error" if errores else "ok", "referencias": revisadas,
                          "hallazgos": hallazgos}, ensure_ascii=False, indent=2))
    else:
        print(f"Referencias revisadas: {len(revisadas)} · errores: {len(errores)} · "
              f"avisos: {len(hallazgos) - len(errores)}")
        for h in hallazgos:
            print(f"  [{h['nivel']}] {h['archivo']}: {h['mensaje']}")
    return 1 if errores else 0


if __name__ == "__main__":
    sys.exit(main())
