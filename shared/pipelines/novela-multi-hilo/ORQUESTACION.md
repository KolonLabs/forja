# Orquestación — agentes, skills y rutas de datos (NOVELA MULTI-HILO)

Referencia para **director** y subagentes. Rutas en `MAPA.md`. Fases en `PIPELINE.md`.

---

## Reglas globales

1. **Quién escribe qué:** solo el agente indicado en la columna «Escribe» modifica ese archivo.
2. **Briefing de spawn:** el director pasa siempre rutas relativas al workspace, IDs (`H_`/`B_`), y `Modo`.
3. **IDs:** cada elemento tiene un `stable_id` opaco e inmutable y un `seq` posicional. `seq` se asigna desde `config.json` → `ultimo_hecho_seq` / `ultimo_beat_seq` y es global en toda la novela (4 dígitos, nunca se reinicia por hilo ni capítulo). Tras asignar, incrementar en el archivo que creó el ID.
   - `H_NNNN` y `B_NNNN` son **displays derivados de `seq`**, nunca identidad persistida.
   - Toda referencia interna (`parent_id`, conexiones cross-hilo, fichas, `cola_d.md`) usa `stable_id`.
4. **Estados en guion:** `⬜` → `🔄` (al empezar beat) → `✅` (validador aprueba). Lo marca el **director** tras cada beat.
5. **Backup** antes de sobrescribir archivos con contenido existente.
6. **Hilos:** el campo `hilo` es siempre el `stable_id` de una entidad `tipo=hilo`. `hilo-sumeria` es slug humano de navegación, nunca identidad.

---

## Matriz de agentes (9 agentes)

| Agente | Invocado por | Lee | Escribe | Invoca | Modelo |
|--------|--------------|-----|---------|--------|--------|
| **director** | usuario `/generar`, `/revisar`, `/expandir`, `/publicar`, `/refinar-hechos`, `/validar-hechos`, `/revisar-guion` | `PIPELINE.md`, `MAPA.md`, `config.json`, `BRIEF.md`, `AGENTS.md`, `contexto.md`, guiones según fase | `config.json`, `contexto.md`, `diseno-hilo.md`, `cola_d.md`, estados en guiones, `draft.md` (ensamblado y separadores `---`), `capitulo.md`, `novela.md` | guionista, escritor, validador, integrador, memoria, cronista, entidades, auditor-beats | `deepseek-v4-pro` |
| **guionista** | director | Briefing + archivos del modo (ver tabla modos abajo) | Guiones según modo y escala | — | `deepseek-v4-pro` |
| **auditor-beats** | director | `guion.md` o `guion-novela.md`, `_actos.md`, `AGENTS.md` | — (read-only, diagnóstico al director) | — | `deepseek-v4-pro` |
| **escritor** | director | Briefing + `guion.md` (beat), `contexto.md`, `fichas/` relevantes, `AGENTS.md`, estilo skill | `draft.md` (append sección `## <stable_id> [<seq>]`) | — | `deepseek-v4-pro` |
| **validador** | director | Briefing + texto del beat, `guion.md`, `contexto.md`, `fichas/` | — (solo JSON) | — | `deepseek-v4-pro` |
| **integrador** | director | Briefing + `draft.md` (beat), JSON validador | `draft.md` (reemplaza sección beat) | — | `deepseek-v4-pro` |
| **memoria** | director | `config.json`, especificación de entidades del cap, hilo(s) activo(s) | — (solo briefing de ~600 tokens) | — | `deepseek-v4-flash` |
| **cronista** | director (cierre de cap) | `draft.md` completo, `config.json`, hilo(s) activo(s) | Qdrant (summaries L1-L4 + entidades `dinamico`), `config.json` (contadores) | — | `deepseek-v4-flash` |
| **entidades** | director | Nombre, tipo, descripción de entidad + contexto narrativo | Qdrant (`upsert-entity`) + `fichas/<tipo>_<slug>.md` | — | `deepseek-v4-pro` |

---

## Guionista — modos y contrato

| Modo | Lee | Escribe | Actualiza config |
|------|-----|---------|------------------|
| `hilo` | `hilos/hilo-S/diseno-hilo.md`, `BRIEF.md`, briefing (slug hilo) | `hilos/hilo-S/guion-hilo.md` (solo hechos) | `ultimo_hecho_seq`; director actualiza `hilos[].estado` |
| `trenzado` | Todos `guion-hilo.md`, `guion-novela.md`, `config.json.hilos` | `guion-novela.md` (tabla `## Trenzado`) | — (director pone `estado=trenzado`) |
| `capitulo` pasada 1 | Tabla trenzado, `guion-hilo.md` de hilos del cap, `contexto.md`, `fichas/` | `capitulos/cap-NN-slug/guion.md` (solo hechos lineales) + `cola_d.md` | `ultimo_hecho_seq`, `ultimo_beat_seq` |
| `capitulo` pasada 2 | `cola_d.md` anotado por el director, `guion.md` del cap | `capitulos/cap-NN-slug/guion.md` (inyecta beats `[D]`) | `ultimo_beat_seq` |
| `revision` | `capitulos/cap-NN-slug/guion.md` (tramo + contexto bilateral), `AGENTS.md` [+ `memoria` si `estado==escritura`] | `capitulos/cap-NN-slug/guion.md` (reemplaza tramo) | — (mismos `stable_id`) |

---

## Auditor-beats — modos y contrato

Read-only en los seis modos. Siempre devuelve diagnóstico al director; nunca modifica archivos.

| Modo | Lee | Skills | Cuándo lo invoca el director |
|------|-----|--------|------------------------------|
| `cobertura` | `capitulos/cap-NN-slug/guion.md`, `_actos.md`, `AGENTS.md` [+ `memoria` si `estado==escritura`] | `beats-estructura`, `estructura-narrativa` | FASE 3.2d |
| `atomizar` | `capitulos/cap-NN-slug/guion.md`, `_actos.md`, `AGENTS.md` | `beats-estructura` | FASE 3.2d |
| `transiciones` | `capitulos/cap-NN-slug/guion.md`, `_actos.md`, `AGENTS.md` [+ `memoria` si `estado==escritura`] | `validacion-coherencia`, `beats-estructura` [+ `hechos-distribuidos` si hay `[D]`] | FASE 3.2d |
| `limpieza` | `capitulos/cap-NN-slug/guion.md`, `AGENTS.md` | `beats-estructura`, `mecanica-prosa` | FASE 3.2d |
| `trenzado` | `guion-novela.md`, `hilos/*/guion-hilo.md`, `config.json` | `trenzado-narrativo`, `diseno-hilo` | FASE 3.6 (cada 3 caps y al cerrar el último) |
| `rachas` | `guion-novela.md`, `guion.md` de los caps del tramo | `validacion-cross-hilo`, `diseno-hilo` | FASE 3.6 |

`trenzado` y `rachas` son exclusivos de esta escala: auditan la arquitectura entre hilos, no los beats de un capítulo. Sin ellos el trenzado se degrada sin aviso.

### → auditor-beats

```
Modo: [cobertura | atomizar | transiciones | limpieza | trenzado | rachas]
Leer: [rutas según el modo — ver tabla]
{{#if estado==escritura}}Memoria: briefing ligero (~300t) desde memoria{{/if}}
{{#if modo trenzado o rachas}}
Tramo auditado: capítulos [NN]–[MM] cerrados desde la última auditoría
Hilos: [nombre] (stable_id: [8hex]) — uno por línea, con su último capítulo
Reglas: máx. 2 hilos/capítulo · racha máx. 3 caps sin un hilo ·
        clímax de hilo en capítulo exclusivo · puentes con propósito
{{/if}}
Output: diagnóstico al director (tablas de problemas + propuestas)
No modificar archivos
```

---
## Skills — rol y quién los carga

| Skill | Invocación | Quién lo aplica | Efecto |
|-------|------------|-----------------|--------|
| `mecanica-prosa` | automática | escritor, integrador | Formato de prosa: guiones de diálogo, párrafos, ⚡, cursiva |
| `beats-estructura` | automática | guionista, auditor-beats, escritor (lectura) | Formato de beat `stable_id [seq]` + `[Tono — EXTENSIÓN] [Personajes] [Zona] [Hilos]` |
| `hechos-estructura` | automática | guionista | Formato de hecho narrativo con `stable_id [seq]` |
| `tonos-beat` | automática | guionista (asignar), escritor (ejecutar) | Catálogo de 15 tonos + reglas BREVE/MEDIA/EXTENSA |
| `estructura-narrativa` | automática | guionista | Jerarquía: actos → capítulos → escenas → beats |
| `plantilla-guion` | automática | guionista | Estructura de archivos de guion (simple y multi-hilo) |
| `plantilla-ficha` | automática | entidades | Estructura FIJO/DINÁMICO para 10 tipos de entidad |
| `plantilla-personaje` / `plantilla-lugar` / `plantilla-objeto` / `plantilla-animal` / `plantilla-arco` / `plantilla-evento` / `plantilla-hilo` / `plantilla-organizacion` | automática | entidades | Campos obligatorios por tipo de entidad |
| `estilo-explicito` / `estilo-contemporaneo` / `estilo-erotico` / `estilo-fantasia` / `estilo-noir` / `estilo-romantico` / `estilo-thriller` | automática | escritor, integrador, validador (tono) | Voz narrativa: vocabulario, ritmo, crudeza, foco sensorial |
| `estilo-prosa` | automática | director (crear/validar estilos) | Meta-skill: estructura que debe tener un skill de estilo |
| `validacion-crudeza` | automática | validador | Evalúa vocabulario explícito, ausencia de eufemismos |
| `validacion-tono` | automática | validador | Evalúa coherencia tonal contra el estilo activo |
| `validacion-geometria` | automática | validador | Evalúa ritmo, cadencia, fluidez de frases |
| `validacion-coherencia` | automática | validador | Evalúa continuidad física, consistencia de personajes, lógica |
| `validacion-sensorial` | automática | validador | Evalúa presencia de los 5 sentidos |
| `validacion-cross-hilo` | condicional en briefing | validador (solo si ≥2 hilos en el cap), auditor-beats modo `rachas` | Consistencia entre hilos: temporal, objetos, personajes, revelaciones |
| `consistencia-narrativa` | manual (`/revisar`) | director → validador | Auditoría de coherencia entre actos, capítulos, arcos |
| `contexto-subagente` | automática | director (antes de spawn) | Define qué información pasar a cada subagente |
| `desarrollo-narrativa` | manual (`/generar` en escritura) | director, escritor | Guía para desarrollar escenas y beats |
| `fichas-personajes` | manual (crear/editar fichas) | director, entidades | Guía para crear perfiles NEXUS/HELIX/VELA/STRIX/AXIOM |
| `hechos-distribuidos` | condicional (si hay `[D]`) | guionista, director (FASE 3.2b), auditor-beats modo `transiciones` | Algoritmo de `cola_d.md`, inyección de beats `[D]` y reordenamiento atómico |
| `diseno-hilo` | automática | **director** (escribe `diseno-hilo.md`), guionista y auditor-beats (leen) | Persistir decisiones de diseño de un hilo |
| `trenzado-narrativo` | automática | guionista modo `trenzado`, auditor-beats modo `trenzado` | Reglas de alternancia y tabla de trenzado |
| `plantilla-hilo` | automática | entidades | Campos obligatorios de una entidad `tipo=hilo` |
| `cronista-ops` | automática | director, cronista | Operaciones atómicas de summaries y entidades; reordenamientos |
| `qdrant` | automática | director, memoria, cronista, entidades, guionista | Schema y guía operativa de Qdrant |
| `neo4j` | automática | memoria, cronista, entidades | Schema y guía operativa de Neo4j |
| `auditoria-neo4j` | automática | cronista | Protocolo de auditoría draft ↔ grafo |

---

## Camino por fase — NOVELA MULTI-HILO (8 fases)

```
FASE 0 diseño global                                     estado: diseno
  director: identifica [D] en _actos.md (skill hechos-distribuidos)
  director + usuario: define hilos (nombre, slug, época, ubicación,
                      personajes, conflicto, tono propio)
  director + usuario: define puntos de conexión cross-hilo
  director + usuario: define partes de la novela
  director: siembra config.json.hilos[] + puntos_conexion
  director → entidades (×N): entidades semilla en Qdrant (fijo, sin dinamico)
  director → neo4j.py: relaciones básicas, marcadas cross-hilo si aplica
  GATE: cada hilo con conflicto propio; hilos[] poblado; semillas creadas

FASE 0.1 componentes iniciales                           estado: diseno
  director → entidades (×N, incremental): fichas básicas
  OUT: Qdrant + fichas/<tipo>_<slug>.md de entidades clave
  GATE: protagonistas de cada hilo, lugares principales y objetos
        cross-hilo fichados
  estado → "diseno_hilos"

FASE 0.2 hilos (bucle por hilo)                          estado: diseno_hilos
  por cada hilo en config.json.hilos[]:
    director + skill diseno-hilo → hilos/hilo-S/diseno-hilo.md
    director → guionista(modo: hilo)
      IN:  diseno-hilo.md, BRIEF.md, config.json
      OUT: hilos/hilo-S/guion-hilo.md (solo hechos, sin beats)
    director + usuario: itera hasta confirmación
    director → entidades: registra el hilo en Qdrant (tipo=hilo)
    director: hilos[].estado = "guion_listo"
  GATE: todos los guion-hilo.md completos
  estado → "trenzado"

FASE 0.3 trenzado                                        estado: trenzado
  director + usuario: afina puntos de conexión
  director → guionista(modo: trenzado)
    IN:  todos guion-hilo.md + puntos_conexion + reglas de alternancia
    OUT: guion-novela.md, tabla ## Trenzado (hechos, no beats)
  GATE: sin hechos huérfanos; todos los hilos presentes en la tabla
  estado → "fichas"

FASE 1 verificación de guion                             estado: fichas
  director: guion-novela.md tiene actos, capítulos, tabla y conexiones
  director: los hechos de la tabla coinciden con su guion-hilo.md origen
  GATE: guion-novela.md consistente

FASE 2 componentes completos                             estado: fichas
  director: verifica Qdrant (qdrant.py check) y Neo4j (neo4j.py check)
  director → entidades (×N): completa fijo + dinamico + fichas markdown
  director/entidades: fichas/conexion-*.md por punto cross-hilo
  director: reconciliación cross-hilo de entidades compartidas
  GATE: entidades detalladas, conexiones documentadas, infra operativa
  estado → "escritura"; version_qdrant y version_neo4j = "activo"

FASE 3 beat a beat cross-hilo (bucle por capítulo)       estado: escritura
  orden: el de la tabla de Trenzado

  3.1 director → memoria
      IN:  config.json, stable_id de hilos activos, entidades del cap
      OUT: briefing ~600 tokens (L4 → L3 → L2 → entidades → relaciones
           → estado de hilos activos), filtrado por hilo

  3.2 director → guionista(modo: capitulo, pasada 1)
      IN:  briefing memoria + fila Trenzado + guion-hilo.md implicados
      OUT: capitulos/cap-NN-slug/guion.md (solo hechos lineales)
           + cola_d.md con los [D] pendientes
      exclusivo: 1 hilo | puente: bloques con --- | espejo: alternado

  3.2b director [+ memoria si estado==escritura]
      evalúa cada [D] por función narrativa y escenas porosas
      OUT: cola_d.md anotado — "tras <stable_id> (B_NNNN) en Escena N"
      GATE: todo [D] con posición concreta; si no, repetir 3.2b

  3.2c director → guionista(modo: capitulo, pasada 2)
      inyecta beats [D] y aplica renumber-siblings (parent_id + hilo)

  3.2d director → auditor-beats × 4 modos secuenciales
      cobertura → atomizar → transiciones → limpieza
      correcciones vía guionista (modo capitulo o revision)
      GATE: beats atómicos, cerrados, sin prosa; [D] validados

  3.2e director + cronista-ops (persistencia temprana)
      qdrant.py update-entity  → dinamico de entidades con cambio claro
      qdrant.py upsert-summary-by-position → L1 por (nivel,parent,seq,hilo)

  3.3 por cada beat ⬜:
      director: marca 🔄
      director → escritor
        IN:  beat (stable_id, seq, parent_id, acción, tono, extensión),
             hilo activo, tipo de capítulo, fichas, últimos 5 beats
             del mismo bloque, briefing memoria, premisa_cap
             [+ contexto del otro hilo y conexiones si puente/espejo]
        OUT: draft.md, sección "## <stable_id> [<seq>] — acción"
      director: GATE de contenido — la sección existe y tiene prosa real
      director → validador (read-only, scope completa)
        cross_hilo: sí solo si el capítulo tiene ≥2 hilos
      director: decide integrador según umbrales
      director: ✅ en guion.md; actualiza ultimo_beat_seq
      director: detección proactiva de entidades sin ficha

  3.4 director → validador(modo: global) sobre el draft del capítulo
      IN:  draft completo, L4, tabla Trenzado, arco, fichas de hilos
           activos, fichas/conexion-*
      si falla: corrige beats señalados vía integrador

  3.5 director → cronista (invocación única, sin submodos)
      IN:  Instrucción concreta + draft.md, guion.md, config.json,
           fichas, diseños de hilo, conexiones
      OUT: L1 por escena (con hilo), L2 del capítulo, L3 si cierra arco,
           L4 si toca; dinamico de entidades; auditoría Neo4j read-only
           + config.json (capitulos_completados, hilos[].ultimo_capitulo)
      director: resuelve discrepancias de Neo4j

  3.6 cada 3 capítulos y al cerrar el último:
      director → auditor-beats(modo: trenzado) sobre guion-novela.md
      director → auditor-beats(modo: rachas)
      desviación futura → guionista(modo: trenzado)
      desviación en tramo escrito → guionista(modo: revision)

  GATE del capítulo: beats ✅, Qdrant actualizado, Neo4j auditado
  bucle: quedan capítulos → 3.1 | no quedan → estado "publicacion"

FASE 4 publicar                                          estado: publicacion
  director: draft.md → capitulo.md por capítulo
    elimina headings "## <stable_id> [<seq>]"
    elimina marcadores <!-- ESCENA ... --> y notas del escritor
    conserva --- entre bloques de hilo
  director: concatena capitulo.md → novela.md
  GATE: sin headings, comentarios ni notas residuales
  estado → "finalizado"   (publicado lo asigna el hub con /crear-libro)
```

---
## Plantillas de briefing (director → subagente)

### → guionista

```
Modo: [hilo | trenzado | capitulo | revision] [pasada: 1 | 2]
Workspace: [cwd]
Leer: [lista rutas relativas]
Escribir: [ruta salida]
IDs: asignar seq desde config ultimo_hecho_seq=[X] ultimo_beat_seq=[Y]
     generar stable_id opaco (8 hex) para cada elemento nuevo
Capítulo: cap-NN-slug (stable_id, seq, parent_id) — si aplica
Hilo(s) activo(s): [nombre] (stable_id: [8hex]) — si aplica
Tipo de capítulo: [exclusivo | puente | espejo] — si aplica
Contexto previo: [últimos 5-8 beats del bloque anterior, contrato común]
Contexto posterior: [beat siguiente al punto de inserción, solo pasada 2]
Criterio: [función narrativa del cap/hilo]
Estilo base: [nombre] — cargar skill estilo-<nombre>
{{#if estilo_secundario}}Estilo secundario: [nombre] — fusionar con estilo-<nombre>{{/if}}
Puntos de conexión: [lista, referenciados por stable_id]
{{#if pasada 2}}cola_d.md: [ruta] — anotado con "tras <stable_id> (B_NNNN) en Escena N"
Renumeración: renumber-siblings solo cambia seq, dentro del mismo parent_id e hilo{{/if}}
{{#if modo revision}}Tramo: beats [stable_id...] — instrucción: [problema concreto]
Memoria: briefing ligero (~300t){{/if}}
```

### → escritor

```
Beat: stable_id=[8hex] seq=[NNNN] parent_id=[8hex del hecho]
Acción: [texto del beat]
Hilo: [nombre] (stable_id: [8hex]) — época: [...] | ubicación: [...] | tono propio: [...]
Tipo de capítulo: [exclusivo | puente | espejo]
{{#if primer beat de bloque}}⚠️ Abres bloque de hilo: el lector viene de otra época/POV. Reancla espacio, tiempo y cuerpo.{{/if}}
Leer: capitulos/.../guion.md (línea beat), contexto.md, fichas/[lista por stable_id]
Briefing memoria: [~600 tokens, filtrado por los stable_id de hilo activos]
Escribir: capitulos/.../draft.md — sección "## <stable_id> [<seq>] — acción" (append; crear archivo si no existe)
Tono: [BREVE|MEDIA|EXTENSA] + [tono de tonos-beat] + [⚡ línea crítica si hay]
Estilo: [estilo_base] — cargar skill estilo-<nombre>
{{#if estilo_secundario}}+ fusionar con estilo-<nombre>{{/if}}
Beat N de M en el capítulo (total_beats, beat_index)
Premisa del capítulo: [extraída de guion-novela.md]
Últimos 5 beats: [del mismo bloque de hilo]
{{#if puente o espejo}}Otro hilo: [qué acaba de ocurrir allí] + fichas/conexion-*.md{{/if}}
{{#if espejo}}Beat contrario: [texto del beat del otro hilo con el que hace paralelismo]{{/if}}
No marcar ✅ en guion — solo prosa en draft
No escribir el separador --- entre bloques (lo pone el director)
```
### → validador

```
Modo: read-only [beat | global]
Beat: stable_id=[8hex] seq=[NNNN] (o modo global)
Texto: [fragmento o ruta draft.md, sección localizada por stable_id]
Dimensiones: ["coherencia", "sensorial", ...] — lista concreta (preferido)
  o Scope: [completa|media|ligera] — formato heredado (se normaliza a dimensiones)
Leer coherencia: contexto.md, fichas/[... por stable_id], guion.md
Hilo del beat: [nombre] (stable_id: [8hex]) — época y ubicación, para detectar anacronismos
Cross-hilo: [sí/no] — sí SOLO si el capítulo tiene ≥2 hilos.
  si sí: cargar validacion-cross-hilo + fichas/conexion-* + tabla de trenzado
  si no: NO cargar el skill ni emitir el bloque cross_hilo en el JSON
IDs declarados en el beat: [Personajes], [Zona], [Props], [Hilos]
Estilo activo: [nombre] — validar tono con skill validacion-tono + estilo-<nombre>
Salida: solo JSON (sin editar archivos). Incluir dimensiones_evaluadas, umbral_aplicado, aprobado
```

### → integrador

```
Beat: stable_id=[8hex] seq=[NNNN] parent_id=[8hex]
Leer: draft.md sección localizada por stable_id, JSON validador adjunto
Escribir: reemplazar la sección "## <stable_id> [<seq>]" en draft.md
Hilo: [nombre] (stable_id: [8hex]) — época, ubicación, tono propio
Tipo de capítulo: [exclusivo | puente | espejo]
Mantener acción nuclear del beat; aplicar mecanica-prosa + estilo
Conservar stable_id y seq sin cambios en el heading devuelto
Estilo: [estilo_base] — cargar skill estilo-<nombre>
{{#if estilo_secundario}}+ fusionar con estilo-<nombre>{{/if}}
Últimos 5 beats del mismo bloque de hilo + beat siguiente (siempre)
{{#if espejo}}Beat contrario del otro hilo: [texto] — conservar el eco{{/if}}
{{#if instruccion_usuario}}instruccion_usuario: [texto] — prioridad absoluta{{/if}}
```
### → memoria

```
Proyecto: [slug]  (--proyecto en todas las consultas)
Capítulo actual: cap-NN (stable_id, seq, parent_id)
Hilos activos: [nombre] (stable_id: [8hex]) — uno por línea
Entidades relevantes: [lista de stable_id del capítulo]
Briefing esperado: ~600 tokens. Estructura:
  1. Resumen L4 (global) — si existe
  2. Resumen L3 del arco activo — si existe
  3. Últimos 3 L2 (capítulos previos)
  4. Entidades del capítulo (fijo + dinámico desde Qdrant), por stable_id
  5. Relaciones activas (Neo4j) de personajes del capítulo
  6. Hilos activos, su estado y sus conexiones cross-hilo pendientes
Summaries: buscar por (nivel, parent_id, seq[, hilo]); el UUID nunca es entrada
```

### → cronista

```
Capítulo completado: cap-NN-slug
Leer: capitulos/cap-NN/draft.md (completo), config.json, hilo(s) activo(s)
Tareas:
  1. Para cada escena en el draft → upsert-summary L1 en Qdrant
  2. upsert-summary L2 del capítulo completo
  3. Si cierre de arco → upsert-summary L3
  4. Si cap % 10 == 0 → upsert-summary L4
  5. Para cada entidad modificada → actualizar dinámico en Qdrant
  6. Auditoría Neo4j (skill auditoria-neo4j): detectar discrepancias draft ↔ grafo
  7. Actualizar config.json: capitulos_completados++, hilos[].ultimo_capitulo
  8. NO escribir en Neo4j (solo lectura). Devolver discrepancias al director.
```

### → entidades

```
Entidad: [nombre], tipo [personaje|lugar|objeto|...], slug
Contexto narrativo: [dónde aparece, qué rol tiene]
{{#if actualización}}Campos a modificar: [lista]. Registro de desarrollo: [capítulo, cambio]{{/if}}
Output: Qdrant (upsert-entity) + fichas/<tipo>_<slug>.md
```

---

## config.json — quién actualiza qué

| Campo | Quién | Cuándo |
|-------|-------|--------|
| `estado` | **director** | Al cerrar cada fase |
| `ultimo_hecho_seq` | **guionista** o **director** | Al asignar un nuevo `seq` de hecho (incrementar después de usarlo) |
| `ultimo_beat_seq` | **guionista** o **director** | Al asignar un nuevo `seq` de beat |
| `capitulos_completados` | **cronista** | Al cerrar capítulo (FASE 3.5) |
| `ultima_modificacion` | quien escriba config | En cada actualización |
| `hilos[].estado` | **director** | Al completar fases del hilo |
| `hilos[].ultimo_capitulo` | **cronista** | Al cerrar capítulo que incluye el hilo |
| `version_qdrant` | **director** | Tras verificar Qdrant en FASE 2 |
| `version_neo4j` | **director** | Tras verificar Neo4j en FASE 2 |

**Valores de `config.json.estado`:**

| Estado | Fase |
|--------|------|
| `diseno` | FASE 0 y 0.1 |
| `diseno_hilos` | FASE 0.2 |
| `trenzado` | FASE 0.3 |
| `fichas` | FASE 1 y 2 |
| `escritura` | FASE 3 |
| `publicacion` | FASE 4 |
| `finalizado` | FASE 4 completada — listo para el hub |

`publicado` no lo escribe el workspace: lo asigna `/crear-libro` desde el hub tras compilar todas las salidas.

**Valores de `config.json.hilos[].estado`:**

| Valor | Significado | Quién lo escribe |
|-------|-------------|------------------|
| `pendiente` | Sembrado por el script; sin diseño propio | script de creación |
| `disenado` | `diseno-hilo.md` con decisiones firmes (FASE 0.2, paso 1) | director |
| `guion_listo` | `guion-hilo.md` generado y confirmado (FASE 0.2, paso 5) | director |

---

## Huecos prohibidos (no delegar sin dueño)

| Acción | Dueño (quién TIENE que hacerlo) |
|--------|--------------------------------|
| Generar `stable_id` y asignar `seq` | **guionista** (director verifica en config) |
| Marcar ⬜🔄✅ en guion | **director** |
| Escribir prosa | **escritor** |
| Corregir prosa tras fallo | **integrador** |
| Validar | **validador** (read-only, solo JSON) |
| Anotar posiciones de `[D]` en `cola_d.md` | **director** (FASE 3.2b) |
| Inyectar beats `[D]` | **guionista** modo `capitulo` pasada 2 |
| Auditar beats, trenzado y rachas | **auditor-beats** (read-only) |
| Publicar limpio | **director** en FASE 4 (vía `/publicar`) |
| Crear entidades | **entidades** (Qdrant + `fichas/<tipo>_<slug>.md`) |
| Actualizar Qdrant post-capítulo | **cronista** |
| Compilar briefing de memoria | **memoria** |
| Escribir `diseno-hilo.md` | **director** + skill `diseno-hilo` |
| Escribir `guion-hilo.md` | **guionista** modo `hilo` |
| Tabla de trenzado | **guionista** modo `trenzado` |
| Escribir `contexto.md` | **director** (al cerrar capítulo) |
| Crear carpetas `capitulos/cap-NN-slug/` | **guionista** (modo capitulo) |
| Separadores `---` entre bloques de hilo | **director** (al ensamblar el draft) |
| Init Qdrant/Neo4j | **director** (`scripts/qdrant.py`, `scripts/neo4j.py`) |
| Asignar `publicado` | **hub** (`/crear-libro`) — nunca el director |