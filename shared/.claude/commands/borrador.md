---
description: "Genera una versión limpia de revisión del trabajo en curso (Markdown, EPUB o PDF) sin cambiar el estado de la obra."
disable-model-invocation: true
---

# /borrador

Genera una versión limpia del trabajo en curso para leerla o revisarla, sin publicar nada. Lo hace `scripts/borrador.ps1`, que es determinista: tú solo traduces los argumentos y ejecutas el script una vez. No editas el draft, el guion, `config.json` ni `publicacion/`.

## Entrada del comando

Argumentos recibidos: `$ARGUMENTS`

## Sintaxis

```
/borrador [cap-NN] [--epub] [--pdf] [--pdf-formato <formato>] [--pdf-motor <motor>] [--titulo "<título>"] [--autor "<autor>"]
```

| Parámetro | Descripción | Default |
|---|---|---|
| `cap-NN` | Solo en novela: capítulo a revisar (`cap-05`, `5` o el nombre de su carpeta) | El capítulo en curso |
| `--epub` | Genera también el EPUB (requiere Pandoc) | Solo Markdown |
| `--pdf` | Genera también el PDF (requiere Pandoc y Typst, wkhtmltopdf o XeLaTeX) | Solo Markdown |
| `--pdf-formato` | `paperback`, `paperback-5x8`, `hardcover`, `hardcover-9pt`, `hardcover-6x9`, `hardcover-6x9-9pt` | `paperback` |
| `--pdf-motor` | `auto`, `typst`, `xelatex`, `wkhtmltopdf` | `auto` |
| `--titulo` | Título de portada y metadatos (se le añade «(borrador)») | `config.json.titulo` |
| `--autor` | Autor de portada y metadatos | `Amaro Alba` |

## Qué incluye

- **Relato:** toda la prosa confirmada de `relato-draft.md`, limpia como en `/publicar`. Una escena todavía en staging no entra.
- **Novela y multi-hilo:** un único capítulo, nunca la novela entera. Solo entran las escenas completas: presentes en el `draft.md` del capítulo y con todos sus beats `✅` en su `guion.md`. Las candidatas `escena-*.pendiente.md` y las escenas con beats pendientes no entran. Si falta una escena entre dos completas, aparece una línea «*[Escena pendiente: <nombre>]*».
- **Capítulo en curso:** el primero con beats pendientes y alguna escena completa; si todos los que tienen escenas completas están cerrados, el último de ellos.

## Ejecución

Ejecuta una sola vez, con los parámetros equivalentes y sin añadir otros:

```
pwsh -NoProfile -File scripts/borrador.ps1 [-Capitulo <cap>] [-Epub] [-Pdf] [-PdfFormat <formato>] [-PdfEngine <motor>] [-Titulo "<título>"] [-Autor "<autor>"]
```

## Resultado

- `publicacion/borrador/<slug>-borrador.*` (relato) o `<slug>-cap-NN-borrador.*` (novela), con un `.manifest.json` que registra las escenas incluidas, los hashes de las fuentes y el commit.
- Cada ejecución sustituye el borrador anterior del mismo alcance. `publicacion/` no se versiona.
- La portada y la primera línea indican que es un borrador, su fecha y su cobertura.
- El estado de la obra no cambia.

## Si falla

Muestra el error tal cual. Si el capítulo no tiene escenas completas, dilo; no generes nada por otra vía ni edites archivos para sortearlo.
