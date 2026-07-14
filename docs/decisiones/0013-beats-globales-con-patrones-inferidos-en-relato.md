# ADR 0013: Beats globales con patrones inferidos en relato

- Estado: aceptada
- Fecha: 2026-07-14
- Sustituye parcialmente: ADR 0007 y ADR 0009
- Ámbito: diseño, transacciones y scaffolding de `shared/pipelines/relato/`.

## Contexto

El contrato anterior representaba una pauta recurrente como un hecho especial `[D]` y la persistía después en `cola_d.md`. Esto mezclaba el nivel editorial de los hechos con una decisión de implementación de beats, obligaba al guionista a ejecutar únicamente marcas ya creadas por el scaffolder y añadía validaciones transaccionales sin mejorar la cadencia por sí mismas.

## Decisión

Relato usa exclusivamente hechos `H_XXXX`, beats `B_XXXX` y escenas `E_XXXX`.

- Un hecho es un contrato causal: puede contener una secuencia, una pauta, una evolución o ejemplos de contexto, siempre que fije lo irrenunciable y la consecuencia sin dictar prosa, escenas ni la colocación de beats.
- El guionista diseña un único mapa global de beats. Lee el arco completo, infiere las pautas explícitas en hechos y brief, elige sus instancias representativas e intercala beats de rutina, relación, ocultación o consecuencia ya respaldados.
- Todos los beats son ordinarios. No existen `[D]`, rangos de distribución, identificadores de recurrencia ni `cola_d.md` en relato.
- El guionista no inventa giros irreversibles, relaciones, revelaciones, restricciones ni desenlaces. Si fueran necesarios para materializar una pauta, informa al director para que solicite un cambio autorizado de hechos.
- El auditor comprueba la cobertura de hechos, causalidad y que una pauta explícita no quede invisible o repetida sin una función distinta. Solo bloquea contradicciones, omisiones obligatorias o invenciones estructurales.
- Las transacciones de diseño y ajuste de guion dejan de persistir y validar `cola_d.md`.

## Consecuencias

- El mapa de beats conserva la función de intercalado que motivó las recurrencias, pero queda en manos del guionista que conoce el arco completo.
- Se eliminan una llamada de subagente, un artefacto canónico y gates asociados, reduciendo sobreingeniería y riesgo de cadenas planas de encuentros o acciones similares.
- El cambio se limita a relatos nuevos. Los workspaces ya creados conservan su contrato aislado y no se migran automáticamente.

## Referencias

- [ADR 0006](0006-beats-globales-y-escenas-derivadas-en-relato.md)
- [ADR 0007](0007-escritura-por-escenas-operativas-en-relato.md)
- [ADR 0009](0009-integridad-transaccional-de-relato.md)
- [Pipeline de relato](../../shared/pipelines/relato/PIPELINE.md)
