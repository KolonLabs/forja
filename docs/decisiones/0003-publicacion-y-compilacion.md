# ADR 0003: Publicacion y compilacion de libros

- Estado: aceptada
- Fecha: 2026-07-13

## Contexto

La compilacion no debe consumir archivos intermedios ni dejar estados de publicacion inconsistentes si falla una salida opcional. Los formatos de libro tienen dependencias externas que deben expresarse de forma uniforme.

## Decision

`/crear-libro` solo acepta el manuscrito limpio generado por `/publicar`: `relato.md` para relatos y `novela.md` para novelas. Las fuentes deben estar en estado `publicacion` o `publicado`.

Un libro es exactamente una de estas composiciones:

- Una novela desde un unico workspace de tipo novela.
- Una antologia desde uno o varios workspaces de tipo relato.

No se pueden mezclar ambos tipos ni repetir una fuente. Toda compilacion genera Markdown; EPUB y PDF son salidas opcionales. EPUB requiere Pandoc. PDF requiere Pandoc y Typst, wkhtmltopdf o XeLaTeX; el motor `auto` prioriza Typst, wkhtmltopdf y XeLaTeX.

Los estados de las fuentes solo se actualizan a `publicado` despues de que todas las salidas solicitadas se hayan generado correctamente.

## Consecuencias

- Los borradores, escenas y beats no pueden entrar accidentalmente en un libro publicado.
- Un fallo al generar EPUB o PDF no debe marcar fuentes como publicadas.
- Las dependencias de compilacion se detectan al solicitar la salida correspondiente.

## Referencias

- [scripts/crear-libro.ps1](../../scripts/crear-libro.ps1)
- [scripts/build-pdf.ps1](../../scripts/build-pdf.ps1)
- [Guia operativa](../operacion-hub.md)
