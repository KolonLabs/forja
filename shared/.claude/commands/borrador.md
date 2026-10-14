---
description: "Genera una versión limpia de revisión del trabajo en curso (Markdown, EPUB o PDF) sin cambiar el estado de la obra."
disable-model-invocation: true
---

# /borrador

Genera una versión limpia del trabajo en curso —la prosa o, con `--guion`, el guion— para leerla o revisarla, sin publicar nada. Lo hace `scripts/borrador.ps1`, que es determinista: tú solo traduces los argumentos y ejecutas el script una vez. No editas el draft, el guion, `config.json` ni `publicacion/`.

## Entrada del comando

Argumentos recibidos: `$ARGUMENTS`

## Sintaxis

```
/borrador [cap-NN] [--guion [--anotado] [--hilo <hilo>]] [--epub] [--pdf] [--pdf-formato <formato>] [--pdf-motor <motor>] [--titulo "<título>"] [--autor "<autor>"]
```

| Parámetro | Descripción | Default |
|---|---|---|
| `cap-NN` | Solo en novela: capítulo a revisar (`cap-05`, `5` o el nombre de su carpeta) | El capítulo en curso |
| `--guion` | Borrador del guion en lugar de la prosa | Prosa |
| `--anotado` | Con `--guion`: añade datos de escena, tono, extensión, personajes, zona, hilos y ⚡ | Solo etiqueta y acción |
| `--hilo` | Con `--guion`, solo en multi-hilo antes de ensamblar: hilo cuyo capítulo se revisa (`vidal` o `hilo-vidal`) | Obligatorio si hay más de un hilo con guion |
| `--epub` | Genera también el EPUB (requiere Pandoc) | Solo Markdown |
| `--pdf` | Genera también el PDF (requiere Pandoc y Typst, wkhtmltopdf o XeLaTeX) | Solo Markdown |
| `--pdf-formato` | `paperback`, `paperback-5x8`, `hardcover`, `hardcover-9pt`, `hardcover-6x9`, `hardcover-6x9-9pt` | `paperback` |
| `--pdf-motor` | `auto`, `typst`, `xelatex`, `wkhtmltopdf` | `auto` |
| `--titulo` | Título del frontmatter (portada y metadatos); se le añade «(borrador)» | `config.json.titulo` |
| `--autor` | Autor del frontmatter (portada y metadatos) | `Amaro Alba` |

## Qué incluye

- **Relato:** toda la prosa confirmada de `relato-draft.md`, limpia como en `/publicar`. Una escena todavía en staging no entra.
- **Novela y multi-hilo:** un único capítulo, nunca la novela entera. Solo entran las escenas completas: presentes en el `draft.md` del capítulo y con todos sus beats `✅` en su `guion.md`. Las candidatas `escena-*.pendiente.md` y las escenas con beats pendientes no entran. Si falta una escena entre dos completas, aparece una línea «*[Escena pendiente: <nombre>]*».
- **Capítulo en curso:** el primero con beats pendientes y alguna escena completa; si todos los que tienen escenas completas están cerrados, el último de ellos.
- **Con `--guion`:** el guion del relato completo o de un capítulo de novela, para revisión humana. Cada escena con su etiqueta y nombre (`## E_0031 — La planta`) y cada beat con su etiqueta visual y su acción (`**B_0220** …`), sin estados, `stable_id`, `seq`, tonos ni notas; `--anotado` los añade. Sin capítulo, usa el capítulo en curso del guion: el primero con beats pendientes (si todos están cerrados, el último con guion). En multi-hilo usa `capitulos/` si ya están ensamblados y, si no, el hilo indicado con `--hilo`. Si el capítulo no tiene guion, falla.

## Ejecución

Ejecuta una sola vez, con los parámetros equivalentes y sin añadir otros:

```
pwsh -NoProfile -File scripts/borrador.ps1 [-Capitulo <cap>] [-Guion] [-Anotado] [-Hilo <hilo>] [-Epub] [-Pdf] [-PdfFormat <formato>] [-PdfEngine <motor>] [-Titulo "<título>"] [-Autor "<autor>"]
```

## Resultado

- **Relato:** `publicacion/borrador/prosa/<slug>-borrador.*`; con `--guion`, `publicacion/borrador/guion/<slug>-guion-borrador.*`.
- **Novela y multi-hilo:** una carpeta por capítulo. Prosa en `publicacion/borrador/prosa/cap-NN/<slug>-cap-NN-borrador.*`; con `--guion`, `publicacion/borrador/guion/cap-NN/<slug>-cap-NN-guion-borrador.*` o, por hilo antes de ensamblar, `publicacion/borrador/guion/hilo-<hilo>/cap-NN/<slug>-<hilo>-cap-NN-guion-borrador.*`.
- `--anotado` añade `-anotado` antes de `-borrador`. Una versión suelta del mismo alcance que dejó una estructura anterior (en `prosa/` o `guion/` sin carpeta de capítulo, o en `publicacion/borrador/`) se retira al regenerarlo.
- Sin formatos, el borrador es el `.md`, con un `.manifest.json` que registra las escenas incluidas, los hashes de las fuentes y el commit. Con `--epub` o `--pdf` se generan además los formatos pedidos y se conserva junto a ellos el `.md` en que se basan; el manifest es un fichero de trabajo y se elimina.
- Cada ejecución sustituye el borrador anterior del mismo alcance. `publicacion/` no se versiona.
- El `.md` abre con un frontmatter YAML con las propiedades de la obra: `title` (con «(borrador)» y, en novela, el capítulo: `<título> · Capítulo N (borrador)`), `subtitle` (el `subtitulo` de la obra, si lo hay, y que es un borrador, su fecha y su cobertura), `author`, `lang`, `date`, `subject` (género y subgénero) e `identifier` (propio de cada borrador, distinto del libro). Título y autor no forman parte del texto, que empieza directamente con la prosa (o con el encabezado del capítulo, en novela). Pandoc usa esas propiedades para la portada y los metadatos del EPUB y del PDF. Con `--epub`, si existe `imagenes/portada.jpg` (o `.png`), el EPUB la lleva como cubierta para ver cómo quedará.
- El estado de la obra no cambia.

## Si falla

Muestra el error tal cual. Si el capítulo no tiene escenas completas (o, con `--guion`, no tiene guion), dilo; si avisa de beats sin etiqueta visual, sugiere ejecutar `etiquetas-guion.py`; no generes nada por otra vía ni edites archivos para sortearlo.
