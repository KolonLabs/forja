---
description: Crea un libro (Markdown/EPUB/PDF) desde workspaces finalizados. Una novela = un libro. Varios relatos = antología.
agent: bibliotecario
---

# /crear-libro

Ensambla un libro desde los archivos limpios (`relato.md` / `novela.md`) de los workspaces indicados.

## Entrada del comando

Argumentos recibidos: `$ARGUMENTS`

Interpreta esos argumentos antes de actuar. El primer valor es el slug del libro y los siguientes, hasta una opción `--...`, son los workspaces fuente. Ejecuta el script una sola vez con los valores resultantes; no inventes rutas ni modifiques manuscritos.

## Sintaxis

```
/crear-libro <slug-libro> <workspace1> [workspace2 ...] [--epub] [--pdf] [--pdf-formato <formato>] [--pdf-motor <motor>] [--titulo "<título>"] [--autor "<autor>"]
```

| Parámetro | Descripción | Default |
|---|---|---|
| `--epub` | Compila también un EPUB (requiere Pandoc) | Solo Markdown |
| `--pdf` | Compila también un PDF | Solo Markdown |
| `--pdf-formato` | `paperback`, `paperback-5x8`, `hardcover`, `hardcover-9pt`, `hardcover-6x9`, `hardcover-6x9-9pt` | `paperback` |
| `--pdf-motor` | `auto`, `typst`, `xelatex`, `wkhtmltopdf` | `auto` |
| `--titulo` | Título mostrado en la portada/metadatos | El propio `<slug-libro>` |
| `--autor` | Nombre de autor en la portada/metadatos | `Amaro Alba` |

## Ejemplos

```
/crear-libro cronicas-del-deseo rutina la-fachada --epub
/crear-libro mi-novela mi-novela --epub --pdf --pdf-formato paperback --titulo "Mi Novela" --autor "Amaro Alba"
```

## Qué hace

1. Lee `relato.md` o `novela.md` de cada workspace fuente
2. Ensambla el contenido en `publicados/<slug-libro>/<slug-libro>.md`
3. Opcionalmente compila EPUB con `--epub` y/o PDF con `--pdf`
4. Rechaza mezclas de relatos y novelas, o más de una novela
5. Escribe `manifest.json` con fuentes congeladas, hashes y formatos generados
6. Solo si todas las salidas solicitadas terminan correctamente, marca `config.json.estado = "publicado"` en los workspaces fuente

## Requisitos

- Los workspaces fuente deben estar en estado `finalizado` tras ejecutar `/publicar`
- El archivo `relato.md` o `novela.md` debe existir en la raíz de cada workspace
- Pandoc debe estar instalado para `--epub` y `--pdf`
- Para PDF se requiere además Typst, wkhtmltopdf o XeLaTeX (el motor `auto` los prueba en ese orden)

## Flujo interno

El comando ejecuta:
```powershell
.\scripts\crear-libro.ps1 -Libro "<slug>" -Fuentes @("<ws1>","<ws2>") [-Epub] [-Pdf] [-PdfFormat "paperback"] [-PdfEngine "auto"] [-Titulo "<título>"] [-Autor "<autor>"]
```
