---
description: Añade o regenera EPUB/PDF desde el Markdown congelado de un libro ya publicado, sin modificar sus workspaces fuente.
agent: bibliotecario
---

# /recompilar-libro

Regenera uno o varios formatos de un libro existente. No vuelve a ensamblar manuscritos ni cambia el estado de ningún workspace.

## Sintaxis

```text
/recompilar-libro <slug-libro> [--epub] [--pdf] [--pdf-formato <formato>] [--pdf-motor <motor>]
```

Debe indicarse al menos una de `--epub` o `--pdf`.

## Qué hace

1. Lee `publicados/<slug-libro>/<slug-libro>.md` y `manifest.json`.
2. Genera o reemplaza solo los formatos solicitados.
3. Actualiza hashes, metadatos de formato e historial en `manifest.json`.
4. Conserva los demás artefactos publicados.
5. No lee ni escribe en `workspaces/`.

## Flujo interno

```powershell
.\scripts\recompilar-libro.ps1 -Libro "<slug-libro>" [-Epub] [-Pdf] [-PdfFormat "paperback"] [-PdfEngine "auto"]
```
