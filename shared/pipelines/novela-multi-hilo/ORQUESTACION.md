# Orquestación — agentes, skills y rutas de datos (NOVELA MULTI-HILO)

Referencia para **director** y subagentes. Rutas en `MAPA.md`. Fases en `PIPELINE.md`.

---

## Reglas globales

1. **Quién escribe qué:** solo el agente indicado en la columna «Escribe» modifica ese archivo.
2. **Briefing de spawn:** el director pasa siempre rutas relativas al workspace, IDs (`H_`/`B_`), y `Modo`.
3. **IDs:** asignar desde `config.json` → `ultimo_hecho_seq` / `ultimo_beat_seq`. Tras asignar, incrementar en el archivo que creó el ID.
   - **Novelas:** IDs globales `H_NNNN`, `B_NNNN` (4 dígitos, nunca se reinician).
   - **Relatos:** IDs locales `H_NN`, `B_NN` por relato.
4. **Estados en guion:** `⬜` → `🔄` (al empezar beat) → `✅` (validador aprueba). Lo marca el **director** tras cada beat.
5. **Backup** antes de sobrescribir archivos con contenido existente.

---

## Matriz de agentes (9 agentes)

| Agente | Invocado por | Lee | Escribe | Invoca | Modelo |
|--------|--------------|-----|---------|--------|--------|
| **director** | usuario `/generar`, `/revisar`, `/expandir`, `/publicar`, `/refinar-hechos`, `/validar-hechos`, `/revisar-guion` | `PIPELINE.md`, `MAPA.md`, `config.json`, `BRIEF.md`, `AGENTS.md`, `contexto.md` o `contexto_narrativo.md`, guiones según fase | `config.json`, `contexto.md` o `contexto_narrativo.md`, `diseno-hilo.md`, estados en guiones, `fichas/` (relato) | guionista, escritor, validador, integrador, memoria, cronista, entidades, auditor-beats | `deepseek-v4-pro` |
| **guionista** | director | Briefing + archivos del modo (ver tabla modos abajo) | Guiones según modo y escala | — | `deepseek-v4-pro` |
| **auditor-beats** | director | `guion.md` o `guion-novela.md`, `_actos.md`, `AGENTS.md` | — (read-only, diagnóstico al director) | — | `deepseek-v4-pro` |
| **escritor** | director | Briefing + `guion.md` (beat), `contexto.md`, `fichas/` relevantes, `AGENTS.md`, estilo skill | `draft.md` (append sección `## B_NNNN`) | — | `deepseek-v4-pro` |
| **validador** | director | Briefing + texto del beat, `guion.md`, `contexto.md`, `fichas/` | — (solo JSON) | — | `deepseek-v4-pro` |
| **integrador** | director | Briefing + `draft.md` (beat), JSON validador | `draft.md` (reemplaza sección beat) | — | `deepseek-v4-pro` |
| **memoria** | director | `config.json`, especificación de entidades del cap, hilo(s) activo(s) | — (solo briefing de ~600 tokens) | — | `deepseek-v4-flash` |
| **cronista** | director (cierre de cap) | `draft.md` completo, `config.json`, hilo(s) activo(s) | Qdrant (summaries L1-L4 + entidades `dinamico`), `config.json` (contadores) | — | `deepseek-v4-flash` |
| **entidades** | director | Nombre, tipo, descripción de entidad + contexto narrativo | Qdrant (`upsert-entity`) + `fichas/<tipo>_<slug>.md` | — | `deepseek-v4-pro` |

---

## Guionista — modos y contrato por escala

### Relato

| Modo | Lee | Escribe | Actualiza config |
|------|-----|---------|------------------|
| `estructura` | `BRIEF.md, _actos.md`, `AGENTS.md` | `guion.md` (escenas, sin beats) | — (director pone `estado=fichas`) |
| `escena` | `guion.md` (escena actual), `AGENTS.md` | `guion.md` (beats bajo hechos) | — |

### Novela Simple

| Modo | Lee | Escribe | Actualiza config |
|------|-----|---------|------------------|
| `estructura-novela` | `BRIEF.md, _actos.md`, `config.json` | `guion-novela.md` (actos, caps, hechos `H_NNNN`) | `ultimo_hecho_seq`; director pone `estado=fichas` |
| `capitulo` | `guion-novela.md` (tramo cap), `contexto.md`, `fichas/`, briefing (cap N, rango H) | `capitulos/cap-NN-slug/guion.md` (crear carpeta) | `ultimo_hecho_seq`, `ultimo_beat_seq` |

### Novela Multi-hilo

| Modo | Lee | Escribe | Actualiza config |
|------|-----|---------|------------------|
| `hilo` | `hilos/hilo-S/diseno-hilo.md`, `BRIEF.md`, briefing (slug hilo) | `hilos/hilo-S/guion-hilo.md` (solo hechos `H_NNNN`) | `ultimo_hecho_seq`; director actualiza `hilos[].estado` |
| `trenzado` | Todos `guion-hilo.md`, `guion-novela.md`, `config.json.hilos` | `guion-novela.md` (tabla `## Trenzado`) | — (director pone `estado=trenzado`) |
| `capitulo` | Tabla trenzado, `guion-hilo.md` de hilos del cap, `contexto.md`, `fichas/` | `capitulos/cap-NN-slug/guion.md` | `ultimo_hecho_seq`, `ultimo_beat_seq` |
| `revision` | `capitulos/cap-NN-slug/guion.md` (tramo + contexto), `AGENTS.md` [+ `memoria` si `estado==escritura`] | `capitulos/cap-NN-slug/guion.md` (reemplaza tramo) | — (mismos IDs) |

---

## Auditor-beats — modos y contrato

| Modo | Lee | Escribe | Skills |
|------|-----|---------|--------|
| `cobertura` | `guion.md` o `capitulos/cap-NN-slug/guion.md`, `_actos.md`, `AGENTS.md` [+ `memoria` si `estado==escritura`] | — (diagnóstico al director) | `beats-estructura`, `estructura-narrativa` |
| `atomizar` | `guion.md` o `capitulos/cap-NN-slug/guion.md`, `_actos.md`, `AGENTS.md` | — (diagnóstico al director) | `beats-estructura` |
| `transiciones` | `guion.md` o `capitulos/cap-NN-slug/guion.md`, `_actos.md`, `AGENTS.md` [+ `memoria` si `estado==escritura`] | — (diagnóstico al director) | `validacion-coherencia`, `beats-estructura` [+ `hechos-distribuidos` si hay `[D]`] |
| `limpieza` | `guion.md` o `capitulos/cap-NN-slug/guion.md`, `AGENTS.md` | — (diagnóstico al director) | `beats-estructura`, `mecanica-prosa` |

### → auditor-beats

```
Modo: [cobertura | atomizar | transiciones | limpieza | trenzado | rachas]
Leer: guion.md (o capitulos/cap-NN-slug/guion.md), _actos.md, AGENTS.md
{{#if estado==escritura}} Memoria: briefing ligero (~300t) desde memoria{{/if}}
{{#if multi-hilo}} Modos extra: trenzado (guion-novela.md), rachas (validacion capitulos puente/espejo){{/if}}
Output: diagnostico al director (tablas de problemas + propuestas)
No modificar archivos
```

---

## Skills — rol y quién los carga

| Skill | Invocación | Quién lo aplica | Efecto |
|-------|------------|-----------------|--------|
| `mecanica-prosa` | automática | escritor, integrador | Formato de prosa: guiones de diálogo, párrafos, ⚡, cursiva |
| `beats-estructura` | automática | guionista, escritor (lectura) | Formato `B_NNNN` — acción. `[Tono — EXTENSIÓN]` |
| `hechos-estructura` | automática (solo novelas) | guionista | Formato `H_NNNN` — hecho narrativo |
| `tonos-beat` | automática | guionista (asignar), escritor (ejecutar) | Catálogo de 15 tonos + reglas BREVE/MEDIA/EXTENSA |
| `estructura-narrativa` | automática | guionista | Jerarquía: actos → capítulos → escenas → beats |
| `plantilla-guion` | automática | guionista | Estructura de archivos de guion (simple y multi-hilo) |
| `plantilla-ficha` | automática | entidades, director (relato) | Estructura FIJO/DINÁMICO para 10 tipos de entidad |
| `plantilla-personaje` / `plantilla-lugar` / `plantilla-objeto` / `plantilla-animal` / `plantilla-arco` / `plantilla-evento` / `plantilla-hilo` / `plantilla-organizacion` | automática | entidades | Campos obligatorios por tipo de entidad |
| `estilo-explicito` / `estilo-contemporaneo` / `estilo-erotico` / `estilo-fantasia` / `estilo-noir` / `estilo-romantico` / `estilo-thriller` | automática | escritor, integrador, validador (tono) | Voz narrativa: vocabulario, ritmo, crudeza, foco sensorial |
| `estilo-prosa` | automática | director (crear/validar estilos) | Meta-skill: estructura que debe tener un skill de estilo |
| `validacion-crudeza` | automática | validador | Evalúa vocabulario explícito, ausencia de eufemismos |
| `validacion-tono` | automática | validador | Evalúa coherencia tonal contra el estilo activo |
| `validacion-geometria` | automática | validador | Evalúa ritmo, cadencia, fluidez de frases |
| `validacion-coherencia` | automática | validador | Evalúa continuidad física, consistencia de personajes, lógica |
| `validacion-sensorial` | automática | validador | Evalúa presencia de los 5 sentidos |
| `validacion-cross-hilo` | manual en briefing | validador | Evalúa consistencia entre hilos: temporal, objetos, personajes, revelaciones |
| `consistencia-narrativa` | manual (`/revisar`) | director → validador | Auditoría de coherencia entre actos, capítulos, arcos |
| `contexto-subagente` | automática | director (antes de spawn) | Define qué información pasar a cada subagente |
| `desarrollo-narrativa` | manual (`/generar` en escritura) | director, escritor | Guía para desarrollar escenas y beats |
| `fichas-personajes` | manual (crear/editar fichas) | director, entidades | Guía para crear perfiles NEXUS/HELIX/VELA/STRIX/AXIOM |
| `diseno-hilo` | automática | **director** (escribe `diseno-hilo.md`), guionista (lee) | Persistir decisiones de diseño de un hilo |
| `trenzado-narrativo` | automática | guionista modo `trenzado` | Reglas de alternancia y tabla de trenzado |
| `qdrant` | automática (solo novelas) | memoria, cronista, entidades | Schema y guía operativa de Qdrant |
| `neo4j` | automática (solo novelas) | memoria, cronista, entidades | Schema y guía operativa de Neo4j |
| `auditoria-neo4j` | automática (solo novelas) | cronista | Protocolo de auditoría draft ↔ grafo |

---

## Caminos por fase — RELATO (4 fases)

```
FASE 1 diseño
  director → guionista(modo: estructura) → guionista(modo: escena × N)
  IN:  BRIEF.md, _actos.md, AGENTS.md
  OUT: guion.md (escenas + beats locales)
  estado → "diseno" → "fichas"

FASE 2 componentes
  director: extrae entidades de guion.md
  director → entidades (×N): crea fichas en fichas/<tipo>_<slug>.md
  director: reconciliación (sin contradicciones entre fichas)
  director: crea contexto_narrativo.md (vacío) + relato-draft.md (vacío)
  OUT: fichas/ + contexto_narrativo.md + relato-draft.md
  estado → "escritura"

FASE 3 beat a beat
  por cada beat ⬜ en guion.md:
    director → escritor(beat, fichas, contexto_narrativo)
    director → validador(read-only, scope completa)
    si falla: director → integrador
    director: ✅ en guion.md, append a relato-draft.md
    si último beat de escena: director actualiza contexto_narrativo.md (2-3 frases)
  estado → "publicacion"

FASE 4 publicar
  /publicar: procesa relato-draft.md → relato.md
  (limpiar headings, convertir comentarios en ---)
```

---

## Caminos por fase — NOVELA SIMPLE (4 fases)

```
FASE 0 diseño
  director → guionista(modo: estructura-novela)
  IN:  BRIEF.md, _actos.md, config.json
  OUT: guion-novela.md (actos, caps, hechos H_NNNN)
  estado → "diseno" → "fichas"

FASE 1 componentes
  director → entidades (×N entidades)
  IN:  BRIEF.md, guion-novela.md
  OUT: Qdrant entidades (fijo + dinámico) + fichas/<tipo>_<slug>.md
  director: init Neo4j (scripts/neo4j.py init <slug>)
  estado → "escritura"

FASE 2 escritura (por capítulo)
  2.1 director → memoria
      IN:  config.json, entidades relevantes del cap, hilo(s) activo(s)
      OUT: briefing ~600 tokens (L4 → L3 → L2 recientes → entidades → relaciones → hilos)

  2.2 director → guionista(modo: capitulo)
      IN:  cap-NN-slug, hechos H_XXXX, briefing memoria
      OUT: capitulos/cap-NN-slug/guion.md (crear carpeta, hechos + beats + Qdrant upsert-beat)

  2.3 por cada beat B_NNNN ⬜:
      director → escritor (con briefing memoria, fichas inline, estilo)
        OUT: draft.md (append ## B_NNNN)
      director → validador (scope completa, read-only)
        OUT: JSON con scores
      si score_global < 7: director → integrador
        OUT: draft.md corregido
      director: ✅ en guion.md, config.json.ultimo_beat_seq

  2.4 director → validador(modo: global) sobre draft completo del cap
      OUT: JSON con problemas_globales
      si falla: iterar beats problemáticos

  2.5 director → cronista
      IN:  draft.md, config.json, hilo(s) activo(s)
      OUT: Qdrant L1 (escena), L2 (capítulo), L3 (si cierre arco), L4 (cada 10 caps)
           + entidades dinámico actualizado
           + auditoría Neo4j (solo lectura, discrepancias al director)
           + config.json: capitulos_completados++
      si quedan capítulos → volver a 2.1

  estado → "publicacion"

FASE 3 publicar
  por cada cap: /publicar → capitulos/cap-NN-slug/capitulo.md
  concatenar → novela.md
```

---

## Caminos por fase — NOVELA MULTI-HILO (8 fases)

```
FASE 0 diseño global
  director: valida hilos, BRIEF.md, puntos_conexion en guion-novela.md
  OUT: guion-novela.md (esqueleto con hilos[])
  estado → "diseno"

FASE 0.1 componentes iniciales
  director → entidades (fichas básicas de entidades conocidas)
  OUT: Qdrant + fichas/ de entidades clave
  estado → "diseno"

FASE 0.2 hilos (por cada hilo)
  por cada hilo en config.json.hilos[]:
    director + skill diseno-hilo → hilos/hilo-S/diseno-hilo.md
    director → guionista(modo: hilo)
      IN:  diseno-hilo.md, BRIEF.md, config.json
      OUT: hilos/hilo-S/guion-hilo.md (solo hechos H_NNNN)
    director: actualiza hilos[].estado = "guion_listo" en config.json
  estado → "diseno_hilos"

FASE 0.3 trenzado
  director → guionista(modo: trenzado)
  IN:  todos guion-hilo.md + puntos_conexion
  OUT: guion-novela.md (tabla ## Trenzado con hechos, no beats)
  estado → "trenzado"

FASE 1 guión (verificación)
  director: verifica guion-novela.md con trenzado completo
  estado → "fichas"

FASE 2 componentes
  director → entidades: completar fichas con detalle + Qdrant
  director: fichas/conexion_<slug>.md para puntos cross-hilo
  director: init Neo4j
  estado → "escritura"

FASE 3 beat a beat (por cap global, orden tabla Trenzado)
  Igual que novela simple FASE 2, pero:

  2.2 guionista modo capitulo:
      - Capítulo exclusivo: mismo que simple (1 hilo)
      - Capítulo puente: bloques por hilo separados con ---
      - Capítulo espejo: dos hilos en paralelo

  2.3 validador:
      - Si ≥ 2 hilos en el cap: añadir validacion-cross-hilo
        (director pasa contexto cross-hilo: tabla trenzado, guion-hilo.md otros hilos,
         fichas/conexion-*)

  2.5 cronista:
      - Summaries filtrados por hilo activo
      - Auditoría cross-hilo en Neo4j
      - Actualizar hilos[].estado, hilos[].ultimo_capitulo

  estado → siguiente cap o "publicacion"

FASE 4 publicar
  mismo que novela simple
```

---

## Plantillas de briefing (director → subagente)

### → guionista

```
Modo: [estructura | escena | estructura-novela | capitulo | hilo | trenzado] [pasada: 1 | 2]
Workspace: [cwd]
Leer: [lista rutas relativas]
Escribir: [ruta salida]
IDs: asignar desde config ultimo_hecho_seq=[X] ultimo_beat_seq=[Y]
Capítulo: cap-NN-slug (si aplica) | Hilo: hilo-S (si aplica)
Contexto previo: [últimos 5-8 beats del capítulo/acto anterior, si aplica]
Contexto posterior: [beat siguiente al punto de inserción, solo pasada 2]
Criterio: [función narrativa del cap/hilo]
Estilo base: [nombre] — cargar skill estilo-<nombre>
{{#if estilo_secundario}}Estilo secundario: [nombre] — fusionar con estilo-<nombre>{{/if}}
Puntos de conexión: [lista]
```

### → escritor (novela, con Qdrant)

```
Beat: B_NNNN | Hecho padre: H_NNNN
Leer: capitulos/.../guion.md (línea beat), contexto.md, fichas/[lista]
Briefing memoria: [~600 tokens desde agente memoria]
Escribir: capitulos/.../draft.md — sección ## B_NNNN (append; crear archivo si no existe)
Tono: [BREVE|MEDIA|EXTENSA] + [tono de tonos-beat] + [⚡ línea crítica si hay]
Estilo: [estilo_base] — cargar skill estilo-<nombre>
{{#if estilo_secundario}}+ fusionar con estilo-<nombre>{{/if}}
Beat N de M en el capítulo
Premisa del capítulo: [extraída de guion-novela.md]
No marcar ✅ en guion — solo prosa en draft
```

### → escritor (relato, sin Qdrant)

```
Beat: B_NN | Escena: E_NN
Leer: guion.md (escena actual), contexto_narrativo.md, fichas/[lista], AGENTS.md,
      TODOS los beats ya escritos de la escena actual (desde el primero),
      últimos 3 beats de la escena anterior (si aplica)
Escribir: relato-draft.md — sección ## B_NN (append)
Tono: [BREVE|MEDIA|EXTENSA] + [tono de tonos-beat]
Estilo: [estilo_base] — cargar skill estilo-<nombre>
Beat N de M en la escena
⚠️ No repetir anclas sensoriales (mismo sonido, olor, textura) ya usadas en beats anteriores de la misma escena
No marcar ✅ en guion — solo prosa en draft
```

### → validador

```
Modo: read-only
Beat: B_NNNN (o modo global)
Texto: [fragmento o ruta draft.md sección B_NNNN]
Dimensiones: ["coherencia", "sensorial", ...] — lista concreta (preferido)
  o Scope: [completa|media|ligera] — formato heredado (se normaliza a dimensiones)
Leer coherencia: contexto.md (o contexto_narrativo.md), fichas/[...], guion.md
Cross-hilo: [sí/no] — si sí, aplicar skill validacion-cross-hilo + rutas fichas/conexion-*
Estilo activo: [nombre] — validar tono con skill validacion-tono + estilo-<nombre>
Salida: solo JSON (sin editar archivos). Incluir dimensiones_evaluadas, umbral_aplicado, aprobado
```

### → integrador

```
Beat: B_NNNN
Leer: draft.md sección B_NNNN, JSON validador adjunto
Escribir: reemplazar sección ## B_NNNN en draft.md
Mantener acción nuclear del beat; aplicar mecanica-prosa + estilo
Estilo: [estilo_base] — cargar skill estilo-<nombre>
{{#if estilo_secundario}}+ fusionar con estilo-<nombre>{{/if}}
```

### → memoria

```
Novela: [slug]
Capítulo actual: cap-NN
Hilos activos: [lista de slugs de hilo que aparecen en este cap]
Entidades relevantes: [lista de IDs tipo-slug del capítulo]
Briefing esperado: ~600 tokens. Estructura:
  1. Resumen L4 (global) — si existe
  2. Resumen L3 del arco activo — si existe
  3. Últimos 3 L2 (capítulos previos)
  4. Entidades del capítulo (fijo + dinámico desde Qdrant)
  5. Relaciones activas (Neo4j) de personajes del capítulo
  6. Hilos activos y su estado
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
| `ultimo_hecho_seq` | **guionista** o **director** | Al asignar nuevo H_NNNN (incrementar después de usarlo) |
| `ultimo_beat_seq` | **guionista** o **director** | Al asignar nuevo B_NNNN |
| `capitulos_completados` | **cronista** (novela) o **director** (relato) | Al cerrar capítulo/relato |
| `ultima_modificacion` | quien escriba config | En cada actualización |
| `hilos[].estado` | **director** | Al completar fases del hilo |
| `hilos[].ultimo_capitulo` | **cronista** | Al publicar cap que incluye el hilo |
| `version_qdrant` | **director** | Tras init Qdrant |
| `version_neo4j` | **director** | Tras init Neo4j |

**Valores posibles de `config.json.estado`:**

| Estado | Relato | Novela Simple | Novela Multi-hilo |
|--------|:------:|:-------------:|:-----------------:|
| `diseno` | ✅ (FASE 1) | ✅ (FASE 0) | ✅ (FASE 0) |
| `diseno_hilos` | — | — | ✅ (FASE 0.2) |
| `trenzado` | — | — | ✅ (FASE 0.3) |
| `fichas` | ✅ (FASE 2) | ✅ (FASE 1) | ✅ (FASE 2) |
| `escritura` | ✅ (FASE 3) | ✅ (FASE 2) | ✅ (FASE 3) |
| `publicacion` | ✅ (FASE 4) | ✅ (FASE 3) | ✅ (FASE 4) |

---

## Huecos prohibidos (no delegar sin dueño)

| Acción | Dueño (quién TIENE que hacerlo) |
|--------|--------------------------------|
| Asignar IDs H_/B_ | **guionista** (director verifica en config) |
| Marcar ⬜🔄✅ en guion | **director** |
| Escribir prosa | **escritor** |
| Corregir prosa tras fallo | **integrador** |
| Validar | **validador** (read-only, solo JSON) |
| Publicar limpio | `/publicar` |
| Crear entidades | **entidades** (novela: Qdrant + markdown; relato: solo markdown) |
| Actualizar Qdrant post-capítulo | **cronista** |
| Compilar briefing de memoria | **memoria** |
| Escribir diseno-hilo.md | **director** + skill `diseno-hilo` |
| Escribir guion-hilo.md | **guionista** modo `hilo` |
| Tabla de trenzado | **guionista** modo `trenzado` |
| Escribir contexto_narrativo.md (relato) | **director** (al cerrar escena) |
| Escribir contexto.md (novela) | **director** (al cerrar capítulo) |
| Crear carpetas capitulos/cap-NN-slug/ | **guionista** (modo capitulo) |
| Init Qdrant/Neo4j | **director** (scripts/qdrant.py, scripts/neo4j.py) |

