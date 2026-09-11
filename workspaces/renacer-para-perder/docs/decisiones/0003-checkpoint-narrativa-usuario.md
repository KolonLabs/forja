# Checkpoint obligatorio tras cada narrativa de escena

- Estado: aceptada por el usuario; implementacion local.
- Fecha: 2026-09-09.
- Alcance: `renacer-para-perder`, generacion, revision y expansion de narrativa.
- Modifica el avance del director, no modelos, permisos, payloads ni comandos del helper.

## Problema

El checkpoint de prosa era condicional ("si el usuario pide validar escena a escena"), pero el pipeline continuaba tras la aprobacion del validador y volvia automaticamente a 2.1 del capitulo siguiente. Una pregunta al final de un mensaje no es una parada si el director sigue invocando agentes antes de recibir respuesta.

## Flujo vigente

1. Generar o corregir la escena autorizada y comprobar terminacion real.
2. `preparar`: guardar candidata pendiente y obtener hash, sin reemplazar el draft aceptado ni su narrativa en Qdrant.
3. **Presentar la escena completa al usuario y detenerse.** Identificar escena y hash/version; esperar respuesta explicita. No iniciar revision editorial, aceptar, sincronizar, marcar completos ni generar/preparar otra escena o capitulo durante esa espera.
4. Si el usuario pide ajustes, corregir solo esa escena, preparar y volver a presentarla. La orden de corregir no aprueba el resultado por anticipado.
5. Tras conformidad humana, revision editorial independiente para el mismo hash. Si el validador requiere cambios, preparar la nueva version y volver al punto 3 antes de la revision focalizada. Una aprobacion humana no permite ignorar un error editorial.
6. Solo con ambas aprobaciones vigentes: `aceptar -> sincronizar -> marcar completos`.
7. Antes de generar la escena siguiente, exigir autorizacion de avance al destino concreto. Puede recabarse en la misma pregunta que la aprobacion del texto ("¿Apruebas esta version y autorizas generar la escena 3?"). Una aprobacion aislada no autoriza continuar.
8. Con la ultima escena aceptada se puede cerrar el capitulo actual (revision global y cronista). Si cambia prosa, se repite el checkpoint de las escenas afectadas. Tras el cierre, informar y pedir autorizacion explicita para iniciar el siguiente capitulo, antes de memoria/guion.

## Alcance de una respuesta

- El checkpoint de guion aprueba estructura, no narrativa aun no vista.
- `/generar`, "escribe el capitulo" o un "adelante" inicial permiten trabajar hasta el siguiente checkpoint, no escribir todo sin paradas.
- Un "si" aprueba solo la version y el alcance de la pregunta inmediatamente presentada; no se extiende a futuras escenas/capitulos.
- Cualquier cambio textual invalida la conformidad anterior, incluso mecanico. Si se habia autorizado avance desde esa version, reconfirmarlo con la nueva candidata.
- Reintentar sincronizacion del mismo texto ya aprobado no requiere otra aprobacion ni nueva generacion.
- No iniciar trabajos especulativos de la siguiente escena/capitulo mientras falta validacion o permiso de avance.

## Registro y reanudacion

El director registra en `contexto.md` escena, hash/version presentado, estado del checkpoint (pendiente/aprobado/ajustes), respuesta del usuario y alcance de avance. No inventa evidencia de conformidad ni la deduce del review del validador, de una marca de guion o de un archivo `.pendiente.md`. Si no consta al reanudar, presenta la candidata existente y pregunta; no regenera ni avanza por suposicion.

## Aplicacion

Se actualizan director, `PIPELINE.md`, `ORQUESTACION.md`, `contexto-subagente` y los comandos `/generar`, `/revisar`, `/expandir`. La guia de replicacion y las decisiones 0001/0002 remiten a esta regla, que sustituye la condicion anterior de checkpoint a peticion.

El helper sigue comprobando revision editorial/hash. **No comprueba por codigo la aprobacion conversacional del usuario**: el gate humano y el permiso de avance son responsabilidad del director. No se modifica la prosa ni se revocan automaticamente versiones aceptadas antes de esta decision.

## Verificacion

Regresiones estaticas en `tests/test_beat_contracts.py`: parada incondicional, distincion entre aprobacion y avance, cambios que invalidan conformidad, bucle de capitulo detenido y comandos de revision/expansion sujetos al mismo checkpoint. No son una prueba de cumplimiento real del agente; tras reiniciar OpenCode hay que comprobar una pausa efectiva con el usuario (NAR-007).

Resultado local: 14 pruebas de contratos de beats/checkpoints y 12 de configuracion aprobadas; cuatro opcionales de schema omitidas al ejecutar sin `--schema`. No se repitieron las suites de persistencia/identidad ni se ejecuto inferencia real: este cambio solo modifica contratos, documentacion y pruebas estaticas.

Backup previo: `C:/Users/migue/AppData/Local/Temp/opencode/renacer-checkpoint-antes-20260909.tar`.
