---
name: contexto-subagente
description: Define qué contexto necesita cada subagente (escritor, validador, integrador, memoria, cronista) según el tipo de proyecto y fase. El director lo carga antes de invocar cualquier subagente.
compatibility: opencode
---

# Skill: contexto-subagente

## Cuándo usar

El director carga este skill antes de invocar cualquier subagente. Define qué información pasarle para que tenga lo necesario sin sobrecargarlo.

---

## Escritor

### Modo normal (escritura de beat)

1. **Guion de la escena actual** — la escena del `guion.md` o `guion-hilo.md` que contiene este beat (objetivo, tensión, transición)
2. **Fichas relevantes inline** — personajes y lugar de la escena actual (campos `fijo`)
3. **Últimos 5 beats del draft** — ventana de contexto para variedad léxica y continuidad
4. **Beat actual** — ID, acción, tono, extensión
5. **Nombre de escena** — si es el primer beat de una escena nueva
6. **`total_beats` del capítulo** y **`beat_index`** — para calibrar cadencia
7. **Estilo activo** — nombre (de `config.json`)

### Modo novela (con memoria)

Añadir a lo anterior:

8. **Briefing de memoria** (~600 tokens) — compilado por el agente `memoria`
9. **Premisa del capítulo** — extraída de `guion-novela.md`

### Modo expansión (`/expandir`)

Añadir:

10. **Beat siguiente del draft** — para no romper la transición

---

## Validador

### Modo beat

1. **Texto del beat** — generado por el escritor
2. **Beat del guion** — ID, acción, tono, extensión
3. **Fichas relevantes inline** — personajes y lugar de la escena
4. **Bloque de escena del guion** — objetivo, tensión, transición
5. **Últimos 5 beats del draft** — ventana de continuidad
6. **Scores del validador del beat anterior** — para no repetir advertencias
7. **Scope** — lista de dimensiones a evaluar o `global`
8. **IDs declarados en el beat** — `[Personajes:]`, `[Zona:]`, `[Props:]`, `[Hilos:]`
9. **Estilo activo** — nombre

### Modo global

Añadir a lo anterior:

10. **Draft completo del capítulo**
11. **Extracto del L4** — macro-contexto acumulado
12. **Sección del arco en `guion-novela.md`** — estructura planificada
13. **Fichas de hilos activos** — Qdrant `hilo-<id>` con tags `abierto` o `en-desarrollo`
14. **Contexto cross-hilo** (solo multi-hilo) — tabla de trenzado, `guion-hilo.md` de otros hilos, puntos de conexión

---

## Integrador

1. **Beat a corregir** — texto original
2. **Feedback del validador** — JSON consolidado de evaluación
3. **Fichas relevantes inline** — personajes y lugar
4. **Beat del guion** — ID, acción, tono, extensión
5. **Últimos 5 beats del draft** — ventana de continuidad
6. **Bloque de escena del guion** — objetivo, tensión
7. **Estilo activo** — nombre
8. **Beat siguiente del draft** (si existe)
9. **`instruccion_usuario`** (si aplica, en `/revisar` y `/expandir`) — prioridad absoluta

---

## Memoria

1. `config.json` — slug, capítulo activo, `ultimo_beat_id`, `hilos` (si multi-hilo)
2. Especificación de entidades relevantes para el capítulo
3. **Hilo(s) activo(s)** del capítulo (de la tabla de trenzado) — filtra entidades

Output: briefing de ~600 tokens con estructura definida en el agente `memoria`.

---

## Cronista

1. `draft.md` del capítulo completado — fuente única de verdad
2. `config.json` — novela, hilos, estado
3. **Hilo(s) activo(s)** del capítulo — para filtrar entidades y summaries

Carga también `auditoria-neo4j` para el protocolo de auditoría.

## Entidades

1. Nombre, tipo y descripción de la entidad a crear/actualizar
2. Contexto narrativo — para coherencia
3. Si es actualización: campos específicos a modificar + registro de desarrollo
