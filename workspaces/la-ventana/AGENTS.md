# La ventana

**Workspace generado por Forja Hub.**
**Escala:** relato | **PIPELINE.md** (fases) | **MAPA.md** (rutas de datos) | **ORQUESTACION.md** (spawn agentes)

## Reglas

- **Idioma:** espanol, contenido en espanol.
- **Estilo:** `estilo-explicito` + `estilo-contemporaneo` (matiz) El estilo base prevalece; el secundario solo aporta matices compatibles y nunca altera restricciones, explicitud, hechos ni beats.
- **Tono:** Cálido, perverso e irónico; doméstico con corriente eléctrica
- **Explicitud:** maximo (sin eufemismos, vocabulario directo).
- **POV:** 3ª limitada (foco en Andrés).

### Temas
- El deseo a los cincuenta: el cuerpo que falla y el deseo que no baja
- El control y la autoría: de titiritero a parte de la obra
- La vergüenza disuelta: ser deseado, ser tomado, ser marcado
- La normalización: lo que era secreto vuelve a casa
- El secreto como última intimidad
- La doble vara de la edad sobre el cuerpo

### Restricciones
- Menores: absoluto — sin contenido sexual con menores bajo ninguna circunstancia
- Marco fantástico acordado: Teresa nunca sabe y no sufre; su despertar se narra como florecimiento con agencia propia
- Sin castigo moral ni final triste: el cierre es felicidad perversa y serena
- Javi, el hijo, queda fuera del marco: no presencia nada ni se entera
- Lluvia dorada permitida; coprofilia fuera

### Skills activos
beats-estructura, contexto-narrativo, contexto-subagente, estilo-contemporaneo, estilo-explicito, estructura-narrativa, mecanica-prosa, plantilla-draft, plantilla-ficha, plantilla-guion, tonos-beat, validacion-coherencia, validacion-crudeza, validacion-geometria, validacion-sensorial, validacion-tono


## Integridad de relato

El director usa `scripts/relato-transaccion.ps1` para hechos, diseño, ajustes de guion, componentes, escritura, correcciones y publicación. No edites `.forja-transaccion/` ni escribas directamente artefactos canónicos; el staging se retoma si sigue siendo válido o se descarta explícitamente.
## Infraestructura
Modo ligero: sin Qdrant ni Neo4j. Memoria en contexto_narrativo.md.

## Arranque
`/generar` (el director lee `config.json` y `PIPELINE.md` y orquesta segun `ORQUESTACION.md`).
