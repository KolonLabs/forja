# ¿Rutina?

**Workspace generado por Forja Hub.**
**Escala:** relato | **PIPELINE.md** (fases) | **MAPA.md** (rutas de datos) | **ORQUESTACION.md** (spawn agentes)

## Reglas

- **Idioma:** espanol, contenido en espanol.
- **Estilo:** `estilo-explicito`
- **Tono:** clinico y visceral, sin juicio
- **Explicitud:** maximo (sin eufemismos, vocabulario directo).
- **POV:** 3ª limitada.

### Temas
- Descubrimiento sexual tardio
- Doble vida
- Cruising como ritual

### Restricciones
- Sin violencia sexual
- Sin mujeres en encuentros

### Skills activos
mecanica-prosa, beats-estructura, estructura-narrativa, tonos-beat, estilo-explicito, plantilla-guion, plantilla-ficha, plantilla-personaje, plantilla-lugar, plantilla-objeto, plantilla-animal, plantilla-arco, plantilla-evento, plantilla-organizacion, validacion-crudeza, validacion-coherencia, validacion-geometria, validacion-sensorial, validacion-tono, consistencia-narrativa, contexto-subagente, desarrollo-narrativa, fichas-personajes, estilo-prosa, generar, revisar, expandir, publicar

## Infraestructura
Modo ligero: sin Qdrant ni Neo4j. Memoria en contexto_narrativo.md.

## Arranque
`/generar` (el director lee `config.json` y `PIPELINE.md` y orquesta segun `ORQUESTACION.md`).
