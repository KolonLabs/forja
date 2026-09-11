# Narrativa por escena y presupuesto de completion

- Estado: aceptada por el usuario, implementacion local.
- Fecha: 2026-09-09.
- Alcance: solo `renacer-para-perder`; no modifica el hub, shared/ ni otros workspaces.
- Conserva modelos, generacion de beats, identidades y manuscrito existente.

## Motivo

La telemetria mostro 28 tareas del escritor con 231 pasos LLM y 399 operaciones de herramientas. Ocho llamadas finales terminaron en `length` con 32000 tokens de razonamiento y cero texto visible: el corte no prueba un fallo de lectura/persistencia ni que una escena completa se perdiera. Los totales de entrada de una sesion son acumulados, no el tamano de una sola peticion.

OpenCode v1.18.29 calcula por defecto `min(model.limit.output, 32000)`. El adaptador Venice 2.1.1 usa `maxCompletionTokens ?? maxTokens ?? maxOutputTokens` para `max_completion_tokens`. Venice anuncia 131072 para Qwen 3.8 Max, thinking-only y sin reasoningEffort configurable. No se configura un esfuerzo no soportado ni se confunde ocultar thinking con ahorrar su computo.

## Decision

1. Escritor e integrador: `options.maxCompletionTokens: 64000`, permisos `"*": deny`. Se mantienen modelo, temperatura y top_p. No cargan skills, consultan archivos ni persisten: contexto completo pertinente en el mensaje.
2. El director prepara una vez el canon, memoria de hechos ocurridos (separada del diseno), voz/POV y restricciones. Por escena anade solo guion, fichas y antecedentes necesarios. No duplica el paquete en rutas e inline ni suprime antecedentes necesarios por una cuota arbitraria.
3. Escritor devuelve una escena como prosa con marcador e identidades. Sin justificaciones ni notas de rutina. Ante canon contradictorio o datos imprescindibles ausentes devuelve BLOQUEO, no inventa.
4. Revision editorial independiente por escena: cobertura, continuidad, personajes/POV, prosa y restricciones. Briefing neutral. Sin scores exhaustivos por beat ni cuotas de sentidos/parrafos/frases. Solo incidencias bloqueante/corregir/opcional. Un error factual no se salva con una buena media.
5. Correccion selectiva: cambios mecanicos exactos sin llamada creativa; integrador solo para prosa afectada y sus transiciones. Una revision focalizada comprueba el resultado, no vuelve a evaluar todo por rutina.
6. Al cierre del capitulo se revisan exclusivamente los cruces entre escenas (tiempo, objetos, conocimientos, arco) antes del cronista. No se repite toda la validacion estilistica.

64000 son tokens tecnicos de completion por peticion, compartidos entre razonamiento y respuesta. No es meta de longitud, reserva exclusiva para prosa ni garantia de menor latencia. El limite no se aumenta globalmente para otros agentes/proyectos. Cambios de configuracion requieren reiniciar el backend de OpenCode.

## Persistencia mecanica

**Ampliacion vigente:** la [decision 0003](0003-checkpoint-narrativa-usuario.md) incorpora un checkpoint humano obligatorio tras `preparar`: presentar la narrativa completa y detenerse antes de revision editorial, aceptacion y avance. Solo con conformidad del usuario y revision editorial del mismo hash se permite aceptar/sincronizar. Todo cambio textual vuelve al checkpoint; el helper comprueba el review, no la aprobacion conversacional ni el permiso para otra escena/capitulo.

El guionista y la persistencia de sus beats no cambian. El helper nuevo trabaja sobre escenas completas con IDs ya existentes; no crea beats ni modifica su identidad.

```text
python scripts/persistir-escena.py preparar --capitulo capitulos/cap-NN-slug --escena SID --entrada <archivo-UTF-8> --finish stop
python scripts/persistir-escena.py aceptar --capitulo capitulos/cap-NN-slug --escena SID --revision '<JSON>'
python scripts/persistir-escena.py sincronizar --capitulo capitulos/cap-NN-slug --escena SID --revision '<JSON>'
```

- `preparar` valida marcador, IDs, orden/seq, cuerpos no vacios y ausencia de notas/metatexto estructural. Entrada completa con `finish=stop`; el director obtiene finish de la ejecucion real, no de la declaracion del escritor. Normaliza solo finales de linea a LF y LF final. Guarda `escena-SID.pendiente.md` y devuelve SHA256; no toca el draft ni Qdrant.
- El validador recibe ese archivo/hash exacto. Una decision de canon pendiente bloquea. Las incidencias opcionales no obligan a reescribir.
- `aceptar` exige review aprobado para el hash vigente e IDs iguales al guion. Inserta o reemplaza la escena en orden conservando las otras escenas, con escritura atomica y backup si cambia un draft existente. Reintento identico es no-op.
- `sincronizar` exige que el draft coincida con el candidato revisado. Recupera todos los puntos y verifica proyecto, identidad, padre y seq antes de escribir. Conserva metadata estructural/fichas y fija los campos narrativos `narrative_text`, `vector_source: narrativa`, `has_narrative: true`. Solo re-embebe textos cambiados, en un proceso/lote. Repara un flag narrativo ausente sin re-embedding. Confirma escrituras por readback.
- Solo tras sincronizacion correcta el director marca completos los beats. Caida de Qdrant: el draft aceptado queda disponible y se reintenta sync, no generacion. No hay transaccion conjunta disco+Qdrant ni CAS remoto; deben serializarse operaciones sobre el mismo capitulo/beats.

Revision JSON inline (tambien acepta campos adicionales del informe editorial):

```json
{
  "escena_stable_id": "a1b2c3d4",
  "candidato_sha256": "<sha256 real devuelto por preparar>",
  "estado": "aprobado",
  "incidencias": []
}
```

Solo se admiten incidencias con `gravedad: opcional` al aceptar/sincronizar. Una correccion cambia el hash y exige revision vigente. El hash une texto y decision; no certifica por si solo calidad literaria ni autoriza al director a inventar aprobacion del validador.

Para revision puntual, escritor/integrador devuelven secciones afectadas; el director las integra en una copia de la escena, verifica el resto intacto y vuelve a preparar. El candidato final siempre es escena completa. No se migran notas/formatos antiguos de otras escenas al usar el helper.

## Recuperacion y medicion

- `length`: guardar evidencia, comprobar secciones completas y presupuesto efectivo. No reintentar a ciegas ni elevar el presupuesto automaticamente; reducir contexto redundante o dividir por un corte narrativo justificado y ensamblar escena completa para revisar.
- Error de transporte: verificar resultado parcial antes de una recuperacion controlada.
- Error de persistencia: reintentar solo el comando mecanico idempotente.
- Maximo dos recuperaciones automaticas por escena; despues pausa e informa. No continuar por escenas dependientes con datos faltantes.
- Telemetria en SQLite de OpenCode (`session`, `message`, `part`): consultar solo metadatos de este proyecto. Distinguir tareas, pasos LLM, herramientas y tiempos, entrada no cacheada/cache y salida/razonamiento. Costes de OpenCode son estimaciones, no facturas conciliadas. No crear otro sistema de logs.

## Pruebas locales

```text
python -B -m unittest discover -s tests -p test_persistir_escena.py -v
python -B tests/test_narrative_contracts.py --schema <cache/opencode-config-schema-20260909.json> -v
node tests/verify-venice-request.mjs --deps <prefijo-npm-temporal> --schema <cache/opencode-config-schema-20260909.json>
```

Instalacion temporal y descargas publicas de schema documentadas en `tests/verify-venice-request.mjs`. No instala paquetes del workspace ni carga credenciales. El runner del adaptador bloquea red y usa fetch simulado con respuestas neutras; prueba doGenerate/generateText y doStream/streamText del paquete Venice 2.1.1 (API nativa V3), con AI SDK 6.0.90. Las fixtures V2 son solo compatibilidad adicional, no el adaptador nativo.

El schema publicado comprueba forma y valores del frontmatter; el mock comprueba `max_completion_tokens: 64000`, fallback 32000, ausencia de herramientas y de parametros de reasoning no soportados. No ejecuta el merge runtime de OpenCode ni garantiza latencia/calidad con 64K. Tras reinicio hay que comprobar el primer uso real; no se ejecuta una inferencia de prueba durante esta implementacion.

### Resultado local (2026-09-09)

- 54 pruebas de persistencia aprobadas, sin omisiones: fixtures neutrales y Qdrant/embeddings simulados.
- 16 pruebas de contratos/schema aprobadas, sin omisiones (12 locales + 4 del schema publicado).
- 17 casos HTTP simulados aprobados, incluidos 8 de streaming; 0 intentos de red real durante el runner.
- Node 22.21.0; Venice provider 2.1.1; AI SDK 6.0.90; PyYAML 6.0.3; jsonschema 4.24.1.
- Schema OpenCode SHA256: `e8cb6e287a3852ee3403f4803be5ad6b19db94948037eaa9672125c333427922`.
- Schema Models.dev SHA256: `f4f900c13c0d56d8a48c3e3b56bec3cacf929e278ec3d5e230d6cbb7404e464d`.
- Dependencias/schemas de prueba en el temporal preaprobado, no en package.json/node_modules del workspace. Respaldo de contratos previo a la edicion en `C:/Users/migue/AppData/Local/Temp/opencode/renacer-flujo-antes-20260909.tar`; comandos en `renacer-comandos-antes-20260909.tar` del mismo directorio.

## Riesgos pendientes

Seguimiento local en `docs/deuda-tecnica.md`.

- 64K puede evitar cortes y a la vez aumentar tiempo/coste. Cierre: medir terminacion, salida util y latencia tras reinicio, y comparar calidad editorial sin atribuir mejoras a una sola muestra.
- El helper no ofrece concurrencia multi-escritor sobre un mismo capitulo o CAS remoto. Cierre operativo: serializar; si se necesita concurrencia real, disenar bloqueo/CAS antes de activarla.
- La deteccion mecanica de metatexto es por estructura/patrones, no comprende el significado de la prosa. La revision independiente sigue siendo necesaria.

## Referencias

- Guia de replicacion para otros workspaces: [replicacion-flujo-narrativa.md](../replicacion-flujo-narrativa.md)

- https://github.com/anomalyco/opencode/blob/v1.18.29/packages/opencode/src/provider/transform.ts
- https://github.com/anomalyco/opencode/blob/v1.18.29/packages/opencode/src/session/llm/request.ts
- https://github.com/dpuyosa/venice-ai-sdk-provider/blob/5468bb8613ef205f800e8732677f74785e7b2c29/src/venice-chat-language-model.ts
- https://docs.venice.ai/overview/guides/reasoning-models
- https://opencode.ai/config.json
