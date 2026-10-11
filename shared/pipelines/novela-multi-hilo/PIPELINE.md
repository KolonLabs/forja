# Pipeline — Novela Multi-hilo (9 fases)

Escala `novela-multi-hilo`. Qdrant+Neo4j activos. Múltiples líneas temporales/POVs que se diseñan y desarrollan **dentro de cada hilo** (beats y escenas agrupados en capítulos-borrador por coherencia de contexto) antes de trenzarse en capítulos globales a nivel de **escena**.

> Spawn y contratos: `ORQUESTACION.md` · Estado: `config.json` + `guion-novela.md` statuses + `hilos[]`

## Jerarquía narrativa

```
hilos/hilo-<slug>/
  ├── diseno-hilo.md   (decisiones de diseño del hilo)
  ├── guion-hilo.md    (hechos H_NNNN del hilo, agrupados por Acto + lista de
  │                     capítulos-borrador: rango de hechos, objetivo, tensión)
  ├── cola_d.md        (registro de contenido por hecho [D]: stable_id + escena +
  │                     resumen corto de cada instancia ya escrita; efímero por
  │                     hilo — nace en FASE 0.3 y se descarta al cerrar el hilo)
  └── cap-NN/
      └── guion.md     (beats + escenas del capítulo-borrador; SIN prosa;
                         NO se persiste en Qdrant — no hay resumen L1-L4
                         hasta que hay prosa real de un capítulo YA trenzado)

guion-novela.md
  ├── Actos con capítulos (reales, ensamblados desde escenas de los hilos)
  ├── ## Trenzado (tabla: escenas por capítulo global, hilo(s), tipo, conexiones)
  └── ## Puntos de conexión (prosa temática en FASE 0; el trenzado la reescribe
      con stable_id de escena concretos al descubrir dónde se materializa cada una)

capitulos/cap-NN-slug/
  ├── guion.md         (escenas ensambladas desde hilos/*/cap-NN/guion.md;
  │                     puente: bloques con ---; sin [D] pendientes — se
  │                     resolvieron todos en FASE 0.3, dentro del hilo)
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
| `H_NNNN` | Evento que debe ocurrir (planificación). Puede ser lineal o distribuido `[D]`. Un hecho pertenece a un único hilo — `[D]` es siempre intra-hilo. | `guion-hilo.md` |
| Escena (`stable_id`, sin display numérico propio) | Unidad de agrupación de beats por coherencia de contexto (mismo espacio/tiempo/cast). Es la **unidad atómica del trenzado**. | `hilos/hilo-<slug>/cap-NN/guion.md` (nace aquí), `capitulos/cap-NN-slug/guion.md` (destino tras trenzar) |
| `B_NNNN` | Beat: unidad dramática con compromiso verificable (display derivado de `seq`) | `hilos/hilo-<slug>/cap-NN/guion.md` (bajo una escena, antes de trenzar), `capitulos/.../guion.md` (después) |

- Los `stable_id` son opacos, inmutables y globales a la novela. El `seq` de un beat es **local a su escena padre**; los hechos conservan su secuencia de planificación (`ultimo_hecho_seq`).
- En `guion-hilo.md` solo hay **hechos**; los beats y escenas se generan en FASE 0.3, **dentro de cada hilo**, agrupando hechos en capítulos-borrador por coherencia de contexto (no por cuota fija de hechos).
- Estados: ✅ completo · 🔄 en progreso · ⬜ pendiente.
- Un hecho `[D · H_XX–H_YY]` describe un patrón recurrente dentro del propio hilo, no un momento único. En FASE 0.3, el `guionista` lo despliega como beats entretejidos con los lineales durante la generación del capítulo-borrador — una sola pasada creativa, sin inyección diferida. El número de instancias es juicio narrativo contextual, no una fórmula prefijada. Al terminar FASE 0.3, ningún beat conserva marca `[D]`: son indistinguibles de los lineales. `hilos/hilo-<slug>/cola_d.md` registra el contenido de cada instancia (stable_id + escena + resumen) para evitar repetición entre capítulos-borrador que comparten un mismo `[D]`, y se descarta al cerrar el hilo.
- Trenzar significa mover el **bloque de escena completo** (con sus beats) desde `hilos/hilo-<slug>/cap-NN/guion.md` a `capitulos/cap-NN-slug/guion.md`, actualizando `parent_id`/`seq` vía `renumber-siblings`. El `stable_id` de la escena y de cada beat es inmutable.
- Skills: `beats-estructura`, `tonos-beat`, `plantilla-guion`, `hechos-distribuidos`.

---

## Fases

### FASE 0 — Diseño global (`estado: diseno`)

Los pasos internos de esta fase usan letras (`0.a`–`0.f`) para no chocar con la numeración de las fases mayores que siguen (`FASE 0.1`, `FASE 0.2`...).

| Paso | Agente | Acción |
|------|--------|--------|
| 0.a Referencias | director | **Solo si `referencias/` existe:** leer los archivos Markdown directamente (sin Qdrant). Extraer información relevante del universo, biblia científica, personajes y conflictos previos que informará las decisiones de hilos y hechos. **Qdrant no se alimenta aquí** — la ingestión con índice estructurado ocurre en FASE 0.1. |
| 0.b `[D]` | director | **Identificar hechos `[D]`** en `_actos.md`. Cargar `hechos-distribuidos`. Anotar granularidad y distribución — cada `[D]` pertenece a un único hilo (identificable por la sección de `_actos.md` donde aparece, aunque `config.json.hilos[]` aún no esté poblado). |
| 0.c Hilos | director + usuario | Identificar hilos: nombre, slug, época, ubicación, personajes, conflicto, tono. **Informado por las referencias leídas** (si existen). El director cruza el material de `referencias/` con el brief para proponer hilos fundados. |
| 0.d Conexiones | director + usuario | Identificar puntos de conexión cross-hilo (objetos, personajes, revelaciones) |
| 0.e Sembrar config | director | Sembrar `config.json.hilos[]` y `puntos_conexion` |
| 0.f Seed entidades | director → `entidades` (×N) + `neo4j.py` | Inferir entidades semilla de `_actos.md` + `BRIEF.md` + hilos. Crear en Qdrant (stable_id, tipo, nombre, fijo) + Neo4j (relaciones básicas, cross-hilo) |

**Gate:** Todos los hilos identificados con conflicto propio. `config.json.hilos[]` poblado.

---

### FASE 0.1 — Refinamiento de hechos (`estado: diseno`)

Objetivo: revisar los hechos del brief (del scaffolder) a la luz de las referencias leídas y los hilos confirmados, antes de comprometerlos a `guion-hilo.md`. Es un diálogo con el usuario.

| Paso | Agente | Acción |
|------|--------|--------|
| 0.1.1 Revisión de hechos | director + usuario | El director presenta los hechos de `_actos.md` al usuario. A la luz de las referencias leídas (paso 0.0), los hilos confirmados (paso 0.2) y las conexiones (paso 0.3), el director propone ajustes: añadir, eliminar, fusionar, dividir o reescribir hechos. El usuario confirma, rechaza o pide cambios adicionales. El director aplica los cambios vía guionista si la reescritura es estructural. Itera hasta que el usuario confirma el conjunto. |
| 0.1.2 Ingesta referencias | `entidades` (×N) | Ingestar cada archivo de `referencias/` en Qdrant como `tipo=referencia`: leer el Markdown, identificar temas, construir el índice estructurado (`fijo` = `resumen` + `temas[]`), asignar tags `relevancia_por_hilo:<stable_id_hilo>`. |
| 0.1.3 Fichas básicas | `entidades` (×N, incremental) | Fichas básicas en Qdrant + `fichas/<tipo>_<slug>.md` para entidades clave |

**Gate:** Hechos refinados y confirmados por el usuario. Referencias ingeridas en Qdrant. Entidades clave de cada hilo fichadas (básico).

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
| 0.2.5 | director | — | **Limpiar `diseno-hilo.md`**: eliminar secciones `## Decisiones tomadas`, `## Pendientes` y `## Descartado`. Son arqueología editorial útil durante la fase de diseño pero ruido para agentes posteriores (`guionista`, `memoria`). Conservar: conflicto central, estructura, personajes, lugares, tono y puntos de conexión. |

**Gate:** Todos los `guion-hilo.md` completos. Todos `hilos[].estado = "guion_listo"`. `diseno-hilo.md` limpios de arqueología editorial.

**Transición:** `config.json.estado = "hilos_beats"`.

---

### FASE 0.3 — Beats y escenas por hilo (`estado: hilos_beats`)

Por cada hilo en `config.json.hilos[]` (con `estado: guion_listo`), en orden:

| Paso | Agente | Skill | Acción |
|------|--------|-------|--------|
| 0.3.1 | director | `hechos-estructura` | Agrupa los hechos `H_NNNN` de `guion-hilo.md` en **capítulos-borrador** por coherencia de contexto (mismo espacio/tiempo/cast) — **no** por cuota fija de hechos. Añade a `guion-hilo.md` una sección `## Capítulos-borrador` con rango de hechos, objetivo narrativo y tensión de cada uno. Si algún `[D]` cruza varios capítulos-borrador, el director lo anota para coordinar la continuidad. |

Por cada capítulo-borrador del hilo, en el orden en que aparecen:

**Si NO contiene ningún `[D]` en su rango:**

| Sub-paso | Agente | Acción |
|----------|--------|--------|
| a | `guionista` modo `hilo-capitulo` | Genera beats + los agrupa en escenas en `hilos/hilo-<slug>/cap-NN/guion.md` en una sola pasada. Recibe **contexto acotado**: últimos beats del capítulo-borrador anterior + objetivo/tensión del actual + resumen compacto de entidades y relaciones relevantes (estilo `memoria`, no fichas completas ni `diseno-hilo.md`/`guion-hilo.md` íntegros). |
| b — **Checkpoint** | director + usuario | Revisan la estructura de escenas propuesta (número de escenas, beats por escena, cortes). El usuario valida o pide ajustes. Más ligero que los checkpoints de `[D]` — no hay instancias que validar, solo estructura. |

**Si contiene algún `[D]` en su rango:**

| Sub-paso | Agente | Acción |
|----------|--------|--------|
| a — **Checkpoint 1 (plan)** | `guionista` → director + usuario | El guionista **propone** un plan para este tramo: qué instancias del patrón `[D]` va a escribir (contenido aproximado, no solo número), informado por la prosa del hecho `[D]` y el registro de instancias ya escritas en capítulos-borrador anteriores del mismo `[D]` (consulta `hilos/hilo-<slug>/cola_d.md` si existe). El director + usuario validan o ajustan el plan. **Sin fórmula numérica fija:** el número de instancias es juicio narrativo contextual. |
| b | `guionista` modo `hilo-capitulo` | **Una sola pasada creativa**: genera la secuencia completa de beats del tramo — lineales y `[D]` entretejidos de forma natural según el plan aprobado. Sin inyección diferida, sin pasada separada para `[D]`. |
| c | `guionista` modo `hilo-capitulo` | Agrupa esa secuencia completa en escenas (marcador `<!-- ESCENA <stable_id>: Nombre -->`) dentro de `hilos/hilo-<slug>/cap-NN/guion.md`. |
| d — **Checkpoint 2 (resultado)** | director + usuario | Revisan beats + escenas ya agrupadas, verificando que las instancias `[D]` no repiten lo ya escrito en tramos anteriores (contra `cola_d.md`). |
| e | director | Actualiza `hilos/hilo-<slug>/cola_d.md` (crear si no existe): por cada `[D]` con instancias en este tramo, registra `stable_id` del beat + escena donde se insertó + resumen corto de lo que muestra. Si un `[D]` completa su rango en este capítulo-borrador, se cierra su entrada. |

**Cierre del hilo:** cuando todos los capítulos-borrador del hilo están completos y todos los `[D]` del hilo tienen sus entradas cerradas en `cola_d.md`, el director marca `hilos[].estado = "beats_listos"`. `cola_d.md` se descarta (todas las entradas cerradas, sin contenido pendiente).

**Gate:** Todos los hilos con `hilos[].estado = "beats_listos"`. Ningún hecho, lineal o `[D]`, sin beats. Ningún beat marcado `[D]` sobrevive — son indistinguibles de los lineales.

**Transición:** `config.json.estado = "trenzado"`.

---

### FASE 0.4 — Trenzado (`estado: trenzado`)

| Paso | Agente | Skill | Acción |
|------|--------|-------|--------|
| 0.4.1 | `guionista` modo `trenzado` | `trenzado-narrativo`, `hechos-estructura` | Lee todas las escenas reales de `hilos/hilo-*/cap-NN/guion.md` (contenido completo: beats, personajes, objetos, referencias) y el `## Puntos de conexión` de `guion-novela.md` (prosa temática, escrita en FASE 0 antes de que existieran escenas — sirve de pista, no de lista a verificar mecánicamente). **Descubre** en el contenido real dónde se materializa cada conexión —y cualquier eco orgánico no previsto— y ensambla las escenas en capítulos globales reales: crea `capitulos/cap-NN-slug/guion.md` moviendo cada bloque de escena completo (con sus beats), actualiza `parent_id`/`seq` vía `renumber-siblings` (el `stable_id` de escena y beats no cambia). |
| 0.4.2 | `guionista` modo `trenzado` | `trenzado-narrativo` | Genera la tabla `## Trenzado` en `guion-novela.md` y **reescribe** su sección `## Puntos de conexión`: pasa de prosa temática a referencias concretas por `stable_id` de escena, reflejando lo que efectivamente descubrió. |
| 0.4.3 | director + usuario | `trenzado-narrativo` | Revisa el resultado: capítulos, tipos, conexiones descubiertas (incluidas las no previstas). Ajusta si hace falta. |

**Reglas de trenzado:** máx. 2 hilos/capítulo; racha máx. 3 caps sin un hilo; clímax en capítulo exclusivo.

**Gate:** Tabla de trenzado completa. Todas las escenas asignadas a un capítulo global. Sin escenas huérfanas. `## Puntos de conexión` de `guion-novela.md` referencia `stable_id` de escena, no prosa genérica.

**Transición:** `config.json.estado = "fichas"`.

---

### FASE 1 — Guion (verificación) (`estado: fichas`)

| Paso | Agente | Acción |
|------|--------|--------|
| 1.1 | director | Verifica `guion-novela.md` con trenzado completo: actos, capítulos, tabla y puntos conexión |
| 1.2 | director | Verifica coherencia: las escenas de la tabla coinciden con las de `hilos/hilo-<slug>/cap-NN/guion.md` de origen (mismo `stable_id`) y con los hechos de `guion-hilo.md` |

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

### FASE 3 — Escritura por escena cross-hilo (`estado: escritura`)

Itera por cada capítulo en el orden de la tabla de Trenzado:

#### 3.1 Memoria

| Paso | Agente | Acción |
|------|--------|--------|
| 3.1.1 | `memoria` | Consulta Qdrant (L4, L3 por arco, L2 recientes cross-hilo, entidades) + Neo4j (relaciones activas) → briefing ~600 tokens filtrado por hilo(s) activo(s) |

#### 3.2 Auditoría de costuras cross-hilo (capítulo ya ensamblado)

El capítulo llega a esta fase con sus escenas **ya generadas dentro de cada hilo** (FASE 0.3) y **ya movidas** a `capitulos/cap-NN-slug/guion.md` (FASE 0.4). Lo que falta auditar son las **costuras**: las escenas de distintos hilos se escribieron en llamadas independientes al guionista y pueden no encajar en la transición.

| Paso | Agente | Acción |
|------|--------|--------|
| 3.2.1 | `auditor-beats` modo `transiciones` [+ `validacion-cross-hilo` si ≥2 hilos en el cap] | Enfocado específicamente en las costuras entre bloques de escenas provenientes de distintos hilos: continuidad temporal, tono, y si el corte funciona como puente/espejo real |
| 3.2.2 | director + usuario | **Checkpoint obligatorio.** Presenta los problemas de costura detectados (o su ausencia). El usuario valida o pide ajustes. |
| 3.2.3 | `guionista` modo `revision` (condicional) | Solo si 3.2.2 señaló ajustes: corrige el tramo de costura señalado |

**Gate:** Costuras cross-hilo sin discontinuidades sin resolver, o el usuario acepta explícitamente dejarlas.

#### 3.2b Auditoría general de beats del capítulo (segunda pasada)

| Paso | Agente | Acción |
|------|--------|--------|
| 3.2b.1 | `auditor-beats` modo `cobertura` | Hechos subdesarrollados: compara `_actos.md` contra `guion.md` |
| 3.2b.2 | `auditor-beats` modo `atomizar` | Beats inconclusos o sobrecargados |
| 3.2b.3 | `auditor-beats` modo `transiciones` | Huecos, incluidos cambios de bloque de hilo |
| 3.2b.4 | `auditor-beats` modo `limpieza` | Prosa del escritor infiltrada en los beats |

Cualquier corrección la aplica el `guionista` (modo `revision`) y usa `renumber-siblings` atómico.

**Gate:** beats atómicos, cerrados y sin prosa. Sin hechos subdesarrollados.

#### 3.2c Persistencia temprana (director + `cronista-ops`)

| Paso | Agente | Acción |
|------|--------|--------|
| 3.2c.1 | director | `qdrant.py update-entity` para `dinamico` de entidades con cambio de estado inequívoco en los beats |
| 3.2c.2 | director | L1 por escena con el `stable_id` canónico del guion: `qdrant.py upsert-summary --id <stable_id_escena> --nivel L1 --parent-id <capitulo> --seq <N> --hilo <stable_id_hilo>` (o `upsert-summary-by-position --id`). Nunca se genera un ID L1 nuevo |

#### 3.3 Escritura por escena con checkpoint

Por cada escena `⬜` del capítulo, en el orden del trenzado:

| Paso | Agente | Acción |
|------|--------|--------|
| 3.3.1 | director | Prepara el contexto inline (canon, memoria, voz/POV, fichas, hilo, costuras puente/espejo y pasajes pertinentes de `referencias/`) e invoca al `escritor` UNA vez con la escena completa |
| 3.3.2 | director | Comprueba terminación real (`stop`/`length`), guarda la salida y ejecuta `persistir-escena.py preparar --finish stop`; queda `escena-<SID>.pendiente.md` con SHA256 |
| 3.3.3 | director + usuario | **Checkpoint obligatorio:** presenta la escena completa con hash/versión y se detiene; sin conformidad no hay revisión ni aceptación |
| 3.3.4 | `validador` (read-only) | Revisión editorial de escena con el hash vigente. Si ≥2 hilos: + `validacion-cross-hilo` como incidencias |
| 3.3.5 | `integrador` (condicional) | Solo fragmentos con incidencia `bloqueante`/`corregir`; devuelve secciones completas. Nuevo texto vuelve a `preparar`, se presenta y se espera de nuevo |
| 3.3.6 | director | Con conformidad y review `aprobado` del mismo hash: `aceptar` → `sincronizar` → marca beats `✅` en lote. Autorización de avance a la siguiente escena por separado |

#### 3.4 Revisión global

| Paso | Agente | Acción |
|------|--------|--------|
| 3.4.1 | `validador` modo `global` | `draft.md` completo + L4 + tabla Trenzado + arco + hilos activos + `fichas/conexion-*.md` |
| | | Si ≥2 hilos: carga `validacion-cross-hilo` |

#### 3.5 Cronista cross-hilo

| Paso | Agente | Acción |
|------|--------|--------|
| 3.5.1 | `cronista` | Por cada escena (L1) del draft: upsert L1 en Qdrant (etiquetado por hilo), actualizar `dinamico` de entidades con cambio inequívoco, aplicar nuevas relaciones o cambios de rol en Neo4j (`upsert-relationship`) |
| 3.5.2 | `cronista` + `auditoria-neo4j` | Tras procesar todas las escenas: upsert L2 (capítulo), L3 (si cierre arco), L4 (cada 10 caps). Auditoría Neo4j cross-hilo (solo lectura): detectar discrepancias residuales no materializables desde el draft |
| 3.5.3 | `cronista` | Actualiza `config.json`: `capitulos_completados++`, `ultimo_beat_seq`, `hilos[].ultimo_capitulo` |
| 3.5.4 | director | Revisa discrepancias residuales; si son errores de lectura del cronista, las descarta; si son contradictorias, decide |

#### 3.6 Auditoría de trenzado y rachas (cada 3 capítulos y al cerrar el último)

| Paso | Agente | Acción |
|------|--------|--------|
| 3.6.1 | `auditor-beats` modo `trenzado` | `guion-novela.md` sigue reflejando los capítulos escritos. Sin hechos huérfanos. Puntos de conexión materializados o con plazo |
| 3.6.2 | `auditor-beats` modo `rachas` | Racha máx. 3 caps sin un hilo. Bloques `---` bien formados en puentes. Paralelismo real en espejos |
| 3.6.3 | director | Desviación en capítulos futuros → `guionista` modo `trenzado`. Desviación en un tramo escrito → `guionista` modo `revision` |

**Gate editorial:** sin incidencias `bloqueante` ni `corregir` y con conformidad del usuario ligada al mismo hash. Las observaciones `opcional` no bloquean.

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
diseno → diseno_hilos → hilos_beats → trenzado → fichas → escritura → publicacion → finalizado
```

`finalizado` es el último estado que escribe el director. `publicado` lo asigna solo `/compilar` (`scripts/compilar.ps1`), que exige `finalizado` o `publicado` como estado de entrada. El director nunca escribe `publicado`.

**Sub-estados y detección:** `config.json.estado` refleja el estado principal. Los sub-estados de diseño (`diseno`, `diseno_hilos`) comparten el valor `"diseno"` en el arranque inicial. El director detecta el progreso por:
- `config.json.hilos[].estado` → `"pendiente"`: falta FASE 0.2
- `config.json.hilos[].estado` → `"guion_listo"` en todos los hilos: falta FASE 0.3 (beats y escenas por hilo)
- `config.json.hilos[].estado` → `"beats_listos"` en todos los hilos: falta FASE 0.4 (trenzado)
- Existencia de tabla `## Trenzado` en `guion-novela.md`: FASE 0.4 completada

Al avanzar FASE 0.2, el director escribe `config.json.estado = "diseno_hilos"`. Al completar FASE 0.2 (todos los hilos `guion_listo`), escribe `config.json.estado = "hilos_beats"`. Al completar FASE 0.3 (todos los hilos `beats_listos`), escribe `config.json.estado = "trenzado"`. Al completar FASE 0.4, escribe `config.json.estado = "fichas"`.

**Plantillas iniciales de hilo:** el script `new-novela-multi-hilo.ps1` crea templates mínimos en `hilos/hilo-<slug>/diseno-hilo.md` y `hilos/hilo-<slug>/guion-hilo.md` con los metadatos del brief (nombre, slug, personajes, conflicto). Estos templates son **reemplazados** por el director (FASE 0.2) y el guionista (modo `hilo`) durante el pipeline. No son el diseño final.

**Creación de directorios:** el `guionista` en modo `hilo-capitulo` crea el directorio `hilos/hilo-<slug>/cap-NN/` (FASE 0.3). El `guionista` en modo `trenzado` crea `capitulos/cap-NN-slug/` al mover las escenas (FASE 0.4). El `escritor` escribe `draft.md` dentro de ese último directorio (append).

**Relaciones Neo4j:** el `entidades` las crea inicialmente (FASE 0, FASE 2). Durante la escritura, el `cronista` **escribe** en Neo4j por escena (FASE 3.5.1): detecta relaciones materializadas en el draft y las aplica con `upsert-relationship`. Tras escribir, audita cross-hilo (solo lectura) y reporta discrepancias residuales al `director`. El director solo delega en `entidades` si una discrepancia requiere reestructurar el grafo (corrección de tipo relacional, no detección de nueva relación).

## Agentes activos (9 agentes)

`director`, `guionista`, `auditor-beats`, `escritor`, `validador`, `integrador`, `memoria`, `cronista`, `entidades`

## Skills activos (44)

**Invariantes del hub (40).** Se inyectan desde `shared/skills/` en `.claude/skills/` del workspace (las leen opencode y Claude Code):

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
- `/compilar [--epub] [--pdf]` — compila el libro en `publicacion/` y asigna `publicado` (`scripts/compilar.ps1`)
- `/borrador [cap-NN] [--epub] [--pdf]` — versión limpia de revisión de un capítulo (el en curso por defecto), solo con sus escenas completas; no cambia el estado (`scripts/borrador.ps1`)

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

| Cap | Hilo(s) | Escenas | Hechos | Tipo | Conexiones |
|-----|---------|---------|--------|------|------------|
| cap-01 | hilo-a | ESC_a1, ESC_a2 | H_0001, H_0002 | exclusivo | — |
| cap-02 | hilo-b | ESC_b1 | H_0003 | exclusivo | — |
| cap-03 | hilo-a, hilo-b | ESC_a3, ESC_b2 | H_0004, H_0005 | puente | objeto_x |
| ... | ... | ... | ... | ... | ... |

La columna **Escenas** es la unidad real que se mueve al trenzar (`stable_id`, no display). La columna **Hechos** queda como referencia de trazabilidad hacia `guion-hilo.md`.

## Política de reintentos

Máximo 3 reintentos por beat. Tipos: formato, contenido, timeout. Ver `ORQUESTACION.md` para detalle.




