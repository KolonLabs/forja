# Pipeline — Novela Simple (4 fases)

Escala `novela-simple`. Qdrant+Neo4j activos. Una línea temporal, sin hilos paralelos.

> Rutas: ver `MAPA.md` · Spawn y contratos: `ORQUESTACION.md` · Estado: `config.json` + `guion-novela.md` statuses

## Jerarquía narrativa

```
_actos.md (estructura de actos)
  └── guion-novela.md (actos, capítulos, hechos H_NNNN estimados)
        └── capitulos/cap-NN-slug/
              ├── guion.md    (hechos H_NNNN + beats B_NNNN bajo cada hecho)
              ├── draft.md    (prosa desarrollada desde beats, secciones ## B_NNNN)
              └── capitulo.md (publicable)

contexto.md (resumen post-capítulo, mantenido por el director al cerrar cada capítulo. Complementa a Qdrant como respaldo legible)
fichas/<tipo>_<slug>.md (entidades en markdown, primarias en Qdrant)
```

## Hechos y beats

| ID | Qué es | Dónde |
|----|--------|-------|
| `H_NNNN` | Evento que debe ocurrir (1-2 frases de guion). Puede ser lineal o distribuido `[D]`. | `guion-novela.md`, `capitulos/.../guion.md` |
| `B_NNNN` | Frase muy corta que el escritor desarrolla en prosa | `capitulos/.../guion.md` (bajo un hecho) |

- IDs globales, 4 dígitos, nunca reutilizar.
- Estados: ✅ completo · 🔄 en progreso · ⬜ pendiente.
- Un hecho `[D · H_XX–H_YY]` no genera capítulos ni escenas propias — sus beats se inyectan en las escenas de los hechos lineales dentro del rango.
- Skills: `beats-estructura`, `tonos-beat`, `plantilla-guion`, `hechos-distribuidos`.

---

## Fases

### FASE 0 — Diseño global (`estado: diseno`)

| Paso | Agente | Skill | Entrada | Salida |
|------|--------|-------|---------|--------|
| 0.1 | `director` | `scaffolding-hecho`, `hechos-distribuidos` | `_actos.md` | Anotaciones `🎬 Director:` bajo hechos `[D]` en `_actos.md` |
| 0.2 Seed entidades | `director` → `entidades` (×N) + `neo4j.py` | — | `_actos.md`, `BRIEF.md` | Entidades básicas en Qdrant (stable_id, tipo, nombre, fijo). Relaciones básicas en Neo4j |
| 0.3 Estructura | `guionista` modo `estructura-novela` | `estructura-narrativa`, `beats-estructura`, `plantilla-guion` [+ `hechos-distribuidos` si hay `[D]`] | `BRIEF.md`, `_actos.md` (con anotaciones) | `guion-novela.md` (actos, capítulos, hechos estimados + inyección `[D]`) |

**Gate:** Cada capítulo tiene función narrativa clara. Hechos estimados asignados.

**Transición:** `config.json.estado = "fichas"`.

---

### FASE 1 — Componentes (`estado: fichas`)

Objetivo: enriquecer entidades semilla con detalle completo y reconciliar. Las entidades base ya existen en Qdrant + Neo4j desde FASE 0.

| Paso | Agente | Acción |
|------|--------|--------|
| 1.1 Verificar infra | director | Qdrant (`scripts/qdrant.py check`) y Neo4j (`scripts/neo4j.py check`) |
| 1.2 Extraer entidades | director | Lee `guion-novela.md`, identifica todas las entidades |
| 1.3 Crear en Qdrant | `entidades` (×N) | `upsert-entity` en colección `entidades` (fijo + dinámico + tags) |
| 1.4 Exportar markdown | `entidades` | `fichas/<tipo>_<slug>.md` (secciones FIJO y DINÁMICO) |
| 1.5 Reconciliación | director | Verifica sin contradicciones entre fichas |

**Gate:** Todas las entidades en Qdrant + markdown. Qdrant y Neo4j operativos.

**Transición:** `config.json.estado = "escritura"`. `config.json.version_qdrant = "activo"`. `config.json.version_neo4j = "activo"`.

---

### FASE 2 — Escritura por capítulo (`estado: escritura`)

Itera por cada capítulo en `guion-novela.md`, en orden secuencial:

#### 2.1 Memoria

| Paso | Agente | Acción |
|------|--------|--------|
| 2.1.1 | `memoria` (deepseek-v4-flash) | Consulta Qdrant (L4, L3, L2 recientes, entidades) + Neo4j (relaciones activas) → briefing ~600 tokens |

#### 2.2 Guion del capítulo

| Paso | Agente | Acción |
|------|--------|--------|
| 2.2.1 | `guionista` modo `capitulo` | Recibe briefing memoria + estructura cap + contexto anterior + IDs → **crea directorio** `capitulos/cap-NN-slug/` y escribe `capitulos/cap-NN-slug/guion.md` |
| 2.2.2 | `auditor-beats` (atomizar → transiciones → limpieza) | Valida `capitulos/cap-NN-slug/guion.md`. Diagnostica: beats inconclusos, huecos, prosa. Director → guionista corrige |

#### 2.3 Beat a beat

Por cada beat `⬜`:

| Paso | Agente | Acción |
|------|--------|--------|
| 2.3.1 | `escritor` | Genera prosa → `draft.md` (append `## B_NNNN`) |
| 2.3.2 | `validador` (read-only) | Scope `completa` por defecto. 5 dimensiones |
| 2.3.3 | `integrador` (condicional) | Si score < 7 o dimensión < 5. Reescribe beat |
| 2.3.4 | director | ✅ en `guion.md`. Actualiza `config.json.ultimo_beat_seq` |

#### 2.4 Revisión global

| Paso | Agente | Acción |
|------|--------|--------|
| 2.4.1 | `validador` modo `global` | Evalúa `draft.md` completo + L4 + arco + hilos activos |
| 2.4.2 | director | Actualiza `contexto.md` con resumen del capítulo (2-4 frases) |

#### 2.5 Cronista

| Paso | Agente | Acción |
|------|--------|--------|
| 2.5.1 | `cronista` (deepseek-v4-flash) | Qdrant: upsert L1 (por escena), L2 (capítulo), L3 (si cierre arco), L4 (cada 10 caps), actualiza dinámico entidades |
| 2.5.2 | `cronista` + `auditoria-neo4j` | Auditoría Neo4j (solo lectura). Devuelve discrepancias |
| 2.5.3 | `cronista` | Actualiza `config.json`: `capitulos_completados++`, `ultimo_beat_seq` |
| 2.5.4 | director | Resuelve discrepancias Neo4j devueltas por el cronista |

**Umbral validador:** `score_global ≥ 8` y todas dimensiones ≥ 7 para aprobación directa sin integrador.

**Gate del capítulo:** Todos los beats ✅, Qdrant actualizado (L1+L2), Neo4j auditado.

**Bucle:** Si quedan capítulos, vuelve a 2.1. Si es el último capítulo → `publicacion`.

**Transición:** `config.json.estado = "publicado"`.

---

### FASE 3 — Publicar (`estado: publicacion`)

| Paso | Agente | Acción |
|------|--------|--------|
| 3.1 Limpiar capítulos | director | `draft.md` → `capitulo.md` por capítulo (elimina headings `## B_XX`, conserva título) |
| 3.2 Concatenar | director | Todos los `capitulo.md` → `novela.md` |

**Gate:** `capitulo.md` por capítulo + `novela.md`.

---

## Transiciones de estado

```
diseno → fichas → escritura → publicacion → publicado
```

**Bucle en FASE 2:** itera capítulo por capítulo. `config.json.capitulos_completados` avanza.

**Creación de directorios:** el `guionista` en modo `capitulo` crea el directorio `capitulos/cap-NN-slug/`. El `escritor` escribe `draft.md` dentro de ese directorio (append).

**Relaciones Neo4j:** el `entidades` las crea inicialmente (FASE 0-1). Durante la escritura, el `cronista` audita Neo4j (solo lectura) y reporta discrepancias al `director`, quien decide si invoca a `entidades` para corregir relaciones. Las nuevas relaciones detectadas por el cronista se sugieren en el JSON de salida (`relaciones_neo4j_sugeridas`).

## Agentes activos (9 agentes)

`director`, `guionista`, `auditor-beats`, `escritor`, `validador`, `integrador`, `memoria`, `cronista`, `entidades`

## Skills activos (39 skills)

`mecanica-prosa`, `beats-estructura`, `estructura-narrativa`, `tonos-beat`, `hechos-estructura`, `hechos-distribuidos`, `plantilla-guion`, `plantilla-ficha`, `plantilla-personaje`, `plantilla-lugar`, `plantilla-objeto`, `plantilla-animal`, `plantilla-arco`, `plantilla-evento`, `plantilla-organizacion`, `plantilla-grupo`, `plantilla-ser-sobrenatural`, `validacion-crudeza`, `validacion-coherencia`, `validacion-geometria`, `validacion-sensorial`, `validacion-tono`, `consistencia-narrativa`, `contexto-subagente`, `contexto-narrativo`, `desarrollo-narrativa`, `fichas-personajes`, `cronista-ops`, `estilo-explicito`, `estilo-contemporaneo`, `estilo-erotico`, `estilo-fantasia`, `estilo-noir`, `estilo-romantico`, `estilo-thriller`, `estilo-prosa`, `qdrant`, `neo4j`, `auditoria-neo4j`

**No aplican (4 skills):** `diseno-hilo`, `trenzado-narrativo`, `validacion-cross-hilo`, `plantilla-hilo`

## Comandos

- `/refinar-hechos` — revisa y afina los hechos de _actos.md antes de generar
- `/validar-hechos` — valida coherencia narrativa entre hechos, detecta problemas de interpretación y propone mejoras
- `/generar` — inicia o continúa desde `config.json.estado`
- `/revisar-guion` — revisa la coherencia de guion.md (escenas, arcos, ritmo, transiciones)
- `/revisar B_NNNN [instrucciones]` — revisión puntual de un beat
- `/expandir B_NNNN [instrucciones]` — expansión de un beat
- `/publicar` — salida limpia (`capitulo.md` por capítulo + `novela.md`)

## Infraestructura

**Qdrant REQUERIDO.** Colecciones: `entidades`, `summaries`, `beats`.
**Neo4j REQUERIDO.** Grafo de relaciones entre entidades.

Scripts: `scripts/qdrant.py` (init, check, query, upsert), `scripts/neo4j.py` (init, check, query).

## Política de reintentos

Máximo 3 reintentos por beat. Tipos: formato, contenido, timeout. Ver `ORQUESTACION.md` para detalle.




