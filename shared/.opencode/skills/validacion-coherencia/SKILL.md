---
name: validacion-coherencia
description: Criterios de evaluación de consistencia narrativa y lógica interna. Úsalo cuando necesites validar que el texto es coherente con guion, personajes y escena.
---

# Validación de Coherencia

## Criterios editoriales

### 1. Compromiso narrativo del beat
- ¿Se realiza el acontecimiento, decision, descubrimiento o inferencia atribuida y su consecuencia? Una unidad dramatica no equivale a una microaccion.
- ¿Se omitio o altero un compromiso obligatorio, distinguiendolo de ejecucion libre y ejemplos opcionales?
- ¿El texto distingue lo dicho, sabido, inferido y confirmado? Una afirmacion o sospecha no se convierte en certeza ni exige confesion para probar cobertura.

### 2. Consistencia de personajes
- ¿El personaje actúa según su personalidad?
- ¿Dice cosas que diría según su perfil?
- ¿Su comportamiento es creíble?
- ¿Respeta sus límites y motivaciones?

### 2. Continuidad física
- ¿Los personajes están donde deberían estar?
- ¿Su posición corporal es consistente (sentado, de pie, etc.)?
- ¿La ropa está correcta (puesta, quitada, etc.)?
- ¿Los objetos están donde deberían?

### 3. Temporalidad
- ¿El tiempo avanza correctamente?
- ¿Hay saltos temporales injustificados?
- ¿Las acciones tienen el orden lógico?
- ¿La duración de las acciones es realista?

### 4. Espacialidad
- ¿El escenario se mantiene consistente?
- ¿Los personajes se mueven de forma lógica?
- ¿Los objetos mencionados existen en el escenario?
- ¿Las distancias y tamaños son coherentes?

### 5. Lógica narrativa
- ¿Lo que pasa tiene sentido con lo anterior?
- ¿Hay contradicciones con lo establecido?
- ¿Las acciones tienen consecuencias lógicas?
- ¿Los diálogos son coherentes con la situación?

### 6. Coherencia de entidades y ejecucion libre (GAP-34 / GAP-36)

Compara cast activo, zonas y objetos causales con el guion y canon. La ausencia de una anotacion no demuestra una contradiccion. `Props` es opcional: no se exige inventariar cada objeto ambiental, mencion incidental o enlace ordinario compatible.

- Una participacion activa no prevista que altera el acontecimiento, un nuevo objeto causal que resuelve el conflicto o un cambio de lugar que contradice el canon requieren decision del director.
- Los detalles ordinarios compatibles son ejecucion libre. No conviertas cada taza, saludo o movimiento en una obligacion de anotacion ni los elimines por no estar enumerados.
- Una contradiccion material si se reporta: un objeto usado de forma imposible, una posesion o conocimiento no adquirido, o un personaje situado en lugares incompatibles. Cita el conflicto, no solo la ausencia en el inventario.
- Distingue una omision de anotaciones del guion de una invencion en prosa. El director resuelve el alcance; no se actualizan fichas o guion para justificar cualquier invencion. Las anotaciones de hilos dependen de la escala: no se exige inventariarlas cuando el guion de la escala no las declara.

## Decision editorial

Usa incidencias concretas (`bloqueante`, `corregir`, `opcional`), no un gate por score. En revision de prosa por `validador`, su contrato fija estado y aprobacion ligados al hash. En auditoria de guion, usa el diagnostico del agente o comando invocante: no requiere candidato ni hash. Un texto con IDs correctos puede fallar por causalidad o dialogo inconexo; no se aprueba por cobertura mecanica.

## Regla especial

Una contradiccion grave exige resolucion antes de aceptar. No se compensa con aciertos en otras dimensiones ni con una media alta.

## Formato de respuesta

Respeta el contrato del consumidor. Para `validador` de prosa: candidato/hash, estado e incidencias con stable_id, fragmento, problema, gravedad y correccion. Para `auditor-beats`, director o comandos de revision de guion: diagnostico con referencias y evidencia, sin exigir un hash de candidata inexistente. Este skill no crea otro formato ni exige puntuaciones por dimension.

## Regla

Cita siempre las frases exactas que contradicen lo anterior.
