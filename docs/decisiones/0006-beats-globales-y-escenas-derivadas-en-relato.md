# ADR 0006: Beats globales y escenas derivadas en relato

- Estado: aceptada
- Fecha: 2026-07-14
- Ámbito: `shared/pipelines/relato/` y los workspaces de relato creados a partir de esta versión.

## Contexto

El pipeline de relato mezclaba una fase que pretendía crear escenas antes de los beats con contratos importados de novela basados en `stable_id`, `parent_id` y secuencias locales. Los relatos no usan Qdrant ni Neo4j, por lo que esa identidad opaca añadía complejidad e incoherencia entre guion, draft, validadores y correcciones.

## Decisión

```text
H_XXXX (hechos de briefing) → B_XXXX (beats globales) → E_XXXX (escenas derivadas) → prosa
```

- `H_XXXX`, `B_XXXX` y `E_XXXX` son visibles, globales y suficientes dentro de un workspace de relato.
- No se usan `stable_id`, UUID, `parent_id` ni `seq` local.
- Los beats se diseñan y auditan para el arco completo antes de agruparse en escenas. Las escenas agrupan beats contiguos por continuidad dramática.
- Los IDs no se renumeran ni se reutilizan. Una inserción recibe el siguiente número disponible y el orden se expresa por la posición en `guion.md`.
- El director es el único persistente de artefactos; los subagentes devuelven texto o diagnósticos. Cada gate y reparación queda en `registro-pipeline.md`.
- Tras tres fallos de validación, un beat queda bloqueado y el pipeline no publica ni avanza de fase.

## Consecuencias

- El flujo puede ejecutarse de forma casi autónoma una vez fijado el arco, con detención solo ante contradicción explícita, ambigüedad editorial material o bloqueo.
- Las correcciones estructurales de una edición derivada actualizan transaccionalmente guion, draft y contexto desde la primera escena afectada.
- La decisión se limita a relato. Novela simple y multi-hilo conservan su modelo de infraestructura hasta sus migraciones específicas.

## Referencias

- [Pipeline de relato](../../shared/pipelines/relato/PIPELINE.md)
- [Orquestación de relato](../../shared/pipelines/relato/ORQUESTACION.md)
- [ADR 0005](0005-ediciones-derivadas-de-relato.md)
