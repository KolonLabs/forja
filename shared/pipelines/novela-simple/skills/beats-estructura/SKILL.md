---
name: beats-estructura
description: Use ONLY when the user is proponiendo, revisando o desarrollando beats, escenas o capítulos de novela simple. Define formato, identidad, orden, personajes y zonas.
---

# Skill — Estructura de Beats (Novela Simple)

## Reglas fundamentales

- Una sola frase con acción concreta narrable por beat.
- Sin títulos de bloque en la propuesta.
- Sin número fijo de beats por bloque, pero sin excederse.
- Los beats crecen hasta que haya masa narrativa suficiente para empaquetar un capítulo.
- Los capítulos se empaquetan por material narrativo, no por una cuota predefinida.
- Sin hilos: las anotaciones de hilo narrativo no aplican en esta escala.
- Cada beat recibe un `stable_id` opaco e inmutable al crearse.
- `seq` expresa la posición y siempre es local al `parent_id` de la escena.
- El ID de presentación se deriva de `seq` y nunca se almacena.

## Formato de beat

```text
⬜ stable_id [seq] — acción [Tono — EXTENSIÓN] [Personajes] [Zona: nombre]
```

Ejemplo canónico:

```text
⬜ a1b2c3d4 [34] — Laura se arrodilla ante Diego [Opresivo — BREVE] [Laura, Diego] [Zona: salón]
```

- `a1b2c3d4`: `stable_id` inmutable.
- `[34]`: `seq` local a la escena padre.
- `i9j0k1l2 [34]`: display derivado de `seq: 34` al presentar; nunca se persiste.
- Las referencias cruzadas, fichas, `parent_id` y `cola_d.md` usan `stable_id`.

## Componentes

| Componente | Formato | Descripción |
|------------|---------|-------------|
| Acción | Frase concreta narrable | Sujeto + verbo + consecuencia |
| Tono y extensión | `[Tono — EXTENSIÓN]` | Tono narrativo y `BREVE`, `MEDIA` o `EXTENSA` |
| Personajes | `[Nombre, Nombre]` | Personajes presentes y activos |
| Zona | `[Zona: nombre]` | Ubicación espacial del beat |

## Ejemplos

```text
✅ a1b2c3d4 [1] — Ricardo desembarca en Villaverde arrastrando la mochila por el muelle [Contemplativo — EXTENSA] [Ricardo] [Zona: muelle de Villaverde]
🔄 e5f6a7b8 [2] — Elena intercepta a Ricardo antes de que salga del puerto y le ofrece alojamiento [Tenso — MEDIA] [Ricardo, Elena] [Zona: salida del puerto]
⬜ 11223344 [3] — Ricardo descubre que la habitación tiene una cerradura por fuera [Inquietante — BREVE] [Ricardo] [Zona: pensión Los Cedros, habitación 3]
⬜ 55667788 [4] — Elena evade las preguntas sobre el pueblo mientras Marcos observa [Incómodo — MEDIA] [Ricardo, Elena, Marcos] [Zona: comedor de la pensión]
```

Estados: ✅ completo · 🔄 en progreso · ⬜ pendiente.

## Orden, inserción y renumeración

Al insertar, eliminar o reordenar hermanos:

1. Identifica el grupo mediante `parent_id`; cada escena mantiene su propia secuencia.
2. Usa `renumber-siblings` desde el primer `seq` afectado para abrir o cerrar el hueco.
3. Actualiza solo `seq`.
4. Mantén `stable_id`, `parent_id`, fichas y referencias externas.
5. Deriva de nuevo displays como `i9j0k1l2 [34]` en la capa de presentación.

Nunca renumeres beats de otra escena por compartir el mismo valor de `seq`.

## Extensiones y tonos

La extensión (`BREVE`, `MEDIA`, `EXTENSA`) y el catálogo de tonos están definidos en `tonos-beat`. El guionista asigna la etiqueta; el escritor la desarrolla. El beat del guion siempre ocupa una línea.

## Qué debe tener

- Sujeto claro que actúa.
- Acción concreta y narrable.
- Consecuencia o cambio.
- Personajes presentes.
- Zona coherente.

## Qué no debe tener

- Estados de ánimo sin acción.
- Resumen de intenciones.
- Descripciones sin evento.
- Reflexiones abstractas.
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

