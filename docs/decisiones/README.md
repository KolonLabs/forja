# Registro de decisiones

Este directorio conserva decisiones arquitectonicas y operativas que deben sobrevivir a una sesion concreta. Cada ADR explica el contexto, la decision vigente y sus consecuencias.

## Uso

- Crea un ADR cuando una decision afecte contratos, aislamiento, infraestructura, formatos de salida o el comportamiento de varios scripts.
- No registres correcciones locales ni hallazgos ya resueltos que no cambien una regla durable.
- No reescribas un ADR aceptado. Si la decision cambia, crea otro ADR que lo sustituya y enlazalo.
- Actualiza [deuda-tecnica.md](../deuda-tecnica.md) cuando exista un riesgo pendiente de resolver, no cuando haya una decision ya cerrada.

## Decisiones vigentes

| ADR | Decision | Estado |
|---|---|---|
| [0001](0001-hub-y-workspaces-aislados.md) | El hub orquesta; los workspaces son autonomos. | Aceptada |
| [0002](0002-contrato-de-creacion-e-infraestructura.md) | La escala determina infraestructura y el brief es un contrato validado. | Aceptada |
| [0003](0003-publicacion-y-compilacion.md) | Publicación y compilación inicial de libros. | Sustituida parcialmente por ADR 0004 |
| [0004](0004-finalizado-y-recompilacion-de-formatos.md) | `finalizado` es la única entrada de compilación; `publicado` es terminal y los formatos se recompilan desde un manifiesto. | Aceptada |
| [0005](0005-ediciones-derivadas-de-relato.md) | Los cambios de contenido de un relato publicado se hacen en una edición derivada. | Aceptada |
| [0006](0006-beats-globales-y-escenas-derivadas-en-relato.md) | Relato diseña beats globales antes de derivar escenas; usa IDs H/B/E visibles sin infraestructura. | Aceptada |
| [0007](0007-escritura-por-escenas-operativas-en-relato.md) | Relato escribe y valida por escenas operativas; regula recurrencias y separadores sin cuotas de prosa. | Aceptada |
| [0008](0008-contratos-ejecutables-de-relato.md) | Relato materializa IDs, aísla sus skills y usa anclas invisibles de beat dentro de prosa por escena. | Aceptada |
| [0009](0009-integridad-transaccional-de-relato.md) | Relato persiste recurrencias y estructura de forma transaccional; las ediciones derivadas validan y regeneran su contrato. | Aceptada |
| [0010](0010-rehidratacion-de-relatos-legados.md) | Un relato legado se reinicia desde su semilla editorial en un destino nuevo; no migra prosa ni guion. | Aceptada |
| [0011](0011-importacion-de-fuentes-narrativas-libres.md) | Fuentes libres se analizan como evidencia trazable antes de construir un brief confirmado. | Aceptada |
