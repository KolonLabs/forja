# Orquestación — agentes, skills y rutas de datos (Novela Simple)

Referencia para **director** y subagentes. Rutas en `MAPA.md`. Fases en `PIPELINE.md`.

---

## Reglas globales

1. **Quién escribe qué:** solo el agente indicado en la columna «Escribe» modifica ese archivo.
2. **Briefing de spawn:** el director pasa siempre rutas relativas al workspace, IDs (`H_`/`B_`), y `Modo`.
3. **IDs:** asignar desde `config.json` → `ultimo_hecho_seq` / `ultimo_beat_seq`. Tras asignar, incrementar en el archivo que creó el ID. IDs globales `H_NNNN`, `B_NNNN` (4 dígitos, nunca se reinician).
4. **Estados en guion:** `⬜` → `🔄` (al empezar beat) → `✅` (validador aprueba). Lo marca el **director** tras cada beat.
5. **Backup** antes de sobrescribir archivos con contenido existente.

---

## Matriz de agentes (9 agentes)

| Agente | Invocado por | Lee | Escribe | Invoca | Modelo |
|--------|--------------|-----|---------|--------|--------|
| **director** | usuario `/generar`, `/revisar`, `/expandir`, `/publicar`, `/refinar-hechos`, `/validar-hechos`, `/revisar-guion` | `PIPELINE.md`, `MAPA.md`, `config.json`, `BRIEF.md`, `AGENTS.md`, `contexto.md`, guiones según fase | `config.json`, `contexto.md`, estados en guiones | guionista, escritor, validador, integrador, memoria, cronista, entidades, auditor-beats | `deepseek-v4-pro` |
| **guionista** | director | Briefing + archivos del modo (ver tabla modos abajo) | Guiones según modo | — | `opencode/claude-sonnet-5` |
| **auditor-beats** | director | `guion.md` o `guion-novela.md`, `_actos.md`, `AGENTS.md` | — (read-only, diagnóstico al director) | — | `deepseek-v4-pro` |
| **escritor** | director | Briefing + `guion.md` (beat), `contexto.md`, `fichas/` relevantes, `AGENTS.md`, estilo skill | `draft.md` (append sección `## B_NNNN`) | — | `deepseek-v4-pro` |
| **validador** | director | Briefing + texto del beat, `guion.md`, `contexto.md`, `fichas/` | — (solo JSON) | — | `opencode/glm-5.2` |
| **integrador** | director | Briefing + `draft.md` (beat), JSON validador | `draft.md` (reemplaza sección beat) | — | `deepseek-v4-pro` |
| **memoria** | director | `config.json`, especificación de entidades del cap | — (solo briefing de ~600 tokens) | — | `deepseek-v4-flash` |
| **cronista** | director (cierre de cap) | `draft.md` completo, `config.json` | Qdrant (summaries L1-L4 + entidades `dinamico`), Neo4j (relaciones por escena), `config.json` (contadores) | — | `deepseek-v4-flash` |
| **entidades** | director | Nombre, tipo, descripción de entidad + contexto narrativo | Qdrant (`upsert-entity`) + `fichas/<tipo>_<slug>.md` | — | `deepseek-v4-pro` |

---

## Guionista — modos y contrato

| Modo | Lee | Escribe | Actualiza config |
|------|-----|---------|------------------|
| `estructura-novela` | `BRIEF.md, _actos.md`, `config.json` | `guion-novela.md` (actos, caps, hechos `H_NNNN`) | `ultimo_hecho_seq`; director pone `estado=fichas` |
| `capitulo` pasada 1 | `guion-novela.md` (tramo cap), `contexto.md`, `fichas/`, briefing (cap N, rango H) | `capitulos/cap-NN-slug/guion.md` (crear carpeta, beats en bruto, sin escenas) | `ultimo_hecho_seq`, `ultimo_beat_seq` |
| `capitulo` pasada 2 | `capitulos/cap-NN-slug/guion.md` (beats en bruto) | `capitulos/cap-NN-slug/guion.md` (inserta marcadores `<!-- ESCENA ... -->` agrupando beats por contexto, no por hecho) | — (mismos IDs) |
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
Modo: [cobertura | atomizar | transiciones | limpieza]
Leer: guion.md (o capitulos/cap-NN-slug/guion.md), _actos.md, AGENTS.md
{{#if estado==escritura}} Memoria: briefing ligero (~300t) desde memoria{{/if}}
Output: diagnóstico al director (tablas de problemas + propuestas)
No modificar archivos
```

---

## Skills — rol y quién los carga

| Skill | Invocación | Quién lo aplica | Efecto |
|-------|------------|-----------------|--------|
| `mecanica-prosa` | automática | escritor, integrador | Formato de prosa: guiones de diálogo, párrafos, ⚡, cursiva |
| `beats-estructura` | automática | guionista, escritor (lectura) | Formato `B_NNNN` — acción. `[Tono — EXTENSIÓN]` |
| `hechos-estructura` | automática | guionista | Formato `H_NNNN` — hecho narrativo |
| `tonos-beat` | automática | guionista (asignar), escritor (ejecutar) | Catálogo de 15 tonos + reglas BREVE/MEDIA/EXTENSA |
| `estructura-narrativa` | automática | guionista | Jerarquía: actos → capítulos → escenas → beats |
| `plantilla-guion` | automática | guionista | Estructura de archivos de guion |
| `plantilla-ficha` | automática | entidades | Estructura FIJO/DINÁMICO para 10 tipos de entidad |
| `plantilla-personaje` / `plantilla-lugar` / `plantilla-objeto` / `plantilla-animal` / `plantilla-arco` / `plantilla-evento` / `plantilla-organizacion` | automática | entidades | Campos obligatorios por tipo de entidad |
| `estilo-explicito` / `estilo-contemporaneo` / `estilo-erotico` / `estilo-fantasia` / `estilo-noir` / `estilo-romantico` / `estilo-thriller` | automática | escritor, integrador, validador (tono) | Voz narrativa: vocabulario, ritmo, crudeza, foco sensorial |
| `estilo-prosa` | automática | director (crear/validar estilos) | Meta-skill: estructura que debe tener un skill de estilo |
| `validacion-crudeza` | automática | validador | Evalúa vocabulario explícito, ausencia de eufemismos |
| `validacion-tono` | automática | validador | Evalúa coherencia tonal contra el estilo activo |
| `validacion-geometria` | automática | validador | Evalúa ritmo, cadencia, fluidez de frases |
| `validacion-coherencia` | automática | validador | Evalúa continuidad física, consistencia de personajes, lógica |
| `validacion-sensorial` | automática | validador | Evalúa presencia de los 5 sentidos |
| `consistencia-narrativa` | manual (`/revisar`) | director → validador | Auditoría de coherencia entre actos, capítulos, arcos |
| `contexto-subagente` | automática | director (antes de spawn) | Define qué información pasar a cada subagente |
| `desarrollo-narrativa` | manual (`/generar` en escritura) | director, escritor | Guía para desarrollar escenas y beats |
| `fichas-personajes` | manual (crear/editar fichas) | director, entidades | Guía para crear perfiles de personaje |
| `qdrant` | automática | memoria, cronista, entidades | Schema y guía operativa de Qdrant |
| `neo4j` | automática | memoria, cronista, entidades | Schema y guía operativa de Neo4j |
| `auditoria-neo4j` | automática | cronista | Protocolo de auditoría draft ↔ grafo |

---

## Camino por fase — NOVELA SIMPLE (4 fases)

Pasos, IN/OUT y gates completos: ver `PIPELINE.md`.

```
FASE 0 diseño
  [si referencias/ existe]
  director: lee referencias/ directamente (Markdown, sin Qdrant)
  director → guionista(modo: estructura-novela)
  IN:  BRIEF.md, _actos.md, config.json
  OUT: guion-novela.md (actos, caps, hechos H_NNNN)

FASE 0.1 refinamiento de hechos
  director + usuario: revisan hechos de guion-novela.md a la luz de
                      referencias/ leídas (paso 0.a)
                      el director propone, el usuario confirma/ajusta
                      director aplica cambios vía guionista si estructural
  director → entidades (×N): ingestar referencias/ como tipo=referencia
    índice estructurado en fijo (resumen + temas[]), sin dinámico
  director → entidades (×N, incremental): fichas básicas
  estado → "fichas"

FASE 1 componentes
  director → entidades (×N entidades)
  IN:  BRIEF.md, guion-novela.md
  OUT: Qdrant entidades (fijo + dinámico) + fichas/<tipo>_<slug>.md
  director: init Neo4j (scripts/neo4j.py init <slug>)
  estado → "escritura"

FASE 2 escritura (por capítulo)
2.1 director → memoria
      IN:  config.json, entidades relevantes del cap
      OUT: briefing ~600 tokens (L4 → L3 → L2 recientes → entidades → relaciones
           + referencias tipo=referencia relevantes, máx. 2)

2.2 director → guionista(modo: capitulo, pasada 1)
      IN:  cap-NN-slug, hechos H_XXXX de este capítulo, briefing memoria
      OUT: capitulos/cap-NN-slug/guion.md (crear carpeta, beats en bruto
           de los hechos de este capítulo, no de la novela completa; SIN escenas)

  2.2.2 director → guionista(modo: capitulo, pasada 2)
       IN:  capitulos/cap-NN-slug/guion.md (beats en bruto)
       OUT: capitulos/cap-NN-slug/guion.md con marcadores <!-- ESCENA ... -->
       (agrupa beats por coherencia de contexto, no por hecho de origen)

  2.2.3 director + usuario — CHECKPOINT OBLIGATORIO
       presenta estructura de escenas propuesta; usuario valida o pide ajustes
       GATE: sin confirmación, no se avanza a 2.2.4

  2.2b director → auditor-beats(modo: atomizar) → auditor-beats(modo: transiciones) → auditor-beats(modo: limpieza)
      IN:  capitulos/cap-NN-slug/guion.md, _actos.md, AGENTS.md
      OUT: diagnóstico de beats (inconclusos, huecos, prosa). Director → guionista corrige

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
       IN:  draft.md, config.json
       OUT: por escena: Qdrant L1 + entidades dinámico + Neo4j relaciones
            tras escena: L2 (capítulo), L3 (si cierre arco), L4 (cada 10 caps)
            + auditoría Neo4j read-only (discrepancias residuales)
            + config.json: capitulos_completados++
       si quedan capítulos → volver a 2.1

  estado → "publicacion"

FASE 3 publicar
  por cada cap: /publicar → capitulos/cap-NN-slug/capitulo.md
  concatenar → novela.md
```

---

## Plantillas de briefing (director → subagente)

### → guionista

```
Modo: [estructura-novela | capitulo] [pasada: 1 | 2]
Workspace: [cwd]
Leer: [lista rutas relativas]
Escribir: [ruta salida]
IDs: asignar desde config ultimo_hecho_seq=[X] ultimo_beat_seq=[Y]
Capítulo: cap-NN-slug (si aplica)
Contexto previo: [últimos 5-8 beats del capítulo/acto anterior, si aplica]
Contexto posterior: [beat siguiente al punto de inserción, solo pasada 2]
Criterio: [función narrativa del cap]
Estilo base: [nombre] — cargar skill estilo-<nombre>
{{#if estilo_secundario}}Estilo secundario: [nombre] — fusionar con estilo-<nombre>{{/if}}
{{#if pasada 1}}Sin marcadores <!-- ESCENA ... -->. Salida: beats en bruto.{{/if}}
{{#if pasada 2}}Agrupa los beats ya generados en escenas (con independencia del hecho de origen). Genera stable_id para cada escena nueva. Inserta marcadores <!-- ESCENA <stable_id>: Nombre -->. No modifiques los beats.{{/if}}
```

### → escritor

```
Beat: B_NNNN | Hecho padre: H_NNNN
Leer: capitulos/.../guion.md (línea beat), contexto.md, fichas/[lista]
Briefing memoria: [~600 tokens desde agente memoria]
Prosa ya escrita de la escena actual: [TODOS los beats de esta escena en draft.md, desde el primero] | Si primer beat de escena: últimos 3 beats de la escena anterior
Escribir: capitulos/.../draft.md — sección ## B_NNNN (append; crear archivo si no existe)
Tono: [BREVE|MEDIA|EXTENSA] + [tono de tonos-beat] + [⚡ línea crítica si hay]
Estilo: [estilo_base] — cargar skill estilo-<nombre>
{{#if estilo_secundario}}+ fusionar con estilo-<nombre>{{/if}}
Beat N de M en el capítulo
Premisa del capítulo: [extraída de guion-novela.md]
No marcar ✅ en guion — solo prosa en draft
```

### → validador

```
Modo: read-only
Beat: B_NNNN (o modo global)
Texto: [fragmento o ruta draft.md sección B_NNNN]
Escena actual (modo beat): TODOS los beats ya escritos de la escena del beat en draft.md (desde el primero) + siguientes tres del guion
Dimensiones: ["coherencia", "sensorial", ...] — lista concreta (preferido)
  o Scope: [completa|media|ligera] — formato heredado (se normaliza a dimensiones)
Leer coherencia: contexto.md, fichas/[...], guion.md
Estilo activo: [nombre] — validar tono con skill validacion-tono + estilo-<nombre>
Salida: solo JSON (sin editar archivos). Incluir dimensiones_evaluadas, umbral_aplicado, aprobado
```

### → integrador

```
Beat: B_NNNN
Leer: draft.md sección B_NNNN, JSON validador adjunto
Escribir: reemplazar seccción ## B_NNNN en draft.md
Mantener acción nuclear del beat; aplicar mecanica-prosa + estilo
Estilo: [estilo_base] - cargar skill estilo-<nombre>
{{#if estilo_secundario}}+ fusionar con estilo-<nombre>{{/if}}
TODOS los beats ya escritos de la escena actual (prosa en draft.md, desde el primero) + siguientes tres del guion
```

### → memoria

```
Novela: [slug]
Capítulo actual: cap-NN
Entidades relevantes: [lista de IDs tipo-slug del capítulo]
Briefing esperado: ~600 tokens. Estructura:
  1. Resumen L4 (global) — si existe
  2. Resumen L3 del arco activo — si existe
  3. Últimos 3 L2 (capítulos previos)
  4. Entidades del capítulo (fijo + dinámico desde Qdrant)
  5. Relaciones activas (Neo4j) de personajes del capítulo
  6. [Opcional] Referencias tipo=referencia relevantes al objetivo del capítulo (máx. 2; resumen, no contenido completo)
```

### → cronista

```
Capítulo completado: cap-NN-slug
Leer: capitulos/cap-NN/draft.md (completo), config.json
Tareas:
  1. Por cada escena en el draft (en orden):
     a. upsert-summary L1 en Qdrant
     b. Actualizar dinámico de entidades con cambio inequívoco en la escena
     c. Detectar relaciones materializadas (nuevas, rotas, cambio de rol) y
        aplicarlas con neo4j.py upsert-relationship
  2. upsert-summary L2 del capítulo completo
  3. Si cierre de arco → upsert-summary L3
  4. Si cap % 10 == 0 → upsert-summary L4
  5. Auditoría Neo4j (skill auditoria-neo4j): detectar discrepancias
     residuales no corregibles desde el draft. Esto es read-only.
  6. Actualizar config.json: capitulos_completados++
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
| `ultimo_hecho_seq` | **guionista** o **director** | Al asignar nuevo H_NNNN (incrementar después de usarlo) |
| `ultimo_beat_seq` | **guionista** o **director** | Al asignar nuevo B_NNNN |
| `capitulos_completados` | **cronista** | Al cerrar capítulo |
| `ultima_modificacion` | quien escriba config | En cada actualización |
| `version_qdrant` | **director** | Tras init Qdrant |
| `version_neo4j` | **director** | Tras init Neo4j |

**Valores posibles de `config.json.estado`:** `diseno` (FASE 0) → `fichas` (FASE 1) → `escritura` (FASE 2) → `publicacion` (FASE 3).

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
| Crear entidades | **entidades** (Qdrant + `fichas/<tipo>_<slug>.md`) |
| Actualizar Qdrant post-escena | **cronista** |
| Actualizar Neo4j post-escena (relaciones) | **cronista** |
| Compilar briefing de memoria | **memoria** |
| Escribir `contexto.md` | **director** (al cerrar capítulo) |
| Crear carpetas `capitulos/cap-NN-slug/` | **guionista** (modo capitulo) |
| Init Qdrant/Neo4j | **director** (`scripts/qdrant.py`, `scripts/neo4j.py`) |
