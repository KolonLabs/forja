# Pipeline — Novela Simple (4 fases)

Escala `novela-simple`. Qdrant+Neo4j activos. Una línea temporal, sin hilos paralelos.

> Rutas: ver `MAPA.md` · Spawn y contratos: `ORQUESTACION.md` · Estado: `config.json` + `guion-novela.md` statuses

## Jerarquía narrativa

```
_actos.md (estructura de actos)
  └── guion-novela.md (actos, capítulos, hechos H_NNNN estimados)
        └── capitulos/cap-NN-slug/
              ├── guion.md    (hechos H_NNNN + beats B_NNNN bajo cada hecho)
              ├── draft.md    (escenas aceptadas, secciones ## <stable_id> [<seq>])
              └── capitulo.md (publicable)

contexto.md (registro obligatorio de cada checkpoint/respuesta y resumen post-capitulo, mantenido por el director; complementa a Qdrant como respaldo legible)
fichas/<tipo>_<slug>.md (entidades en markdown, primarias en Qdrant)
```

## Hechos y beats

| ID | Qué es | Dónde |
|----|--------|-------|
| `H_NNNN` | Evento que debe ocurrir (1-2 frases de guion). Puede ser lineal o distribuido `[D]`. | `guion-novela.md`, `capitulos/.../guion.md` |
| `B_NNNN` | Compromiso narrativo de una unidad dramatica, no microaccion ni prosa prefijada | `capitulos/.../guion.md` (bajo un hecho) |

- IDs globales, 4 dígitos, nunca reutilizar.
- Estados: ✅ completo · 🔄 en progreso · ⬜ pendiente.
- Un hecho `[D · H_XX–H_YY]` no genera capítulos ni escenas propias — sus beats se inyectan en las escenas de los hechos lineales dentro del rango.
- Skills: `beats-estructura`, `tonos-beat`, `plantilla-guion`, `hechos-distribuidos`.

**Contrato editorial:** unidad dramatica y cobertura por acontecimientos/consecuencias, sin cuotas ni division por puntuacion. Director separa Obligatorio, Libre y Ejemplos opcionales; escritor e integrador reciben el contrato inline, conservan IDs/cuerpos y desarrollan una escena continua. No convierten lo sabido en preguntas, lo inferido en confesiones ni ejemplos en canon. Conflictos de guion/literalidad vuelven al director. El modo `atomizar` conserva nombre pero evalua unidad dramatica. Ver `beats-estructura` y `contexto-subagente`.

---

## Fases

### FASE 0 — Diseño global (`estado: diseno`)

Los pasos internos de esta fase usan letras (`0.a`–`0.d`) para no chocar con la numeración de las fases mayores que siguen (`FASE 0.1`, `FASE 1`...).

| Paso | Agente | Skill | Entrada | Salida |
|------|--------|-------|---------|--------|
| 0.a Referencias | `director` | — | `referencias/` (si existe) | **Solo si `referencias/` existe:** leer los archivos Markdown directamente (sin Qdrant). Extraer información relevante para personajes, mundo y conflictos que informará las decisiones de hechos. **Qdrant no se alimenta aquí** — la ingestión con índice estructurado ocurre en FASE 0.1 paso 0.1.2. |
| 0.b `[D]` | `director` | `scaffolding-hecho`, `hechos-distribuidos` | `_actos.md` | Anotaciones `🎬 Director:` bajo hechos `[D]` en `_actos.md` |
| 0.c Seed entidades | `director` → `entidades` (×N) + `neo4j.py` | — | `_actos.md`, `BRIEF.md` | Entidades básicas en Qdrant (stable_id, tipo, nombre, fijo). Relaciones básicas en Neo4j |
| 0.d Estructura | `guionista` modo `estructura-novela` | `estructura-narrativa`, `beats-estructura`, `plantilla-guion` [+ `hechos-distribuidos` si hay `[D]`] | `BRIEF.md`, `_actos.md` (con anotaciones) | `guion-novela.md` (actos, capítulos, hechos estimados + inyección `[D]`) |

**Gate:** Cada capítulo tiene función narrativa clara. Hechos estimados asignados.

---

### FASE 0.1 — Refinamiento de hechos (`estado: diseno`)

Objetivo: revisar los hechos del guion a la luz de las referencias leídas, antes de comprometerlos.

| Paso | Agente | Acción |
|------|--------|--------|
| 0.1.1 Revisión de hechos | director + usuario | El director presenta los hechos de `guion-novela.md` al usuario. A la luz de las referencias leídas (paso 0.a), el director propone ajustes: añadir, eliminar, fusionar, dividir o reescribir hechos. El usuario confirma, rechaza o pide cambios. El director aplica vía guionista si la reescritura es estructural. Itera hasta confirmación. |
| 0.1.2 Ingesta referencias | `entidades` (×N) | **Solo si `referencias/` existe:** ingestar cada archivo como `tipo=referencia` en Qdrant (`fijo` = índice estructurado con `resumen` + `temas[]`, sin `dinamico`). El archivo original queda intacto en `referencias/` como fuente legible. |
| 0.1.3 Fichas básicas | `entidades` (×N) | Fichas básicas en Qdrant + `fichas/<tipo>_<slug>.md` para entidades clave |

**Gate:** Hechos refinados y confirmados por el usuario. Referencias ingeridas en Qdrant. Fichas básicas de entidades clave.

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

Recorre los capitulos de `guion-novela.md` en orden, con autorizacion de avance y checkpoint obligatorio tras la narrativa de cada escena. No es un bucle autonomo hasta terminar la novela.

#### 2.1 Memoria

| Paso | Agente | Acción |
|------|--------|--------|
| 2.1.1 | `memoria` | Consulta Qdrant (L4, L3, L2 recientes, entidades) + Neo4j (relaciones activas) → briefing ~600 tokens |

#### 2.2 Guion del capítulo

| Paso | Agente | Acción |
|------|--------|--------|
| 2.2.1 | `guionista` modo `capitulo`, pasada 1 | Recibe briefing memoria + estructura cap + contexto anterior + IDs → **crea directorio** `capitulos/cap-NN-slug/` y escribe `capitulos/cap-NN-slug/guion.md`. **Descompone en beats los hechos de este capítulo** (extraídos de `guion-novela.md`, no de toda la novela). **No inserta marcadores `<!-- ESCENA ... -->` en esta pasada.** Salida: beats en bruto, sin agrupar en escenas. |
| 2.2.2 | `guionista` modo `capitulo`, pasada 2 | **Agrupa los beats ya generados en escenas.** Con independencia total del hecho de origen (la procedencia del hecho es irrelevante — el hecho ya cumplió su función de planificar y no existe en este paso). Inserta los marcadores `<!-- ESCENA <stable_id>: Nombre -->`. |
| 2.2.3 | director + usuario | **Checkpoint obligatorio.** El director presenta la estructura de escenas propuesta al usuario (número de escenas, beats por escena, corte). El usuario valida o pide ajustes. **No se avanza a 2.2.4 sin confirmación.** |
| 2.2.4 | `auditor-beats` (atomizar → transiciones → limpieza) | Valida `capitulos/cap-NN-slug/guion.md`. Diagnostica: beats inconclusos, huecos, prosa. Director → guionista corrige |

#### 2.3 Por escena

Por cada escena del capítulo (todos sus beats a la vez):

| Paso | Agente | Acción |
|------|--------|--------|
| 2.3.1 | director + `escritor` | Contexto de capitulo preparado una vez y tramo pertinente inline. Escritor genera una escena sin herramientas; completion maxima 64000 en opencode (razonamiento + salida). Sin notas rutinarias. |
| 2.3.1b | director | `persistir-escena.py preparar`: comprobar finish, IDs, orden y cuerpos; guardar candidato pendiente y SHA256. No sobrescribir draft aprobado ni Qdrant. |
| 2.3.1c | director + usuario | **Checkpoint obligatorio de narrativa.** Presentar la escena completa con stable_id y hash/version; detenerse y esperar respuesta explicita antes de revision editorial, aceptacion o avance. Ajustes solicitados autorizan corregir solo esta escena y volver a presentarla. |
| 2.3.2 | `validador` (modo escena, read-only) | Una revision editorial independiente: cobertura, continuidad, personajes/POV, prosa y restricciones. Solo incidencias concretas; aprobacion ligada al hash. Sin scores por beat ni cuotas sensoriales. |
| 2.3.3 | director + `integrador` (condicional) | Cambios mecanicos exactos o una llamada del integrador para fragmentos afectados. Nuevo candidato/hash: volver a 2.3.1c, esperar conformidad y obtener revision focalizada; canon incierto bloquea. |
| 2.3.4 | director | Solo con conformidad explicita del usuario y revision editorial aprobada para el mismo hash: `aceptar` guarda de forma atómica; `sincronizar` actualiza Qdrant en lote. Solo tras exito marca los beats ✅. Reintentos del mismo texto idempotentes sin regenerar. |
| 2.3.5 | director + usuario | **Autorizacion de avance.** Aprobar una escena no autoriza la siguiente escena: preguntar cual se inicia y esperar confirmacion, salvo que el usuario haya aprobado expresamente texto y ese avance en la misma respuesta. Sin generacion ni preparacion especulativa. |

> **Flujo vigente:** contexto preparado -> generacion -> candidato comprobado -> presentar al usuario y detenerse -> revision editorial -> correccion selectiva si procede (nuevo texto vuelve al checkpoint) -> aceptacion y sincronizacion con ambas aprobaciones -> avance solo autorizado. El checkpoint de guion se conserva; las restricciones, identidades y cobertura siguen siendo obligatorias.

#### 2.4 Revisión global

| Paso | Agente | Acción |
|------|--------|--------|
| 2.4.1 | `validador` modo `global` | Revisa cruces entre escenas: cronologia, objetos, conocimientos y arco. No repite toda la revision estilistica. Usa memoria de hechos ocurridos, no planes como hechos consumados. |
| 2.4.2 | director | Actualiza `contexto.md` con resumen del capítulo (2-4 frases) |

#### 2.5 Cronista

| Paso | Agente | Acción |
|------|--------|--------|
| 2.5.1 | `cronista` | Por cada escena (L1) del draft: upsert L1 en Qdrant, actualizar `dinamico` de entidades con cambio inequívoco, aplicar nuevas relaciones o cambios de rol en Neo4j (`upsert-relationship`) |
| 2.5.2 | `cronista` + `auditoria-neo4j` | Tras procesar todas las escenas: upsert L2 (capítulo), L3 (si cierre arco), L4 (cada 10 caps). Auditoría Neo4j (solo lectura): detectar discrepancias residuales |
| 2.5.3 | `cronista` | Actualiza `config.json`: `capitulos_completados++`, `ultimo_beat_seq` |
| 2.5.4 | director | Revisa discrepancias residuales; si son errores de lectura del cronista, las descarta; si son contradictorias, decide |

**Gate editorial:** revision `aprobado` para el hash vigente, sin incidencias `bloqueante` ni `corregir`. Una preferencia opcional no obliga a reescribir; un error factual no se aprueba por una buena media. La revision final debe corresponder al texto aceptado.

**Gate humano:** conformidad explicita con la misma version presentada. Cualquier cambio textual invalida la conformidad anterior y exige nueva presentacion/espera, incluso correcciones mecanicas o de revision global. Registrar escena, hash/version, decision y alcance de avance en `contexto.md`; al reanudar sin evidencia, preguntar sobre la candidata existente. El review del validador no prueba aprobacion humana.

**Gate del capítulo:** Todos los beats ✅, Qdrant actualizado (L1+L2+entidades), Neo4j actualizado (relaciones por escena) y auditado.

**Avance entre capitulos:** tras el cierre, informar y detenerse para pedir autorizacion explicita para iniciar el siguiente capitulo, antes de 2.1 (memoria/guion incluidos). Aprobar la ultima escena permite cerrar el capitulo actual, no arrancar otro. Si es el ultimo capitulo → `publicacion`.

---

### FASE 3 — Publicar (`estado: publicacion`)

| Paso | Agente | Acción |
|------|--------|--------|
| 3.1 Limpiar capítulos | director | `draft.md` → `capitulo.md` por capítulo (elimina headings `## <stable_id> [<seq>]`, marcadores `<!-- ESCENA ... -->` y notas del escritor; conserva título) |
| 3.2 Concatenar | director | Todos los `capitulo.md` → `novela.md` |

**Gate:** `capitulo.md` por capítulo + `novela.md`. Sin headings, comentarios ni notas residuales.

**Transición:** `config.json.estado = "finalizado"`.

---

## Transiciones de estado

```
diseno → fichas → escritura → publicacion → finalizado
```

`finalizado` es el estado terminal del workspace. `publicado` lo asigna solo `/compilar` (`scripts/compilar.ps1`), que exige `finalizado` o `publicado` como estado de entrada. El director nunca escribe `publicado`.

**Bucle en FASE 2:** itera capítulo por capítulo. `config.json.capitulos_completados` avanza.

**Creación de directorios:** el `guionista` crea `capitulos/cap-NN-slug/`. El director guarda candidatas pendientes y persiste texto aceptado con `scripts/persistir-escena.py`; escritor e integrador no escriben archivos ni vectores.

**Relaciones Neo4j:** el `entidades` las crea inicialmente (FASE 0-1). Durante la escritura, el `cronista` **escribe** en Neo4j por escena (FASE 2.5.1): detecta relaciones materializadas en el draft y las aplica con `upsert-relationship`. Tras escribir, audita (solo lectura) y reporta discrepancias residuales al `director`. El director solo delega en `entidades` si una discrepancia requiere reestructurar el grafo.

## Agentes activos (9 agentes)

`director`, `guionista`, `auditor-beats`, `escritor`, `validador`, `integrador`, `memoria`, `cronista`, `entidades`

## Skills activos (40)

**Invariantes del hub (36).** Se inyectan desde `shared/skills/` en `.claude/skills/` del workspace (las leen opencode y Claude Code):

`mecanica-prosa`, `tonos-beat`, `hechos-estructura`, `hechos-distribuidos`, `plantilla-ficha`, `plantilla-personaje`, `plantilla-lugar`, `plantilla-objeto`, `plantilla-animal`, `plantilla-arco`, `plantilla-evento`, `plantilla-organizacion`, `plantilla-grupo`, `plantilla-ser-sobrenatural`, `validacion-crudeza`, `validacion-coherencia`, `validacion-geometria`, `validacion-sensorial`, `validacion-tono`, `consistencia-narrativa`, `desarrollo-narrativa`, `fichas-personajes`, `cronista-ops`, `estilo-explicito`, `estilo-contemporaneo`, `estilo-erotico`, `estilo-fantasia`, `estilo-noir`, `estilo-romantico`, `estilo-thriller`, `estilo-prosa`, `qdrant`, `neo4j`, `auditoria-neo4j`, `scaffolding-hecho`, `scaffolding-acto`

**Exclusivos de escala (4).** Definidos solo en `shared/pipelines/novela-simple/skills/`; no existe versión común de estos cuatro. Si una escala futura declara uno con el mismo nombre en `shared/`, el de escala prevalece:

`beats-estructura`, `estructura-narrativa`, `plantilla-guion`, `contexto-subagente`

**No se inyectan** `contexto-narrativo` (memoria Markdown de la escala relato; aquí la memoria es Qdrant + Neo4j con `contexto.md` como resumen legible) ni las skills de hilo (`diseno-hilo`, `plantilla-hilo`, `trenzado-narrativo`, `validacion-cross-hilo`), exclusivas de multi-hilo.

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

No repetir a ciegas. `finish=length` requiere inspeccionar salida parcial y presupuesto; no es un fallo generico de formato. Maximo dos recuperaciones automaticas por escena; despues, pausa. Una caida de Qdrant se recupera con `sincronizar`, sin regenerar prosa. Ver `ORQUESTACION.md` y el agente director.
