# MAPA — Eros-9 (eros-9, escala novela-simple)

## Jerarquía narrativa
_actos.md (actos con hechos) → guion-novela.md → capitulos/cap-NN-slug/guion.md (escenas + beats) → capitulos/cap-NN-slug/draft.md → novela.md (limpio, publicable)

## Dónde vive cada cosa
| Archivo | Quién crea | Quién actualiza | Contenido |
|---|---|---|---|
| config.json | Script | director, guionista (IDs) | Estado, contadores, estilo |
| BRIEF.md | Script | — | Logline, personajes, mundo |
| _actos.md | Script | director / guionista | Actos con hechos |
| AGENTS.md | Script | director | Reglas del proyecto |
| PIPELINE.md | Script | — | Fases del pipeline |
| ORQUESTACION.md | Script | — | Contratos de spawn |
| MAPA.md | Script | — | Este archivo |
| guion-novela.md | guionista | guionista, director (estados) | Capítulos, escenas, beats |
| capitulos/cap-NN-slug/guion.md | guionista | guionista, director | Escenas + beats del capítulo |
| capitulos/cap-NN-slug/draft.md | escritor | escritor, validador | Prosa del capítulo |
| capitulos/cap-NN-slug/capitulo.md | director | — | Versión limpia del capítulo |
| novela.md | director (/publicar) | — | Versión limpia publicable |
| contexto.md | director | director, memoria | Memoria narrativa de la novela |
| fichas/ | entidades | entidades | Fichas de personajes, lugares, objetos |

## Convención de nombres
Fichas: <tipo>_<slug>.md (personaje_elena.md, lugar_laboratorio.md, objeto_eros9.md)
Capítulos: capitulos/cap-NN-slug/ donde NN es el número de capítulo con padding de 2 dígitos

## Fases
| Fase | Estado | Acción |
|---|---|---|
| FASE 1: Diseño | diseno | guionista → guion-novela.md + capítulos |
| FASE 2: Componentes | fichas | entidades → fichas/ + reconciliación + neo4j |
| FASE 3: Beat a beat | escritura | escritor → validador → ±integrador → memoria |
| FASE 4: Publicar | publicacion | /publicar → novela.md |

## Transiciones
diseno → fichas → escritura → publicacion → publicado

## Agentes
director, guionista, escritor, validador, integrador, entidades, memoria, cronista

## Infraestructura
Qdrant + Neo4j activos. Colecciones y grafos bajo prefijo `eros-9`.

