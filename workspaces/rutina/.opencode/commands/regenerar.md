---
description: Descarta la prosa de una escena y la reescribe por completo desde sus beats, sin tocar la estructura.
agent: director
---

# /regenerar — Relato

Solicitud recibida: $ARGUMENTS

Regenera una escena completa: **descarta la prosa actual** de una `E_XXXX` y la reescribe desde cero a partir de sus beats. A diferencia de `/revisar` y `/expandir`, que respetan y ajustan la prosa existente, `/regenerar` la tira y parte de los beats como si la escena no se hubiera escrito nunca. No es para cambiar qué ocurre: produce prosa nueva para los **mismos** beats.

## Disponibilidad

Solo en `escritura` o `correccion`. En `diseno` o `fichas`, dirige a `/generar`. En `finalizado` o `publicado`, indica volver al hub y ejecutar `/nueva-edicion <origen> <slug-edicion>`.

## Alcance

- **Conserva la estructura intacta:** la escena mantiene su `E_XXXX`, sus `B_XXXX`, su orden, su arco tonal y su `Salida: continua|separador`. Regenerar reescribe la prosa, nunca los beats ni los hechos.
- **Solo prosa.** Si la petición implica cambiar qué ocurre —un beat, un hecho, la acción nuclear, dividir o fusionar escenas— no regeneres: dirige a `/corregir estructura <instrucción>` o, si toca hechos, al hub.
- Un `enfoque` opcional en los argumentos orienta la reescritura (p. ej. «más contención», «menos repetición de sujeto»), pero no puede introducir acciones, relaciones ni giros que los beats no contengan.

## Procedimiento

1. Extrae la `E_XXXX` de los argumentos. Si falta, pídela antes de actuar. Comprueba que esa escena ya tiene marcador en `relato-draft.md`; si aún no fue escrita, es trabajo de `/generar`, no de regeneración.
2. Ejecuta `pwsh -NoProfile -File scripts/relato-transaccion.ps1 -Accion Recuperar`. Retoma un staging válido o descártalo antes de abrir otro.
3. Ejecuta `pwsh -NoProfile -File scripts/relato-transaccion.ps1 -Accion Preparar -Operacion correccion` y trabaja solo en `.forja-transaccion/siguiente/`.
4. Reúne para el escritor exactamente lo que recibe en `/generar`: la `E_XXXX` completa con sus beats en orden, la escena previa y la siguiente del draft, las fichas necesarias, el delta de contexto relevante y el estilo activo. Añade el `enfoque` si se indicó.
5. El escritor genera la **escena completa** en una respuesta, con `<!-- B_XXXX -->` antes del primer pasaje que realiza cada beat. No conserva ningún fragmento de la prosa anterior: es una escritura nueva.
6. El validador evalúa la escena regenerada: realiza cada acción nuclear, continuidad con las escenas vecinas, arco tonal, crudeza y verosimilitud conductual. Si hay correcciones, el integrador reescribe solo los tramos señalados.
7. En el staging, reemplaza el tramo completo de esa `E_XXXX` en `relato-draft.md`, conservando su marcador de escena y la misma `Salida`. Verifica: anclas únicas y ordenadas, prosa no vacía tras cada ancla, y que el draft sigue siendo un prefijo válido y continuo.
8. Actualiza `contexto_narrativo.md` desde esta escena (su delta pudo cambiar) y registra en `correcciones.md`: fecha, `regenerar`, `E_XXXX` afectada, enfoque si lo hubo y resultado.
9. Confirma la transacción. Si un gate falla antes de confirmar, ejecuta `-Accion Descartar`; la prosa viva queda intacta.

## Notas

- Regenerar es destructivo sobre la prosa de esa escena y no reversible una vez confirmado, salvo por el propio historial de transacción. Úsalo cuando corregir tramo a tramo sea peor que rehacer la escena entera.
- La escena se reescribe con el modelo que el escritor tenga configurado en ese momento. Regenerar la misma escena tras cambiar el modelo del escritor la sobrescribe: si necesitas comparar salidas de varios modelos, guarda cada resultado antes de la siguiente pasada.
- Deja siempre rastro en `correcciones.md`: la regeneración es una decisión editorial trazable, no una tirada que se repite hasta que salga bien.
