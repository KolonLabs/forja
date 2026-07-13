---
name: scaffolding-mapa
description: Define la estructura del MAPA.md del workspace según la escala. Lo carga el scaffolder en Fase 7 para generar el MAPA en el brief JSON.
---

# MAPA.md — estructura por escala

El **MAPA.md** es el índice de datos del workspace. Responde "¿dónde está X?" para que el director y los subagentes sepan qué leer y dónde escribir.

El scaffolder genera este archivo en Fase 7 y lo incluye en el brief JSON. No hay plantilla: el contenido se construye en contexto según la escala.

## Campos del brief para MAPA

El brief JSON debe incluir un campo `"_mapa"` con el contenido markdown completo del MAPA.md. El script lo escribe directamente, sin expandir templates ni condicionales.

## Estructura por escala

### Relato

```markdown
# MAPA — {{TITULO}} ({{SLUG}}, escala relato)

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
| FASE 4: Finalizar | escritura | /publicar → relato.md y estado `finalizado` |

## Transiciones
diseno → fichas → escritura → finalizado → publicado (hub)

## Agentes
director, guionista, escritor, validador, integrador, entidades
No aplican: memoria, cronista

## Infraestructura
Sin Qdrant. Sin Neo4j. Memoria en contexto_narrativo.md.
```

### Novela simple

Añadir respecto al relato:
- `guion-novela.md` en jerarquía y archivos
- `capitulos/cap-NN-slug/` (guion.md, draft.md, capitulo.md)
- `novela.md` como salida publicable
- `contexto.md` en vez de `contexto_narrativo.md`
- Agentes: añadir memoria, cronista
- Skills extra: qdrant, neo4j, auditoria-neo4j, hechos-estructura, plantilla-arco
- Infraestructura: Qdrant + Neo4j activos
- Transiciones: diseno → fichas → escritura → publicacion → publicado

### Novela multi-hilo

Añadir respecto a novela simple:
- `hilos/hilo-<kebab-case>/diseno-hilo.md` y `guion-hilo.md`
- `fichas/conexion_<slug>.md`
- `guion-novela.md` con tabla `## Trenzado`
- Skills extra: diseno-hilo, plantilla-hilo, trenzado-narrativo, validacion-cross-hilo
- Transiciones: diseno → diseno_hilos → trenzado → fichas → escritura → publicacion → publicado
```

## Instrucciones para el scaffolder

1. Carga este skill al inicio de Fase 7
2. Construye el MAPA.md en el campo `_mapa` del brief JSON según la escala confirmada
3. No incluyas secciones que no apliquen (ej. no pongas Qdrant en un relato)
4. Usa el slug y título reales del proyecto, no placeholders
5. El script escribe `_mapa` directamente en el workspace como `MAPA.md`
