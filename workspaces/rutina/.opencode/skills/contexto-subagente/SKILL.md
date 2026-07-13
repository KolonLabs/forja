---
name: contexto-subagente
description: Define qué contexto necesita cada subagente (escritor, validador, integrador, entidades) para un relato. El director lo carga antes de invocar cualquier subagente.
compatibility: opencode
---

# Skill: contexto-subagente

## Cuándo usar

El director carga este skill antes de invocar cualquier subagente. Define qué información pasarle para que tenga lo necesario sin sobrecargarlo.

---

## Escritor

### Modo normal (escritura de beat)

1. **Guion de la escena actual** — la escena del `guion.md` que contiene este beat (objetivo, tensión, transición)
2. **Fichas relevantes inline** — personajes y lugar de la escena actual (campos `fijo`)
3. **Últimos 5 beats del draft** — ventana de contexto para variedad léxica y continuidad
4. **Beat actual** — ID, acción, tono, extensión
5. **Nombre de escena** — si es el primer beat de una escena nueva
6. **`total_beats` del relato** y **`beat_index`** — para calibrar cadencia
7. **Estilo activo** — nombre (de `config.json`)

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
8. **Estilo activo** — nombre

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
5. **Últimos 5 beats del draft** — ventana de continuidad
6. **Bloque de escena del guion** — objetivo, tensión
7. **Estilo activo** — nombre
8. **Beat siguiente del draft** (si existe)
9. **`instruccion_usuario`** (si aplica, en `/revisar` y `/expandir`) — prioridad absoluta

---

## Entidades

1. Nombre, tipo y descripción de la entidad a crear/actualizar
2. Contexto narrativo — para coherencia
3. Si es actualización: campos específicos a modificar + registro de desarrollo
