---
description: Ensambla una antología (Markdown/EPUB/PDF) desde dos o más relatos finalizados. Una obra única se compila dentro de la obra con /compilar.
agent: bibliotecario
---

# /crear-libro

Ensambla una antología desde los manuscritos limpios (`relato.md`) de los relatos indicados. Las obras viven en la raíz de obras (`FORJA_OBRAS`; por defecto, `../Forja-resultados/Obras`) y el libro se escribe en la raíz de publicados (`FORJA_PUBLICADOS`; por defecto, `../Forja-resultados/Publicados`). Ver ADR 0026.

Una novela o un relato suelto no pasan por aquí: se compilan dentro de su propia obra con `/compilar`.

## Entrada del comando

Argumentos recibidos: `$ARGUMENTS`

Interpreta esos argumentos antes de actuar. El primer valor es el slug del libro y los siguientes, hasta una opción `--...`, son los relatos fuente. Ejecuta el script una sola vez con los valores resultantes; no inventes rutas ni modifiques manuscritos.

## Sintaxis

```
/crear-libro <slug-libro> <relato1> <relato2> [relato3 ...] [--epub] [--pdf] [--pdf-formato <formato>] [--pdf-motor <motor>] [--titulo "<título>"] [--autor "<autor>"]
```

| Parámetro | Descripción | Default |
|---|---|---|
| `--epub` | Compila también un EPUB (requiere Pandoc) | Solo Markdown |
| `--pdf` | Compila también un PDF | Solo Markdown |
| `--pdf-formato` | `paperback`, `paperback-5x8`, `hardcover`, `hardcover-9pt`, `hardcover-6x9`, `hardcover-6x9-9pt` | `paperback` |
| `--pdf-motor` | `auto`, `typst`, `xelatex`, `wkhtmltopdf` | `auto` |
| `--titulo` | Título mostrado en la portada/metadatos | El propio `<slug-libro>` |
| `--autor` | Nombre de autor en la portada/metadatos | `Amaro Alba` |

## Ejemplo

```
/crear-libro cronicas-del-deseo rutina la-fachada --epub
```

## Qué hace

1. Lee `relato.md` de cada relato fuente
2. Ensambla el contenido en `<raíz de publicados>/<slug-libro>/<slug-libro>.md`
3. Opcionalmente compila EPUB con `--epub` y/o PDF con `--pdf`
4. Rechaza menos de dos fuentes, novelas y fuentes repetidas
5. Escribe `manifest.json` con fuentes congeladas, hashes y formatos generados
6. Solo si todas las salidas solicitadas terminan correctamente, marca `config.json.estado = "publicado"` en los relatos fuente

## Requisitos

- Los relatos fuente deben estar en estado `finalizado` tras ejecutar `/publicar`
- El archivo `relato.md` debe existir en la raíz de cada obra
- Pandoc debe estar instalado para `--epub` y `--pdf`
- Para PDF se requiere además Typst, wkhtmltopdf o XeLaTeX (el motor `auto` los prueba en ese orden)

## Flujo interno

El comando ejecuta:
```powershell
.\scripts\crear-libro.ps1 -Libro "<slug>" -Fuentes @("<relato1>","<relato2>") [-Epub] [-Pdf] [-PdfFormat "paperback"] [-PdfEngine "auto"] [-Titulo "<título>"] [-Autor "<autor>"]
```
