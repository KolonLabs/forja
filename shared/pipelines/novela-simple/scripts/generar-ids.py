#!/usr/bin/env python3
"""Genera identificadores aleatorios para stable_id. Los agentes no deben inventarlos.

  python -X utf8 scripts/generar-ids.py            -> 1 id de 8 hex (hechos, beats, escenas, capitulos)
  python -X utf8 scripts/generar-ids.py --n 12     -> 12 ids de 8 hex, uno por linea
  python -X utf8 scripts/generar-ids.py --uuid     -> 1 UUID v4 (entidades)

Un identificador escrito por un modelo no es aleatorio (tiende a repetir patrones);
este script usa el generador criptografico del sistema y no repite ids dentro de una llamada.
"""
import argparse
import secrets
import uuid


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--n", type=int, default=1, help="Cantidad de ids (1-1000)")
    parser.add_argument("--uuid", action="store_true", help="UUID v4 completo en lugar de 8 hex")
    args = parser.parse_args()
    if not 1 <= args.n <= 1000:
        parser.error("--n debe estar entre 1 y 1000")
    ids = []
    while len(ids) < args.n:
        nuevo = str(uuid.uuid4()) if args.uuid else secrets.token_hex(4)
        if nuevo not in ids:
            ids.append(nuevo)
    print("\n".join(ids))


if __name__ == "__main__":
    main()
