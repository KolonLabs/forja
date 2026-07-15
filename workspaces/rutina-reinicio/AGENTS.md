# ¿Rutina?

**Workspace generado por Forja Hub.**
**Escala:** relato | **PIPELINE.md** (fases) | **MAPA.md** (rutas de datos) | **ORQUESTACION.md** (spawn agentes)

## Reglas

- **Idioma:** espanol, contenido en espanol.
- **Estilo:** `estilo-explicito`
- **Tono:** clínico y visceral, sin juicio. Descripciones anatómicas, precisas, sin carga moral. La ironía emerge de la estructura, no del narrador.
- **Explicitud:** maximo (sin eufemismos, vocabulario directo).
- **POV:** 3ª limitada.

### Temas
- Descubrimiento sexual tardío
- Doble vida y secreto conyugal
- Cruising como ritual y pertenencia
- Poder, sumisión y dominación en el matrimonio
- Inversión de roles de género

### Restricciones
- Sin violencia sexual
- Los encuentros de cruising de Miguel son exclusivamente entre hombres
- Tono clínico mantenido hasta el final: sin celebración ni condena

### Skills activos
mecanica-prosa, beats-estructura, contexto-narrativo, contexto-subagente, estructura-narrativa, plantilla-guion, plantilla-draft, plantilla-ficha, tonos-beat, validacion-coherencia, validacion-crudeza, validacion-geometria, validacion-sensorial, validacion-tono, estilo-explicito


## Integridad de relato

El director usa `scripts/relato-transaccion.ps1` para hechos, diseño, ajustes de guion, componentes, escritura, correcciones y publicación. No edites `.forja-transaccion/` ni escribas directamente artefactos canónicos; el staging se retoma si sigue siendo válido o se descarta explícitamente.
## Infraestructura
Modo ligero: sin Qdrant ni Neo4j. Memoria en contexto_narrativo.md.

## Arranque
`/generar` (el director lee `config.json` y `PIPELINE.md` y orquesta segun `ORQUESTACION.md`).
