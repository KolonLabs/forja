---
name: beats-estructura
description: Estructura de beats para relato. Formato, identidad, orden, reglas y prohibiciones. Cárgalo al generar, insertar, reordenar o revisar beats.
---

# Skill — Estructura de Beats (Relato)

## Reglas fundamentales

- Una sola frase con acción concreta narrable por beat.
- Sin títulos de bloque en la propuesta.
- Sin número fijo de beats por bloque, pero sin excederse.
- Cada beat recibe un `stable_id` opaco e inmutable al crearse.
- `seq` expresa su posición y siempre es local al `parent_id` de la escena.
- El ID de presentación se deriva de `seq` al mostrar y nunca se almacena.

## Formato de beat

```text
⬜ stable_id [seq] — acción [Tono — EXTENSIÓN]
```

Ejemplo canónico:

```text
⬜ a1b2c3d4 [34] — Laura se arrodilla ante Diego [Opresivo — BREVE]
```

- `a1b2c3d4`: `stable_id` inmutable.
- `[34]`: `seq` local a la escena padre.
- `i9j0k1l2 [34]`: display derivado de `seq: 34` únicamente al presentar el beat.
- `stable_id` se usa en `parent_id`, fichas y anotaciones de `cola_d.md`.

### Estados

```text
✅ a1b2c3d4 [1] — Desembarca en Villaverde arrastrando la mochila por el muelle [Contemplativo — MEDIA]
🔄 e5f6a7b8 [2] — Observa a los trabajadores portuarios descargar la mercancía [Tenso — BREVE]
⬜ 11223344 [3] — Descubre el cuerpo flotando entre dos barcazas [Revelación — EXTENSA]
⬜ 55667788 [4] — Decide no avisar a nadie y sigue caminando [Clínico — BREVE]
```

Estados: ✅ completo · 🔄 en progreso · ⬜ pendiente.

## Orden, inserción y renumeración

Al insertar, eliminar o reordenar hermanos:

1. Identifica el grupo por `parent_id`; `seq` nunca se interpreta globalmente.
2. Usa la operación `renumber-siblings` para abrir o cerrar el hueco desde el primer `seq` afectado.
3. Cambia exclusivamente `seq`.
4. Conserva `stable_id`, `parent_id` y todas las referencias externas.
5. Regenera displays como `i9j0k1l2 [34]` solo al presentar el resultado.

`stable_id` es inmutable. Una renumeración jamás crea un beat nuevo ni modifica su identidad.

## Extensiones y tonos

La extensión (`BREVE`, `MEDIA`, `EXTENSA`) y el catálogo de tonos están definidos en `tonos-beat`. El guionista asigna la etiqueta; el escritor la desarrolla. El beat del guion siempre ocupa una línea.

## Qué debe tener un beat

- Sujeto claro que actúa.
- Acción concreta y narrable.
- Consecuencia o cambio en la trama.

## Qué no debe tener

- Estados de ánimo sin acción.
- Resumen de intenciones.
- Descripciones de escenario sin evento.
- Reflexiones abstractas del narrador.

## Evaluación

| # | Criterio | ¿Pasa? |
|---|----------|--------|
| 1 | ¿Hay un sujeto claro que actúa? | |
| 2 | ¿La acción puede escribirse como escena? | |
| 3 | ¿Tiene consecuencia en la trama? | |
| 4 | ¿Evita repetir beats anteriores? | |
| 5 | ¿Progresa el arco narrativo? | |
| 6 | ¿`seq` es local al padre y `stable_id` permanece inmutable? | |

