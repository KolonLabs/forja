---
name: beats-estructura
description: Use ONLY when the user is proponiendo, revisando o desarrollando beats, escenas, capítulos o trenzado de novela multi-hilo. Define formato, identidad, orden, personajes, zonas e hilos.
---

# Skill — Estructura de Beats (Novela Multi-Hilo)

## Reglas fundamentales

- Una sola frase con acción concreta narrable por beat.
- Sin títulos de bloque en la propuesta.
- Sin número fijo de beats por bloque, pero sin excederse.
- Los beats crecen hasta que haya masa narrativa suficiente para empaquetar un capítulo.
- Los capítulos se empaquetan por material narrativo, no por una cuota predefinida.
- Cada beat pertenece al menos a un hilo narrativo; varios hilos pueden coexistir en el capítulo.
- Cada beat recibe un `stable_id` opaco e inmutable al crearse.
- `seq` expresa la posición y siempre es local al `parent_id` de la escena o bloque de hilo.
- El ID de presentación se deriva de `seq` y nunca se almacena.

## Formato de beat

```text
⬜ stable_id [seq] — acción [Tono — EXTENSIÓN] [Personajes] [Zona: nombre] [Hilos: hilo-S]
```

Ejemplo canónico:

```text
⬜ a1b2c3d4 [34] — Laura se arrodilla ante Diego [Opresivo — BREVE] [Laura, Diego] [Zona: salón] [Hilos: hilo-S]
```

- `a1b2c3d4`: `stable_id` inmutable.
- `[34]`: `seq` local al padre.
- `i9j0k1l2 [34]`: display derivado de `seq: 34` al presentar; nunca se persiste.
- Las referencias cruzadas, fichas, `parent_id` y `cola_d.md` usan `stable_id`.

## Componentes

| Componente | Formato | Descripción |
|------------|---------|-------------|
| Acción | Frase concreta narrable | Sujeto + verbo + consecuencia |
| Tono y extensión | `[Tono — EXTENSIÓN]` | Tono narrativo y `BREVE`, `MEDIA` o `EXTENSA` |
| Personajes | `[Nombre, Nombre]` | Personajes presentes y activos |
| Zona | `[Zona: nombre]` | Ubicación espacial del beat |
| Hilos | `[Hilos: hilo-A, hilo-B]` | Hilos narrativos del beat |

## Ejemplos

```text
✅ a1b2c3d4 [1] — Ricardo desembarca en Villaverde arrastrando la mochila por el muelle [Contemplativo — EXTENSA] [Ricardo] [Zona: muelle de Villaverde] [Hilos: hilo-ricardo]
🔄 e5f6a7b8 [2] — Isabel recibe el informe sobre la desaparición de su hermano [Administrativo — BREVE] [Isabel, Funcionario] [Zona: Ministerio del Interior] [Hilos: hilo-isabel]
⬜ 11223344 [3] — Elena intercepta a Ricardo en el puerto y le ofrece alojamiento [Tenso — MEDIA] [Ricardo, Elena] [Zona: salida del puerto] [Hilos: hilo-ricardo, hilo-elena]
⬜ 55667788 [4] — Isabel soborna al celador para acceder a los expedientes sellados [Clandestino — MEDIA] [Isabel, Celador] [Zona: archivo provincial] [Hilos: hilo-isabel]
```

Estados: ✅ completo · 🔄 en progreso · ⬜ pendiente.

## Orden, inserción y renumeración

Al insertar, eliminar o reordenar hermanos:

1. Identifica el grupo por `parent_id` y, cuando corresponda, por `hilo`.
2. Usa `renumber-siblings` desde el primer `seq` afectado para abrir o cerrar el hueco.
3. Actualiza exclusivamente `seq`.
4. Conserva `stable_id`, `parent_id`, hilo, fichas y referencias externas.
5. Deriva de nuevo displays como `i9j0k1l2 [34]` solo al presentar.

No renumeres beats de otra escena o bloque de hilo por compartir el mismo `seq`. La secuencia siempre es local al padre.

## Reglas de hilos

- Todo beat anota al menos un hilo mediante `[Hilos: hilo-S]`.
- Un beat puede pertenecer a varios hilos cuando estos interactúan.
- Los beats de hilos distintos se trenzan en el guion del capítulo.
- No se fuerza alternancia 1:1; manda la tensión narrativa.
- En capítulos puente, el padre o el filtro `hilo` delimitan los grupos de hermanos que se renumeran.

## Extensiones y tonos

La extensión (`BREVE`, `MEDIA`, `EXTENSA`) y el catálogo de tonos están definidos en `tonos-beat`. El guionista asigna la etiqueta; el escritor la desarrolla. El beat del guion siempre ocupa una línea.

## Qué debe tener

- Sujeto claro que actúa.
- Acción concreta y narrable.
- Consecuencia o cambio.
- Personajes presentes.
- Zona coherente.
- Hilo o hilos narrativos.

## Qué no debe tener

- Estados de ánimo sin acción.
- Resumen de intenciones.
- Descripciones sin evento.
- Reflexiones abstractas.
- Beats sin hilo asignado.

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
| 8 | ¿Tiene al menos un hilo? | |
| 9 | ¿Los hilos son coherentes con la acción? | |
| 10 | ¿`seq` es local al padre y `stable_id` permanece inmutable? | |

