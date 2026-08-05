---
name: contexto-subagente
description: Define el contexto mínimo para subagentes de novela multi-hilo usando proyecto, stable_id, parent_id, nivel, seq local e hilo.
compatibility: opencode
---

# Contexto de subagentes — Novela Multi-Hilo

## Contrato común

Todo briefing comienza con `proyecto`. Todo capítulo multi-hilo declara los `stable_id` de sus hilos activos. Cada beat incluye:

```text
stable_id, seq, parent_id, acción, tono, extensión, hilo
```

- `stable_id` es inmutable.
- `seq` siempre es local a `parent_id`.
- `hilo` es el `stable_id` de una entidad `tipo=hilo`; `[Hilos: hilo-S]` es solo anotación humana.
- `i9j0k1l2 [34]` se deriva de `seq: 34` para presentación y nunca es identidad.
- Renumerar cambia solo `seq`, filtrado por `parent_id` y `hilo` cuando aplique.
- Summaries se buscan por `(nivel, parent_id, seq[, hilo])`; el UUID físico nunca es entrada.

## Guionista

### Modo estructura-novela

1. `proyecto`.
2. Hechos de `_actos.md`, con `stable_id`, `seq`, `parent_id` y `hilo` cuando estén materializados.
3. `BRIEF.md`.
4. `config.json`, hilos activos por `stable_id` y estilo.

### Modo capítulo — pasada 1

1. `proyecto`.
2. Capítulo: `stable_id`, `seq`, `parent_id`, función y tipo de trenzado.
3. Hilos activos: nombre, slug humano y `stable_id` canónico.
4. Hechos por `stable_id [seq]` y `stable_id` de hilo.
5. Últimos 5-8 beats del capítulo anterior con contrato común.
6. Briefing de memoria y estilo.

### Modo capítulo — pasada 2, inyección `[D]`

1. `proyecto`, capítulo e hilos activos por `stable_id`.
2. `cola_d.md` con `tras <stable_id> (B_NNNN) en Escena N`.
3. Beats anterior y posterior con contrato común.
4. Escena receptora: `stable_id`, `seq`, `parent_id`, `hilo`, objetivo, tensión y tono.
5. `BRIEF.md`.
6. Instrucción de `renumber-siblings`: cambiar solo `seq` dentro del mismo `parent_id` e hilo.

## Escritor

### Modo normal

1. `proyecto`.
2. Capítulo, escena y bloque de hilo actuales.
3. `stable_id` del hilo activo y slugs solo como ayudas humanas.
4. Fichas relevantes por `stable_id`.
5. **TODOS los beats ya escritos de la escena actual** (prosa en `draft.md`, desde el primero de la escena) + siguientes tres del guion. Si es primer beat de escena: últimos 3 beats del bloque anterior.
6. Beat actual: `stable_id`, `seq`, `parent_id`, acción, tono, extensión e hilo.
7. Personajes, zona y props declarados.
8. Display derivado opcional, nunca usado para lookup.
9. Nombre de escena, `total_beats`, `beat_index` y estilo.

### Modo novela con memoria

Añade:

10. Briefing de memoria filtrado por los stable IDs de hilo.
11. Premisa y posición del capítulo.
12. En capítulos puente o espejo, contexto mínimo del otro hilo y fichas de conexión.

### Modo expansión

Añade el beat siguiente y su hilo. La expansión conserva `stable_id` y `seq` salvo reordenamiento explícito.

## Validador

### Modo beat

1. `proyecto`.
2. Texto del beat.
3. Beat de guion: `stable_id`, `seq`, `parent_id`, acción, tono, extensión e hilo.
4. Fichas relevantes.
5. TODOS los beats ya escritos de la escena actual (prosa en `draft.md`, desde el primero) + el beat actual + siguientes tres del guion. Si el beat actual abre escena: últimos 3 beats del bloque anterior.
6. Hilos activos por `stable_id`, personajes, zona, props, scores, scope y estilo.
7. Contexto cross-hilo si el capítulo tiene más de un hilo.

### Modo global

1. `proyecto`.
2. Draft completo.
3. L4, L3 y L2 con sus resultados de `stable_id`, `seq`, `parent_id`, `nivel` e `hilo`.
4. Tabla de trenzado.
5. Entidades de hilos activos por `stable_id`.
6. Fichas de conexión, estilo, scope y validación cross-hilo.

## Integrador

1. `proyecto`.
2. Beat localizado por `stable_id`.
3. Feedback del validador.
4. Beat de guion con contrato común, incluido hilo.
5. Fichas, TODOS los beats ya escritos de la escena actual (prosa en `draft.md`) + el beat a reescribir + siguientes tres del guion, trenzado y estilo.
6. `instruccion_usuario` si aplica.

No cambia `stable_id`. Si el cambio exige mover el beat a otro bloque, el director decide el nuevo `parent_id` e hilo y renumera `seq` de forma atómica.

## Memoria

1. `proyecto`.
2. Capítulo: `stable_id`, `seq`, `parent_id`.
3. Hilos activos: `stable_id`, nombre y estado.
4. Entidades relevantes por `stable_id`, filtradas por hilo.
5. Conexiones cross-hilo pendientes y objetivo del capítulo.
6. Referencias `tipo=referencia` con tag `relevancia_por_hilo:<stable_id_hilo>` (máx. 2; resumen, no contenido completo).

Output: briefing L4 → L3 → L2 → entidades → relaciones → hilos → referencias, mostrando stable IDs, posición e hilo.

## Cronista — modo único cross-hilo

1. `proyecto`.
2. `Instrucción` concreta; no selector de submodo.
3. `Leer`: `draft.md`, `guion.md`, `config.json`, fichas, diseños de hilo y conexiones.
4. Capítulo, arco y escenas con `stable_id`, `seq`, `parent_id`, `nivel` e `hilo`.
5. Entidades relevantes por `stable_id`.

Carga `cronista-ops`, `qdrant` y `auditoria-neo4j`. Persiste summaries por `(nivel, parent_id, seq[, hilo])`, usando el `stable_id` del hilo.

## Entidades

1. `proyecto`, nombre, tipo y descripción.
2. `stable_id` si actualiza; UUID nuevo opaco si crea.
3. Hilos afectados por `stable_id`.
4. Contexto narrativo, campos y registro de desarrollo.

