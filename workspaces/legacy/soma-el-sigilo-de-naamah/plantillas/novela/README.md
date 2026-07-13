# Novela: [TÍTULO]

## Estructura

- `guion-novela.md` — arcos, capítulos, escenas, hilos (generado en FASE 0)
- `config.json` — metadatos y estado actual
- `_brainstorming.md` — ideas, worldbuilding, notas de diseño
- `_actos.md` — estructura de actos (I-VII)

## Capítulos

`capitulos/cap-XX-slug/`
- `guion.md` — beats del capítulo
- `draft.md` — borrador con beats
- `capitulo.md` — versión publicable limpia

## Fichas

`fichas/` — una ficha por entidad (markdown, exportadas desde Qdrant)

## Memoria

- Qdrant: summaries L0-L4, entidades (fijo/dinamico), beats
- Neo4j: grafo de relaciones entre entidades
