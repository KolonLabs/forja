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
- `hilo` es el `stable_id` de una entidad `tipo=hilo`; `[Hilos: hilo-<slug>]` es solo anotación humana.
- `i9j0k1l2 [34]` se deriva de `seq: 34` para presentación y nunca es identidad.
- Renumerar cambia solo `seq`, filtrado por `parent_id` y `hilo` cuando aplique.
- Summaries se buscan por `(nivel, parent_id, seq[, hilo])`; el UUID físico nunca es entrada.

## Guionista

Cuatro modos: `hilo`, `hilo-capitulo`, `trenzado`, `revision`. Cada uno recibe **solo** lo que necesita — nunca `diseno-hilo.md` ni `guion-hilo.md` íntegros salvo en modo `hilo`.

### Modo `hilo`

1. `proyecto`.
2. `hilos/hilo-<slug>/diseno-hilo.md` (decisiones firmes de diseño de este hilo).
3. `BRIEF.md`.
4. `config.json`: hilos, estilo activo, `ultimo_hecho_seq`.

Salida: `hilos/hilo-<slug>/guion-hilo.md` — solo hechos `H_NNNN` agrupados por acto, sin beats.

### Modo `hilo-capitulo`

1. `proyecto`.
2. Capítulo-borrador actual: rango de hechos (`stable_id [seq]`), objetivo narrativo y tensión — campos cortos, **no** `diseno-hilo.md` ni `guion-hilo.md` íntegros.
3. Últimos beats del capítulo-borrador anterior del mismo hilo (contrato de continuidad).
4. Resumen compacto de entidades y relaciones relevantes (estilo `memoria`).
5. Si el rango contiene `[D]`: `hilos/hilo-<slug>/cola_d.md` (instancias ya escritas en capítulos-borrador anteriores del mismo `[D]`, con `stable_id` + escena + resumen — no solo el conteo).
6. IDs: asignar `seq` desde `ultimo_beat_seq`; generar `stable_id` opaco para cada beat y escena nuevos.

Flujo:
- **Sin `[D]` en el rango**: una sola pasada — genera beats de todos los hechos del rango y agrúpalos en escenas por coherencia de contexto. Marcador `<!-- ESCENA <stable_id>: Nombre -->`. Sin renumeración (posiciones nuevas).
- **Con `[D]` en el rango**: primero **Checkpoint 1** — propone el plan de instancias (qué y cuántas, sin fórmula fija) sin escribir beats todavía. Tras validación del director + usuario: genera la secuencia completa (lineales + `[D]` entretejidos) en una sola pasada y agrupa en escenas — **Checkpoint 2** revisa el resultado contra `cola_d.md`.

Salida: `hilos/hilo-<slug>/cap-NN/guion.md`. El director (no el guionista) actualiza `cola_d.md` tras el Checkpoint 2.

### Modo `trenzado`

1. `proyecto`.
2. Todos `hilos/hilo-*/cap-NN/guion.md` (contenido **completo**: beats, personajes, objetos — no solo metadatos; `[D]` ya resuelto).
3. `guion-novela.md`, sección `## Puntos de conexión` — pista temática escrita en FASE 0, antes de que existiera ninguna escena; no es una lista a verificar mecánicamente.
4. `config.json.hilos` (stable_id de cada hilo).
5. Reglas de alternancia (skill `trenzado-narrativo`): máx. 2 hilos/capítulo, racha máx. 3 caps sin un hilo, clímax en capítulo exclusivo.

Tarea: descubre en el contenido real dónde se materializa cada conexión —y cualquier eco orgánico no previsto—, no solo lo ya anotado.

Salida: mueve cada bloque de escena completo a `capitulos/cap-NN-slug/guion.md` (`renumber-siblings` en `parent_id`/`seq`; `stable_id` no cambia), genera la tabla `## Trenzado`, reescribe `## Puntos de conexión` con `stable_id` de escena concretos.

### Modo `revision`

1. `proyecto`.
2. Tramo: beats `[stable_id...]` con sus acciones actuales.
3. Contexto bilateral: 5-8 beats antes y después del tramo.
4. `AGENTS.md`.
5. Si `estado==escritura`: briefing ligero de `memoria` (~300 tokens).
6. Instrucción concreta: qué problema corregir (costura cross-hilo, transición brusca, cobertura insuficiente, tono inconsistente).

Salida: reemplaza solo el tramo indicado, en el mismo archivo leído (`capitulos/cap-NN-slug/guion.md` tras el trenzado, o `hilos/hilo-<slug>/cap-NN/guion.md` si es previo). Mismos `stable_id` salvo que la instrucción pida añadir/eliminar beats.

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
