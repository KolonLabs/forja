---
name: beats-estructura
description: Use ONLY when the user is proponiendo, revisando o desarrollando beats, escenas o capítulos de novela simple. Define formato, identidad, orden, personajes y zonas.
user-invocable: false
---

# Skill — Estructura de Beats (Novela Simple)

## Reglas fundamentales

- Una unidad dramatica concreta por beat: acontecimiento, decision, descubrimiento o inferencia atribuida que aporta un cambio narrativo. Una linea de guion no equivale a una microaccion ni a un parrafo de prosa.
- Sin títulos de bloque en la propuesta.
- Sin número fijo de beats por bloque: la cantidad es criterio editorial del director, no una cuota (el exceso solo se juzga como dilución narrativa, no contra un número).
- Los beats crecen hasta que haya masa narrativa suficiente para empaquetar un capítulo.
- Los capítulos se empaquetan por material narrativo, no por una cuota predefinida.
- Sin hilos: las anotaciones de hilo narrativo no aplican en esta escala.
- Cada beat recibe un `stable_id` opaco e inmutable al crearse.
- `seq` expresa la posición y siempre es local al `parent_id` de la escena.
- La etiqueta de lectura `B_NNNN` no se deriva del `seq`: la pone `scripts/etiquetas-guion.py` en el guion y nunca es identidad (ADR 0033).

## Contrato de interpretacion

El beat fija un compromiso narrativo, no su ejecucion literal. Puede contener varios gestos o intercambios si sirven al mismo acontecimiento. Divide por cambios independientes de objetivo, informacion, decision o contexto; no por puntuacion, numero de verbos o mezcla de tonos. Tampoco agrupes todo un capitulo bajo una intencion vaga: la cobertura debe poder comprobarse.

- **Obligatorio:** hechos, decisiones, consecuencias, restricciones y quien sabe, dice o infiere cada cosa. Una declaracion no acredita su verdad; una inferencia no es una certeza ni debe convertirse en confesion de otro personaje.
- **Libre:** palabras, gestos, pausas, detalle, ritmo y enlaces ordinarios compatibles con el canon. No fijes silencios, miradas o reacciones para fabricar tension si no tienen funcion necesaria.
- **Ejemplos opcionales:** ilustran posibilidades; no son canon ni una lista que deba aparecer completa. Un ejemplo solo pasa a obligatorio mediante una decision explicita del director/usuario.

Estas distinciones viven en el objetivo y contexto editorial existente, no en campos nuevos del payload. El director las pasa inline a escritor e integrador, que no cargan skills.

### Dialogo e interioridad

El guion establece que se comunica y que cambia, no un turno por beat. Revisa la conversacion completa: cada replica responde al intercambio anterior; saludos, despedidas y desplazamientos ordinarios caben en los beats existentes cuando son pertinentes. No exijas un beat por gesto ni omitas un enlace porque no esta enumerado.

Una decision o deduccion interior puede ser el cambio narrativo. Define su contenido y grado de certeza sin escribir el pensamiento literal ni sustituirlo automaticamente por una mirada. El escritor construye su voz: inferir no obliga a enumerar datos en cursiva. El tono de la escena puede nacer de lo que comprende el POV mientras otro personaje habla con normalidad.

Reserva `⚡` para palabras exactas exigidas por el usuario o cuya literalidad tenga una funcion causal documentada (por ejemplo, una clave reconocida despues). Sin esa necesidad, fija el contenido verbal, no la replica literal. Una frase `⚡` vigente sigue siendo obligatoria: ante conflicto, el director resuelve y actualiza el guion antes de escribir; no se elimina ni se recoloca para salvarla a cualquier precio.

### Comprobacion antes de entregar

1. ¿Se puede identificar el acontecimiento y su consecuencia sin inventar un hecho nuevo?
2. ¿Queda claro que es dicho, sabido, inferido y confirmado, y por quien?
3. ¿Dos ejecuciones distintas cumplirian el beat sin cambiar el canon? Si no, revisa si el detalle fijado es realmente obligatorio.
4. ¿La interaccion completa tiene una progresion causal, sin preguntas redundantes, confesiones forzadas ni puentes artificiales?
5. ¿La cobertura responde al hecho, sin cuotas de beats ni microcoreografia?

### Ejemplos neutrales

- Demasiado prescrito: `Eva responde dejando un silencio tras cada palabra y mirando la taza`.
- Compromiso: `Eva cuenta con normalidad su jornada; Luis relaciona el cambio de horario con una preocupacion que ella no menciona`. La preocupacion es inferencia de Luis, no reconocimiento de Eva.
- Una unidad: `Luis solicita el cambio de turno y obtiene la autorizacion`. Pregunta, respuesta y gestos no requieren beats separados.
- Dos cambios independientes: `Luis obtiene el cambio de turno; al salir descubre que han cancelado el tren`. La puntuacion no decide: la autorizacion y el descubrimiento tienen consecuencias distintas.

## Representacion tecnica

```text
⬜ stable_id [seq] — acción [Tono — EXTENSIÓN] [Personajes] [Zona: nombre]
```

Ejemplo canónico:

```text
⬜ a1b2c3d4 [34] — Laura se arrodilla ante Diego [Opresivo — BREVE] [Laura, Diego] [Zona: salón]
```

- `a1b2c3d4`: `stable_id` inmutable.
- `[34]`: `seq` local a la escena padre.
- `B_NNNN · ` delante del `stable_id`: etiqueta visual de lectura que inserta y renumera `scripts/etiquetas-guion.py`; nunca es identidad (ADR 0033).
- Las referencias cruzadas, fichas, `parent_id` y `cola_d.md` usan `stable_id`.

## Componentes

| Componente | Formato | Descripción |
|------------|---------|-------------|
| Acción | Compromiso narrativo concreto | Sujeto + acontecimiento/decision/inferencia + consecuencia |
| Tono y extensión | `[Tono — EXTENSIÓN]` | Tono narrativo y `BREVE`, `MEDIA` o `EXTENSA` |
| Personajes | `[Nombre, Nombre]` | Personajes presentes y activos |
| Zona | `[Zona: nombre]` | Ubicación espacial del beat |

## Ejemplos

```text
✅ a1b2c3d4 [1] — Ricardo desembarca en Villaverde arrastrando la mochila por el muelle [Contemplativo — EXTENSA] [Ricardo] [Zona: muelle de Villaverde]
🔄 e5f6a7b8 [2] — Elena intercepta a Ricardo antes de que salga del puerto y le ofrece alojamiento [Tenso — MEDIA] [Ricardo, Elena] [Zona: salida del puerto]
⬜ 11223344 [3] — Ricardo descubre que la habitación tiene una cerradura por fuera [Revelación — BREVE] [Ricardo] [Zona: pensión Los Cedros, habitación 3]
⬜ 55667788 [4] — Elena evade las preguntas sobre el pueblo mientras Marcos observa [Tenso — MEDIA] [Ricardo, Elena, Marcos] [Zona: comedor de la pensión]
```

Estados: ✅ completo · 🔄 en progreso · ⬜ pendiente.

## Orden, inserción y renumeración

Al insertar, eliminar o reordenar hermanos:

1. Identifica el grupo mediante `parent_id`; cada escena mantiene su propia secuencia.
2. Usa `renumber-siblings` desde el primer `seq` afectado para abrir o cerrar el hueco.
3. Actualiza solo `seq`.
4. Mantén `stable_id`, `parent_id`, fichas y referencias externas.
5. Recalcula las etiquetas visuales con `python -X utf8 scripts/etiquetas-guion.py`.

Nunca renumeres beats de otra escena por compartir el mismo valor de `seq`.

## Extensiones y tonos

La extensión (`BREVE`, `MEDIA`, `EXTENSA`) y el catálogo de tonos están definidos en `tonos-beat`. El guionista asigna la etiqueta; el escritor la desarrolla. El beat del guion siempre ocupa una línea.

## Qué debe tener

- Sujeto claro que actua, decide, descubre o infiere.
- Acontecimiento concreto y narrable, no solo una intencion vaga.
- Consecuencia o cambio.
- Personajes presentes.
- Zona coherente.

## Qué no debe tener

- Estados de animo estaticos sin funcion o cambio narrativo.
- Resumen de intenciones.
- Descripciones sin evento.
- Reflexiones abstractas o pensamientos ya redactados como prosa; si cambia la comprension del personaje, indicar el contenido de la inferencia y su certeza.
- Referencias a hilos narrativos.

## Evaluación

| # | Criterio | ¿Pasa? |
|---|----------|--------|
| 1 | ¿Hay un sujeto claro que actúa? | |
| 2 | ¿La acción es narrable? | |
| 3 | ¿Tiene consecuencia en la trama? | |
| 4 | ¿No repite información anterior? | |
| 5 | ¿Progresa el arco? | |
| 6 | ¿Los personajes anotados coinciden con la acción? | |
| 7 | ¿La zona es coherente? | |
| 8 | ¿`seq` es local al padre y `stable_id` permanece inmutable? | |

