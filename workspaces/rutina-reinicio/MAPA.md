# MAPA — ¿Rutina? (rutina-reinicio, escala relato)

## Jerarquía narrativa
_actos.md (actos con hechos H_XXXX) → guion.md (escenas + beats B_XXXX) → relato-draft.md (prosa por escena + anclas invisibles B_XXXX) → relato.md (limpio, publicable)

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
| guion.md | guionista | guionista, director (estados) | Escenas, hechos, beats |
| relato-draft.md | director | escritor (por escena) | Prosa continua por escena; anclas invisibles de beat |
| relato.md | director (/publicar) | — | Versión limpia publicable |
| EDICION.md | /nueva-edicion (solo edición) | — | Linaje y motivo de la edición derivada |
| relato-edicion-anterior.md | /nueva-edicion (solo edición) | — | Manuscrito publicado de referencia, solo lectura |
| correcciones.md | /nueva-edicion, director | director | Registro de las correcciones de una edición |
| contexto_narrativo.md | director | director | Memoria del relato |
| fichas/ | entidades | entidades | Fichas de entidades |

## Convención de nombres
Fichas: <tipo>_<slug>.md (personaje_miguel.md, lugar_parking.md)

## Fases
| Fase | Estado | Acción |
|---|---|---|
| FASE 1: Diseño | diseno | guionista → guion.md |
| FASE 2: Componentes | fichas | entidades → fichas/ + reconciliación |
| FASE 3: Por escena | escritura | escritor → validador → ±integrador por cada `E_XXXX` |
| FASE 4: Finalizar | escritura | /publicar → relato.md y estado `finalizado` |

## Transiciones
diseno → fichas → escritura → finalizado → publicado (hub)

## Agentes
director, guionista, auditor-beats, escritor, validador, integrador, entidades
No aplican: memoria, cronista

## Infraestructura
Sin Qdrant. Sin Neo4j. Memoria en contexto_narrativo.md.

