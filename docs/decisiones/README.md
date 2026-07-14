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
| [0007](0007-escritura-por-escenas-operativas-en-relato.md) | Relato escribe y valida por escenas operativas; su contrato de recurrencias fue sustituido por ADR 0013. | Sustituida parcialmente por ADR 0013 |
| [0008](0008-contratos-ejecutables-de-relato.md) | Relato materializa IDs, aísla sus skills y usa anclas invisibles de beat dentro de prosa por escena. | Aceptada |
| [0009](0009-integridad-transaccional-de-relato.md) | Relato persiste estructura de forma transaccional; la cola de recurrencias fue sustituida por ADR 0013. | Sustituida parcialmente por ADR 0013 |
| [0010](0010-rehidratacion-de-relatos-legados.md) | Un relato legado se reinicia desde su semilla editorial en un destino nuevo; no migra prosa ni guion. | Aceptada |
| [0011](0011-importacion-de-fuentes-narrativas-libres.md) | Fuentes libres se analizan como evidencia trazable antes de construir un brief confirmado. | Sustituida por ADR 0012 |
| [0012](0012-importacion-general-y-extraccion-editorial.md) | La importación es transversal a escalas y usa una skill para extraer evidencia antes de proponer la escala. | Aceptada |
| [0013](0013-beats-globales-con-patrones-inferidos-en-relato.md) | Relato integra patrones y contraste en el mapa global de beats, sin `[D]` ni `cola_d.md`. | Aceptada |
