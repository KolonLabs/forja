---
name: contexto-subagente
description: Define el contexto mínimo para subagentes de relato usando proyecto, stable_id, parent_id y seq local al padre.
compatibility: opencode
---

# Contexto de subagentes — Relato

## Contrato común

Todo briefing que mencione un beat incluye:

```text
stable_id, seq, parent_id, acción, tono, extensión
```

Reglas:

- `stable_id` es la identidad inmutable.
- `seq` es posición local a `parent_id`.
- Un display como `i9j0k1l2 [34]` se deriva de `seq: 34` solo para lectura humana.
- Al reordenar, solo cambia `seq`; `stable_id` permanece intacto.
- Las referencias cruzadas y puntos de inserción usan `stable_id`, nunca el display.

## Guionista

### Modo estructura — pasada 1

1. Hechos lineales del acto actual.
2. Últimos 5-8 beats del acto anterior, cada uno con `stable_id`, `seq`, `parent_id`, acción, tono y extensión.
3. `BRIEF.md` y `AGENTS.md`.
4. Estado de `config.json` y último `stable_id` conocido; no tratar el display como contador persistido.

### Modo estructura — pasada 2, inyección `[D]`

1. `cola_d.md` con puntos `tras <stable_id> (B_NNNN) en Escena N`.
2. Beat anterior y posterior al punto, ambos con el contrato común.
3. Escena receptora: `stable_id`, objetivo, tensión y tono.
4. `BRIEF.md`.
5. Instrucción de reordenamiento: aplicar `renumber-siblings`; cambiar solo `seq` local al padre.

### Modo escena

1. Hechos de la escena actual.
2. Escena: `stable_id`, `seq`, `parent_id`, objetivo y transición.
3. Últimos cinco beats de la escena anterior.
4. Primeros tres beats de la siguiente.
5. `AGENTS.md`.

## Escritor

### Modo normal

1. Guion de la escena actual.
2. Fichas relevantes inline, referenciadas por `stable_id`.
3. Beats ya escritos necesarios para continuidad, cada uno identificado por `stable_id` y `seq`.
4. Siguientes tres beats del guion.
5. Beat actual: `stable_id`, `seq`, `parent_id`, acción, tono y extensión.
6. Display derivado opcional, por ejemplo `i9j0k1l2 [34]`; nunca usarlo para lookup.
7. Nombre de escena si abre una nueva.
8. `total_beats`, `beat_index` y estilo activo.

## Validador

### Modo beat

1. Texto del beat.
2. Beat de guion: `stable_id`, `seq`, `parent_id`, acción, tono y extensión.
3. Fichas relevantes por `stable_id`.
4. Bloque de escena.
5. Ventana anterior y siguientes tres beats.
6. Scores previos.
7. Scope y estilo.

### Modo global

1. Draft completo.
2. `guion.md` completo.
3. Fichas de personajes y lugares.
4. Estilo y scope.
5. Verificación de que displays derivados coincidan con `seq` sin sustituir `stable_id`.

## Integrador

1. Beat a corregir localizado por `stable_id`.
2. Texto original y feedback.
3. Beat de guion: `stable_id`, `seq`, `parent_id`, acción, tono y extensión.
4. Fichas relevantes.
5. Ventanas anterior y posterior.
6. Bloque de escena y estilo.
7. `instruccion_usuario` si aplica.

Nunca cambia `stable_id`; una corrección o expansión modifica texto, no identidad.

## Entidades

1. `proyecto`, nombre, tipo y descripción.
2. `stable_id` si es actualización; se genera una sola vez si es creación.
3. Contexto narrativo.
4. Campos concretos y registro de desarrollo.

## Cierre de escena — contexto narrativo

El director actualiza `contexto_narrativo.md` al cerrar cada escena. El formato y protocolo estan definidos en el skill `contexto-narrativo`. El escritor recibe el contexto acumulado inline en cada briefing de beat durante FASE 3.

