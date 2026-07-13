# Dinastías del Poder

**Workspace generado por Forja Hub.**
**Escala:** novela-multi-hilo | **PIPELINE.md** (fases) | **MAPA.md** (rutas de datos) | **ORQUESTACION.md** (spawn agentes)

## Reglas

- **Idioma:** espanol, contenido en espanol.
- **Estilo:** `estilo-explicito` + `estilo-fantasia` (fusion)
- **Tono:** asfixiante, opresivo, sensual
- **Explicitud:** maximo (sin eufemismos, vocabulario directo).
- **POV:** 3ª limitada múltiple.

### Temas
- poder y corrupción
- sexo como arma de control
- ciclo de ascenso y caída
- linaje y legado
- anonimato vs visibilidad

### Restricciones
- (ninguna)

### Skills activos
mecanica-prosa, beats-estructura, estructura-narrativa, tonos-beat, hechos-distribuidos, estilo-explicito, estilo-fantasia, plantilla-guion, plantilla-ficha, plantilla-personaje, plantilla-lugar, plantilla-objeto, plantilla-animal, plantilla-evento, plantilla-organizacion, validacion-crudeza, validacion-coherencia, validacion-geometria, validacion-sensorial, validacion-tono, consistencia-narrativa, contexto-subagente, desarrollo-narrativa, fichas-personajes, estilo-prosa, plantilla-arco, qdrant, neo4j, auditoria-neo4j, plantilla-hilo, diseno-hilo, trenzado-narrativo, validacion-cross-hilo, generar, revisar, expandir, publicar

### Hilos
Hilos en `config.json.hilos` y `hilos/hilo-*/`.
`config.json.hilos[].estado` indica el progreso de cada hilo (pendiente | disenado | guion_listo).
## Infraestructura
Qdrant `:6333` + Neo4j `:7687` (colecciones/grafos `dinastias-del-poder_*`)

## Arranque
`/generar` (el director lee `config.json` y `PIPELINE.md` y orquesta segun `ORQUESTACION.md`).
