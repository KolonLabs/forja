# Orquestación — agentes, skills y rutas de datos (NOVELA MULTI-HILO)

Referencia para **director** y subagentes. Fases en `PIPELINE.md`.

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
| **director** | usuario `/generar`, `/revisar`, `/expandir`, `/publicar`, `/refinar-hechos`, `/validar-hechos`, `/revisar-guion` | `PIPELINE.md`, `config.json`, `BRIEF.md`, `AGENTS.md`, `contexto.md`, guiones según fase | `config.json`, `contexto.md`, `diseno-hilo.md`, `cola_d.md`, estados en guiones, `draft.md` (ensamblado y separadores `---`), `capitulo.md`, `novela.md` | guionista, escritor, validador, integrador, memoria, cronista, entidades, auditor-beats | `deepseek-v4-pro` |
| **guionista** | director | Briefing + archivos del modo (ver tabla modos abajo) | Guiones según modo y escala | — | `opencode/claude-sonnet-5` |
| **auditor-beats** | director | `guion.md` o `guion-novela.md`, `_actos.md`, `AGENTS.md` | — (read-only, diagnóstico al director) | — | `deepseek-v4-pro` |
| **escritor** | director | Briefing + `guion.md` (beat), `contexto.md`, `fichas/` relevantes, `AGENTS.md`, estilo skill | `draft.md` (append sección `## <stable_id> [<seq>]`) | — | `deepseek-v4-pro` |
| **validador** | director | Briefing + texto del beat, `guion.md`, `contexto.md`, `fichas/` | — (solo JSON) | — | `opencode/glm-5.2` |
| **integrador** | director | Briefing + `draft.md` (beat), JSON validador | `draft.md` (reemplaza sección beat) | — | `deepseek-v4-pro` |
| **memoria** | director | `config.json`, especificación de entidades del cap, hilo(s) activo(s) | — (solo briefing de ~600 tokens) | — | `deepseek-v4-flash` |
| **cronista** | director (cierre de cap) | `draft.md` completo, `config.json`, hilo(s) activo(s) | Qdrant (summaries L1-L4 + entidades `dinamico`), Neo4j (relaciones por escena), `config.json` (contadores) | — | `deepseek-v4-flash` |
| **entidades** | director | Nombre, tipo, descripción de entidad + contexto narrativo | Qdrant (`upsert-entity`) + `fichas/<tipo>_<slug>.md` | — | `deepseek-v4-pro` |

---

## Guionista — modos y contrato

| Modo | Lee | Escribe | Actualiza config |
|------|-----|---------|------------------|
| `hilo` | `hilos/hilo-<slug>/diseno-hilo.md`, `BRIEF.md`, briefing (slug hilo) | `hilos/hilo-<slug>/guion-hilo.md` (solo hechos) | `ultimo_hecho_seq`; director actualiza `hilos[].estado` |
| `hilo-capitulo` | `hilos/hilo-<slug>/guion-hilo.md` (rango de hechos del cap-borrador + objetivo/tensión), últimos beats del cap-borrador anterior, resumen compacto de entidades/relaciones (estilo `memoria`), `hilos/hilo-<slug>/cola_d.md` si existe (registro de instancias `[D]` ya escritas en cap-borradores anteriores del mismo hilo) | `hilos/hilo-<slug>/cap-NN/guion.md` (beats lineales + `[D]` entretejidos en una sola pasada, luego agrupados en escenas, marcador `<!-- ESCENA <stable_id>: Nombre -->`) | `ultimo_beat_seq`; director actualiza `cola_d.md` (registro de contenido por `[D]`) y `hilos[].estado` al cerrar el hilo |
| | **Siempre** incluye un checkpoint tras agrupar en escenas (director + usuario validan estructura). **Si hay `[D]` en el rango**, añade un checkpoint previo de plan de instancias. | | |
| `trenzado` | Todos `hilos/hilo-<slug>/cap-NN/guion.md` (escenas y beats completos, `[D]` ya resueltos), `guion-novela.md` (incl. `## Puntos de conexión` como pista temática) | `capitulos/cap-NN-slug/guion.md` (mueve bloques de escena completos, `renumber-siblings` en `parent_id`/`seq`), `guion-novela.md` (tabla `## Trenzado` + reescribe `## Puntos de conexión` con `stable_id` de escena) | — (director pone `estado=fichas`) |
| `revision` | `capitulos/cap-NN-slug/guion.md` (tramo + contexto bilateral) o `hilos/hilo-<slug>/cap-NN/guion.md` (tramo, si la corrección es previa al trenzado), `AGENTS.md` [+ `memoria` si `estado==escritura`] | El mismo archivo leído (reemplaza tramo) | — (mismos `stable_id`) |

---

## Auditor-beats — modos y contrato

Read-only en los seis modos. Siempre devuelve diagnóstico al director; nunca modifica archivos.

| Modo | Lee | Skills | Cuándo lo invoca el director |
|------|-----|--------|------------------------------|
| `cobertura` | `capitulos/cap-NN-slug/guion.md`, `_actos.md`, `AGENTS.md` [+ `memoria` si `estado==escritura`] | `beats-estructura`, `estructura-narrativa` | FASE 3.2b |
| `atomizar` | `capitulos/cap-NN-slug/guion.md`, `_actos.md`, `AGENTS.md` | `beats-estructura` | FASE 3.2b |
| `transiciones` | `capitulos/cap-NN-slug/guion.md`, `_actos.md`, `AGENTS.md` [+ `memoria` si `estado==escritura`] | `validacion-coherencia`, `beats-estructura` [+ `validacion-cross-hilo` si ≥2 hilos, en FASE 3.2] | FASE 3.2 (costuras cross-hilo, primera pasada) y FASE 3.2b (huecos generales, segunda pasada) |
| `limpieza` | `capitulos/cap-NN-slug/guion.md`, `AGENTS.md` | `beats-estructura`, `mecanica-prosa` | FASE 3.2b |
| `trenzado` | `guion-novela.md`, `hilos/*/guion-hilo.md`, `config.json` | `trenzado-narrativo`, `diseno-hilo` | FASE 3.6 (cada 3 caps y al cerrar el último) |
| `rachas` | `guion-novela.md`, `guion.md` de los caps del tramo | `validacion-cross-hilo`, `diseno-hilo` | FASE 3.6 |

`trenzado` y `rachas` son exclusivos de esta escala: auditan la arquitectura entre hilos, no los beats de un capítulo. Sin ellos el trenzado se degrada sin aviso.

### → auditor-beats

```
Modo: [cobertura | atomizar | transiciones | limpieza | trenzado | rachas]
Leer: [rutas según el modo — ver tabla]
{{#if estado==escritura}}Memoria: briefing ligero (~300t) desde memoria{{/if}}
{{#if modo transiciones, FASE 3.2 (costuras cross-hilo)}}
Foco: SOLO las costuras entre bloques de escena de distinto hilo (no el capítulo completo)
Cross-hilo: sí si el capítulo tiene ≥2 hilos → cargar validacion-cross-hilo
{{/if}}
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
| `hechos-distribuidos` | condicional (si hay `[D]`) | `guionista` modo `hilo-capitulo` (propone plan en Checkpoint 1, genera beats entretejidos), director (valida checkpoints, mantiene `cola_d.md` como registro de contenido) | Guía de despliegue de `[D]` en una sola pasada por capítulo-borrador, sin fórmula numérica fija. Se resuelve por completo antes del trenzado — no interviene en FASE 3. |
| `diseno-hilo` | automática | **director** (escribe `diseno-hilo.md`), guionista y auditor-beats (leen) | Persistir decisiones de diseño de un hilo |
| `trenzado-narrativo` | automática | guionista modo `trenzado`, auditor-beats modo `trenzado` | Reglas de alternancia y tabla de trenzado |
| `plantilla-hilo` | automática | entidades | Campos obligatorios de una entidad `tipo=hilo` |
| `cronista-ops` | automática | director, cronista | Operaciones atómicas de summaries y entidades; reordenamientos |
| `qdrant` | automática | director, memoria, cronista, entidades, guionista | Schema y guía operativa de Qdrant |
| `neo4j` | automática | memoria, cronista, entidades | Schema y guía operativa de Neo4j |
| `auditoria-neo4j` | automática | cronista | Protocolo de auditoría draft ↔ grafo |

---

## Camino por fase — NOVELA MULTI-HILO (9 fases)

Pasos, IN/OUT y gates completos de cada fase: ver `PIPELINE.md`. Esta tabla es solo el mapa rápido de estados — quién actúa y qué resuelve cada fase — para orientarte sin tener que abrir `PIPELINE.md` en cada turno.

| Fase | `estado` | Quién actúa | Objetivo en una frase |
|------|----------|--------------|------------------------|
| FASE 0 | `diseno` | director + usuario | Identificar hilos, conexiones cross-hilo y entidades semilla |
| FASE 0.1 | `diseno` | director + usuario + `entidades` | Refinar hechos con el usuario, ingerir `referencias/` a Qdrant, fichas básicas |
| FASE 0.2 | `diseno_hilos` | director + `guionista` (modo `hilo`) × hilo | Diseñar y guionizar (solo hechos) cada hilo por separado |
| FASE 0.3 | `hilos_beats` | director + `guionista` (modo `hilo-capitulo`) × hilo | Beats y escenas dentro de cada hilo, con checkpoints; `[D]` se resuelve por completo aquí |
| FASE 0.4 | `trenzado` | director + `guionista` (modo `trenzado`) | Mover escenas a capítulos globales; generar la tabla de Trenzado |
| FASE 1 | `fichas` | director | Verificar consistencia de `guion-novela.md` ya trenzado |
| FASE 2 | `fichas` | director + `entidades` | Fichas detalladas, conexiones cross-hilo documentadas, infraestructura verificada |
| FASE 3 | `escritura` | director + escritor/validador/integrador/cronista/memoria/auditor-beats | Bucle beat a beat, capítulo por capítulo, según la tabla de Trenzado |
| FASE 4 | `publicacion` | director | Limpiar drafts y concatenar → `novela.md` |

**Transiciones:** `diseno → diseno_hilos → hilos_beats → trenzado → fichas → escritura → publicacion → finalizado`. `publicado` lo asigna solo el hub (`/crear-libro`) sobre un workspace ya `finalizado`.

---
## Plantillas de briefing (director → subagente)

### → guionista

```
Modo: [hilo | hilo-capitulo | trenzado | revision]
Workspace: [cwd]
Leer: [lista rutas relativas]
Escribir: [ruta salida]
IDs: asignar seq desde config ultimo_hecho_seq=[X] ultimo_beat_seq=[Y]
     generar stable_id opaco (8 hex) para cada elemento nuevo
Capítulo: cap-NN-slug (stable_id, seq, parent_id) - si aplica
Hilo(s) activo(s): [nombre] (stable_id: [8hex]) - si aplica
Tipo de capítulo: [exclusivo | puente | espejo] - si aplica
Contexto previo: [últimos 5-8 beats del bloque/capítulo-borrador anterior, contrato común]
Criterio: [función narrativa del cap/hilo]
Estilo base: [nombre] - cargar skill estilo-<nombre>
{{#if estilo_secundario}}Estilo secundario: [nombre] - fusionar con estilo-<nombre>{{/if}}
{{#if modo hilo-capitulo}}
⚠️ MODO HILO-CAPITULO — trabajas DENTRO de un hilo, antes del trenzado.
Capítulo-borrador: hilos/hilo-<slug>/cap-NN (rango de hechos H_NNNN, objetivo narrativo, tensión)
Contexto acotado (NO diseno-hilo.md ni guion-hilo.md íntegros):
  - Últimos beats del capítulo-borrador anterior del mismo hilo
  - Objetivo narrativo + tensión del capítulo-borrador actual (campos cortos)
  - Resumen compacto de entidades y relaciones relevantes (estilo memoria)
  {{#if hay [D] en el rango}}
  - hilos/hilo-<slug>/cola_d.md (registro de instancias [D] ya escritas en cap-borradores
    anteriores del mismo hecho [D], con stable_id + escena + resumen)
  {{/if}}

{{#if sin [D] en el rango}}
Una sola pasada: genera beats de todos los hechos del rango y agrúpalos en
escenas por coherencia de contexto (mismo espacio/tiempo/cast).
Tras agrupar: el director + usuario revisan la estructura de escenas
(checkpoint ligero — número de escenas, beats por escena, cortes).
{{/if}}

{{#if hay [D] en el rango}}
⚠️ Este capítulo-borrador contiene hechos [D]. Flujo con checkpoints:

1. PROPUESTA DE PLAN (output al director, NO escribas beats todavía):
   - Para cada [D] del rango: qué instancias vas a escribir en este tramo
     (contenido aprox., no solo número; el número es juicio narrativo contextual)
   - Informado por: la prosa del hecho [D] + cola_d.md (lo ya escrito antes)
   - Si el [D] cruza varios cap-borrador, indica cuántas instancias van en este
     y cuántas reservas para los siguientes

2. [Espera validación del director/usuario — NO avances sin confirmación]

3. Tras validación: genera la secuencia COMPLETA de beats del tramo en UNA sola
   pasada (lineales + [D] entretejidos según el plan aprobado). Luego agrupa en
   escenas. Sin inyección diferida: todo junto, en orden narrativo natural.
   Ningún beat conserva marca [D] — quedan indistinguibles de los lineales.
{{/if}}

Output: hilos/hilo-<slug>/cap-NN/guion.md con marcadores
        <!-- ESCENA <stable_id>: Nombre --> agrupando los beats.
        Genera stable_id nuevo para cada beat y cada escena.
{{/if}}
{{#if modo revision}}Tramo: beats [stable_id...] - instrucción: [problema concreto]
Memoria: briefing ligero (~300t){{/if}}
{{#if modo trenzado}}
⚠️ MODO TRENZADO — mueves ESCENAS ya generadas (con sus beats, [D] ya
resueltos) desde cada hilo a los capítulos globales. No generas beats,
hechos ni escenas nuevas.
Entrada: Todos los hilos/*/cap-NN/guion.md (escenas con sus beats, contenido
         completo) + guion-novela.md (## Puntos de conexión — pista temática
         escrita en FASE 0, antes de que existieran escenas; NO es una lista
         a verificar mecánicamente, es contexto para tu búsqueda).
Tarea: lee el contenido real de las escenas de todos los hilos. Descubre en
       ese contenido dónde se materializa cada conexión de la pista temática
       —y cualquier eco orgánico no previsto que detectes—. Asigna cada
       escena a un capítulo global. Mueve el bloque de escena completo
       (marcador + beats) a capitulos/cap-NN-slug/guion.md, aplicando
       renumber-siblings sobre parent_id/seq (stable_id no cambia).
Reglas: máx. 2 hilos/capítulo, racha máx. 3 caps sin que aparezca un hilo,
        clímax de hilo en capítulo exclusivo, puentes solo con propósito narrativo.
Output: Escribe directamente los guion.md de capitulos/ Y la tabla ## Trenzado
        en guion-novela.md (NO respondas con la tabla en texto — usa la
        herramienta de escritura). Formato:
| Cap | Hilo(s) | Escenas | Tipo | Conexiones |
|-----|---------|---------|------|------------|
| cap-01 | hilo-X | ESC_a1, ESC_a2 | exclusivo | — |
...hasta cubrir TODAS las escenas de TODOS los hilos sin excepción.
Reescribe también ## Puntos de conexión en guion-novela.md: sustituye la
prosa temática por lo que descubriste, referenciado por stable_id de escena.
{{/if}}
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
Prosa ya escrita de la escena actual: [TODOS los beats de esta escena en draft.md, desde el primero] | Si primer beat de escena: últimos 3 beats del bloque anterior
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
Escena actual (modo beat): TODOS los beats ya escritos de la escena del beat en draft.md (desde el primero) + siguientes tres del guion
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
Hilo: [nombre] (stable_id: [8hex]) - época, ubicación, tono propio
Tipo de capítulo: [exclusivo | puente | espejo]
Mantener acción nuclear del beat; aplicar mecanica-prosa + estilo
Conservar stable_id y seq sin cambios en el heading devuelto
Estilo: [estilo_base] - cargar skill estilo-<nombre>
{{#if estilo_secundario}}+ fusionar con estilo-<nombre>{{/if}}
TODOS los beats ya escritos de la escena actual (prosa en draft.md, desde el primero) + siguientes tres del guion (siempre)
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
  7. [Opcional] Referencias tipo=referencia con tag relevancia_por_hilo=<hilo_activo> (máx. 2; incluir solo si aportan contexto no cubierto por los summaries; contar en el presupuesto de ~600 tokens)
Summaries: buscar por (nivel, parent_id, seq[, hilo]); el UUID nunca es entrada
```

### → cronista

```
Capítulo completado: cap-NN-slug
Leer: capitulos/cap-NN/draft.md (completo), config.json, hilo(s) activo(s)
Tareas:
  1. Por cada escena en el draft (en orden):
     a. upsert-summary L1 en Qdrant (etiquetado por hilo)
     b. Actualizar dinámico de entidades con cambio inequívoco en la escena
     c. Detectar relaciones materializadas (nuevas, rotas, cambio de rol) y
        aplicarlas con neo4j.py upsert-relationship
  2. upsert-summary L2 del capítulo completo
  3. Si cierre de arco → upsert-summary L3
  4. Si cap % 10 == 0 → upsert-summary L4
  5. Auditoría Neo4j cross-hilo (skill auditoria-neo4j): detectar discrepancias
     residuales no corregibles desde el draft (relaciones que el grafo tiene
     pero el draft contradice). Esto es read-only.
  6. Actualizar config.json: capitulos_completados++, hilos[].ultimo_capitulo
  7. Devolver JSON con summaries, entidades, relaciones aplicadas,
     discrepancias residuales.
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
| `hilos_beats` | FASE 0.3 |
| `trenzado` | FASE 0.4 |
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
| `beats_listos` | Todos los `cap-NN` del hilo tienen beats+escenas generados y todos los `[D]` del hilo con sus entradas cerradas en `cola_d.md`; el archivo se descarta (FASE 0.3) | director |

---

## Huecos prohibidos (no delegar sin dueño)

| Acción | Dueño (quién TIENE que hacerlo) |
|--------|--------------------------------|
| Generar `stable_id` y asignar `seq` | **guionista** (director verifica en config) |
| Marcar ⬜🔄✅ en guion | **director** |
| Escribir prosa | **escritor** |
| Corregir prosa tras fallo | **integrador** |
| Validar | **validador** (read-only, solo JSON) |
| Proponer plan de instancias `[D]` por capítulo-borrador | **guionista** modo `hilo-capitulo` (FASE 0.3, Checkpoint 1) |
| Validar plan de instancias `[D]` y resultado | **director** + usuario (Checkpoints 1 y 2, FASE 0.3) |
| Generar beats (lineales + `[D]` entretejidos) y agrupar en escenas | **guionista** modo `hilo-capitulo` (una sola pasada, FASE 0.3) |
| Actualizar registro de contenido `[D]` en `cola_d.md` | **director** (tras cada Checkpoint 2, FASE 0.3) |
| Mover escenas a capítulos globales (trenzar) + descubrir conexiones | **guionista** modo `trenzado` (FASE 0.4) |
| Auditar costuras cross-hilo del capítulo ensamblado | **auditor-beats** modo `transiciones` (read-only, FASE 3.2) |
| Validar costuras cross-hilo del capítulo ensamblado | **director** + usuario (checkpoint FASE 3.2) |
| Auditar beats, trenzado y rachas | **auditor-beats** (read-only) |
| Publicar limpio | **director** en FASE 4 (vía `/publicar`) |
| Crear entidades | **entidades** (Qdrant + `fichas/<tipo>_<slug>.md`) |
| Actualizar Qdrant post-escena | **cronista** |
| Actualizar Neo4j post-escena (relaciones) | **cronista** |
| Compilar briefing de memoria | **memoria** |
| Escribir `diseno-hilo.md` | **director** + skill `diseno-hilo` |
| Escribir `guion-hilo.md` | **guionista** modo `hilo` |
| Tabla de trenzado | **guionista** modo `trenzado` |
| Escribir `contexto.md` | **director** (al cerrar capítulo) |
| Crear carpetas `hilos/hilo-<slug>/cap-NN/` | **guionista** modo `hilo-capitulo` |
| Crear carpetas `capitulos/cap-NN-slug/` | **guionista** modo `trenzado` |
| Separadores `---` entre bloques de hilo | **director** (al ensamblar el draft) |
| Init Qdrant/Neo4j | **director** (`scripts/qdrant.py`, `scripts/neo4j.py`) |
| Asignar `publicado` | **hub** (`/crear-libro`) — nunca el director |