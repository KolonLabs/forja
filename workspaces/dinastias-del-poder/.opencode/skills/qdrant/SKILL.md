---
name: qdrant
description: Schema unificado, IDs y operaciones de Qdrant para beats, summaries y entidades. Cárgalo al persistir, consultar, reordenar o auditar memoria narrativa.
---

# Qdrant — schema unificado

## Infraestructura

| Parámetro | Valor |
|-----------|-------|
| URL | `http://localhost:6333` o `$QDRANT_URL` |
| Helper | `scripts/qdrant.py` |
| Embedding | `intfloat/multilingual-e5-large` (1024 dimensiones) |
| Colecciones | `beats`, `summaries`, `entidades` |

Todos los datos se aíslan mediante `proyecto`, el slug del workspace. `proyecto` reemplaza por completo cualquier campo anterior llamado `novela` o `novela_slug`.

## Identidad

Cada elemento lógico posee un `stable_id` opaco e inmutable. El ID físico del punto Qdrant se calcula siempre de forma determinista:

```python
uuid5(NAMESPACE_URL, stable_id)
```

Forma abreviada del contrato: `uuid5(URL, stable_id)`.

Reglas:

1. El `stable_id` se genera una vez y nunca cambia.
2. El UUID v5 identifica el punto dentro de Qdrant; no tiene semántica narrativa.
3. Nunca se inventan namespaces por proyecto, nivel o tipo.
4. Nunca se usan prefijos semánticos como `per-`, `lug-`, `obj-`, `hilo-`, `B_` o `E_` como identidad persistida.
5. Los IDs de presentación (`i9j0k1l2 [34]`, `E_323`, `C_121`, `A_001`, etc.) se derivan de `seq` al mostrar datos y nunca se almacenan.
6. `seq` siempre es local a `parent_id`; no es un contador global.
7. Renumerar solo cambia `seq`. El `stable_id` y el UUID v5 del punto permanecen intactos.

## Regla de búsqueda

**Nunca se busca por el UUID v5 del punto.** Ese UUID es un resultado interno, no una entrada de negocio.

- Beats y entidades se referencian por `stable_id` cuando se conoce su identidad.
- Summaries se localizan siempre por posición: `(nivel, parent_id, seq[, hilo])`.
- El llamador pasa el `stable_id` del padre como `parent_id`; el helper resuelve internamente cualquier UUID físico.
- En multi-hilo, `hilo` forma parte de la posición cuando aplica.

Ejemplo:

```bash
python scripts/qdrant.py query-summary-by-position \
  --proyecto mi-proyecto \
  --nivel L1 \
  --parent-id a1b2c3d4 \
  --seq 3
```

La respuesta puede incluir `stable_id` y el UUID físico. Ambos son resultados de la búsqueda, nunca sustitutos de la tupla posicional.

## Colección `beats`

Payload canónico:

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `proyecto` | string | Slug del workspace |
| `stable_id` | string | Identidad opaca e inmutable del beat |
| `seq` | integer | Posición local dentro de `parent_id` |
| `parent_id` | string | `stable_id` de la escena padre |
| `accion` | string | Acción concreta definida en el guion |
| `tono` | string | Tono narrativo |
| `extension` | string | `BREVE`, `MEDIA` o `EXTENSA` |
| `fichas` | string[] | `stable_id` de las entidades presentes |
| `narrative_text` | string o null | Prosa final del beat |
| `vector_source` | string | `guion` o `narrativa` |

Ejemplo:

```json
{
  "proyecto": "mi-proyecto",
  "stable_id": "a1b2c3d4",
  "seq": 34,
  "parent_id": "e5f6a7b8",
  "accion": "Laura se arrodilla ante Diego",
  "tono": "Opresivo",
  "extension": "BREVE",
  "fichas": ["9c7d6e5f", "3a2b1c0d"],
  "narrative_text": null,
  "vector_source": "guion"
}
```

El display `i9j0k1l2 [34]` se deriva de `seq: 34` solo al presentar el beat.

Vectorización:

- Beat de guion: vector de `accion`, `vector_source: "guion"`.
- Beat con prosa: vector de `narrative_text`, `vector_source: "narrativa"`.
- Una reescritura actualiza `narrative_text` y su vector, sin alterar `stable_id`.

Índices de payload: `proyecto`, `stable_id`, `parent_id`, `fichas`.

## Colección `summaries`

Payload canónico:

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `proyecto` | string | Slug del workspace |
| `stable_id` | string | Identidad opaca e inmutable del summary |
| `seq` | integer | Posición local dentro de `parent_id` |
| `nivel` | string | `L1`, `L2`, `L3` o `L4` |
| `parent_id` | string o null | `stable_id` del summary padre |
| `texto` | string | Resumen narrativo |
| `fichas` | string[] | `stable_id` de entidades implicadas |
| `hilo` | string opcional | `stable_id` del hilo en proyectos multi-hilo |

Jerarquía:

| Nivel | Contenido | Padre | Display derivado |
|-------|-----------|-------|------------------|
| `L1` | Escena | `stable_id` del L2 del capítulo | `E_{seq:03d}` |
| `L2` | Capítulo | `stable_id` del L3 del arco | `C_{seq:03d}` |
| `L3` | Arco | `stable_id` del L4 global | `A_{seq:03d}` |
| `L4` | Proyecto completo | raíz/global | Derivado por presentación si se necesita |

`seq` vuelve a empezar para cada padre. Dos escenas de capítulos distintos pueden tener `seq: 1` sin colisión porque su `parent_id` es diferente. En multi-hilo, `hilo` desambigua posiciones del mismo nivel y padre.

Todos los summaries viven en Qdrant. No existe fallback Markdown para L1/L2/L3/L4.

Índices de payload: `proyecto`, `stable_id`, `nivel`, `parent_id`, `fichas`; `hilo` se usa como filtro posicional en multi-hilo.

## Colección `entidades`

Payload canónico:

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `proyecto` | string | Slug del workspace |
| `stable_id` | string | UUID opaco e inmutable de la entidad |
| `tipo` | string | Tipo del vocabulario cerrado |
| `nombre` | string | Nombre legible |
| `slug` | string | Slug para el archivo Markdown, no para relaciones |
| `fijo` | string | Datos inmutables serializados |
| `dinamico` | string | Estado evolutivo serializado |
| `tags` | string[] | Etiquetas de filtrado |

Tipos válidos, sin variaciones:

```text
personaje
lugar
objeto
animal
ser_sobrenatural
hilo
organizacion
arco
evento
grupo
```

Los IDs de entidad son UUIDs opacos. El tipo, el nombre, el proyecto y el slug no se codifican dentro del ID. Están prohibidos los IDs con prefijos semánticos (`per-`, `lug-`, `obj-`, `hilo-`, etc.).

`fichas` en beats y summaries contiene exclusivamente `stable_id` de entidades. Para conocer nombre o tipo se consulta `entidades`; nunca se deducen del ID.

Índices de payload: `proyecto`, `stable_id`, `tipo`, `tags`.

## Comandos posicionales

### `query-summary-by-position`

Busca summaries mediante `(nivel, parent_id, seq[, hilo])`:

```bash
python scripts/qdrant.py query-summary-by-position \
  --proyecto "$PROYECTO" \
  --nivel L1 \
  --parent-id "$CAPITULO_STABLE_ID" \
  --seq 3 \
  --hilo "$HILO_STABLE_ID"
```

Omite `--hilo` fuera de multi-hilo. La salida entrega la identidad encontrada.

### `upsert-summary-by-position`

Escritura idempotente por posición:

```bash
python scripts/qdrant.py upsert-summary-by-position \
  --proyecto "$PROYECTO" \
  --nivel L2 \
  --parent-id "$ARCO_STABLE_ID" \
  --seq 5 \
  --texto-file resumen.txt \
  --fichas '["9c7d6e5f","3a2b1c0d"]'
```

Si la posición existe, conserva su `stable_id` y actualiza el payload. Si no existe, crea un `stable_id` nuevo. Repetir la misma operación no duplica puntos.

### `renumber-siblings`

Reordena hermanos después de insertar o eliminar:

```bash
python scripts/qdrant.py renumber-siblings \
  --proyecto "$PROYECTO" \
  --nivel L1 \
  --parent-id "$CAPITULO_STABLE_ID" \
  --from-seq 3 \
  --direction up \
  --step 1
```

- `up`: desplaza `seq` hacia arriba antes de insertar.
- `down`: desplaza `seq` hacia abajo después de eliminar.
- `--hilo` limita el cambio a los hermanos de ese hilo.
- Solo cambia `seq`; nunca cambia `stable_id`, `parent_id` ni los hijos.

La misma regla se aplica al reordenamiento de beats: el conjunto de hermanos queda ordenado mediante `seq` local al padre y todas las referencias siguen apuntando a `stable_id`.

## Operaciones básicas

```bash
# Beat idempotente
python scripts/qdrant.py upsert-beat \
  --proyecto "$PROYECTO" \
  --beat "$BEAT_STABLE_ID" \
  --seq 34 \
  --parent-id "$ESCENA_STABLE_ID" \
  --accion "Laura se arrodilla ante Diego" \
  --tono "Opresivo" \
  --extension BREVE \
  --fichas '["9c7d6e5f","3a2b1c0d"]'

# Enriquecer el mismo beat con prosa
python scripts/qdrant.py enrich-beat \
  --proyecto "$PROYECTO" \
  --beat "$BEAT_STABLE_ID" \
  --parent-id "$ESCENA_STABLE_ID" \
  --narrative-file beat.txt

# Entidad por stable_id
python scripts/qdrant.py query-entity \
  --proyecto "$PROYECTO" \
  --stable-id "$ENTIDAD_STABLE_ID"
```

Nunca se pasa el UUID v5 físico del punto a estos comandos.

## Idempotencia

Todas las escrituras deben ser idempotentes:

- `stable_id` produce siempre el mismo UUID v5 de punto.
- Un upsert de beat o entidad reemplaza/actualiza el mismo punto lógico.
- `upsert-summary-by-position` reutiliza el summary de la posición.
- Enriquecer o actualizar repite el cambio sobre el mismo elemento.
- Reintentar tras timeout no crea duplicados.
- `renumber-siblings` se usa de forma explícita para abrir o cerrar huecos tras inserciones y borrados.

## Setup y backup

```bash
pip install fastembed
docker run -d -p 6333:6333 qdrant/qdrant
python scripts/qdrant.py init

python scripts/qdrant.py export --proyecto "$PROYECTO" --output backup.json
python scripts/qdrant.py import --proyecto "$PROYECTO" --input backup.json
```

`init` crea `beats`, `summaries` y `entidades` con sus índices. Exportación e importación siempre quedan filtradas por `proyecto`.

