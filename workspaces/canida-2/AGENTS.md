# Canida 2

**Workspace generado por Forja Hub.**
**Escala:** novela-multi-hilo | **PIPELINE.md** (fases) | **MAPA.md** (rutas de datos) | **ORQUESTACION.md** (spawn agentes)

## Reglas

- **Idioma:** espanol, contenido en espanol.
- **Estilo:** `estilo-contemporaneo`
- **Tono:** coherente con contemporaneo
- **Explicitud:** maximo (sin eufemismos, vocabulario directo).
- **POV:** segun BRIEF.md.

### Temas
- (ver BRIEF.md)

### Restricciones
- (ninguna)

### Skills activos
auditoria-neo4j, beats-estructura, consistencia-narrativa, contexto-subagente, cronista-ops, desarrollo-narrativa, diseno-hilo, estilo-contemporaneo, estilo-erotico, estilo-explicito, estilo-fantasia, estilo-noir, estilo-prosa, estilo-romantico, estilo-thriller, estructura-narrativa, fichas-personajes, hechos-distribuidos, hechos-estructura, mecanica-prosa, neo4j, plantilla-animal, plantilla-arco, plantilla-evento, plantilla-ficha, plantilla-grupo, plantilla-guion, plantilla-hilo, plantilla-lugar, plantilla-objeto, plantilla-organizacion, plantilla-personaje, plantilla-ser-sobrenatural, qdrant, scaffolding-acto, scaffolding-hecho, tonos-beat, trenzado-narrativo, validacion-coherencia, validacion-cross-hilo, validacion-crudeza, validacion-geometria, validacion-sensorial, validacion-tono

### Hilos
Hilos en `config.json.hilos` y `hilos/hilo-*/`.
`config.json.hilos[].estado` indica el progreso de cada hilo (pendiente | disenado | guion_listo).

## Infraestructura
Qdrant `:6333` y Neo4j `:7687` compartidos, aislados por el slug `canida-2` en los datos.

## Arranque
`/generar` (el director lee `config.json` y `PIPELINE.md` y orquesta segun `ORQUESTACION.md`).
