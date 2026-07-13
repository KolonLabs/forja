---
name: cronista-ops
description: Operaciones atómicas sobre Qdrant y Neo4j para gestión de memoria narrativa. Documenta el modelo de datos, los comandos CLI y las convenciones de búsqueda. Cargado por el director y el cronista.
---

# cronista-ops — Modelo de datos y operaciones

Este skill documenta cómo operar sobre Qdrant y Neo4j para gestionar la memoria de un proyecto narrativo (novela simple o multi-hilo). No es una guía de Qdrant o Neo4j en general; es la referencia específica del modelo de Forja.

## Modelo de datos

### Identificadores

| Elemento | Identificador (stable_id) | Display (derivado) |
|----------|:---:|---------|
| Beat (L0) | UUID8 | `B_{seq:04d}` → a1b2c3d4 |
| Escena/bloque (L1) | UUID8 | `E_{seq:03d}` → e1e2e3e4 |
| Capítulo (L2) | UUID8 | `C_{seq:03d}` → c1c2c3c4 |
| Acto (L3) | UUID8 | `A_{seq:03d}` → a0a1a2a3 |
| Novela (L4) | UUID8 | `global` |
| Entidad (personaje, lugar, etc.) | UUID8 | (por nombre) |

- **`stable_id` (UUID8) es inmutable.** No cambia al renumerar.
- **`seq` es local al padre.** El L1.3 del cap 5 es la tercera escena del capítulo 5, no la tercera escena del acto.
- **El display se deriva de `seq` al presentar.** Nunca se almacena.

### Colecciones Qdrant

- **`beats`**: cada beat con su acción, tono, extensión, prosa y entidades referenciadas.
- **`summaries`**: niveles L1-L4. El nivel L4 es único (stable_id="global").
- **`entidades`**: personajes, lugares, objetos, hilos, etc. Con `tipo` y `tags`.

### Niveles en `summaries`

- **L1**: escena o bloque de hilo dentro de un capítulo. Tiene `parent_id` apuntando al L2.
- **L2**: capítulo. Tiene `parent_id` apuntando al L3 (acto).
- **L3**: acto. Tiene `parent_id` apuntando al L4 (novela). Si es multi-hilo, tiene `hilo` apuntando al hilo.
- **L4**: novela. `parent_id` vacío. `stable_id = "global"`.

### Regla fundamental de búsqueda

> **NUNCA se busca por UUID.** Se busca por posición: `(nivel, parent_id, seq[, hilo])`. El UUID se obtiene como **resultado** de la búsqueda, no como punto de partida.

Esto sobrevive a renumeraciones. Si el L1 "escena 3 del capítulo 5" pasa a ser "escena 4 del capítulo 5", basta con buscar `seq=4` en el mismo `parent_id`.

## Comandos Qdrant (qdrant.py)

### Por proyecto

Todos los comandos usan `--proyecto SLUG` para aislar por workspace.

### Beats

```bash
# Crear o reemplazar un beat
qdrant.py upsert-beat --proyecto X --beat a1b2c3d4 --accion "Laura se arrodilla" \
  --parent-id e1e2e3e4 --seq 34 --tono "Opresivo" --extension MEDIA \
  --fichas '["11111111","33333333"]'

# Actualizar campos estructurales
qdrant.py update-beat --proyecto X --beat a1b2c3d4 --seq 35 --parent-id e1e2e3e4

# Añadir prosa y re-embed
qdrant.py enrich-beat --proyecto X --beat a1b2c3d4 --narrative "Laura cayó de rodillas..."
```

### Summaries (búsqueda por posición)

```bash
# Buscar un summary por su posición
qdrant.py query-summary-by-position --proyecto X --nivel L1 --parent-id c5c6c7c8 --seq 3

# Crear o reemplazar idempotente
qdrant.py upsert-summary-by-position --proyecto X --nivel L1 --parent-id c5c6c7c8 --seq 3 \
  --texto "Resumen de la escena..." [--hilo <uuid>]

# Renumerar hermanos (tras insertar o eliminar)
qdrant.py renumber-siblings --proyecto X --nivel L1 --parent-id c5c6c7c8 --from-seq 4 \
  --direction up|down [--step N] [--hilo <uuid>]

# Buscar L2 recientes
qdrant.py query-l2-recent --proyecto X --current-id c5c6c7c8 --last 3

# Buscar L3 (actos cerrados)
qdrant.py query-l3 --proyecto X [--arco a0a1a2a3]

# Obtener L4 (novela)
qdrant.py query-l4-current --proyecto X

# Crear o reemplazar un summary por stable_id directo (uso raro)
qdrant.py upsert-summary --proyecto X --nivel L1 --id e1e2e3e4 --seq 3 \
  --parent-id c5c6c7c8 --texto "..." [--hilo <uuid>]
```

### Entidades

```bash
# Crear o reemplazar
qdrant.py upsert-entity --proyecto X --stable-id 11111111 --tipo personaje \
  --nombre "Laura" --slug "laura" --fijo "Madre, 38 años..." \
  --tags "madre,esposa" --dinamico '{"estado_operativo": {"estado": "activa"}}'

# Actualizar campos
qdrant.py update-entity --proyecto X --stable-id 11111111 --dinamico '{"estado_operativo": {"ubicacion": "casa"}}'

# Consultar
qdrant.py query-entity --proyecto X --stable-id 11111111
qdrant.py query-entities --proyecto X --tipo personaje [--tag muerta]
qdrant.py query-entities-by-text --proyecto X --text "madre de familia"
```

### Búsqueda semántica

```bash
# Búsqueda semántica en beats
qdrant.py query --proyecto X --text "escena de dominación en la cocina" --limit 5

# Búsqueda de capítulos relevantes (dos pasos)
qdrant.py query-chapters-by-beat --proyecto X --text "Laura pierde agencia" --top-chapters 3
```

## Comandos Neo4j (neo4j.py)

### Relaciones persona-persona (con rol)

```bash
neo4j.py upsert-relationship --proyecto X --from-stable-id 11111111 --to-stable-id 22222222 \
  --type PAREJA_DE --rol esposa

neo4j.py upsert-relationship --proyecto X --from-stable-id 22222222 --to-stable-id 33333333 \
  --type SENTIMIENTO_HACIA --rol odio
```

### Relaciones cross-entity (sin rol)

```bash
neo4j.py upsert-relationship --proyecto X --from-stable-id 11111111 --to-stable-id 44444444 \
  --type VIVE_EN

neo4j.py upsert-relationship --proyecto X --from-stable-id 33333333 --to-stable-id 55555555 \
  --type FRECUENTA
```

### Consultar

```bash
neo4j.py query-relationships --proyecto X --stable-id 11111111
```

## Convenciones de operación

### Idempotencia

Todas las operaciones de escritura son idempotentes:
- `upsert-beat` con mismo `--beat` y `--proyecto` sobreescribe.
- `upsert-summary-by-position` busca por `(nivel, parent_id, seq)`; si existe, actualiza; si no, crea.
- `upsert-entity` con mismo `--stable-id` sobreescribe.

Esto permite al cronista y al director reintentar operaciones sin crear duplicados.

### Reglas del director

- **Solo actualiza `dinamico` ante cambios inequívocos.** Si duda, no actualiza — deja que el cronista lo detecte desde la prosa en FASE 2.5.
- **Usa el LLM como criterio, no como verificador mecánico.** El LLM evalúa si un cambio de estado es explícito en el beat.
- **Si las colecciones están vacías, informa al usuario y ofrece inicializar.** No asumas que hay datos en Qdrant/Neo4j.

### Reglas del cronista

- **Procesa capítulo completo solo cuando se le pide.** Un solo modo. Invocado con instrucción concreta: "procesa el capítulo completo desde draft.md" o "actualiza Laura: estado → sin_agencia".
- **Carga este skill (cronista-ops) para conocer los comandos.**
- **Usa búsqueda por posición, nunca por UUID.** El UUID se obtiene como resultado, no como entrada.

## Operaciones compuestas habituales

| Operación | Secuencia de comandos |
|-----------|----------------------|
| Seed de acto (L3) | `upsert-summary-by-position --nivel L3 --parent-id global --seq N --texto "..." [--hilo <uuid>]` |
| Seed de novela (L4) | `upsert-summary-by-position --nivel L4 --parent-id "" --seq 0 --texto "..."` (crea con nuevo stable_id si no existe) |
| Seed de capítulo (L2) | `upsert-summary-by-position --nivel L2 --parent-id <L3_stable_id> --seq N --texto "..."` |
| Seed de escena (L1) | `upsert-summary-by-position --nivel L1 --parent-id <L2_stable_id> --seq N --texto "..." [--hilo <uuid>]` |
| Reordenar escenas dentro de un capítulo | `renumber-siblings --nivel L1 --parent-id <L2_stable_id> --from-seq 5 --direction up\|down` |
| Insertar escena en medio | Crear L1 con `seq=5` → `renumber-siblings --from-seq 5 --direction up --step 1` |
| Eliminar escena | `query-summary-by-position` para obtener UUID → eliminar (no hay comando directo, usar `delete-point` o eliminar desde L0 primero) |
| Actualizar `dinamico` de entidad | `update-entity --stable-id <id> --dinamico '{"...": "..."}'` |

## Jerarquía multi-hilo

### Hilo como atributo (no nivel)

Los hilos no son un nivel estructural. Son un campo `hilo` en el payload de L1 y L3:
- L1 con `hilo: <uuid>` = bloque de hilo dentro de un capítulo
- L3 con `hilo: <uuid>` = acto de un hilo específico
- L2 (capítulo) sin `hilo` = global, puede contener bloques de varios hilos
- L4 (novela) sin `hilo` = global

Las entidades pueden tener `tags: ["hilo-madrid", "hilo-sumeria"]` para indicar que aparecen en varios hilos.

### Búsqueda con filtro de hilo

```bash
# L1 del hilo-sumeria en el capítulo 5
qdrant.py query-summary-by-position --nivel L1 --parent-id c5c6c7c8 --seq 3 --hilo <h_sumeria_uuid>

# Renumerar solo los L1 de un hilo
qdrant.py renumber-siblings --nivel L1 --parent-id c5c6c7c8 --from-seq 5 --direction up --hilo <h_sumeria_uuid>
```

## Carga de este skill

Quién lo carga:
- **`director`** (novela-simple + multi-hilo): para operaciones quirúrgicas en conversación.
- **`cronista`** (shared): para operaciones batch en FASE 2.5.

El skill no define lógica de negocio — solo el modelo de datos y los comandos disponibles.

