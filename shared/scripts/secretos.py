"""Lectura de secretos del usuario (ADR 0029).

Orden: variable de entorno del proceso con el mismo nombre; después el archivo de
secretos (FORJA_SECRETOS o ~/.forja/secretos.env). Nunca escribe ni muestra valores.

Uso como módulo:  from secretos import obtener_secreto
Comprobación:     python secretos.py --comprobar ELEVENLABS_API_KEY
"""
import argparse
import os
import re
import sys
from pathlib import Path

NOMBRE = re.compile(r"^[A-Z][A-Z0-9_]*$")


def ruta_secretos():
    return Path(os.environ.get("FORJA_SECRETOS") or Path.home() / ".forja" / "secretos.env")


def buscar_secreto(nombre):
    """Devuelve (valor, fuente) o None si el secreto no está definido."""
    if not NOMBRE.match(nombre):
        raise ValueError(f"secretos: nombre '{nombre}' no válido. Usa MAYUSCULAS_CON_GUIONES_BAJOS.")
    valor = os.environ.get(nombre, "").strip()
    if valor:
        return valor, "variable de entorno"
    ruta = ruta_secretos()
    if not ruta.is_file():
        return None
    for linea in ruta.read_text(encoding="utf-8-sig").splitlines():
        linea = linea.strip()
        if not linea or linea.startswith("#"):
            continue
        clave, sep, valor = linea.partition("=")
        if not sep or clave.strip() != nombre:
            continue
        valor = valor.strip()
        if len(valor) >= 2 and valor[0] == valor[-1] and valor[0] in "\"'":
            valor = valor[1:-1]
        return (valor, f"archivo {ruta}") if valor.strip() else None
    return None


def obtener_secreto(nombre):
    """Devuelve el valor o lanza KeyError indicando dónde definirlo, sin mostrar nada."""
    encontrado = buscar_secreto(nombre)
    if encontrado is None:
        raise KeyError(f"secretos: '{nombre}' no está definido. Añádelo a {ruta_secretos()} o como variable de entorno.")
    return encontrado[0]


def main():
    parser = argparse.ArgumentParser(description="Comprueba secretos de Forja sin mostrar su valor.")
    parser.add_argument("--comprobar", required=True, metavar="NOMBRE")
    args = parser.parse_args()
    encontrado = buscar_secreto(args.comprobar)
    if encontrado is None:
        print(f"{args.comprobar} no definido")
        return 1
    print(f"{args.comprobar} definido (fuente: {encontrado[1]})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
