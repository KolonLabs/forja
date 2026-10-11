---
description: Añade o regenera EPUB/PDF desde el Markdown congelado de una antología ya publicada, sin modificar sus obras fuente.
agent: bibliotecario
---

# /recompilar-libro

Regenera uno o varios formatos de una antología existente en la raíz de publicados (`FORJA_PUBLICADOS`; por defecto, `../Forja-resultados/Publicados`). No vuelve a ensamblar manuscritos ni cambia el estado de ninguna obra. El libro de una obra única se regenera dentro de la obra con `/compilar`.

## Sintaxis

```text
/recompilar-libro <slug-libro> [--epub] [--pdf] [--pdf-formato <formato>] [--pdf-motor <motor>]
```

Debe indicarse al menos una de `--epub` o `--pdf`.

## Qué hace

1. Lee `<raíz de publicados>/<slug-libro>/<slug-libro>.md` y `manifest.json`.
2. Genera o reemplaza solo los formatos solicitados.
3. Actualiza hashes, metadatos de formato e historial en `manifest.json`.
4. Conserva los demás artefactos publicados.
5. No lee ni escribe en las obras.

## Flujo interno

```powershell
.\scripts\recompilar-libro.ps1 -Libro "<slug-libro>" [-Epub] [-Pdf] [-PdfFormat "paperback"] [-PdfEngine "auto"]
```
