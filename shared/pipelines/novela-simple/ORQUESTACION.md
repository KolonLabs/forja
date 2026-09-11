# Orquestación — agentes, skills y rutas de datos (Novela Simple)

Referencia para **director** y subagentes. Rutas en `MAPA.md`. Fases en `PIPELINE.md`.

---

## Reglas globales

1. **Quién escribe qué:** solo el agente indicado en la columna «Escribe» modifica ese archivo.
2. **Briefing de spawn:** `proyecto`, identidades opacas, seq local y modo. Para escritor/integrador, contexto inline ya preparado (sin ordenes de leer archivos o cargar skills). Los demas agentes reciben solo rutas pertinentes.
3. **IDs:** asignar desde `config.json` → `ultimo_hecho_seq` / `ultimo_beat_seq`. Tras asignar, incrementar en el archivo que creó el ID. IDs globales `H_NNNN`, `B_NNNN` (4 dígitos, nunca se reinician).
4. **Estados en guion:** `⬜` → `🔄` (al iniciar la narrativa) → `✅` solo tras conformidad del usuario, revision editorial del mismo hash y sincronizacion exitosa. El **director** actualiza los beats de la escena en lote; aprobar el validador por si solo no los completa.
5. **Backup** antes de sobrescribir archivos con contenido existente.
6. **Contrato editorial comun:** `beats-estructura` y `contexto-subagente` rigen la formulacion e interpretacion: unidad dramatica, no microaccion; separar Obligatorio, Libre y Ejemplos opcionales en el contexto existente. Sin cuotas de beats ni division por puntuacion. Lo dicho, sabido, inferido y confirmado no se intercambia.
7. **Escritura continua:** encabezados y cuerpos por beat se conservan para trazabilidad, no para reiniciar conversaciones. El director pasa inline la libertad de ejecucion y sus limites a escritor/integrador, sin herramientas. Una literalidad o guion incompatible vuelve al director antes de generar; no se fuerza la prosa. Ver `beats-estructura` y `mecanica-prosa`.

---

## Matriz de agentes (9 agentes)

### Checkpoint obligatorio de narrativa

En este workspace, cada generacion o correccion de prosa termina en `preparar` -> presentar la escena completa al usuario con su hash/version -> detenerse y esperar respuesta explicita. Se aplica siempre, no solo cuando el usuario lo pida. El checkpoint de guion no aprueba la narrativa posterior.

Conformidad humana, revision editorial por hash y permiso de avance son decisiones distintas. Aprobar el texto no autoriza la siguiente escena. Se puede preguntar conjuntamente por esa version y el avance a una escena concreta; si no se autorizo expresamente, preguntar y esperar. No generar ni preparar otras escenas o capitulos especulativamente. Cualquier cambio textual invalida la conformidad anterior y el avance asociado; se presenta de nuevo y se reconfirma antes de aceptar/sincronizar.

Registrar escena, hash/version, decision del usuario y alcance de avance en `contexto.md`; reanudar sin ese dato requiere preguntar, no deducir aprobacion de un review o archivo pendiente. Tras el cierre del capitulo, pedir autorizacion explicita para iniciar el siguiente capitulo antes de memoria/guion. Contrato completo: `PIPELINE.md`, gate de narrativa.

| Agente | Invocado por | Lee | Escribe | Invoca | Modelo |
|--------|--------------|-----|---------|--------|--------|
| **director** | usuario `/generar`, `/revisar`, `/expandir`, `/publicar`, `/refinar-hechos`, `/validar-hechos`, `/revisar-guion` | `PIPELINE.md`, `MAPA.md`, `config.json`, `BRIEF.md`, `AGENTS.md`, `contexto.md`, guiones según fase | `config.json`, `contexto.md`, estados en guiones | guionista, escritor, validador, integrador, memoria, cronista, entidades, auditor-beats | `deepseek/deepseek-v4-pro` |
| **guionista** | director | Briefing + archivos del modo (ver tabla modos abajo) | Guiones según modo | — | `deepseek/deepseek-v4-pro` |
| **auditor-beats** | director | `guion.md` o `guion-novela.md`, `_actos.md`, `AGENTS.md` | — (read-only, diagnóstico al director) | — | `deepseek-v4-pro` |
| **escritor** | director | Contexto preparado inline, guion de escena, transicion, fichas y voz pertinentes | Nada; devuelve prosa con IDs, sin herramientas, completion maxima 64000 | — | `venice/qwen-3-8-max` |
| **validador** | director | Candidato/hash, guion, canon y contexto pertinente; briefing neutral | Nada; JSON de incidencias editoriales, sin scores por beat | — | `deepseek/deepseek-v4-pro` |
| **integrador** | director | Fragmentos afectados y ambos extremos de transicion inline; incidencias concretas | Nada; devuelve secciones corregidas, sin herramientas, completion maxima 64000 | — | `venice/qwen-3-8-max` |
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
| `mecanica-prosa` | al preparar contexto | director; reglas inline para escritor e integrador | Formato de prosa: dialogos, parrafos, lineas obligatorias y cursiva |
| `beats-estructura` | automática | guionista, escritor (lectura) | Formato `B_NNNN` — acción. `[Tono — EXTENSIÓN]` |
| `hechos-estructura` | automática | guionista | Formato `H_NNNN` — hecho narrativo |
| `tonos-beat` | automática | guionista (asignar), escritor (ejecutar) | Catálogo de 15 tonos + reglas BREVE/MEDIA/EXTENSA |
| `estructura-narrativa` | automática | guionista | Jerarquía: actos → capítulos → escenas → beats |
| `plantilla-guion` | automática | guionista | Estructura de archivos de guion |
| `plantilla-ficha` | automática | entidades | Estructura FIJO/DINÁMICO para 10 tipos de entidad |
| `plantilla-personaje` / `plantilla-lugar` / `plantilla-objeto` / `plantilla-animal` / `plantilla-arco` / `plantilla-evento` / `plantilla-organizacion` | automática | entidades | Campos obligatorios por tipo de entidad |
| `estilo-explicito` / `estilo-contemporaneo` / `estilo-erotico` / `estilo-fantasia` / `estilo-noir` / `estilo-romantico` / `estilo-thriller` | al preparar contexto | director; extracto vigente inline a agentes narrativos | Voz, ritmo y registro; sin recargar skills por beat |
| `estilo-prosa` | automática | director (crear/validar estilos) | Meta-skill: estructura que debe tener un skill de estilo |
| `validacion-crudeza` | automática | validador | Evalúa vocabulario explícito, ausencia de eufemismos |
| `validacion-tono` | automática | validador | Evalúa coherencia tonal contra el estilo activo |
| `validacion-geometria` | automática | validador | Evalúa ritmo, cadencia, fluidez de frases |
| `validacion-coherencia` | automática | validador | Evalúa continuidad física, consistencia de personajes, lógica |
| `validacion-sensorial` | si aporta al diagnostico | validador | Valora detalle pertinente, sin cuotas de sentidos por beat/parrafo |
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

  2.3 por cada escena (todos sus beats):
       2.3.1 contexto pertinente inline -> escritor sin herramientas
             OUT: solo prosa con identidades; completion maxima 64000
       2.3.1b director: persistir-escena.py preparar (finish stop)
             OUT: candidata pendiente + SHA256; sin draft ni Qdrant
       2.3.1c director + usuario: presentar escena completa y DETENERSE
             OUT: conformidad explicita de esa version o ajustes; esperar respuesta
       2.3.2 validador: una revision editorial independiente por escena
             OUT: estado + incidencias concretas + hash revisado
       2.3.3 si hay incidencias: correccion selectiva (mecanica o integrador)
             OUT: candidata nueva, nuevo hash -> volver al checkpoint 2.3.1c
             Tras conformidad: revision focalizada para ese hash
       2.3.4 director: ambas aprobaciones -> aceptar -> sincronizar -> completos
             Reintento identico no duplica; falla red -> reintenta sync,
              no regenera. No hay transaccion conjunta disco + Qdrant.
       2.3.5 director + usuario: avance solo con autorizacion explicita
             Sin permiso para la escena siguiente, detenerse y preguntar

  2.4 director → validador(modo: global) sobre cruces entre escenas
       OUT: incidencias transversales (cronologia, objetos, arco)
       si falla: corregir alcance afectado; no repuntuar todo el estilo

2.5 director → cronista
       IN:  draft.md, config.json
       OUT: por escena: Qdrant L1 + entidades dinámico + Neo4j relaciones
            tras escena: L2 (capítulo), L3 (si cierre arco), L4 (cada 10 caps)
            + auditoría Neo4j read-only (discrepancias residuales)
            + config.json: capitulos_completados++
       si quedan capitulos -> informar cierre, preguntar y esperar autorizacion
       Solo entonces 2.1 del siguiente capitulo; no iniciar memoria/guion antes

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
Obligatorio: [compromisos, consecuencias, restricciones; literalidad solo si exigida o causalmente justificada]
Libre: [ejecucion compatible, sin microcoreografia]
Ejemplos opcionales: [posibilidades, no canon ni lista a cumplir]
Estilo base: [nombre] — cargar skill estilo-<nombre>
{{#if estilo_secundario}}Estilo secundario: [nombre] — fusionar con estilo-<nombre>{{/if}}
{{#if pasada 1}}Sin marcadores <!-- ESCENA ... -->. Salida: beats en bruto.{{/if}}
{{#if pasada 2}}Agrupa los beats ya generados en escenas (con independencia del hecho de origen). Genera stable_id para cada escena nueva. Inserta marcadores <!-- ESCENA <stable_id>: Nombre -->. No modifiques los beats.{{/if}}
```

### → escritor

```
Proyecto: [slug]
Modo: escena | expansion puntual
Capitulo/escena: stable_id, seq local, parent_id
Contexto inline: canon y memoria ya resueltos; voz/POV/mecanica/restricciones;
guion de la escena; fichas pertinentes; transicion previa y compromisos posteriores.
Obligatorio / Libre / Ejemplos opcionales: separar compromisos de ejecucion.
Interpretacion inline: escena continua, dicho/sabido/inferido/confirmado distintos;
no convertir ejemplos en canon ni deducciones en listas o confesiones.
No duplicar contexto en rutas ni pedir cargar skills. No hay herramientas.
Salida: marcador ESCENA y secciones ## <stable_id> [<seq>] — accion breve,
solo prosa, sin notas rutinarias, JSON ni fences. Ante canon incierto: BLOQUEO.
Director conserva terminacion real, prepara y presenta la candidata al usuario;
se detiene. Revision editorial y conformidad humana por version antes de persistir.
```

### → validador

```
Proyecto: [slug]
Modo: escena | revision focalizada | global transversal
Escena/capitulo: [stable_id]; candidato_sha256: [hash real]
Entrada: candidato exacto, guion, canon y contexto de transicion necesarios.
Obligatorio / Libre / Ejemplos opcionales: comprobar compromisos y naturalidad,
no reproducir cada gesto ilustrativo ni aprobar solo por cobertura de IDs.
Briefing neutral: sin elogios ni defensas previas de la solucion.
Salida: JSON con estado (aprobado/corregir/bloqueado), hash e incidencias.
Cada incidencia: beat_stable_id, area, gravedad, fragmento, problema, correccion.
Gravedades: bloqueante / corregir / opcional. Sin scores por beat.
No aprobar errores factuales por promedio ni completar cuotas sensoriales.
```

### → integrador

```
Proyecto: [slug]
Modo: correccion selectiva
Inline: contratos y texto de fragmentos afectados + incidencias concretas,
ambos extremos de transicion, fichas/voz/POV/restricciones pertinentes.
Obligatorio / Libre / Ejemplos opcionales: mismo contrato de interpretacion.
Texto completo de secciones solicitadas: reparar el mecanismo en el intercambio
minimo autorizado; conflicto de guion o alcance insuficiente -> BLOQUEO al director.
Salida: solo secciones corregidas ## <stable_id> [<seq>] — accion breve.
Sin original duplicado, JSON, notas ni herramientas. Canon incierto -> BLOQUEO.
Director ensambla y prepara el candidato, presenta la escena completa y se detiene
para conformidad humana; revision focalizada por hash antes de aceptar/sincronizar.
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
Leer: capitulos/cap-NN/draft.md (completo), guion.md (marcadores de escena), config.json
Tareas:
  1. Por cada escena en el draft (en orden):
      a. upsert-summary --id <stable_id_escena> --nivel L1 --parent-id <capitulo>
         --seq <N> --proyecto <slug> — CONSERVAR la identidad del guion/draft.
         Si falta ID canonico, bloquear: no crear L1 con identidad aleatoria.
         Preflight del helper ANTES de escribir: posicion unica, identidad
         esperada y punto fisico del mismo proyecto/nivel/padre/seq/hilo.
         Conflicto -> detener y reconciliar, no crear segundo L1.
         Verificar despues posicion e integridad beat -> L1 -> L2.
     b. Actualizar dinámico de entidades con cambio inequívoco en la escena
     c. Detectar relaciones materializadas (nuevas, rotas, cambio de rol) y
        aplicarlas con neo4j.py upsert-relationship
  2. upsert-summary --id <capitulo> L2 del capitulo completo
  3. Si cierre de arco -> upsert-summary --id <arco> L3
  4. Si cap % 10 == 0 → upsert-summary L4
  5. Auditoría Neo4j (skill auditoria-neo4j): detectar discrepancias
     residuales no corregibles desde el draft. Esto es read-only.
  6. Solo si pasa el gate: actualizar config.json (capitulos_completados)
  7. Devolver JSON con summaries, entidades, relaciones aplicadas,
      discrepancias_qdrant y discrepancias_neo4j por separado.
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
| Persistir narrativa aceptada / vectores de beats | **director**, via `scripts/persistir-escena.py` |
| Actualizar summaries y dinamico al cierre | **cronista** |
| Actualizar Neo4j post-escena (relaciones) | **cronista** |
| Compilar briefing de memoria | **memoria** |
| Escribir `contexto.md` | **director** (registro obligatorio en cada checkpoint y respuesta; tambien resumen al cerrar capitulo) |
| Crear carpetas `capitulos/cap-NN-slug/` | **guionista** (modo capitulo) |
| Init Qdrant/Neo4j | **director** (`scripts/qdrant.py`, `scripts/neo4j.py`) |
