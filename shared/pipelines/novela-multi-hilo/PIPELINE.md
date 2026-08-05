# Pipeline — Novela Multi-hilo (8 fases)

Escala `novela-multi-hilo`. Qdrant+Neo4j activos. Múltiples líneas temporales/POVs que se diseñan, desarrollan y trenzan en capítulos globales.

> Rutas: ver `MAPA.md` (índice completo + hilos/) · Spawn y contratos: `ORQUESTACION.md` · Estado: `config.json` + `guion-novela.md` statuses + `hilos[]`

## Jerarquía narrativa

```
hilos/hilo-<slug>/
  ├── diseno-hilo.md   (decisiones de diseño del hilo)
  └── guion-hilo.md    (hechos H_NNNN del hilo, agrupados por Acto)

guion-novela.md
  ├── Actos con capítulos
  ├── ## Trenzado (tabla: hechos por capítulo global, tipo, conexiones)
  └── puntos de conexión

capitulos/cap-NN-slug/
  ├── guion.md         (hechos del cap + beats; puente: bloques con ---)
  ├── cola_d.md        (hechos [D] pendientes de posicionar; efímero por capítulo)
  ├── draft.md         (prosa; secciones "## <stable_id> [<seq>] — acción")
  └── capitulo.md      (publicable)

contexto.md                  (resumen legible por hilo que mantiene el director)
fichas/<tipo>_<slug>.md      (entidades en markdown, primarias en Qdrant)
fichas/conexion-*.md         (documentación de puntos cross-hilo)
```

## Contrato del draft

El `draft.md` de cada capítulo usa **una sola forma de encabezado**:

```
<!-- ESCENA <stable_id_escena>: Nombre | hilo: <stable_id_hilo> -->

## <stable_id> [<seq>] — acción breve
...prosa...
```

- El escritor y el integrador escriben exactamente ese heading. `B_NNNN` es display derivado de `seq`, nunca encabezado.
- El director localiza cada beat por `stable_id`, no por posición ni por display.
- En FASE 4 se eliminan headings, marcadores de escena y notas del escritor. Solo sobrevive la prosa y los `---` entre bloques de hilo.

## Hechos y beats

| ID | Qué es | Dónde |
|----|--------|-------|
| `H_NNNN` | Evento que debe ocurrir (planificación). Puede ser lineal o distribuido `[D]`. Los `[D]` pueden ser cross-hilo. | `guion-hilo.md`, `guion-novela.md` (tabla Trenzado), `capitulos/.../guion.md` |
| `B_NNNN` | Frase muy corta para el escritor | `capitulos/.../guion.md` (bajo un hecho) |

- Ambos con IDs **globales** en toda la novela (no reiniciar por hilo).
- En `guion-hilo.md` solo hay **hechos**; los beats se generan al preparar el capítulo.
- Estados: ✅ completo · 🔄 en progreso · ⬜ pendiente.
- Un hecho `[D · H_XX–H_YY]` no genera capítulos ni escenas propias — sus beats se inyectan en las escenas de los hechos lineales dentro del rango.
- Skills: `beats-estructura`, `tonos-beat`, `plantilla-guion`, `hechos-distribuidos`.

---

## Fases

### FASE 0 — Diseño global (`estado: diseno`)

| Paso | Agente | Acción |
|------|--------|--------|
| 0.0 | director | **Identificar hechos `[D]`** en `_actos.md`. Cargar `hechos-distribuidos`. Anotar granularidad y distribución (+ hilo si aplica). |
| 0.1 | director + usuario | Identificar hilos: nombre, slug, época, ubicación, personajes, conflicto, tono |
| 0.2 | director + usuario | Identificar puntos de conexión cross-hilo (objetos, personajes, revelaciones) |
| 0.3 | director + usuario | Definir partes de la novela |
| 0.4 | director | Sembrar `config.json.hilos[]` y `puntos_conexion` |
| 0.5 Seed entidades | director → `entidades` (×N) + `neo4j.py` | Inferir entidades semilla de `_actos.md` + `BRIEF.md` + hilos. Crear en Qdrant (stable_id, tipo, nombre, fijo) + Neo4j (relaciones básicas, cross-hilo) |

**Gate:** Todos los hilos identificados con conflicto propio. `config.json.hilos[]` poblado.

---

### FASE 0.1 — Componentes iniciales (`estado: diseno`)

| Paso | Agente | Acción |
|------|--------|--------|
| 0.1.0 Referencias | `entidades` (×N) | **Solo si `referencias/` existe:** por cada archivo Markdown en `referencias/`, leer el contenido, identificar temas principales, construir un índice estructurado (`resumen` + `temas[]` con título, palabras clave y descripción) y persistirlo en Qdrant como entidad `tipo=referencia` (`fijo` = índice serializado, sin `dinamico`). El archivo original queda intacto en `referencias/` como fuente legible. Asignar tag `relevancia_por_hilo:<stable_id_hilo>` por cada hilo al que algún tema del documento sea relevante. |
| 0.1.1 | `entidades` (×N, incremental) | Fichas básicas en Qdrant + `fichas/<tipo>_<slug>.md` para entidades clave |

**Gate:** Entidades clave de cada hilo fichadas (básico). Si hay `referencias/`, todas ingresadas en Qdrant.

**Transición:** `config.json.estado = "diseno_hilos"`.

---

### FASE 0.2 — Hilos (`estado: diseno_hilos`)

Por cada hilo en `config.json.hilos[]`, en orden:

| Paso | Agente | Skill | Acción |
|------|--------|-------|--------|
| 0.2.1 | director | `diseno-hilo` | Conversa diseño → escribe `hilos/hilo-<slug>/diseno-hilo.md` (decisiones firmes) |
| 0.2.2 | `guionista` modo `hilo` | `hechos-estructura`, `plantilla-guion` | Genera `hilos/hilo-<slug>/guion-hilo.md` (solo hechos H_NNNN) |
| 0.2.3 | `entidades` | — | Registra el hilo en Qdrant (`tipo=hilo`) |
| 0.2.4 | director | — | Actualiza `hilos[].estado = "guion_listo"` en `config.json` |

**Gate:** Todos los `guion-hilo.md` completos. Todos `hilos[].estado = "guion_listo"`.

**Transición:** `config.json.estado = "trenzado"`.

---

### FASE 0.3 — Trenzado (`estado: trenzado`)

| Paso | Agente | Skill | Acción |
|------|--------|-------|--------|
| 0.3.1 | director + usuario | `trenzado-narrativo` | Revisar puntos de conexión cross-hilo |
| 0.3.2 | `guionista` modo `trenzado` | `trenzado-narrativo`, `hechos-estructura` | Genera tabla de Trenzado en `guion-novela.md` (capítulos globales con hechos cross-hilo) |

**Reglas de trenzado:** máx. 2 hilos/capítulo; racha máx. 3 caps sin un hilo; clímax en capítulo exclusivo.

**Gate:** Tabla de trenzado completa. Sin hechos huérfanos.

**Transición:** `config.json.estado = "fichas"`.

---

### FASE 1 — Guion (verificación) (`estado: fichas`)

| Paso | Agente | Acción |
|------|--------|--------|
| 1.1 | director | Verifica `guion-novela.md` con trenzado completo: actos, capítulos, tabla, puntos conexión |
| 1.2 | director | Verifica coherencia: hechos en tabla coinciden con `guion-hilo.md` de origen |

**Gate:** `guion-novela.md` validado y consistente.

---

### FASE 2 — Componentes completos (`estado: fichas`)

| Paso | Agente | Acción |
|------|--------|--------|
| 2.1 | director | Verifica Qdrant + Neo4j operativos |
| 2.2 | `entidades` (×N) | Completa fichas con detalle en Qdrant + actualiza `fichas/<tipo>_<slug>.md` |
| 2.3 | `entidades` o director | Crea `fichas/conexion-*.md` para puntos cross-hilo |
| 2.4 | director | Reconciliación cross-hilo: entidades compartidas coherentes en todos los hilos |

**Gate:** Entidades detalladas. Conexiones documentadas. Qdrant y Neo4j operativos.

**Transición:** `config.json.estado = "escritura"`. `config.json.version_qdrant = "activo"`. `config.json.version_neo4j = "activo"`.

---

### FASE 3 — Beat a beat cross-hilo (`estado: escritura`)

Itera por cada capítulo en el orden de la tabla de Trenzado:

#### 3.1 Memoria

| Paso | Agente | Acción |
|------|--------|--------|
| 3.1.1 | `memoria` (deepseek-v4-flash) | Consulta Qdrant (L4, L3 por arco, L2 recientes cross-hilo, entidades) + Neo4j (relaciones activas) → briefing ~600 tokens filtrado por hilo(s) activo(s) |

#### 3.2 Guion del capítulo — pasada 1 (hechos lineales)

| Paso | Agente | Acción |
|------|--------|--------|
| 3.2.1 | `guionista` modo `capitulo`, pasada 1 | Recibe briefing memoria + fila Trenzado + `guion-hilo.md` de hilos implicados + IDs → **crea directorio** `capitulos/cap-NN-slug/` y escribe `capitulos/cap-NN-slug/guion.md` |
| | | **Solo beats de hechos lineales.** Los `[D]` no generan beats: se anotan en `cola_d.md` y se devuelven al director |
| | | Si puente (≥2 hilos): bloques por hilo con `---` |
| | | Si espejo: beats alternados entre hilos |

#### 3.2b Distribución de `[D]` (director)

| Paso | Agente | Acción |
|------|--------|--------|
| 3.2b.1 | director [+ `memoria` si `estado==escritura`] | Revisa la estructura real de escenas. Evalúa cada `[D]` por función narrativa, no por número. Reconoce escenas porosas (montajes que absorben varios beats no consecutivos) |
| 3.2b.2 | director | Anota en `cola_d.md` la posición exacta de cada beat `[D]`: `tras <stable_id> (B_NNNN) en Escena N`, + `stable_id` del hilo |

**Gate:** todo `[D]` de `cola_d.md` tiene posición concreta con `stable_id`. Si falta alguna, se repite 3.2b — no se avanza.

#### 3.2c Guion del capítulo — pasada 2 (inyección `[D]`)

| Paso | Agente | Acción |
|------|--------|--------|
| 3.2c.1 | `guionista` modo `capitulo`, pasada 2 | Recibe `cola_d.md` anotado. Inyecta los beats `[D]` en las posiciones indicadas, revisa transiciones y aplica `renumber-siblings` por `parent_id` e `hilo` (solo cambia `seq`) |

#### 3.2d Auditoría de beats del capítulo

| Paso | Agente | Acción |
|------|--------|--------|
| 3.2d.1 | `auditor-beats` modo `cobertura` | Hechos subdesarrollados: compara `_actos.md` contra `guion.md` |
| 3.2d.2 | `auditor-beats` modo `atomizar` | Beats inconclusos o sobrecargados |
| 3.2d.3 | `auditor-beats` modo `transiciones` | Huecos, incluidos cambios de bloque de hilo. Carga `hechos-distribuidos` si hay `[D]` |
| 3.2d.4 | `auditor-beats` modo `limpieza` | Prosa del escritor infiltrada en los beats |

Cualquier corrección la aplica el `guionista` (modo `capitulo` o `revision`) y usa `renumber-siblings` atómico.

**Gate:** beats atómicos, cerrados y sin prosa. `[D]` validados. Sin hechos subdesarrollados.

#### 3.2e Persistencia temprana (director + `cronista-ops`)

| Paso | Agente | Acción |
|------|--------|--------|
| 3.2e.1 | director | `qdrant.py update-entity` para `dinamico` de entidades con cambio de estado inequívoco en los beats |
| 3.2e.2 | director | `qdrant.py upsert-summary-by-position` L1 por `(nivel, parent_id, seq, hilo)` si hay estructura de escenas o bloques de hilo |

#### 3.3 Beat a beat

Por cada beat `⬜`:

| Paso | Agente | Acción |
|------|--------|--------|
| 3.3.1 | `escritor` | Genera prosa → `draft.md` (append `## <stable_id> [<seq>]`) |
| 3.3.2 | `validador` (read-only) | Scope `completa`. Si ≥2 hilos en cap: + `validacion-cross-hilo` |
| 3.3.3 | `integrador` (condicional) | Si score < 7 o dimensión < 5 |
| 3.3.4 | director | ✅ en `guion.md`. Actualiza `config.json.ultimo_beat_seq` |

#### 3.4 Revisión global

| Paso | Agente | Acción |
|------|--------|--------|
| 3.4.1 | `validador` modo `global` | `draft.md` completo + L4 + tabla Trenzado + arco + hilos activos + `fichas/conexion-*.md` |
| | | Si ≥2 hilos: carga `validacion-cross-hilo` |

#### 3.5 Cronista cross-hilo

| Paso | Agente | Acción |
|------|--------|--------|
| 3.5.1 | `cronista` (deepseek-v4-flash) | Por cada escena (L1) del draft: upsert L1 en Qdrant (etiquetado por hilo), actualizar `dinamico` de entidades con cambio inequívoco, aplicar nuevas relaciones o cambios de rol en Neo4j (`upsert-relationship`) |
| 3.5.2 | `cronista` + `auditoria-neo4j` | Tras procesar todas las escenas: upsert L2 (capítulo), L3 (si cierre arco), L4 (cada 10 caps). Auditoría Neo4j cross-hilo (solo lectura): detectar discrepancias residuales no materializables desde el draft |
| 3.5.3 | `cronista` | Actualiza `config.json`: `capitulos_completados++`, `ultimo_beat_seq`, `hilos[].ultimo_capitulo` |
| 3.5.4 | director | Revisa discrepancias residuales; si son errores de lectura del cronista, las descarta; si son contradictorias, decide |

#### 3.6 Auditoría de trenzado y rachas (cada 3 capítulos y al cerrar el último)

| Paso | Agente | Acción |
|------|--------|--------|
| 3.6.1 | `auditor-beats` modo `trenzado` | `guion-novela.md` sigue reflejando los capítulos escritos. Sin hechos huérfanos. Puntos de conexión materializados o con plazo |
| 3.6.2 | `auditor-beats` modo `rachas` | Racha máx. 3 caps sin un hilo. Bloques `---` bien formados en puentes. Paralelismo real en espejos |
| 3.6.3 | director | Desviación en capítulos futuros → `guionista` modo `trenzado`. Desviación en un tramo escrito → `guionista` modo `revision` |

**Umbral validador:** `score_global ≥ 8` y todas dimensiones ≥ 7 para aprobación directa sin integrador.

**Gate del capítulo:** Todos los beats ✅, Qdrant actualizado (L1+L2+entidades), Neo4j actualizado (relaciones por escena) y auditado cross-hilo.

**Bucle:** Si quedan capítulos en tabla Trenzado, vuelve a 3.1. Si no → `publicacion`.

---

### FASE 4 — Publicar (`estado: publicacion`)

| Paso | Agente | Acción |
|------|--------|--------|
| 4.1 Limpiar capítulos | director | `draft.md` → `capitulo.md` por capítulo (elimina headings `## <stable_id> [<seq>]`, marcadores `<!-- ESCENA ... -->` y notas del escritor; conserva `---` entre hilos) |
| 4.2 Concatenar | director | Todos los `capitulo.md` → `novela.md` |

**Gate:** `capitulo.md` por capítulo + `novela.md`. Sin headings, comentarios ni notas residuales.

**Transición:** `config.json.estado = "finalizado"`.

---

## Transiciones de estado

```
diseno → diseno_hilos → trenzado → fichas → escritura → publicacion → finalizado
```

`finalizado` es el estado terminal del workspace. `publicado` lo asigna solo el hub con `/crear-libro`, que además exige `finalizado` como estado de entrada. El director nunca escribe `publicado`.

**Sub-estados y detección:** `config.json.estado` refleja el estado principal. Los sub-estados de diseño (`diseno`, `diseno_hilos`, `trenzado`) comparten el valor `"diseno"` en el arranque inicial. El director detecta el progreso por:
- `config.json.hilos[].estado` → `"pendiente"`: falta FASE 0.2
- `config.json.hilos[].estado` → `"guion_listo"` en todos los hilos: falta FASE 0.3
- Existencia de tabla `## Trenzado` en `guion-novela.md`: FASE 0.3 completada

Al avanzar FASE 0.2, el director escribe `config.json.estado = "diseno_hilos"`. Al completar FASE 0.3, escribe `config.json.estado = "trenzado"`.

**Plantillas iniciales de hilo:** el script `new-novela-multi-hilo.ps1` crea templates mínimos en `hilos/hilo-<slug>/diseno-hilo.md` y `hilos/hilo-<slug>/guion-hilo.md` con los metadatos del brief (nombre, slug, personajes, conflicto). Estos templates son **reemplazados** por el director (FASE 0.2) y el guionista (modo `hilo`) durante el pipeline. No son el diseño final.

**Creación de directorios:** el `guionista` en modo `capitulo` crea el directorio `capitulos/cap-NN-slug/`. El `escritor` escribe `draft.md` dentro de ese directorio (append).

**Relaciones Neo4j:** el `entidades` las crea inicialmente (FASE 0, FASE 2). Durante la escritura, el `cronista` **escribe** en Neo4j por escena (FASE 3.5.1): detecta relaciones materializadas en el draft y las aplica con `upsert-relationship`. Tras escribir, audita cross-hilo (solo lectura) y reporta discrepancias residuales al `director`. El director solo delega en `entidades` si una discrepancia requiere reestructurar el grafo (corrección de tipo relacional, no detección de nueva relación).

## Agentes activos (9 agentes)

`director`, `guionista`, `auditor-beats`, `escritor`, `validador`, `integrador`, `memoria`, `cronista`, `entidades`

## Skills activos (44)

**Invariantes del hub (40).** Se inyectan desde `shared/.opencode/skills/`:

`mecanica-prosa`, `hechos-estructura`, `hechos-distribuidos`, `tonos-beat`, `plantilla-ficha`, `plantilla-personaje`, `plantilla-lugar`, `plantilla-objeto`, `plantilla-animal`, `plantilla-arco`, `plantilla-evento`, `plantilla-organizacion`, `plantilla-grupo`, `plantilla-ser-sobrenatural`, `validacion-crudeza`, `validacion-coherencia`, `validacion-geometria`, `validacion-sensorial`, `validacion-tono`, `consistencia-narrativa`, `desarrollo-narrativa`, `fichas-personajes`, `cronista-ops`, `estilo-explicito`, `estilo-contemporaneo`, `estilo-erotico`, `estilo-fantasia`, `estilo-noir`, `estilo-romantico`, `estilo-thriller`, `estilo-prosa`, `qdrant`, `neo4j`, `auditoria-neo4j`, `scaffolding-hecho`, `scaffolding-acto`, `diseno-hilo`, `trenzado-narrativo`, `validacion-cross-hilo`, `plantilla-hilo`

**Exclusivos de escala (4).** Definidos solo en `shared/pipelines/novela-multi-hilo/skills/`; no existe versión común de estos cuatro. Si una escala futura declara uno con el mismo nombre en `shared/`, el de escala prevalece:

`beats-estructura`, `estructura-narrativa`, `plantilla-guion`, `contexto-subagente`

**No se inyecta** `contexto-narrativo`: es la memoria Markdown de la escala relato. Aquí la memoria es Qdrant + Neo4j, con `contexto.md` como resumen legible del director.

Los cuatro últimos son los que hacen a esta escala consciente de los hilos: definen el campo `hilo` en el beat, la jerarquía con bloques de hilo, la estructura de `guion-hilo.md` y el contrato de briefing con `stable_id` de hilo.

## Comandos

- `/refinar-hechos` — revisa y afina los hechos de `_actos.md` antes de generar
- `/validar-hechos` — valida coherencia narrativa entre hechos, detecta problemas de interpretación y propone mejoras
- `/generar` — inicia o continúa desde `config.json.estado`
- `/revisar-guion` — revisa la coherencia estructural (trenzado, reparto por hilo, arcos, ritmo, transiciones)
- `/revisar B_NNNN [instrucciones]` — revisión puntual de un beat (incluye cross-hilo si el capítulo tiene ≥2 hilos)
- `/expandir B_NNNN [instrucciones]` — expansión de un beat
- `/publicar` — salida limpia (`capitulo.md` por capítulo + `novela.md`), deja el workspace en `finalizado`

`/corregir` no se inyecta en esta escala: contempla solo ediciones derivadas de relato.

## Infraestructura

**Qdrant REQUERIDO.** Colecciones: `entidades`, `summaries`, `beats`.
**Neo4j REQUERIDO.** Grafo de relaciones entre entidades con trazabilidad cross-hilo.

Scripts: `scripts/qdrant.py` (init, check, query, upsert), `scripts/neo4j.py` (init, check, query).

## Capítulos puente y espejo

| Tipo | Descripción | Guion | Validación |
|------|-------------|-------|------------|
| **Exclusivo** | Un solo hilo | Beats normales | Sin cross-hilo |
| **Puente** | ≥2 hilos | Bloques por hilo con `---` | `validacion-cross-hilo` |
| **Espejo** | ≥2 hilos, paralelismos | Beats alternados | `validacion-cross-hilo` |

## Tabla de Trenzado (en guion-novela.md)

| Cap | Hilo(s) | Hechos | Tipo | Conexiones |
|-----|---------|--------|------|------------|
| cap-01 | hilo-a | H_0001, H_0002 | exclusivo | — |
| cap-02 | hilo-b | H_0003 | exclusivo | — |
| cap-03 | hilo-a, hilo-b | H_0004, H_0005 | puente | objeto_x |
| ... | ... | ... | ... | ... |

## Política de reintentos

Máximo 3 reintentos por beat. Tipos: formato, contenido, timeout. Ver `ORQUESTACION.md` para detalle.




