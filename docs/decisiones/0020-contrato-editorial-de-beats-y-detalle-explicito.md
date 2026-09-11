# ADR 0020: Contrato editorial de beats y detalle explícito en novelas

- Estado: aceptada
- Fecha: 2026-09-11
- Ámbito: escalas `novela-simple` y `novela-multi-hilo`.
- Complementa: ADR 0019.
- Origen: contrato validado en `workspaces/renacer-para-perder/docs/decisiones/0002-contrato-editorial-beats.md` y sus refuerzos del 2026-09-10.

## Contexto

Las revisiones del capítulo 02 de renacer detectaron beats que fijaban pausas y gestos (microcoreografía), ejemplos elevados a frases obligatorias, inferencias convertidas en listas o preguntas y validaciones que comprobaban IDs sin leer la naturalidad del diálogo. Después, la validación con el usuario de una escena explícita detectó prosa sexual resumida con sentencias que contaban en lugar de mostrar («No era intimidad. Era descarga.»).

## Decisión

1. **El beat es una unidad dramática** con compromiso verificable: acontecimiento, decisión, descubrimiento o inferencia atribuida y su consecuencia. No se divide por puntuación, verbos, mezcla tonal ni cuotas de beats.
2. **Obligatorio / Libre / Ejemplos opcionales** se distinguen en objetivos y contexto existentes (sin campos nuevos del payload). Los ejemplos no son canon ni una lista a completar.
3. **Dicho / sabido / inferido / confirmado** se distinguen con sujeto y certeza. Conocer no obliga a preguntar; inferir no exige confesión ajena; una declaración no acredita su verdad.
4. **La interioridad conserva la voz del personaje**: pensamiento directo, indirecto libre o narración indirecta compatibles con el POV; no listas en cursiva ni resumen editorial disfrazado.
5. **El tono orienta expresión, no conducta ni conocimiento.** Una conversación normal puede resultar opresiva por lo que comprende el POV.
6. **Guionista y auditor**: la acción declara el acontecimiento y su consecuencia, sin gestos, miradas, posiciones, adverbios de modo, detalles de ambiente ni valoraciones. El espacio, la utilería y el cast viven en la cabecera de escena y en las fichas; **la ejecución es del escritor**. Prueba de libertad: dos ejecuciones distintas deben poder cumplir el mismo beat.
7. **Integrador**: repara el mecanismo del defecto en el intercambio mínimo autorizado, devuelve completas las secciones solicitadas y usa `BLOQUEO:` si falta contexto/alcance o el guion impide el arreglo.
8. **Validador**: comprueba naturalidad y cobertura semántica con evidencia; sin scores por defecto. La salida respeta al consumidor: candidato/hash para prosa, diagnóstico sin hash para auditoría de guion.
9. **Detalle explícito**: en escenas explícitas el acto se muestra con progresión (secuencia de actos, transiciones físicas, reacción del POV por fase, sensación concreta); los resúmenes que dejan el acto fuera de cámara son `corregir` y no se compensan con vocabulario crudo. Objetivo declarado: que el lector viva la escena intensamente.

## Consecuencias

- Las skills de ambos pipelines de novela y las compartidas (`estilo-explicito`, `validacion-crudeza`, `mecanica-prosa`, `tonos-beat`, validaciones, hechos, consistencia) quedan alineadas con el contrato.
- `validacion-cross-hilo` emite incidencias con gravedad, sin scores.
- Las comprobaciones automáticas son salvaguardas textuales: no demuestran comprensión de los agentes ni calidad literaria (deuda DT-010).

## Referencias

- `workspaces/renacer-para-perder/docs/decisiones/0002-contrato-editorial-beats.md`.
- `workspaces/renacer-para-perder/docs/replicacion-flujo-narrativa.md`, secciones 3.6 y 3.7.
