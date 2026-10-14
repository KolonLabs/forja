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
| publicacion/ | /compilar (`scripts/compilar.ps1`) | /compilar | Libro compilado (Markdown, EPUB/PDF, manifest.json); no se versiona |
| publicacion/borrador/ | /borrador (`scripts/borrador.ps1`) | /borrador | Versiones limpias de revisión del trabajo en curso; no cambian el estado ni se versionan |
| EDICION.md | /nueva-edicion (solo edición) | — | Linaje y motivo de la edición derivada |
| relato-edicion-anterior.md | /nueva-edicion (solo edición) | — | Manuscrito publicado de referencia, solo lectura |
| correcciones.md | /nueva-edicion, director | director | Última corrección y decisiones pendientes; cada corrección lo sobrescribe (historial en git) |
| contexto_narrativo.md | director | director | Memoria del relato y notas para escenas pendientes |
| fichas/ | entidades | entidades | Fichas de entidades |
| scripts/ | Script | — | Helpers de la escala, `renumerar.ps1` y compilación (`compilar.ps1`, `borrador.ps1`, `build-epub.ps1`, `build-pdf.ps1`) |
| .gitignore | Script | — | Repositorio git propio de la obra; los commits los decide la persona usuaria |

## Historial
La obra es su propio repositorio git. Nadie crea copias de seguridad ni hace commits automáticos: el historial son los commits que decide la persona usuaria.

## Convención de nombres
Fichas: <tipo>_<slug>.md (personaje_miguel.md, lugar_parking.md)

## Fases
| Fase | Estado | Acción |
|---|---|---|
| FASE 1: Diseño | diseno | guionista → guion.md |
| FASE 2: Componentes | fichas | entidades → fichas/ + reconciliación |
| FASE 3: Por escena | escritura | escritor → validador → ±integrador por cada `E_XXXX` |
| FASE 4: Finalizar | escritura | /publicar → relato.md y estado `finalizado` |
| Compilar | finalizado / publicado | /compilar → publicacion/ y estado `publicado` |

## Transiciones
diseno → fichas → escritura → finalizado → publicado (/compilar)

## Agentes
director, guionista, auditor-beats, escritor, validador, integrador, entidades
No aplican: memoria, cronista

## Infraestructura
Sin Qdrant. Sin Neo4j. Memoria en contexto_narrativo.md.
```

### Novela simple

Añadir respecto al relato:
- `guion-novela.md` en jerarquía y archivos
- `capitulos/cap-NN-slug/` (guion.md, draft.md, capitulo.md, `escena-<SID>.pendiente.md`)
- `scripts/persistir-escena.py` (preparar / aceptar / sincronizar; lo opera el director)
- `novela.md` como salida publicable; `/compilar` genera el libro en `publicacion/`
- `contexto.md` en vez de `contexto_narrativo.md` (incluye el registro de checkpoint de narrativa)
- Checkpoint humano de narrativa por escena: el director presenta la candidata con hash y se detiene; escritor e integrador no escriben archivos
- `referencias/` (material de referencia no-narrativo si el proyecto fue importado; vacío si no hay)
- Agentes: añadir memoria, cronista
- Skills extra: qdrant, neo4j, auditoria-neo4j, hechos-estructura, plantilla-arco
- Sin `contexto-narrativo`: esa skill es la memoria Markdown de relato
- Infraestructura: Qdrant + Neo4j activos
- Transiciones: diseno → fichas → escritura → publicacion → finalizado
  (`publicado` lo asigna `/compilar`, nunca el director)

### Novela multi-hilo

Añadir respecto a novela simple:
- `hilos/hilo-<kebab-case>/diseno-hilo.md` y `guion-hilo.md`
- `fichas/conexion_<slug>.md`
- `guion-novela.md` con tabla `## Trenzado`
- `capitulos/cap-NN-slug/cola_d.md` (hechos `[D]` pendientes de posicionar; efímero por capítulo)
- `scripts/persistir-escena.py` con soporte de `| hilo:` en el marcador de escena
- Checkpoint de narrativa por escena **después del trenzado**, además de los checkpoints de estructura de FASE 0.3; cada escena pertenece a un solo hilo
- `referencias/` (material de referencia no-narrativo si el proyecto fue importado; vacío si no hay)
- Skills extra: diseno-hilo, plantilla-hilo, trenzado-narrativo, validacion-cross-hilo
- Transiciones: diseno → diseno_hilos → trenzado → fichas → escritura → publicacion → finalizado
  (`publicado` lo asigna `/compilar`, nunca el director)
```

## Instrucciones para el scaffolder

1. Carga este skill al inicio de Fase 7
2. Construye el MAPA.md en el campo `_mapa` del brief JSON según la escala confirmada
3. No incluyas secciones que no apliquen (ej. no pongas Qdrant en un relato)
4. Usa el slug y título reales del proyecto, no placeholders
5. El script escribe `_mapa` directamente en el workspace como `MAPA.md`
