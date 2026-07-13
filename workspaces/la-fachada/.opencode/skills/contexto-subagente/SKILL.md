---
name: contexto-subagente
description: Define qué contexto necesita cada subagente (escritor, validador, integrador, entidades) para un relato. El director lo carga antes de invocar cualquier subagente.
compatibility: opencode
---

# Skill: contexto-subagente

## Cuándo usar

El director carga este skill antes de invocar cualquier subagente. Define qué información pasarle para que tenga lo necesario sin sobrecargarlo.

---

## Guionista

### Modo estructura — pasada 1 (lineales)

1. **Hechos del acto actual** — solo los hechos lineales del acto que se va a generar
2. **Últimos 5-8 beats del acto anterior** (si es Acto II o III) — contexto para transición de tono y continuidad narrativa. Leídos del `guion.md` ya generado.
3. **BRIEF.md** y **AGENTS.md** — referencia de tono, estilo, restricciones
4. **IDs desde `config.json`** — `ultimo_hecho_global` y `ultimo_beat_global`

### Modo estructura — pasada 2 (inyección `[D]`)

1. **`cola_d.md`** — anotaciones del director con ubicación exacta de cada inyección
2. **Beat anterior y posterior** al punto de inserción (1 beat a cada lado) — contexto bilateral mínimo para escribir un beat que fluya con sus vecinos
3. **Escena que contiene el punto de inserción** — objetivo, tensión, tono
4. **BRIEF.md** — para mantener coherencia con personajes y arco

### Modo escena

1. **Hechos de la escena actual** — del `guion.md`
2. **Últimos 5 beats de la escena anterior** — para continuidad de tono y ritmo
3. **Primeros 3 beats de la escena siguiente** (si existe en `guion.md`) — para preparar la transición de salida
4. **AGENTS.md** — estilo, tono, restricciones

---

## Escritor

### Modo normal (escritura de beat)

1. **Guion de la escena actual** — la escena del `guion.md` que contiene este beat (objetivo, tensión, transición)
2. **Fichas relevantes inline** — personajes y lugar de la escena actual (campos `fijo`)
3. **Últimos 5 beats del draft** — ventana de contexto para variedad léxica y continuidad
4. **Siguientes 3 beats del guion** — planificación de lo que viene (leídos de `guion.md`, no tienen prosa aún en el draft). Ayudan al escritor a preparar la salida del beat actual hacia lo que sigue.
5. **Beat actual** — ID, acción, tono, extensión
6. **Nombre de escena** — si es el primer beat de una escena nueva
7. **`total_beats` del relato** y **`beat_index`** — para calibrar cadencia
8. **Estilo activo** — nombre (de `config.json`)

---

## Validador

### Modo beat

1. **Texto del beat** — generado por el escritor
2. **Beat del guion** — ID, acción, tono, extensión
3. **Fichas relevantes inline** — personajes y lugar de la escena
4. **Bloque de escena del guion** — objetivo, tensión, transición
5. **Últimos 5 beats del draft** — ventana de continuidad
6. **Siguientes 3 beats del guion** — para validar que la transición hacia adelante es coherente
7. **Scores del validador del beat anterior** — para no repetir advertencias
8. **Scope** — lista de dimensiones a evaluar o `global`
9. **Estilo activo** — nombre

### Modo global

1. **Draft completo del relato**
2. **`guion.md` completo** — estructura planificada
3. **Fichas de todos los personajes y lugares** — fuente de verdad
4. **Estilo activo** — nombre
5. **Scope** — dimensiones a evaluar

---

## Integrador

1. **Beat a corregir** — texto original
2. **Feedback del validador** — JSON consolidado de evaluación
3. **Fichas relevantes inline** — personajes y lugar
4. **Beat del guion** — ID, acción, tono, extensión
5. **Últimos 5 beats del draft** — ventana de continuidad hacia atrás
6. **Siguientes 3 beats del draft** — ventana de continuidad hacia adelante (si existen)
7. **Bloque de escena del guion** — objetivo, tensión
8. **Estilo activo** — nombre
9. **`instruccion_usuario`** (si aplica, en `/revisar` y `/expandir`) — prioridad absoluta

---

## Entidades

1. Nombre, tipo y descripción de la entidad a crear/actualizar
2. Contexto narrativo — para coherencia
3. Si es actualización: campos específicos a modificar + registro de desarrollo
