---
description: "Compila el manuscrito limpio de la obra a libro (Markdown, EPUB y PDF opcionales) en publicacion/."
disable-model-invocation: true
---

# /compilar

Compila el manuscrito limpio de esta obra (`relato.md` o `novela.md`) a libro. Lo hace `scripts/compilar.ps1`, que es determinista: tú solo traduces los argumentos y ejecutas el script una vez. No editas el manuscrito, `config.json` ni `publicacion/`.

## Entrada del comando

Argumentos recibidos: `$ARGUMENTS`

## Sintaxis

```
/compilar [--epub] [--pdf] [--pdf-formato <formato>] [--pdf-motor <motor>] [--titulo "<título>"] [--autor "<autor>"]
```

| Parámetro | Descripción | Default |
|---|---|---|
| `--epub` | Genera también el EPUB (requiere Pandoc) | Solo Markdown |
| `--pdf` | Genera también el PDF (requiere Pandoc y Typst, wkhtmltopdf o XeLaTeX) | Solo Markdown |
| `--pdf-formato` | `paperback`, `paperback-5x8`, `hardcover`, `hardcover-9pt`, `hardcover-6x9`, `hardcover-6x9-9pt` | `paperback` |
| `--pdf-motor` | `auto`, `typst`, `xelatex`, `wkhtmltopdf` | `auto` |
| `--titulo` | Título del frontmatter (portada y metadatos) | `config.json.titulo` |
| `--autor` | Autor del frontmatter (portada y metadatos) | `Amaro Alba` |

## Requisitos

- `config.json.estado` es `finalizado` (tras `/publicar`) o `publicado` (para regenerar formatos). En cualquier otro estado, indica que primero hay que terminar la obra con `/publicar` y no ejecutes nada.
- Existe el manuscrito limpio en la raíz del workspace.

## Ejecución

Ejecuta una sola vez, con los parámetros equivalentes y sin añadir otros:

```
pwsh -NoProfile -File scripts/compilar.ps1 [-Epub] [-Pdf] [-PdfFormat <formato>] [-PdfEngine <motor>] [-Titulo "<título>"] [-Autor "<autor>"]
```

## Resultado

- `publicacion/<slug>.md` y, si se pidieron, `<slug>.epub` y `<slug>.pdf`. El `.md` abre con un frontmatter YAML (`title`, `author`, `lang`, `date` y `subject`) que Pandoc usa para la portada y los metadatos; título y autor no forman parte del texto.
- `publicacion/manifest.json` con el hash del manuscrito y el commit de la obra.
- `config.json.estado = "publicado"`, solo si todas las salidas se generaron. Lo escribe el script, nunca tú.

`publicacion/` no se versiona: se regenera desde el manuscrito. Si el script avisa de que el manuscrito tiene cambios sin commitear, transmite el aviso: el commit lo decide la persona usuaria, no lo hagas tú.

## Si falla

Muestra el error tal cual. No reintentes con otros parámetros ni edites archivos para sortearlo: el estado y la publicación anterior quedan intactos.
