---
name: neo4j
description: Schema, vocabulario y guía operativa de Neo4j para el grafo de relaciones de la novela. Cárgalo cuando necesites crear, actualizar o consultar relaciones entre entidades.
---

# Neo4j — Schema, vocabulario y guía operativa

## Infraestructura

| Parámetro | Valor |
|-----------|-------|
| URL | `bolt://localhost:7687` (o `$NEO4J_URL`) |
| Script helper | `scripts/neo4j.py` |
| Auth | `neo4j` / `devpassword` (configurable vía `$NEO4J_USER` / `$NEO4J_PASSWORD`) |
| Driver Python | `neo4j` (`pip install neo4j`) |

**Neo4j complementa Qdrant**. Qdrant tiene los vectores (búsqueda semántica, resúmenes, entidades). Neo4j tiene el **grafo de relaciones** (quién conoce a quién, qué sienten, qué han hecho).

```
Qdrant: estado actual, vectores, resúmenes    Neo4j: historia relacional, grafo
```

---

## Vocabulario — cerrado y validado

El vocabulario es **cerrado en el spec**. El script `neo4j.py` valida cada tipo/rol. Si el cronista necesita algo no listado, **pausa y notifica al usuario** (no se autocrea).

### 1. Tipos person-person (con `rol` validado)

Cada uno de estos 4 tipos tiene un `rol` que debe estar en su enum cerrado.

#### `PAREJA_DE` (10 roles)
```cypher
CREATE (ana)-[:PAREJA_DE {rol: 'esposa',     desde: 'cap-01'}]->(carlos)
CREATE (ana)-[:PAREJA_DE {rol: 'amante',     desde: 'cap-05'}]->(pedro)
CREATE (ana)-[:PAREJA_DE {rol: 'ex_esposa',  desde: 'cap-01', hasta: 'cap-08'}]->(carlos)
```
**Roles**: `marido`, `esposa`, `novio`, `novia`, `amante`, `ex_marido`, `ex_esposa`, `ex_novio`, `ex_novia`, `ex_amante`

#### `FAMILIA_DE` (26 roles)
```cypher
CREATE (ana)-[:FAMILIA_DE {rol: 'madre',   desde: 'cap-01'}]->(carlos)
CREATE (ana)-[:FAMILIA_DE {rol: 'tío',     desde: 'cap-03'}]->(maria)
CREATE (juan)-[:FAMILIA_DE {rol: 'prima',   desde: 'cap-05'}]->(ana)
```
**Roles**: `padre`, `madre`, `hijo`, `hija`, `hermano`, `hermana`, `abuelo`, `abuela`, `nieto`, `nieta`, `tío`, `tía`, `sobrino`, `sobrina`, `primo`, `prima`, `suegro`, `suegra`, `yerno`, `nuera`, `cuñado`, `cuñada`, `padrastro`, `madrastra`, `hijastro`, `hijastra`

#### `SENTIMIENTO_HACIA` (12 roles)
**Positivos** (6): `amor`, `ternura`, `deseo`, `amistad`, `admiracion`, `alianza`
**Negativos** (6): `odio`, `miedo`, `obsesion`, `resentimiento`, `enemistad`, `rivalidad`

```cypher
CREATE (ana)-[:SENTIMIENTO_HACIA {rol: 'amor',      desde: 'cap-01'}]->(carlos)
CREATE (carlos)-[:SENTIMIENTO_HACIA {rol: 'miedo',    desde: 'cap-05'}]->(ana)
CREATE (ana)-[:SENTIMIENTO_HACIA {rol: 'enemistad', desde: 'cap-05'}]->(carlos)
```

#### `ACCION_SOBRE` (9 roles)
**Acciones que alguien hace sobre otro** (verbos, no estados).

```cypher
CREATE (carlos)-[:ACCION_SOBRE {rol: 'traiciona', desde: 'cap-05'}]->(ana)
CREATE (ana)-[:ACCION_SOBRE {rol: 'perdona',   desde: 'cap-08'}]->(carlos)
```

**Roles**: `traiciona`, `perdona`, `ayuda`, `protege`, `chantajea`, `secuestra`, `ataca`, `envenena`, `engaña`

### 2. Tipos cross-entity (sin `rol`)

31 tipos que no aceptan `rol` (el tipo es la semántica). Lista completa definida en `scripts/neo4j.py`. Algunos ejemplos:

| Tipo | Dirección | Ejemplo |
|------|-----------|---------|
| `VIVE_EN` | persona → lugar | Ana-[:VIVE_EN]->casa |
| `POSEE` | persona → objeto | Ana-[:POSEE]->anillo |
| `MIEMBRO_DE` | persona → organización | Ana-[:MIEMBRO_DE]->empresa |
| `DUENO_DE` | persona → animal | Ana-[:DUENO_DE]->gato |
| `IMPLICADO_EN` | persona → hilo | Ana-[:IMPLICADO_EN]->hilo_traicion |
| `PARTICIPO_EN` | persona → evento | Ana-[:PARTICIPO_EN]->boda |
| `EVENTO_EN` | lugar → evento | boda-[:EVENTO_EN]->iglesia |

Lista completa en `scripts/neo4j.py` (`CROSS_ENTITY_TYPES`).

---

## Schema del grafo

**Nodos**: cada entity de Qdrant se mapea a un nodo Neo4j con la **etiqueta según su prefijo**:

| Prefijo de ID | Etiqueta Neo4j | Ejemplo |
|---------------|----------------|---------|
| `per-` | `Personaje` | `per-ana-lopez` |
| `lug-` | `Lugar` | `lug-casa-ana` |
| `obj-` | `Objeto` | `obj-anillo-promesa` |
| `ani-` | `Animal` | `ani-gato-mishi` |
| `hilo-` | `Hilo` | `hilo-traicion-carlos` |
| `org-` | `Organizacion` | `org-circulo-noir` |
| `arc-` | `Arco` | `arc-la-promesa` |
| `eve-` | `Evento` | `eve-boda-ana` |
| otro | `Entity` (fallback) | |

**Propiedades del nodo**:
- `id`: estable, con prefijo de tipo (igual que en Qdrant)
- `novela`: slug de la novela (multi-tenant)
- `nombre` (opcional): display name

**Propiedades de la arista** (todas las relaciones):
- `novela`: string (multi-tenant)
- `rol` (solo person-person): el rol validado
- `desde`: chapter ID cuando empezó (ej. `cap-01`)
- `hasta`: chapter ID cuando terminó (null = activa)
- `estado`: narrativa (default `activa`)

**Constraints** (creadas por `init`):
- UNIQUE en (`novela`, `id`) por cada etiqueta — un entity es único dentro de su novela

---

## Prerrequisito — novela activa

```bash
NOVELA=$(python3 -c "import json; print(json.load(open('estado.json'))['novela_activa'])")
```

---

## Operaciones

### Setup inicial (una sola vez por novela)

```bash
python3 scripts/neo4j.py init
```

Crea constraints UNIQUE por etiqueta y novela. No carga datos — eso lo hace el cronista al cierre de cada cap.

### Cronista — upsert de relación

```bash
python3 scripts/neo4j.py upsert-relationship \
  --novela "$NOVELA" \
  --from per-carlos-vega --to per-ana-lopez \
  --type ACCION_SOBRE --rol traiciona \
  --desde cap-05
```

Si el `--type` o `--rol` no está en el vocabulario, el script falla con error claro y el cronista pausa para notificar al usuario.

### Memoria — query de relaciones

```bash
# Todas las relaciones de una entity (activas e inactivas)
python3 scripts/neo4j.py query-relationships --novela "$NOVELA" --entity per-ana-lopez

# Solo las activas (sin `hasta`, o `hasta` posterior al cap actual)
python3 scripts/neo4j.py query-relationship-active \
  --novela "$NOVELA" \
  --entity per-ana-lopez \
  --current-cap cap-10

# Relaciones que cambiaron en un cap
python3 scripts/neo4j.py query-relationships-changed \
  --novela "$NOVELA" \
  --cap cap-05
```

### Backup

```bash
python3 scripts/neo4j.py export --novela "$NOVELA" --output backups/cap-010-neo4j.json
python3 scripts/neo4j.py import --novela "$NOVELA" --input  backups/cap-010-neo4j.json
```

**Backup recomendado cada 10 caps** (en paralelo al de Qdrant).

---

## Detección de vocabulario nuevo

El script `validate_type_and_rol` rechaza tipos/rols no listados. Cuando esto ocurre:

```
Error: unknown relationship type 'ENGAÑO_A'.
  Valid types (35):
    ACCION_SOBRE, BUSCA, CUIDA_DE, ...
  → The cronista must pause and notify the user.
    The user decides whether to add 'ENGAÑO_A' to the vocabulary.
```

El cronista reporta esto en su output JSON:
```json
{
  "vocabulary_problems": [
    {
      "type_attempted": "ENGAÑO_A",
      "context": "Carlos engañó a Ana durante 6 meses",
      "suggestion": "Could use TRAICIONA_A or add ENGAÑO_A to vocabulary"
    }
  ]
}
```

**El usuario decide**:
1. **Reusar un tipo existente** (ej. `TRAICIONA_A` cubre el caso)
2. **Añadir el tipo/rol al vocabulario** en `scripts/neo4j.py` (y reintentar)
3. **Omitir la relación** (no es importante narrativamente)

Una vez añadido al vocabulario, el spec y el SKILL se actualizan, y el cronista reintenta.

---

## Queries Cypher comunes

### Q1: ¿Quiénes son las parejas de Ana?
```cypher
MATCH (ana {id: 'per-ana-lopez'})-[:PAREJA_DE]-(p)
RETURN p.nombre, p.id, r.rol, r.desde, r.hasta
```

### Q2: ¿Ana odia a Carlos?
```cypher
MATCH (ana {id: 'per-ana-lopez'})-[r:SENTIMIENTO_HACIA {rol: 'odio'}]-(carlos {id: 'per-carlos-vega'})
RETURN COUNT(*) > 0
```

### Q3: ¿Qué acciones tomó Carlos contra Ana?
```cypher
MATCH (carlos {id: 'per-carlos-vega'})-[:ACCION_SOBRE]->(ana {id: 'per-ana-lopez'})
RETURN r.rol, r.desde, r.hasta
```

### Q4: Historia completa de la relación Ana-Carlos
```cypher
MATCH (a)-[r]-(b)
WHERE a.id = 'per-ana-lopez' AND b.id = 'per-carlos-vega'
RETURN type(r) AS tipo, r.rol, r.desde, r.hasta, r.estado
ORDER BY r.desde
```

### Q5: ¿Qué cambió en este cap?
```cypher
MATCH (a)-[r]->(b)
WHERE r.novela = 'mi-novela' AND (r.desde = 'cap-05' OR r.hasta = 'cap-05')
RETURN a.id, type(r), r.rol, b.id, r.desde, r.hasta, r.estado
```

---

## Setup de Neo4j

```bash
docker run -d --name neo4j \
  -p 7474:7474 -p 7687:7687 \
  -e NEO4J_AUTH=neo4j/devpassword \
  -v neo4j_data:/data \
  neo4j:5
```

Variables de entorno (opcional):
```bash
export NEO4J_URL="bolt://localhost:7687"
export NEO4J_USER="neo4j"
export NEO4J_PASSWORD="devpassword"
```

Si Neo4j no está disponible, el sistema degrada gracefully — el briefing omite la sección de relaciones y la novela continúa.

---

## Multi-tenancy

- Cada nodo tiene `novela` (slug) en sus propiedades
- Cada arista tiene `novela` (slug) en sus propiedades
- Todas las queries filtran por `--novela`
- Constraints UNIQUE en (`novela`, `id`) por etiqueta

**Un mismo `per-ana-lopez` puede existir en múltiples novelas** (novelas en paralelo) sin colisión, porque el constraint incluye la novela.

---

## Limitaciones

- **Neo4j es un grafo operacional**: cualquier fallo de Qdrant o Neo4j requiere intervención manual (export, restart, etc.)
- **Backup es manual**: recomendado cada 10 caps
- **El vocabulario es fijo**: cualquier adición requiere actualizar `scripts/neo4j.py`
- **El sistema no infiere relaciones**: el cronista debe identificar las explícitamente
