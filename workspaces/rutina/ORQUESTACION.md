# Orquestación — agentes, skills y rutas de datos (RELATO)

Referencia para **director** y subagentes. Rutas en `MAPA.md`. Fases en `PIPELINE.md`.

---

## Reglas globales

1. **Quién escribe qué:** solo el agente indicado en la columna «Escribe» modifica ese archivo.
2. **Briefing de spawn:** el director pasa siempre rutas relativas al workspace, IDs (`H_`/`B_`), y `Modo`.
3. **IDs:** asignar desde `config.json` → `ultimo_hecho_global` / `ultimo_beat_global`. Tras asignar, incrementar en el archivo que creó el ID.
   - **Relatos:** IDs locales `H_NNNN`, `B_NNNN` por relato.
4. **Estados en guion:** `⬜` → `🔄` (al empezar beat) → `✅` (validador aprueba). Lo marca el **director** tras cada beat.
5. **Backup** antes de sobrescribir archivos con contenido existente.

---

## Matriz de agentes (6 agentes)

| Agente | Invocado por | Lee | Escribe | Invoca | Modelo |
|--------|--------------|-----|---------|--------|--------|
| **director** | usuario `/generar`, `/revisar`, `/expandir`, `/publicar` | `PIPELINE.md`, `MAPA.md`, `config.json`, `BRIEF.md`, `AGENTS.md`, `contexto_narrativo.md`, guiones según fase | `config.json`, `contexto_narrativo.md`, estados en guiones, `fichas/` | guionista, escritor, validador, integrador, entidades | `deepseek-v4-pro` |
| **guionista** | director | Briefing + archivos del modo (ver tabla modos abajo) | Guiones según modo | — | `deepseek-v4-pro` |
| **escritor** | director | Briefing + `guion.md` (beat), `contexto_narrativo.md`, `fichas/` relevantes, `AGENTS.md`, estilo skill | `relato-draft.md` (append sección `## B_NNNN`) | — | `deepseek-v4-pro` |
| **validador** | director | Briefing + texto del beat, `guion.md`, `contexto_narrativo.md`, `fichas/` | — (solo JSON) | — | `deepseek-v4-pro` |
| **integrador** | director | Briefing + `relato-draft.md` (beat), JSON validador | `relato-draft.md` (reemplaza sección beat) | — | `deepseek-v4-pro` |
| **entidades** | director | Nombre, tipo, descripción de entidad + contexto narrativo | `fichas/<tipo>_<slug>.md` (markdown) | — | `deepseek-v4-pro` |

---

## Guionista — modos y contrato

### Relato

| Modo | Lee | Escribe | Actualiza config |
|------|-----|---------|------------------|
| `estructura` | `BRIEF.md`, `_actos.md`, `AGENTS.md` | `guion.md` (escenas, sin beats) | — (director pone `estado=fichas`) |
| `escena` | `guion.md` (escena actual), `AGENTS.md` | `guion.md` (beats bajo hechos) | — |

---

## Skills — rol y quién los carga

| Skill | Invocación | Quién lo aplica | Efecto |
|-------|------------|-----------------|--------|
| `mecanica-prosa` | automática | escritor, integrador | Formato de prosa: guiones de diálogo, párrafos, ⚡, cursiva |
| `beats-estructura` | automática | guionista, escritor (lectura) | Formato `B_NNNN` — acción. `[Tono — EXTENSIÓN]` |
| `tonos-beat` | automática | guionista (asignar), escritor (ejecutar) | Catálogo de 15 tonos + reglas BREVE/MEDIA/EXTENSA |
| `estructura-narrativa` | automática | guionista | Jerarquía: actos → capítulos → escenas → beats |
| `plantilla-guion` | automática | guionista | Estructura de archivos de guion |
| `plantilla-ficha` | automática | entidades, director | Estructura FIJO/DINÁMICO para 10 tipos de entidad |
| `plantilla-personaje` / `plantilla-lugar` / `plantilla-objeto` / `plantilla-animal` / `plantilla-evento` / `plantilla-organizacion` | automática | entidades | Campos obligatorios por tipo de entidad |
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
| `fichas-personajes` | manual (crear/editar fichas) | director, entidades | Guía para crear perfiles NEXUS/HELIX/VELA/STRIX/AXIOM |

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

## Plantillas de briefing (director → subagente)

### → guionista

```
Modo: [estructura | escena]
Workspace: [cwd]
Leer: [lista rutas relativas]
Escribir: [ruta salida]
IDs: asignar desde config ultimo_hecho_global=[X] ultimo_beat_global=[Y]
Criterio: [función narrativa]
Estilo base: [nombre] — cargar skill estilo-<nombre>
{{#if estilo_secundario}}Estilo secundario: [nombre] — fusionar con estilo-<nombre>{{/if}}
```

### → escritor (relato)

```
Beat: B_NNNN | Escena: E_NN
Leer: guion.md (escena actual), contexto_narrativo.md, fichas/[lista], AGENTS.md,
      TODOS los beats ya escritos de la escena actual (desde el primero),
      últimos 3 beats de la escena anterior (si aplica)
Escribir: relato-draft.md — sección ## B_NNNN (append)
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
Texto: [fragmento o ruta relato-draft.md sección B_NNNN]
Dimensiones: ["coherencia", "sensorial", ...] — lista concreta (preferido)
  o Scope: [completa|media|ligera] — formato heredado (se normaliza a dimensiones)
Leer coherencia: contexto_narrativo.md, fichas/[...], guion.md
Estilo activo: [nombre] — validar tono con skill validacion-tono + estilo-<nombre>
Salida: solo JSON (sin editar archivos). Incluir dimensiones_evaluadas, umbral_aplicado, aprobado
```

### → integrador

```
Beat: B_NNNN
Leer: relato-draft.md sección B_NNNN, JSON validador adjunto
Escribir: reemplazar sección ## B_NNNN en relato-draft.md
Mantener acción nuclear del beat; aplicar mecanica-prosa + estilo
Estilo: [estilo_base] — cargar skill estilo-<nombre>
{{#if estilo_secundario}}+ fusionar con estilo-<nombre>{{/if}}
```

### → entidades

```
Entidad: [nombre], tipo [personaje|lugar|objeto|...], slug
Contexto narrativo: [dónde aparece, qué rol tiene]
Output: fichas/<tipo>_<slug>.md
```

---

## config.json — quién actualiza qué

| Campo | Quién | Cuándo |
|-------|-------|--------|
| `estado` | **director** | Al cerrar cada fase |
| `ultimo_hecho_global` | **guionista** o **director** | Al asignar nuevo H_NNNN (incrementar después de usarlo) |
| `ultimo_beat_global` | **guionista** o **director** | Al asignar nuevo B_NNNN |
| `capitulos_completados` | **director** | Al cerrar relato |
| `ultima_modificacion` | quien escriba config | En cada actualización |

**Valores posibles de `config.json.estado`:**

| Estado | Relato |
|--------|:------:|
| `diseno` | ✅ (FASE 1) |
| `fichas` | ✅ (FASE 2) |
| `escritura` | ✅ (FASE 3) |
| `publicacion` | ✅ (FASE 4) |

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
| Crear entidades | **entidades** (solo markdown) |
| Escribir contexto_narrativo.md | **director** (al cerrar escena) |
