---
name: neo4j
description: Schema unificado y vocabulario cerrado de Neo4j para relaciones entre entidades. Cárgalo al crear, actualizar, consultar o auditar el grafo narrativo.
---

# Neo4j — schema unificado

## Infraestructura

| Parámetro | Valor |
|-----------|-------|
| URL | `bolt://localhost:7687` o `$NEO4J_URL` |
| Helper | `scripts/neo4j.py` |
| Driver | `neo4j` para Python |
| Grafo | Único y compartido por todos los proyectos |

Neo4j complementa Qdrant: Qdrant conserva vectores, summaries y estado de entidades; Neo4j conserva sus relaciones. No existe un grafo por proyecto. El aislamiento se realiza con la propiedad `proyecto` en todos los nodos y relaciones.

`proyecto` reemplaza cualquier uso anterior de `novela`.

## Identidad y constraint

Cada nodo posee un `stable_id` opaco e inmutable. La identidad lógica es la pareja `(proyecto, stable_id)`:

```cypher
CREATE CONSTRAINT entity_stable_id IF NOT EXISTS
FOR (n:Entity) REQUIRE (n.proyecto, n.stable_id) IS UNIQUE
```

Reglas:

1. Todos los nodos llevan la label base `Entity` y una label derivada de `tipo`.
2. Todas las referencias de entidad usan `stable_id`.
3. Nunca se usan nombres, slugs ni prefijos semánticos como identidad.
4. Están prohibidos IDs del tipo `44444444`, `55555555`, `obj-anillo` o `hilo-sumer`.
5. Un mismo `stable_id` puede existir en proyectos distintos porque el constraint incluye `proyecto`.
6. Toda consulta y escritura filtra por `--proyecto`.

## Labels derivadas de `tipo`

| `tipo` | Label Neo4j |
|--------|-------------|
| `personaje` | `Personaje` |
| `lugar` | `Lugar` |
| `objeto` | `Objeto` |
| `animal` | `Animal` |
| `ser_sobrenatural` | `SerSobrenatural` |
| `hilo` | `Hilo` |
| `organizacion` | `Organizacion` |
| `arco` | `Arco` |
| `evento` | `Evento` |
| `grupo` | `Grupo` |

Los nombres de tipo son un vocabulario cerrado y no admiten alias.

## Propiedades de nodo

| Propiedad | Tipo | Descripción |
|-----------|------|-------------|
| `proyecto` | string | Slug del workspace |
| `stable_id` | string | UUID opaco e inmutable |
| `tipo` | string | Tipo canónico de entidad |
| `nombre` | string | Nombre legible |
| `slug` | string | Slug de presentación/archivo |
| `fijo` | string | Datos inmutables serializados |
| `dinamico` | string | Estado evolutivo serializado |

`tipo`, `nombre` y `slug` son propiedades consultables; no se codifican en `stable_id`. La label específica se deriva de `tipo`.

## Relaciones

El vocabulario es cerrado. No se crean tipos o roles ad hoc. Si una relación no cabe en el vocabulario vigente, se detiene la operación y se informa al director.

Todas las relaciones llevan `proyecto`. Las relaciones persona-persona requieren `rol`; las relaciones cross-entity no aceptan `rol` porque su tipo ya expresa la semántica.

### Persona-persona con roles

#### `PAREJA_DE`

Roles:

```text
marido, esposa, novio, novia, amante,
ex_marido, ex_esposa, ex_novio, ex_novia, ex_amante
```

#### `FAMILIA_DE`

Roles:

```text
padre, madre, hijo, hija, hermano, hermana,
abuelo, abuela, nieto, nieta, tío, tía,
sobrino, sobrina, primo, prima, suegro, suegra,
yerno, nuera, cuñado, cuñada, padrastro, madrastra,
hijastro, hijastra
```

#### `SENTIMIENTO_HACIA`

Roles:

```text
amor, ternura, deseo, amistad, admiracion, alianza,
odio, miedo, obsesion, resentimiento, enemistad, rivalidad
```

#### `ACCION_SOBRE`

Roles:

```text
catalizador_de, traiciona, perdona, ayuda, protege,
chantajea, secuestra, ataca, envenena, engaña
```

### Cross-entity sin rol

Tipos vigentes:

```text
VIVE_EN, VIVIO_EN, TRABAJA_EN, FRECUENTA, EVITA,
ENCUENTRO_EN, ENCERRADA_EN,
POSEE, PERTENECIO_A, BUSCA, ENCUENTRA, PERDIO,
ROBO, REGALO_A, SIMBOLIZA,
DUENO_DE, CUIDA_DE,
MIEMBRO_DE, EX_MIEMBRO_DE, LIDERA, FUNDÓ,
IMPLICADO_EN, TESTIGO_DE, CULPABLE_DE, DESCUBRIO,
INTENTA_RESOLVER,
PARTICIPO_EN, ORGANIZO, VICTIMA_DE, PERPETRO,
EVENTO_EN
```

Ejemplos: `VIVE_EN` conecta personaje → lugar, `POSEE` personaje → objeto y `FRECUENTA` personaje → lugar.

## CLI

### Crear o actualizar una relación

```bash
python scripts/neo4j.py upsert-relationship \
  --proyecto "$PROYECTO" \
  --from-stable-id "$ORIGEN_STABLE_ID" \
  --to-stable-id "$DESTINO_STABLE_ID" \
  --from-tipo personaje \
  --to-tipo personaje \
  --type SENTIMIENTO_HACIA \
  --rol amor
```

Argumentos canónicos:

| Argumento | Uso |
|-----------|-----|
| `--proyecto` | Aísla el proyecto en el grafo compartido |
| `--from-stable-id` | Entidad origen por `stable_id` |
| `--to-stable-id` | Entidad destino por `stable_id` |
| `--from-tipo` | Tipo canónico del origen |
| `--to-tipo` | Tipo canónico del destino |
| `--type` | Tipo de relación del vocabulario cerrado |
| `--rol` | Rol obligatorio solo para relaciones persona-persona |

Ejemplo cross-entity sin `--rol`:

```bash
python scripts/neo4j.py upsert-relationship \
  --proyecto "$PROYECTO" \
  --from-stable-id "$PERSONA_STABLE_ID" \
  --to-stable-id "$LUGAR_STABLE_ID" \
  --from-tipo personaje \
  --to-tipo lugar \
  --type VIVE_EN
```

### Eliminar una relación

```bash
python scripts/neo4j.py delete-relationship \
  --proyecto "$PROYECTO" \
  --from-stable-id "$ORIGEN_STABLE_ID" \
  --to-stable-id "$DESTINO_STABLE_ID" \
  --from-tipo personaje \
  --to-tipo personaje \
  --type SENTIMIENTO_HACIA \
  --rol amor
```

### Consultar una entidad

```bash
python scripts/neo4j.py query-relationships \
  --proyecto "$PROYECTO" \
  --stable-id "$ENTIDAD_STABLE_ID" \
  --tipo personaje
```

La respuesta devuelve relaciones entrantes y salientes, roles y el `stable_id` de la otra entidad. Ninguna operación acepta prefijos semánticos o nombres como sustituto del `stable_id`.

## Cypher de referencia

```cypher
MATCH (a:Entity {proyecto: $proyecto, stable_id: $from_stable_id})
MATCH (b:Entity {proyecto: $proyecto, stable_id: $to_stable_id})
MERGE (a)-[r:SENTIMIENTO_HACIA]->(b)
SET r.proyecto = $proyecto, r.rol = $rol
```

Consulta aislada:

```cypher
MATCH (a:Entity {proyecto: $proyecto, stable_id: $stable_id})-[r]-(b:Entity)
WHERE b.proyecto = $proyecto
RETURN type(r), r.rol, b.stable_id, b.tipo, b.nombre
```

## Idempotencia y coherencia

- `upsert-relationship` es idempotente para el mismo origen, destino, tipo y rol.
- Repetir una operación no crea nodos duplicados por el constraint `(proyecto, stable_id)`.
- Los nodos creados o reconciliados deben llevar `Entity`, la label derivada y las propiedades canónicas.
- Las relaciones no se infieren del nombre o del slug.
- El director resuelve discrepancias; el cronista audita y no escribe en Neo4j.
- Si `tipo`, `type` o `rol` no pertenecen al vocabulario cerrado, la operación falla y no se sustituye por un valor inventado.

## Grafo compartido, backup y setup

```bash
docker run -d --name neo4j \
  -p 7474:7474 -p 7687:7687 \
  -e NEO4J_AUTH=neo4j/devpassword \
  -v neo4j_data:/data \
  neo4j:5

python scripts/neo4j.py init
python scripts/neo4j.py export --proyecto "$PROYECTO" --output backup-neo4j.json
python scripts/neo4j.py import --proyecto "$PROYECTO" --input backup-neo4j.json
```

El grafo sigue siendo único y compartido. Exportación, importación, consultas y mutaciones quedan delimitadas por `proyecto`.

