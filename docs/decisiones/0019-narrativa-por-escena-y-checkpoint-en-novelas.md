# ADR 0019: Narrativa por escena y checkpoint humano en novelas

- Estado: aceptada
- Fecha: 2026-09-11
- Ámbito: escalas `novela-simple` y `novela-multi-hilo`.
- Complementa: ADR 0017 (contrato de draft en novelas) y ADR 0018 (multi-tenant).
- Origen: flujo medido y validado localmente en `workspaces/renacer-para-perder` y su guía `docs/replicacion-flujo-narrativa.md`.

## Contexto

La escritura de novela gastaba pasos LLM leyendo archivos y cargando skills por beat: la telemetría de renacer registró 28 tareas del escritor con 231 pasos y 399 operaciones de herramientas solo hasta cerrar el capítulo 1. Ocho llamadas terminaron en `finish: length` con 32.000 tokens de razonamiento y salida visible nula (el límite por defecto de OpenCode recorta `completion`, que en Venice incluye razonamiento). El validador producía cinco puntuaciones por beat que ocultaban errores factuales reales, y el pipeline avanzaba al capítulo siguiente sin parada humana. Renacer rediseñó el flujo por escena con persistencia mecánica, lo probó offline (54 de persistencia + 22 de identidad + 14/16 de contratos) y lo documentó para replicación.

## Decisión

1. **Escritor e integrador sin herramientas.** `permission: "*": deny`, incluida la carga de skills. Reciben contexto preparado inline (canon, memoria de hechos ocurridos, voz/POV, restricciones) y devuelven solo prosa (escritor) o solo las secciones corregidas (integrador). Ante canon contradictorio o datos imprescindibles ausentes devuelven `BLOQUEO:` al director.
2. **Una escena por llamada.** El director prepara el paquete de canon una vez; por escena añade guion, fichas y antecedentes. El escritor entrega la escena completa con el marcador `<!-- ESCENA ... -->` y encabezados `## <stable_id> [<seq>] — acción breve` (ADR 0017).
3. **Presupuesto de completion.** Escritor e integrador usan `options.maxCompletionTokens: 64000` sobre `venice/qwen-3-8-max` (131072 publicados, thinking-only, sin `reasoningEffort`). Es presupuesto técnico compartido entre razonamiento y salida, no meta de longitud; es una decisión por agente y proveedor, y no se copia a modelos sin verificar su serialización.
4. **Persistencia mecánica.** `scripts/persistir-escena.py` con `preparar` (valida IDs/orden/cuerpos/metatexto estructural, guarda `escena-<SID>.pendiente.md` y devuelve SHA256; solo acepta `--finish stop`), `aceptar` (review aprobado para ese hash, inserción/reemplazo con backup atómico, no-op en reintentos) y `sincronizar` (preflight de proyecto/identidad/padre/seq, lote de embeddings solo para texto cambiado, readback). El director es el único que persiste; un fallo de red se repara con `sincronizar`, nunca regenerando prosa.
5. **Revisión editorial por escena.** Incidencias con gravedad `bloqueante/corregir/opcional`, sin scores por beat ni cuotas sensoriales; el SHA256 liga texto y decisión. Corrección selectiva con revisión focalizada de cambios y transiciones. Un error factual no se aprueba por promedio.
6. **Checkpoint humano obligatorio.** Tras `preparar`, el director presenta la escena completa y se detiene. Conformidad humana y revisión editorial del mismo hash preceden a `aceptar/sincronizar`. Iniciar otra escena o capítulo exige autorización expresa; cualquier cambio textual invalida la conformidad anterior. El registro vive en `contexto.md`.
7. **Multi-hilo.** La narrativa se valida escena a escena **después del trenzado** (FASE 3), con marcador `| hilo:` y costura contra la escena vecina real. Los checkpoints de estructura de FASE 0.3 y de costuras de guion (3.2.2) siguen siendo la capa de guion y no se sustituyen.
8. **Modelos.** Director, guionista, auditor-beats, entidades y validador usan `deepseek/deepseek-v4-pro`; memoria y cronista, `deepseek/deepseek-v4-flash`. El validador conserva `temperature: 0.2` y `top_p: 0.9`, coherente con su función de revisión.

## Consecuencias

- Los workspaces nuevos de novela nacen con el flujo por escena; los existentes conservan su copia del pipeline y se reinyectan solo si se decide, caso por caso.
- El helper no verifica por código la conformidad humana ni el permiso de avance: la parada efectiva depende del director (deuda DT-008).
- No hay transacción conjunta disco+Qdrant: las operaciones se serializan por capítulo/escena (deuda DT-009).
- Las pruebas son estáticas/offline; el primer uso real tras reiniciar el backend queda pendiente de validación (deuda DT-010).

## Referencias

- `workspaces/renacer-para-perder/docs/decisiones/0001-narrativa-por-escena.md` y `0003-checkpoint-narrativa-usuario.md`.
- [ADR 0017](0017-contrato-de-draft-y-estado-terminal-en-novelas.md)
- [ADR 0018](0018-aislamiento-multi-tenant-qdrant-neo4j-y-contrato-l4.md)
