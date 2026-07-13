# MAPA — ¿Rutina? (rutina, escala relato)

## Jerarquía narrativa
_actos.md (actos con hechos) → guion.md (escenas + hechos H_NNNN + beats B_NNNN) → relato-draft.md (prosa, ## B_NNNN) → relato.md (limpio, publicable)

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
| guion.md | guionista | guionista, director (estados) | Escenas, hechos, beats |
| relato-draft.md | director | escritor (append) | Prosa beat a beat |
| relato.md | director (/publicar) | — | Versión limpia publicable |
| contexto_narrativo.md | director | director | Memoria del relato |
| fichas/ | entidades | entidades | Fichas de entidades |

## Convención de nombres
Fichas: <tipo>_<slug>.md (personaje_miguel.md, lugar_parking.md)

## Fases

| Fase | Estado | Acción |
|---|---|---|
| FASE 1: Diseño | diseno | guionista → guion.md |
| FASE 2: Componentes | fichas | entidades → fichas/ + reconciliación |
| FASE 3: Beat a beat | escritura | escritor → validador → ±integrador |
| FASE 4: Publicar | publicacion | /publicar → relato.md |

## Transiciones
diseno → fichas → escritura → publicacion → publicado

## Agentes
director, guionista, escritor, validador, integrador, entidades
No aplican: memoria, cronista

## Infraestructura
Sin Qdrant. Sin Neo4j. Memoria en contexto_narrativo.md.
