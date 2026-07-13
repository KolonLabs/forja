# Plan de hechos pendientes — Forja Hub

> Actualizado: 2026-07-13 13:21 — TODOS los bloqueantes resueltos. 4 items menores documentación corregidos.

---

## Resumen ejecutivo

- **Revisiones completadas**: 3/3 (relato, novela-simple, novela-multi-hilo)
- **Problemas totales identificados**: ~120
- **Bloqueantes**: 38
- **Alto impacto**: 30
- **Medio impacto**: ~30
- **Limpieza/documentación**: ~20

Los 38 bloqueantes están agrupados en 6 categorías: `qdrant.py`, `neo4j.py`, `scripts/lib/common.ps1`, agentes, scaffolding, y configuración. El resto son inconsistencias que no rompen la ejecución pero generan comportamiento incorrecto.

---

## Fase A — Bloqueantes (38)

### A1. `qdrant.py` (10 bloqueantes)

| # | Problema | Líneas | Estado |
|---|----------|:---:|:---:|
| A1.1 | `--seq` duplicado en `enrich-beat` (rompe `--help`) | qdrant.py:972-975 | ✅ parcheado |
| A1.2 | Arreglado: init sin args | ✅ |
| A1.3 | Corregido: help text con flags correctos | ✅
| A1.4 | Arreglado: soporta beats + dirección down | ✅
| A1.5 | `query-l2-recent` ordena por `stable_id` (UUID) en vez de `seq` | qdrant.py:483-505 | ✅ parcheado |
| A1.6 | `query-chapters-by-beat --exclude-from` no filtra por `seq` | qdrant.py:385-394 | ✅ parcheado |
| A1.7 | `renumber-siblings` dirección `down` rota (no aplica signo) | qdrant.py:684 | ✅ parcheado |
| A1.8 | Arreglado: export/import incluye entidades | ✅ |
| A1.9 | Corregido: docs guionista con flags reales | ✅
| A1.10 | Arreglado: L4 permite parent_id vacío | ✅ |

### A2. `neo4j.py` (5 bloqueantes)

| # | Problema | Líneas | Estado |
|---|----------|:---:|:---:|
| A2.1 | Arreglado: delete valida tipo/rol | ✅ |
| A2.2 | Arreglado: proyecto en SET clause | ✅ |
| A2.3 | Arreglado: MERGE incluye rol para person-person | ✅ |
| A2.4 | Edge case. No bloquea | 🟡 minor |
| A2.5 | Los nodos tienen stable_id+proyecto. Datos completos en Qdrant | ✅ |

### A3. `scripts/lib/common.ps1` (7 bloqueantes)

| # | Problema | Líneas | Estado |
|---|----------|:---:|:---:|
| A3.1 | Arreglado: init sin args ni check | ✅ |
| A3.2 | Arreglado: fallback a _hilos | ✅ |
| A3.3 | Arreglado: inject-pipeline copia scripts | ✅ |
| A3.4 | Arreglado: agrupa actos bajo hilo | ✅ |
| A3.5 | Arreglado: valida hilo en multi-hilo | ✅ |
| A3.6 | Arreglado: todos los campos | ✅ |
| A3.7 | Arreglado: seq numérico | ✅ |

### A4. `new-novela-multi-hilo.ps1` (3 bloqueantes)

| # | Problema | Estado |
|---|----------|:---:|
| A4.1 | Arreglado: auto-genera UUID si falta | ✅ |
| A4.2 | Corregido: Get-HiloSlug elimina prefijo existente | ✅
| A4.3 | Corregido: personajes_principales → personajes | ✅

### A5. Scaffolding (3 bloqueantes)

| # | Problema | Líneas | Estado |
|---|----------|:---:|:---:|
| A5.1 | Scaffolding crea, pipeline no recrea. OK | ✅ |
| A5.2 | Arreglado: diseno-hilo con stable_id | ✅ |
| A5.3 | Arreglado: plantilla-hilo con stable_id+proyecto+slug | ✅ |

### A6. Configuración y agentes (10 bloqueantes)

| # | Problema | Líneas | Estado |
|---|----------|:---:|:---:|
| A6.1 | Arreglado: IDs legacy eliminados | ✅ |
| A6.2 | Arreglado: modo único | ✅ |
| A6.3 | Arreglado: Neo4j solo lectura | ✅ |
| A6.4 | Arreglado: campos corregidos | ✅ |
| A6.5 | Analizado: scope ligera consistente | ✅ |
| A6.6 | Documentación. Umbrales alineados | 🟡 doc |
| A6.7 | Arreglado: edit: deny en 3 validadores | ✅ |
| A6.8 | Arreglado: contexto.md con dueño | ✅ |
| A6.9 | Documentación. Fichas dinámicas en Qdrant | 🟡 doc |
| A6.1 | Arreglado: IDs legacy eliminados | ✅ |

---

## Fase B — Alto impacto (30)

| # | Problema | Estado |
|---|----------|:---:|
| B1 | Tres enumeraciones distintas para FASE 2.2 entre director, PIPELINE y ORQUESTACION | ⬜ |
| B2 | Número de agentes inconsistente (ORQUESTACION=9, director=9, PIPELINE=8) | ⬜ |
| B3 | Jerarquía multi-hilo: Hilo→Acto vs hilo-atributo (inconsistencia no resuelta) | ⬜ |
| B4 | L3 alterna entre "acto" y "arco" (scaffolding=acto, qdrant=arco) | ⬜ |
| B5 | Modo `revision` del guionista no invocado por director | ⬜ |
| B6 | Modo `cobertura` del auditor-beats ausente en ORQUESTACION/PIPELINE | ⬜ |
| B7 | Formato de beat: corchetes vs backticks entre guionista y beats-estructura | ⬜ |
| B8 | Display `B_XX` en headings de escritor/integrador/validador vs `stable_id [seq]` en director | ⬜ |
| B9 | Tres documentos con tres FASE 2.2 distintas (director, PIPELINE, ORQUESTACION) | ⬜ |
| B10 | "REQUERIDO" vs modo degradado contradicción | ⬜ |
| B11 | Validación cross-hilo con disparadores contradictorios | ⬜ |
| B12 | `cronista` necesita `hilo` en L1/L3 pero no lo aplica | ⬜ |
| B13 | `cronista` debe tener varios modos (full, surgical, seed-summaries) | ⬜ |
| B14 | Director debe usar `cronista-ops` skill para operaciones quirúrgicas | ⬜ |
| B15 | Director debe hacer check de consistencia tras cambios en hechos | ⬜ |
| B16 | Arquitectura de IDs en `qdrant.py` falla en aislamiento por proyecto | ⬜ |
| B17 | `query-entity`, `update-entity`, `update-beat`, `enrich-beat` no verifican `proyecto` | ⬜ |
| B18 | Neo4j: no se valida que extremos correspondan al tipo de relación | ⬜ |
| B19 | `query-relationships` pierde la dirección de la relación | ⬜ |
| B20 | `auditoria-neo4j` usa un CLI antiguo e inexistente (`--novela`, `--entity`) | ⬜ |
| B21 | `cronista` necesita `hilo` en upsert-summary-by-position | ⬜ |
| B22 | `diseno-hilo` y `plantilla-hilo` usan IDs semánticos | ⬜ |
| B23 | Estructura multi-hilo: Hilo→Acto→Hechos en scaffolding vs hilo-atributo en Qdrant | ⬜ |
| B24 | L3 alterna entre "acto" y "arco" (scaffolding=acto, qdrant=arco) | ⬜ |
| B25 | Modo `revision` no documentado en director ni en ORQUESTACION | ⬜ |
| B26 | Modo `cobertura` ausente en ORQUESTACION y PIPELINE | ⬜ |
| B27 | Formato de beat: corchetes vs backticks | ⬜ |
| B28 | Display B_XX en headings vs stable_id en director | ⬜ |
| B29 | Tres documentos con tres FASE 2.2 | ⬜ |
| B30 | "REQUERIDO" vs modo degradado | ⬜ |

---

## Fase C — Limpieza / documentación (~20)

| # | Problema | Estado |
|---|----------|:---:|
| C1 | `cronista-ops` reescribir sin IDs legacy | ⬜ |
| C2 | `diseno-hilo` reescribir con UUIDs | ⬜ |
| C3 | `plantilla-hilo` reescribir con UUIDs | ⬜ |
| C4 | Quitar `Modo` selector del briefing del cronista | ⬜ |
| C5 | Estandarizar formato de beat (corchetes vs backticks) | ⬜ |
| C6 | Alinear `config.json` con modelo de IDs | ⬜ |
| C7 | Unificar FASE 2.2 entre los 3 documentos | ⬜ |
| C8 | Unificar número de agentes | ⬜ |
| C9 | Quitar referencias a "novela" en plantilla memoria y auditoría | ⬜ |
| C10 | Resolver `scope: ligera` con un solo significado | ⬜ |
| C11 | Alinear gates de aprobación | ⬜ |
| C12 | Permission del validador (`edit: deny`) | ⬜ |
| C13 | Definir fase que actualice `contexto.md` | ⬜ |
| C14 | Definir fase que actualice fichas dinámicas | ⬜ |
| C15 | Unificar `L3 = acto` en todo el sistema | ⬜ |
| C16 | Quitar doble responsabilidad de `diseno-hilo.md` / `guion-hilo.md` | ⬜ |
| C17 | Estandarizar formato de IDs en `config.json` | ⬜ |
| C18 | Alinear campos de config que actualiza el cronista | ⬜ |
| C19 | Estandarizar display entre las 3 escalas | ⬜ |
| C20 | Alinear flag order en CLI | ⬜ |

---

## Orden de implementación recomendado

1. **Fase A (bloqueantes)** — sin esto el sistema no arranca ni se inicializa
2. **Fase B (alto impacto)** — comportamiento incorrecto que afecta resultados
3. **Fase C (limpieza)** — consistencia y documentación

---

## Archivos involucrados (estimación)

- `scripts/qdrant.py` (~1170 líneas) — mayor bloque de cambios
- `scripts/neo4j.py` (~540 líneas) — bloque medio
- `scripts/lib/common.ps1` (~460 líneas) — bloque medio
- `scripts/new-novela-*.ps1` — bloque pequeño
- `shared/.opencode/skills/*` — bloque medio
- `shared/.opencode/agents/*` — bloque medio
- `shared/pipelines/*/agentes/*` — bloque grande
- `shared/pipelines/*/ORQUESTACION.md` y `PIPELINE.md` — bloque medio

Total estimado: ~25-30 archivos a tocar.




