---
name: qdrant
description: Schema, IDs y guía operativa de Qdrant para el sistema de novelas. Cárgalo cuando necesites crear, actualizar o consultar entries en Qdrant.
---

# Qdrant — Schema y guía operativa

## Infraestructura

| Parámetro | Valor |
|-----------|-------|
| URL | `http://localhost:6333` (o `$QDRANT_URL`) |
| Script helper | `scripts/qdrant.py` |
| Modelo embedding | `intfloat/multilingual-e5-large` (1024d, multilingüe) |
| Librería | `fastembed` — `pip install fastembed` |

**Tres colecciones**: `beats` (L0), `summaries` (L1/L2/L3/L4), `entidades` (personajes, lugares, etc.).

**Todos los resúmenes viven exclusivamente en Qdrant**. No hay archivos Markdown de resúmenes en el flujo. Si el briefing de memoria necesita L1/L2/L3/L4, los consulta a Qdrant.

---

## IDs — modelo unificado jerárquico

Cada nivel tiene un prefijo de letra y numeración global posicional en la novela. Si reordenas, los IDs se renumeran (operación batch explícita).

| Nivel | Tipo | Formato | Ejemplo | Notas |
|-------|------|---------|---------|-------|
| L0 | Beat | `B_NNNN` (4 dígitos) | `B_0005` | El 5º beat de la novela |
| L1 | Escena | `E_NNN` (3 dígitos) | `E_323` | La 323ª escena de la novela |
| L2 | Capítulo | `C_NNN` (3 dígitos) | `C_121` | El 121er capítulo |
| L3 | Arco | `A_NNN` (3 dígitos) | `A_001` | El 1er arco |
| L4 | Novela | `global` | `global` | Constante |
| — | Entity | `<tipo>-<slug>` | `per-ana-lopez` | Slug semántico |

**Relación jerárquica** (un solo campo `parent_id` en summaries):

| Nivel | `id` | `parent_id` |
|-------|------|-------------|
| L0 (beat) | `B_0042` | `E_323` |
| L1 (escena) | `E_323` | `C_121` |
| L2 (cap) | `C_121` | `A_001` |
| L3 (arco) | `A_001` | `""` (vacío) |
| L4 (novela) | `global` | `""` (vacío) |

El `parent_id` apunta al nivel inmediatamente superior. La cadena lleva a la raíz.

**UUIDs deterministas** (Qdrant point IDs):
```
beats:     uuid5("{novela}:{id}")
summaries: uuid5("{novela}:{nivel}:{id}")
entidades: uuid5("{novela}:entidad:{id}")
```

El `id` es global, no necesita novela en el prefijo (la novela ya está en el UUID).

---

## Schema — colección `beats`

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `novela_slug` | string | Slug de la novela |
| `id` | string | ID lógico global: `B_0005` |
| `parent_id` | string | Escena a la que pertenece: `E_323` |
| `accion` | string | Acción del beat (guión) — **overwritable** por upsert |
| `tono` | string | Tono del beat |
| `extension` | string | `BREVE` · `MEDIA` · `EXTENSA` |
| `fichas` | string[] | IDs de entidades que aparecen (ej: `["per-ana-lopez","lug-casa-ana"]`) |
| `narrative_text` | string\|null | Texto narrativo. `null` hasta que el escritor lo añade |
| `vector_source` | string | `"guion"` o `"narrativa"` |

**Sin**: `cap_id` (derivable via escena → escena.parent_id), `has_narrative` (derivable de `narrative_text`), `cap_num`, `escena`.

**Vector**: `accion` → re-embed con `narrative_text`
**Payload indexes**: `novela_slug`, `parent_id`, `fichas`

---

## Schema — colección `summaries`

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `novela_slug` | string | Slug de la novela |
| `nivel` | string | `L1` · `L2` · `L3` · `L4` |
| `id` | string | ID lógico: `E_NNN` · `C_NNN` · `A_NNN` · `global` |
| `parent_id` | string | ID del nivel superior (vacío para L3/L4) |
| `title` | string | **Obligatorio**. Nombre humano (escena, cap, arco, novela) |
| `fichas` | string[] | IDs de entidades que aparecen |
| `summary` | string | Texto del resumen (también lo que se embebe) |

**Sin**: `cap_id` (reemplazado por `parent_id`), `arco` (reemplazado por `parent_id`), `cap_num`, `texto` (renombrado a `summary`).

**Vector**: `summary`
**Payload indexes**: `novela_slug`, `nivel`, `parent_id`, `fichas`

### Convenciones por nivel

| Nivel | `id` | `parent_id` | Cuándo se actualiza | Frecuencia |
|-------|------|-------------|---------------------|------------|
| L1 | `E_NNN` | `C_NNN` (el cap) | Cierre de cap por cronista (1 L1 por escena) | ~3-5 por cap |
| L2 | `C_NNN` | `A_NNN` (el arco) | Cierre de cap por cronista | 1 por cap |
| L3 | `A_NNN` | `""` | Cierre de arco por cronista | 1 por arco |
| L4 | `global` | `""` | Cronista si `cap % 10 == 0` o cierre de arco | Sobrescrito |

---

## Schema — colección `entidades`

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `novela_slug` | string | Slug de la novela |
| `id` | string | ID estable (incluye prefijo de tipo): `per-ana-lopez` |
| `tipo` | string | `personaje` · `lugar` · `objeto` · `animal` · `hilo` · `organizacion` · `arcos` · `evento` · `escena` |
| `nombre` | string | Display name (puede cambiar; el `id` es estable) |
| `tags` | string[] | Filtrado semántico (ej: `["muerto"]`, `["villano"]`) |
| `fijo` | string | **Embebido**. Descripción inmutable (cuerpo FIJO) |
| `dinamico` | string | Estado actual (actualizado por cronista al cierre de cada cap) |

**Sin**: `estado` (reemplazado por `tags`), `capitulo_creacion` (derivable).

**Vector**: `fijo`
**Payload indexes**: `novela_slug`, `id`, `tipo`, `tags`
**Sin `refs`**: relaciones viven en Neo4j (⏳ pendiente) o en el texto del `fijo`

### Estados como tags

Los estados de entidad se modelan como tags:
- Personaje muerto → `tags: ["muerto"]`
- Hilo cerrado → `tags: ["cerrado"]`
- Lugar destruido → `tags: ["destruido"]`
- Personaje villano → `tags: ["villano", "activo"]`

Esto da flexibilidad por tipo (cada tipo usa sus propios tags) sin rigidizar el schema.

---

## Lo que enlaza todo: `fichas` como `string[]`

En `beats` y `summaries`, el campo `fichas` es un array de strings (IDs de entidades):

```json
"fichas": [
  "per-ana-lopez",
  "lug-casa-ana",
  "hilo-traicion-carlos"
]
```

- **Solo IDs** — el `tipo` es derivable del prefijo (`per-`, `lug-`, `hilo-`, etc.)
- **Indexado en `fichas`** (keyword sobre `string[]`) — habilita queries cross-entry
- **Lookup del nombre**: `query-entity --novela X --id per-ana-lopez` (devuelve `{id, tipo, nombre, ...}`)

---

## Prerrequisito — novela activa

Antes de cualquier operación, lee el slug de la novela activa:

```bash
NOVELA=$(python3 -c "import json; print(json.load(open('estado.json'))['novela_activa'])")
```

**Todos los comandos requieren `--novela`** (multi-tenancy). Si omite, el script falla con `error: the following arguments are required: --novela`.

---

## Operaciones por rol

### Guionista — beat nuevo

```bash
python3 scripts/qdrant.py upsert-beat \
  --novela "$NOVELA" \
  --beat B_0005 \
  --parent-id E_001 \
  --accion "TONO — descripción de la acción" \
  --tono "TONO" \
  --extension "BREVE|MEDIA|EXTENSA" \
  --fichas '["per-ana-lopez","per-carlos-vega","lug-casa-ana"]'
```

Crea el entry con `narrative_text: null`, vectorizado con `accion`.

### Guionista — modificar beat existente

```bash
python3 scripts/qdrant.py update-beat \
  --novela "$NOVELA" \
  --beat B_0005 \
  --accion "nueva descripción" \
  --tono "nuevo tono"
```

Si `--accion` cambia y el beat no tiene narrativa: re-embeds automáticamente.
Si ya tiene narrativa: actualiza solo el campo `accion` — el vector narrativo se preserva.

Para mover un beat a otra escena: `--parent-id E_005` (nueva escena).

### Escritor — enriquecer con narrativa

```bash
cat > /tmp/beat_narrative.txt << 'NARRATIVE_EOF'
[texto completo del beat — sin el heading ## B_0005]
NARRATIVE_EOF

python3 scripts/qdrant.py enrich-beat \
  --novela "$NOVELA" \
  --beat B_0005 \
  --parent-id E_001 \
  --narrative-file /tmp/beat_narrative.txt
```

Re-embeds con `narrative_text`. El campo `accion` queda preservado.

### Integrador — reescritura de beat

Igual que escritor: usa `enrich-beat` con el texto corregido final.
**Solo si `cambios_realizados` no está vacío** — si no hubo cambios, no actualices Qdrant.

### Cronista — verificación de beats

Para cada beat del `draft.md` que no tenga `narrative_text`, ejecuta `enrich-beat`. Es un paso de verificación.

### Cronista — indexar resumen L1 (escena)

```bash
python3 scripts/qdrant.py upsert-summary \
  --novela "$NOVELA" \
  --nivel L1 \
  --id E_001 \
  --parent-id C_001 \
  --title "Salón de la casa de Ana" \
  --texto-file /tmp/l1_salon.txt \
  --fichas '["per-ana-lopez","lug-casa-ana"]'
```

### Cronista — indexar resumen L2 (capítulo)

```bash
python3 scripts/qdrant.py upsert-summary \
  --novela "$NOVELA" \
  --nivel L2 \
  --id C_001 \
  --parent-id A_001 \
  --title "El regreso de Ana" \
  --texto-file /tmp/l2.txt \
  --fichas '["per-ana-lopez","per-carlos-vega","lug-casa-ana","hilo-traicion-carlos"]'
```

### Cronista — indexar resumen L3 (al cerrar arco)

```bash
python3 scripts/qdrant.py upsert-summary \
  --novela "$NOVELA" \
  --nivel L3 \
  --id A_001 \
  --parent-id "" \
  --title "La promesa rota" \
  --texto-file /tmp/l3.txt
```

`--parent-id` vacío para L3.

### Cronista — indexar resumen L4

```bash
python3 scripts/qdrant.py upsert-summary \
  --novela "$NOVELA" \
  --nivel L4 \
  --id global \
  --parent-id "" \
  --title "La promesa oscura" \
  --texto-file /tmp/l4.txt
```

---

## Queries de memoria

### `query` — búsqueda directa en beats

```bash
python3 scripts/qdrant.py query --novela "$NOVELA" --text "..." --limit 5
```

**Salida**: array JSON con `ref` (`parent_id:id`), `score`, `has_narrative`, `tono`, `fichas`, `text`.

### `query-chapters-by-beat` — caps históricos relevantes

```bash
python3 scripts/qdrant.py query-chapters-by-beat \
  --novela "$NOVELA" \
  --text "objetivo del cap actual — 1-2 frases" \
  --top-beats 8 \
  --top-chapters 3 \
  --min-score 0.75
```

**Salida**: array JSON con `chapter_id`, `title`, `beat_score`, `l2_summary`, `source: "qdrant"`.

**Flujo interno**:
1. Semantic search en `beats` → top 8 hits
2. Agrupa por `parent_id` (escena) — best score per scene
3. Fetch las escenas de `summaries` (L1) → obtiene `parent_id` (capítulo)
4. Agrupa por capítulo — best score per chapter
5. Fetch los L2 de los top 3 capítulos

### `query-l2-recent` — últimos K L2 antes del cap actual

```bash
python3 scripts/qdrant.py query-l2-recent \
  --novela "$NOVELA" \
  --current-id C_005 \
  --last 3
```

**Salida**: array JSON con los últimos 3 L2s (ordenados por `id` desc, excluyendo el actual).

### `query-l3` — L3s (arcos cerrados)

```bash
# Arco específico
python3 scripts/qdrant.py query-l3 --novela "$NOVELA" --arco A_001

# Todos los arcos cerrados
python3 scripts/qdrant.py query-l3 --novela "$NOVELA"
```

**Argumento `--arco`**: el ID del arco (ej: `A_001`). Filtra por `id == A_001`.

**Salida con `--arco`**: objeto JSON con `id`, `title`, `parent_id`, `summary`. Objeto `{}` si el arco no tiene L3 (aún no cerrado).
**Salida sin `--arco`**: array JSON ordenado por `id` asc.

### `query-l4-current` — L4 global

```bash
python3 scripts/qdrant.py query-l4-current --novela "$NOVELA"
```

**Salida**: objeto JSON con `id`, `title`, `parent_id`, `summary`. Objeto `{}` si no existe.

### `query-entity` / `query-entities` — entidades

```bash
# Una entidad por ID
python3 scripts/qdrant.py query-entity --novela "$NOVELA" --id per-ana-lopez

# Lista filtrada
python3 scripts/qdrant.py query-entities --novela "$NOVELA" --tipo personaje
python3 scripts/qdrant.py query-entities --novela "$NOVELA" --tag muerto
```

### `query-entities-by-text` — búsqueda semántica

```bash
python3 scripts/qdrant.py query-entities-by-text \
  --novela "$NOVELA" \
  --text "personaje villano con pasado oscuro"
```

---

## Detección de transición de arco (memoria FASE 1)

Para detectar `transicion_arco`:

```bash
# 1. L2 del cap N-1 (para conocer su parent_id = arco previo)
L2_PREV=$(python3 scripts/qdrant.py upsert-summary --novela "$NOVELA" --nivel L2 --id C_N-1 --parent-id A_X ...)

# El campo arco del L2 es el parent_id
ARCO_PREV=$(echo $L2_PREV | python3 -c "import json,sys; print(json.load(sys.stdin)['parent_id'])")

# 2. Comparar con el arco_actual del director
if [ "$ARCO_PREV" != "$ARCO_ACTUAL" ]; then
  # Hay transición — buscar el L2 del último cap del arco previo
  # (filtrar L2s por parent_id == ARCO_PREV, ordenar por id desc, tomar primero)
fi
```

---

## Estrategia de vectorización

| Fase | Texto embebido | `vector_source` |
|------|---------------|----------------|
| Beat creado (guión) | `accion` | `"guion"` |
| Beat enriquecido (narrativa) | `narrative_text` | `"narrativa"` |
| Beat reescrito (integrador) | `narrative_text` actualizado | `"narrativa"` |
| Entity creada | `fijo` | (no aplica) |
| Summary creado | `summary` | (no aplica) |

---

## Backup y restauración

### `export` — volcar novela a JSON

```bash
python3 scripts/qdrant.py export --novela "$NOVELA" --output backups/cap-010.json
```

Genera un JSON con todos los beats, summaries y entidades de la novela. Se recomienda ejecutar **cada 10 caps** como salvaguarda.

### `import` — restaurar novela desde JSON

```bash
python3 scripts/qdrant.py import --novela "$NOVELA" --input backups/cap-010.json
```

Restaura desde un JSON producido por `export`. Útil tras un crash de Qdrant o para sincronizar entre máquinas.

---

## Setup inicial (una sola vez)

```bash
pip install fastembed
docker run -d -p 6333:6333 qdrant/qdrant
python3 scripts/qdrant.py init
```

`init` crea las 3 colecciones con sus payload indexes (`novela_slug`, `parent_id`, `fichas`, `nivel`, `id`, `tipo`, `tags`).
