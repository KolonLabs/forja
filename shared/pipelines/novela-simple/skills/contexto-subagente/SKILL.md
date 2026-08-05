---
name: contexto-subagente
description: Define el contexto mínimo para subagentes de novela simple usando proyecto, stable_id, parent_id, nivel y seq local al padre.
compatibility: opencode
---

# Contexto de subagentes — Novela Simple

## Contrato común

Todo briefing comienza con `proyecto` y, para cada beat, incluye:

```text
stable_id, seq, parent_id, acción, tono, extensión
```

- `stable_id` es inmutable.
- `seq` siempre es local a `parent_id`.
- `i9j0k1l2 [34]` se deriva de `seq: 34` en presentación y nunca es identidad persistida.
- Renumerar cambia solo `seq` mediante las operaciones de `cronista-ops`.
- Summaries se describen por `nivel`, `parent_id` y `seq`; el UUID físico nunca es entrada.

## Guionista

### Modo estructura-novela

1. `proyecto`.
2. Hechos de `_actos.md`, con `stable_id`, `seq` y `parent_id` cuando estén materializados.
3. `BRIEF.md`.
4. `config.json` y estilo.

### Modo capítulo — pasada 1 (beats)

1. `proyecto`.
2. Capítulo: `stable_id`, `seq`, `parent_id` y función narrativa.
3. Hechos del capítulo por `stable_id [seq]`.
4. Últimos 5-8 beats del capítulo anterior con contrato común.
5. Briefing de memoria.
6. Estilo activo.
7. **Sin marcadores `<!-- ESCENA ... -->`**. Salida: beats en bruto, sin agrupar en escenas.

### Modo capítulo — pasada 2 (escenas)

1. `proyecto`, capítulo actual.
2. `capitulos/cap-NN-slug/guion.md` con los beats ya generados en pasada 1.
3. Criterio de agrupación: coherencia de contexto (mismo espacio, tiempo y cast). Una escena puede envolver beats de varios hechos; un hecho largo puede fraccionarse en dos escenas si hay corte de contexto.
4. Generar `stable_id` opaco para cada escena nueva.
5. Insertar `<!-- ESCENA <stable_id>: Nombre -->` antes del primer beat de cada escena. **No modificar los beats** — solo agrupar.
6. No hay renumeración: la posición de los beats no cambia.

## Escritor

### Modo normal

1. `proyecto`.
2. Guion de la escena actual.
3. Fichas relevantes inline por `stable_id`.
4. **TODOS los beats ya escritos de la escena actual** (prosa en `draft.md`, desde el primero de la escena) + siguientes tres del guion. Si es primer beat de escena: últimos 3 beats de la escena anterior.
5. Beat actual: `stable_id`, `seq`, `parent_id`, acción, tono y extensión.
6. Personajes, zona y props declarados.
7. Display derivado opcional, nunca usado para lookup.
8. Nombre de escena, `total_beats`, `beat_index` y estilo.

### Modo novela con memoria

Añade:

9. Briefing de memoria de unas 600 palabras.
10. Premisa y posición del capítulo (`stable_id`, `seq`, `parent_id`).

### Modo expansión

Añade el beat siguiente del draft para conservar la transición. La expansión mantiene `stable_id` y `seq`.

## Validador

### Modo beat

1. `proyecto`.
2. Texto del beat.
3. Beat de guion: `stable_id`, `seq`, `parent_id`, acción, tono y extensión.
4. Fichas relevantes.
5. TODOS los beats ya escritos de la escena actual (prosa en `draft.md`, desde el primero) + el beat actual + siguientes tres del guion. Si el beat actual abre escena: últimos 3 beats de la escena anterior.
6. Scores previos, scope, personajes, zona, props y estilo.

### Modo global

1. `proyecto`.
2. Draft completo.
3. Summary L4 y sección de arco, con `nivel`, `stable_id`, `seq` y `parent_id` en el resultado.
4. Entidad de hilo activo por `stable_id`, sin prefijo semántico.
5. Fichas relevantes, estilo y scope.

## Integrador

1. `proyecto`.
2. Beat localizado por `stable_id`.
3. Feedback del validador.
4. Beat de guion con contrato común.
5. Fichas, TODOS los beats ya escritos de la escena actual (prosa en `draft.md`) + el beat a reescribir + siguientes tres del guion y estilo.
6. `instruccion_usuario` si aplica.

No cambia `stable_id`; una reescritura conserva identidad y posición salvo reordenamiento explícito.

## Memoria

1. `proyecto`.
2. Capítulo: `stable_id`, `seq`, `parent_id`.
3. Entidades relevantes por `stable_id`.
4. `stable_id` del hilo implícito si existe como entidad.
5. Objetivo del capítulo.
6. Referencias `tipo=referencia` relevantes al objetivo del capítulo (máx. 2; resumen, no contenido completo).

Output: briefing estructurado por L4 → L3 → L2 → entidades → relaciones → referencias, mostrando stable IDs y posición.

## Cronista — modo único

1. `proyecto`.
2. `Instrucción` concreta; no selector de submodo.
3. `Leer`: `draft.md`, `guion.md`, `config.json` y fichas relevantes.
4. Capítulo, arco y escenas con `stable_id`, `seq`, `parent_id` y `nivel`.
5. Entidades relevantes por `stable_id`.

Carga `cronista-ops`, `qdrant` y `auditoria-neo4j`. Los summaries se persisten por `(nivel, parent_id, seq)`.

## Entidades

1. `proyecto`, nombre, tipo y descripción.
2. `stable_id` si actualiza; UUID nuevo opaco si crea.
3. Contexto narrativo.
4. Campos y registro de desarrollo.

