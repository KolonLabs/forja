# Eros-9

**Workspace generado por Forja Hub.**
**Escala:** novela-simple | **PIPELINE.md** (fases) | **MAPA.md** (rutas de datos) | **ORQUESTACION.md** (spawn agentes)

## Reglas

- **Idioma:** espanol, contenido en espanol.
- **Estilo:** `estilo-explicito` + `estilo-thriller` (fusion)
- **Tono:** urgente, paranoico, sórdido
- **Explicitud:** maximo (sin eufemismos, vocabulario directo).
- **POV:** múltiple.

### Temas
- adicción
- autodestrucción
- ambición científica sin ética
- deseo y control
- identidad y disolución

### Restricciones
- (ninguna)

### Skills activos
mecanica-prosa, beats-estructura, estructura-narrativa, tonos-beat, hechos-distribuidos, estilo-explicito, estilo-thriller, plantilla-guion, plantilla-ficha, plantilla-personaje, plantilla-lugar, plantilla-objeto, plantilla-animal, plantilla-evento, plantilla-organizacion, validacion-crudeza, validacion-coherencia, validacion-geometria, validacion-sensorial, validacion-tono, consistencia-narrativa, contexto-subagente, desarrollo-narrativa, fichas-personajes, estilo-prosa, plantilla-arco, qdrant, neo4j, auditoria-neo4j, generar, revisar, expandir, publicar

## Infraestructura
Qdrant `:6333` + Neo4j `:7687` (colecciones/grafos `eros-9_*`)

## Arranque
`/generar` (el director lee `config.json` y `PIPELINE.md` y orquesta segun `ORQUESTACION.md`).
