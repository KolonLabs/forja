# ADR 0021: Alcance de relato en la adopción del flujo de escena

- Estado: aceptada
- Fecha: 2026-09-11
- Ámbito: escala `relato`.
- Relaciona: ADR 0007, ADR 0013, ADR 0019

## Contexto

Relato ya escribe y valida por escena operativa (`E_XXXX`), persiste de forma transaccional con `relato-transaccion.ps1` y valida por incidencias concretas sin puntuaciones. La propuesta de adoptar el flujo de renacer incluía un checkpoint humano obligatorio que contradice su autonomía declarada: en relato el director solo consulta al usuario si una decisión cambia un hecho, el desenlace, una restricción o una relación ya fijada.

## Decisión

1. Relato **mantiene su autonomía**: sin checkpoint humano de narrativa, sin candidata/hash obligatoria y sin cambios en su flujo transaccional.
2. Relato **no adopta** nada relacionado con Qdrant/Neo4j (no los usa) ni el endurecimiento de identidades de summaries.
3. Relato **sí adopta** el paquete de escena explícita: la sección «Nivel de detalle en escenas explícitas» de `estilo-explicito`, el criterio «mostrar, no contar» en su override de `validacion-crudeza` y el matiz de `estructura-narrativa` para que el registro no contradiga el detalle explícito.
4. El desarrollo sigue siendo por escena, no por beat.

## Consecuencias

- Los relatos nuevos reciben el estilo actualizado; los existentes conservan su copia.
- La autonomía y los contratos de relato (ADR 0007, 0008, 0009, 0013) no cambian.

## Referencias

- `workspaces/renacer-para-perder/docs/replicacion-flujo-narrativa.md`, sección 3.7.
- `shared/pipelines/relato/ORQUESTACION.md`.
