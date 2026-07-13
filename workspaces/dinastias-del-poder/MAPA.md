# MAPA — Dinastías del Poder (dinastias-del-poder, escala novela-multi-hilo)

## Jerarquía narrativa
_actos.md (actos con hechos, estructura Hilo → Acto → Hechos) → hilos/hilo-*/diseno-hilo.md (diseño de cada hilo) → hilos/hilo-*/guion-hilo.md (escenas + hechos H_NNNN + beats B_NNNN) → guion-novela.md (trenzado de hilos) → capitulos/cap-NN-slug/ (guion.md, draft.md, capitulo.md) → novela.md (limpio, publicable)

## Dónde vive cada cosa
| Archivo | Quién crea | Quién actualiza | Contenido |
|---|---|---|---|
| config.json | Script | director (estado, IDs, hilos) | Estado, contadores, estilo, hilos, partes |
| BRIEF.md | Script | — | Logline, personajes, mundo, reflexión editorial |
| _actos.md | Script | director / guionista | Actos con hechos organizados por hilo |
| AGENTS.md | Script | director | Reglas del proyecto, skills activos |
| PIPELINE.md | Script | — | 8 fases del pipeline |
| ORQUESTACION.md | Script | — | Contratos de spawn por fase |
| MAPA.md | Script | — | Este archivo |
| hilos/hilo-<slug>/diseno-hilo.md | Script (scaffolder) | director / integrador | Diseño narrativo del hilo: personajes, arco, tono, hechos asignados |
| hilos/hilo-<slug>/guion-hilo.md | guionista | guionista, director (estados) | Escenas, hechos y beats del hilo |
| guion-novela.md | integrador | integrador, director | Tabla de trenzado con escenas de todos los hilos |
| capitulos/cap-NN-slug/ | director | escritor, validador | Guion, draft y capítulo final de cada capítulo |
| novela.md | director (/publicar) | — | Versión limpia publicable con todos los capítulos |
| contexto.md | director, memoria | director, memoria | Memoria vectorial (Qdrant) + grafo (Neo4j) |
| fichas/ | entidades | entidades | Fichas de personajes, lugares, objetos, eventos |

## Convención de nombres
- Fichas: <tipo>_<slug>.md (personaje_daniel-ortega.md, lugar_vallecas.md, objeto_sello-cilindrico.md)
- Capítulos: capitulos/cap-01-el-despertar/ (guion.md, draft.md, capitulo.md)
- Hilos: hilos/hilo-actualidad/ (diseno-hilo.md, guion-hilo.md)

## Hilos
| ID | Slug | Nombre | Época | Estado |
|---|---|---|---|---|
| hilo-actualidad | actualidad | Daniel Ortega | actualidad | pendiente |
| hilo-mateo | mateo | Mateo Ortega | 1752 | pendiente |
| hilo-livia | livia | Livia Orteia | 62 d.C. | pendiente |
| hilo-ninkasi | ninkasi | Nin-Kasi | 2900 a.C. | pendiente |

## Fases
| Fase | Estado | Acción |
|---|---|---|
| FASE 0: Setup | setup | director carga briefing, configura workspace, verifica infraestructura |
| FASE 1: Diseño de hilos | diseno_hilos | guionista diseña cada hilo → diseno-hilo.md y guion-hilo.md |
| FASE 2: Trenzado | trenzado | integrador trenza los hilos → guion-novela.md |
| FASE 3: Fichas | fichas | entidades crea fichas de personajes, lugares, objetos, eventos |
| FASE 4: Escritura | escritura | escritor redacta capítulos → validador audita → ±integrador reconcilia |
| FASE 5: Revisión de hechos | revision_hechos | director revisa cobertura de hechos pendientes |
| FASE 6: Revisión de guion | revision_guion | guionista revisa y ajusta guiones por hilo |
| FASE 7: Validación cross-hilo | validacion | validador comprueba coherencia entre hilos |
| FASE 8: Publicar | publicacion | /publicar → novela.md |

## Transiciones
setup → diseno_hilos → trenzado → fichas → escritura → revision_hechos → revision_guion → validacion → publicacion → publicado

## Agentes
director, guionista, escritor, validador, integrador, entidades, memoria, cronista

## Infraestructura
Qdrant :6333 + Neo4j :7687 (colecciones/grafos dinastias-del-poder_*). Búsqueda semántica cross-hilo y grafo de relaciones entre personajes, lugares, objetos y eventos a través de las cuatro épocas.
