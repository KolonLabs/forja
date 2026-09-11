# Renacer para perder

**Workspace generado por Forja Hub.**
**Escala:** novela-simple | **PIPELINE.md** (fases) | **MAPA.md** (rutas de datos) | **ORQUESTACION.md** (spawn agentes)

## Reglas

- **Idioma:** espanol, contenido en espanol.
- **Estilo:** `estilo-explicito` + `estilo-thriller` (matiz) El estilo base prevalece; el secundario solo aporta matices compatibles y nunca altera restricciones, explicitud, hechos ni beats.
- **Tono:** Sombrío, opresivo, deniable
- **Explicitud:** maximo (sin eufemismos, vocabulario directo).
- **POV:** 3ª limitada.

### Temas
- El hambre como herida — no puedes llenar un agujero hecho por ser devorada, devorando el mundo
- El ciclo del abuso — se reproduce, nadie escapa, la familia reescena el matrimonio con roles invertidos
- Inversión — de objeto a sujeto, de devorada a devoradora, de víctima a depredadora
- Denegabilidad — todo es deniable, nunca nombrado, el lector decide qué creer
- Renacimiento forzado — el renacimiento no es por elección, es impuesto, y es camino a la pérdida
- Transmisión — la semilla se transmite, el ciclo continúa, la hija hereda

### Restricciones
- Menores: absoluto — no contenido sexual con menores bajo ninguna circunstancia
- Incesto: madre-hijos no físico durante la novela (influencia/mirada/reflejo, actos maternales de doble interpretación sensual/fraternal, sin acto sexual); contacto físico permitido más adelante como situación puntual justificada — poco antes de su muerte, cuando Elena pierde el control y usa a todos incluso a su familia (alcance: qué familiares, a decidir con el desarrollo); todos adultos, nunca menores. Sibling (Rodrigo-Pilar, epílogo): nunca físico — deniable, el lector puede imaginárselo por los precedentes con Elena pero queda en posibilidad que el lector decide. Fijación de Rodrigo: hacia su madre durante la novela (escarceos/provocaciones de tensión, sin contacto), hacia Pilar en el epílogo (sin relación sexual continua ni contacto)
- Profanación (cuerpo usado después de muerte): dentro como horror interior (su conciencia moribunda sintiéndolo, sin poder actuar), no espectáculo externo
- Entidad: nunca aparece, nunca nombrada, solo efectos (deniable)
- Red: sin sectas ni aspectos esotéricos, normalizada desde el punto de vista de los personajes, solo el lector se percata de que no es normal

### Skills activos
auditoria-neo4j, beats-estructura, consistencia-narrativa, contexto-subagente, cronista-ops, desarrollo-narrativa, estilo-contemporaneo, estilo-erotico, estilo-explicito, estilo-fantasia, estilo-noir, estilo-prosa, estilo-romantico, estilo-thriller, estructura-narrativa, fichas-personajes, hechos-distribuidos, hechos-estructura, mecanica-prosa, neo4j, plantilla-animal, plantilla-arco, plantilla-evento, plantilla-ficha, plantilla-grupo, plantilla-guion, plantilla-lugar, plantilla-objeto, plantilla-organizacion, plantilla-personaje, plantilla-ser-sobrenatural, qdrant, scaffolding-acto, scaffolding-hecho, tonos-beat, validacion-coherencia, validacion-crudeza, validacion-geometria, validacion-sensorial, validacion-tono


## Infraestructura
Qdrant `:6333` y Neo4j `:7687` compartidos, aislados por el slug `renacer-para-perder` en los datos.

## Arranque
`/generar` (el director lee `config.json` y `PIPELINE.md` y orquesta segun `ORQUESTACION.md`).
