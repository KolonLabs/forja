# MAPA — Renacer para perder (renacer-para-perder, escala novela-simple)

## Jerarquía narrativa
_actos.md (actos con hechos H_XXXX) → guion-novela.md (estructura global, arcos, capítulos) → capitulos/cap-NN-slug/guion.md (escenas + beats B_XXXX) → capitulos/cap-NN-slug/draft.md (prosa por escena + anclas invisibles B_XXXX) → capitulos/cap-NN-slug/capitulo.md (limpio) → novela.md (ensamblado, publicable)

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
| GUIA.md | Script | — | Cuándo usar cada comando y cuándo volver al hub |
| guion-novela.md | guionista | guionista, director | Estructura global, arcos, capítulos |
| capitulos/cap-NN-slug/guion.md | guionista | guionista, director (estados) | Escenas, hechos, beats del capítulo |
| capitulos/cap-NN-slug/escena-SID.pendiente.md | director via persistir-escena.py | director | Candidato de escena validado mecanicamente, pendiente de revision editorial |
| capitulos/cap-NN-slug/draft.md | director via persistir-escena.py | director | Escenas aceptadas por hash, con marcadores y headings stable_id [seq] |
| capitulos/cap-NN-slug/capitulo.md | director | — | Versión limpia del capítulo |
| novela.md | director (/publicar) | — | Versión limpia publicable (ensamblado de capítulos) |
| contexto.md | director | director, memoria | Memoria de la novela |
| fichas/ | entidades | entidades | Fichas de entidades |
| referencias/ | Script | — | Material de referencia no-narrativo (vacío si no hay) |
| scripts/persistir-escena.py | desarrollo local autorizado | desarrollo local | preparar / aceptar / sincronizar; sin generar narrativa |
| docs/decisiones/0001-narrativa-por-escena.md | desarrollo local autorizado | desarrollo local | Contrato vigente del flujo narrativo, 64000 tokens y pruebas |

## Convención de nombres
Fichas: <tipo>_<slug>.md (personaje_elena.md, lugar_ayuntamiento.md)
Capítulos: capitulos/cap-NN-slug/ (cap-01-jaula/, cap-02-despertar/, etc.)

## Fases
| Fase | Estado | Acción |
|---|---|---|
| FASE 1: Diseño | diseno | guionista → guion-novela.md + capitulos/*/guion.md |
| FASE 2: Componentes | fichas | entidades → fichas/ + reconciliación |
| FASE 3: Por escena | escritura | escritor → validador → ±integrador por cada `E_XXXX` |
| FASE 4: Publicación | publicacion | /publicar → novela.md y estado `finalizado` |

## Transiciones
diseno → fichas → escritura → publicacion → finalizado → publicado (hub)

## Agentes
director, guionista, auditor-beats, escritor, validador, integrador, entidades, memoria, cronista

## Infraestructura
Qdrant + Neo4j activos. Memoria en contexto.md + Qdrant (embeddings) + Neo4j (grafo de entidades).
