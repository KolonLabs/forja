---
name: beats-estructura
description: Define beats globales de relato como acciones concretas sin invadir la prosa.
user-invocable: false
---

# Beats — Relato

`B_XXXX` es un ID global y durable **desde que el guion queda persistido**. Antes de ese gate, el director puede asignar un rango provisional que no sobrevive a una interrupción. Ya persistido, su posición es la que ocupa en el guion; no se renumera, reutiliza ni deriva de una escena, salvo petición expresa de la persona usuaria mediante `renumeracion-ids`.

## Formato

```text
⬜ B_0001 — Ana borra el aviso antes de que Luis lo vea. [Clínico — BREVE]
⬜ B_0002 — Luis pregunta qué estaba mirando Ana. [Tenso — MEDIA]
⬜ B_0003 — Ana se lo enseña. [Revelación — EXTENSA]
```

Todo beat lleva `[Tono — EXTENSIÓN]` del catálogo de `tonos-beat`, común a todas las escalas: uno o dos tonos (`Explícito / Visceral`) y una extensión, `BREVE`, `MEDIA` o `EXTENSA`, que indica peso dentro de la escena, nunca cifras. El tono y la extensión son independientes (un beat `Clínico` puede ser `EXTENSA`; uno `Explícito`, `BREVE`). `[elipsis]`, añadido a la etiqueta, marca un salto deliberado.

No añadas etiquetas de hecho, número de palabras, cuotas, POV, lugar ni encabezados narrativos al beat.

## Atomicidad

Un beat es **una acción completa**: quién hace qué a quién (y en qué situación), desde su preparación hasta que esa acción cambia. Dentro del mismo beat van la preparación que la sirve (acercarse, colocarse, cerrar la puerta), las indicaciones, los frenos y permisos que no cambian la acción y su escalada: esa progresión la desarrolla el escritor. Una acción larga es `EXTENSA`; si es muy larga, puede dividirse en dos fases de la misma acción.

El beat se corta cuando:

- cambia la acción o la situación (de la puerta a la mesa, de discutir a recoger);
- cambia de verdad quién lleva la acción (un relevo real, no una indicación). Cuando los relevos son continuos, basta un beat que diga que se alternan y deje al escritor desarrollar el cambio;
- ocurre algo externo que interrumpe (un portazo, una llamada);
- se produce una revelación, una decisión o un estado que un hecho exige mostrar.

No metas en un beat dos acciones distintas, ni partas una misma acción en sus gestos. La longitud no es criterio: un beat puede ser largo si sigue siendo una sola acción, y no se divide ni se recorta por número de palabras. Una pauta o una escena no explícita sigue la misma regla: una situación completa hasta que cambia.

El beat no dicta cómo se ejecuta la acción: sin listas entre paréntesis, sin indicaciones de ritmo o modo (despacio, con cuidado, mirándolo), sin sensaciones y sin el contenido de lo que alguien dice o contesta cuando eso es ejecución (basta «le pregunta qué prefiere y elige el orden»). Los beats no llevan diálogo entrecomillado: el escritor respetaría la frase al pie de la letra. El beat dice qué pretende expresar el personaje (le reprocha que no avisara, le echa en cara que esto es lo que quería) y el escritor decide las palabras, aunque la frase venga de un hecho o del canon. Dentro de un acto sexual, las prácticas concretas (qué se hace y a quién, más allá del acto que define el beat) las decide el escritor: el beat dice, por ejemplo, «le hace lo que ella le ha contado que le gusta», no la práctica.

El beat narra solo lo que el personaje POV hace o puede percibir. No repite las reglas globales del brief: ya obligan al escritor y repetirlas en cada beat es ruido.

## Qué fija un beat

- quién hace qué;
- qué cambia o qué consecuencia deja;
- la acción mínima que la prosa debe realizar.

## Qué pertenece a la escena o al escritor

- lugar, tiempo, POV, objetivo y resultado: `E_XXXX`;
- ritmo, frases, diálogo, imágenes, sensorialidad y psicología: escritor;
- cobertura de `H_XXXX` y de sus pautas explícitas: comprobación temporal de diseño;
- la decisión de intercalar beats de contraste, rutina o consecuencia cuando el arco los necesite.

Un beat no es un resumen, una descripción, una emoción abstracta ni prosa parcialmente escrita.

## Reparaciones

Al insertar un acontecimiento causal nuevo, asigna el siguiente `B_XXXX` y colócalo donde corresponda. Conserva los IDs supervivientes. Si la inserción altera una agrupación, reevalúa las escenas afectadas sin inventar una jerarquía adicional.
