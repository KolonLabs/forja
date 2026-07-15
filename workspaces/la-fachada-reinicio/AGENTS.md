# La Fachada

**Workspace generado por Forja Hub.**
**Escala:** relato | **PIPELINE.md** (fases) | **MAPA.md** (rutas de datos) | **ORQUESTACION.md** (spawn agentes)

## Reglas

- **Idioma:** espanol, contenido en espanol.
- **Estilo:** `estilo-erotico` + `estilo-explicito` (matiz) El estilo base prevalece; el secundario solo aporta matices compatibles y nunca altera restricciones, explicitud, hechos ni beats.
- **Tono:** perturbador, tenso, con ironía oscura. Contraste entre rutina doméstica impoluta y degradación voluntaria.
- **Explicitud:** maximo (sin eufemismos, vocabulario directo).
- **POV:** 3ª limitada, foco variable entre Laura y Miguel según el hecho.

### Temas
- Pérdida de agencia y sumisión progresiva
- Fachada social vs deseo oculto
- Culpa como combustible de la excitación
- Matrimonio como complicidad perversa
- Poder como algo accidental, precario y reversible

### Restricciones
- Sin menores en contenido sexual
- Explicitud al servicio del conflicto interno, nunca gratuita
- Degradación con matiz psicológico, no solo físico
- Arco de Miguel matizado: no es un villano ni un cornudo patético

### Skills activos
mecanica-prosa, beats-estructura, contexto-narrativo, contexto-subagente, estructura-narrativa, plantilla-guion, plantilla-draft, plantilla-ficha, tonos-beat, validacion-coherencia, validacion-crudeza, validacion-geometria, validacion-sensorial, validacion-tono, estilo-erotico, estilo-explicito


## Integridad de relato

El director usa `scripts/relato-transaccion.ps1` para hechos, diseño, ajustes de guion, componentes, escritura, correcciones y publicación. No edites `.forja-transaccion/` ni escribas directamente artefactos canónicos; el staging se retoma si sigue siendo válido o se descarta explícitamente.
## Infraestructura
Modo ligero: sin Qdrant ni Neo4j. Memoria en contexto_narrativo.md.

## Arranque
`/generar` (el director lee `config.json` y `PIPELINE.md` y orquesta segun `ORQUESTACION.md`).
