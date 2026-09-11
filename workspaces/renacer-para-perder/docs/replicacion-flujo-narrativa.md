# Replicación del flujo narrativo por escena — guía para otros workspaces

> Documento generado el 2026-09-09 desde el workspace `renacer-para-perder`
> (`C:\Proyectos\Personal\Writting\Forja\workspaces\renacer-para-perder`).
> Propósito: que **otros workspaces** repliquen estos cambios **adaptándolos a sus particularidades** (modelo, proveedor, estilo, escala). No es un mandato del hub ni un contrato compartido: cada workspace decide si y cómo lo adopta.
> Registros normativos locales: [0001 — narrativa por escena](decisiones/0001-narrativa-por-escena.md) y [0002 — contrato editorial de beats](decisiones/0002-contrato-editorial-beats.md). Riesgos locales: `docs/deuda-tecnica.md`.
> Avance vigente: [0003 — checkpoint obligatorio de narrativa](decisiones/0003-checkpoint-narrativa-usuario.md), que sustituye las paradas solo a peticion del usuario.

---

## 1. Resumen ejecutivo

El flujo de narrativa se rediseñó por **evidencia medida** (telemetría SQLite de OpenCode + serialización real del adaptador Venice), no por impresiones:

- **Generación**: el escritor deja de ser un agente que lee archivos, carga skills, escribe y sincroniza. Ahora **recibe todo el contexto preparado inline y devuelve solo prosa**. Sin herramientas.
- **Revisión**: una **revisión editorial independiente por escena**, con incidencias concretas, en lugar de cinco puntuaciones numéricas por cada beat y cuotas de sentidos.
- **Corrección**: selectiva — solo fragmentos señalados — y con revisión focalizada posterior. Un error factual nunca se aprueba por una buena media.
- **Persistencia**: un script determinista con **aprobación vinculada a hash** (`preparar → revisar → aceptar → sincronizar`), escrituras atómicas, idempotencia y sincronización Qdrant por lotes que conserva metadatos.
- **Presupuesto técnico**: `maxCompletionTokens: 64000` para escritor e integrador (comparte razonamiento + salida). Es presupuesto, **no meta de longitud**.
- **Contrato editorial de beats (ampliacion 0002)**: unidad dramatica con compromiso verificable, no microaccion ni parrafo prefijado. Guionista, auditor, director, escritor, integrador y validador distinguen lo obligatorio de la ejecucion libre y de los ejemplos opcionales. La cobertura de IDs no demuestra naturalidad del dialogo.
- **Validacion del usuario (ampliacion 0003)**: tras generar y preparar cada narrativa, presentar la escena completa y detenerse. Conformidad humana y revision editorial por el mismo hash preceden a aceptar/sincronizar; iniciar la siguiente escena o capitulo requiere autorizacion expresa.
- **Nivel de detalle en escenas explícitas (ampliacion 2026-09-10b)**: el sexo se narra acto a acto con progresion, transiciones y sensacion concreta, sin sentencias que cuenten; objetivo declarado: que el lector lo viva intensamente excitandose. Creatividad del escritor segun el momento de la escena, no una plantilla.

Resultado historico del flujo tecnico: **54** (persistencia) + **16** (contratos/schema) + **17** (adaptador, con streaming), todas aprobadas, 0 red real. Verificacion posterior del contrato editorial: **99 pruebas aprobadas** (11 de beats + 12 de configuracion local + 54 de persistencia + 22 de identidad), con cuatro pruebas opcionales de schema omitidas al ejecutar sin `--schema`. No se repitio el runner del adaptador ni se valido generacion real en esa ampliacion.

---

## 2. Diagnóstico que motivó el cambio (con evidencia)

Telemetría extraída de la BD de OpenCode (`~/.local/share/opencode/opencode.db`, tablas `session`, `message`, `part`) y del log (`log/opencode.log`) **para este proyecto**.

### 2.1 Coste y forma del trabajo anterior (hasta cerrar cap-01)

| Agente | Tareas (subagente) | Pasos LLM | Herramientas | Entrada no cacheada | Razonamiento | Salida | Coste est. |
|---|---:|---:|---:|---:|---:|---:|---:|
| escritor | 28 | 231 | 399 | 8.228.056 | 638.788 | 73.820 | ~$29,27 |
| validador | 24 | 80 | 321 | 830.653 | 172.872 | 43.326 | ~$0,56 |
| integrador | 7 | 78 | 124 | 1.711.423 | 126.435 | 33.953 | ~$5,76 |
| entidades | 19 | 216 | 388 | 485.835 | 160.112 | 154.123 | ~$0,53 |

- «Una llamada al escritor» **no equivalía a una generación**: una sola tarea (B_0014, un beat breve) registró **17 pasos LLM y 24 operaciones de herramientas** (5 skills, 7 lecturas, 9 bash, 1 glob, 2 escrituras), ~18 minutos, con 1.066.842 tokens de entrada **acumulados** en esos pasos.
- Las «notas del escritor» por beat eran ensayos de 300–500 palabras (a veces más largos que la prosa) que FASE 3 elimina: meta-texto puro.
- El validador producía JSON gigantes con 5 dimensiones y desgloses por criterio para cada beat, incluidas reescrituras gatilladas por «falta un sentido» o por promedios que ocultaban errores factuales (p. ej. una taza «llena» que nunca se sirvió, una alarma 6:30 vs 7:00).

### 2.2 El corte a 32.000 y los outputs vacíos

Ocho tareas del escritor terminaron con la última respuesta en **`finish: length`, `reasoning: 32000`, `output: 0`** (sin error de transporte). Entre ellas una **sin ninguna herramienta ejecutada** (escena 5, un solo mensaje, 822 s). Esto **corrige diagnósticos previos**: no está demostrado que leer archivos o persistir causara todos los vacíos, ni que cada fallo perdiera una escena completa generada.

Cadena técnica comprobada (OpenCode `v1.18.29` + adaptador `venice-ai-sdk-provider@2.1.1`):

```text
OUTPUT_TOKEN_MAX = 32_000 (default OpenCode, packages/opencode/src/provider/transform.ts)
maxOutputTokens = min(model.limit.output, 32_000)
Venice: max_completion_tokens = maxCompletionTokens ?? maxTokens ?? maxOutputTokens
```

- Venice publica para `qwen-3-8-max`: `maxCompletionTokens: 131072`, contexto 1M, **thinking-only**, `supportsReasoningEffort: false`.
- `max_completion_tokens` **incluye razonamiento y respuesta visible**; al agotarse, `finish_reason: "length"` (docs de Venice).
- Conclusión: el modelo consumió el presupuesto razonando y no dejó tokens para emitir. Subir el límite da margen; **no garantiza menor latencia** (puede razonar más). Por eso el valor 64.000 es una decisión medible pendiente de validación real tras reinicio.

### 2.3 Tiempo real de la última escena (escena 5)

| Operación | Duración | Resultado |
|---|---:|---|
| Escritor intento 1 | 13 min 43 s | `length`, 32.000 raz., 0 salida, sin herramientas |
| Escritor reintento | 7 min 57 s | `stop`, 1.973 salida, 18.915 raz. (≈91 % del completion fue razonamiento) |
| Validador de escena | 3 min 46 s | completado |
| Total tareas | 25 min 27 s | — |
| Total transcurrido | 27 min 21 s | incluye intervalos entre llamadas |

### 2.4 Contradicciones de contrato detectadas

- Escritor: «carga 4 skills» frente a «NO uses herramientas»; permisos técnicos seguían permitiendo edit/bash.
- Pipeline por escena frente a director beat a beat (tablas, modos, plantillas y skill `contexto-subagente` desalineados).
- Integrador con contrato de un solo beat mientras el pipeline pedía una pasada de escena; tabla de modelos desactualizada.
- Briefings del validador con elogios/defensas previas («impecable», «coherente por diseño») que condicionaban la revisión.

---

## 3. Inventario de cambios por archivo

### 3.1 Agentes (`.opencode/agents/`)

| Archivo | Cambio | Motivo |
|---|---|---|
| `escritor.md` | Reescrito. Sin herramientas (`permission: "*": deny`), `options.maxCompletionTokens: 64000`, contrato de salida solo prosa con `<!-- ESCENA ... -->` y `## <stable_id> [<seq>] — acción breve`, BLOQUEO ante canon incierto, sin notas rutinarias | Una generación por tarea sin sobrecarga operativa; evitar el ciclo leer/cargar/reescribir que multiplicaba pasos LLM; margen ante el corte de completion |
| `integrador.md` | Reescrito. Ídem permisos/64K; corrección selectiva de fragmentos; devuelve solo secciones corregidas; BLOQUEO si exige cambiar canon | Eliminar reescrituras por sistema y justificaciones de fichas a posteriori |
| `validador.md` | Reescrito. Revisión editorial por escena con incidencias `bloqueante/corregir/opcional`; sin scores por beat ni cuotas sensoriales; briefing neutral; hash del candidato en la decisión | Revisión independiente útil sin el coste de 5 evaluaciones por beat ni promedios que oculten errores factuales |
| `director.md` | Secciones 2.3/2.4, `/revisar`, `/expandir`, política de reintentos, criterio de integrador y tabla de subagentes actualizadas al flujo por escena y al modelo real (escritor/integrador = venice/qwen-3-8-max) | Coherencia del contrato con la nueva mecánica; reintentos diferenciados (length ≠ fallo de formato) |

### 3.2 Skills (`.opencode/skills/`)

| Archivo | Cambio | Motivo |
|---|---|---|
| `contexto-subagente/SKILL.md` | Contratos de escritor (contexto preparado, sin herramientas), validador (escena/revisión/global con hash) e integrador (fragmentos) | Única fuente del contrato de spawn coherente con los agentes |
| `validacion-sensorial/SKILL.md` | Eliminadas cuotas («al menos 3 sentidos», «máx. 4 con 1 sentido»), pesos y JSON de scores; criterio contextual | La ausencia sensorial puede ser deliberada; se evalúa la carencia narrativa concreta |
| `validacion-geometria/SKILL.md` | Longitud de párrafo ya no es defecto por número de líneas; scoring solo si se solicita | Ritmo por calidad, no por conteo |
| `tonos-beat/SKILL.md` | Extensión como peso relativo (concentrado/moderado/amplio) sin suelo ni techo numérico; regla de extensión actualizada | Evitar que el escritor recorte prosa para caber en un número |
| `plantilla-guion/SKILL.md` | Línea de EXTENSIÓN alineada | Coherencia |
| `estilo-explicito/SKILL.md` | Seccion nueva «Nivel de detalle en escenas explícitas»: secuencia de actos, progresion interna, transiciones fisicas, reaccion del POV por fase, sensacion concreta sin juicios, espacio real y creatividad/criterio segun el momento de la escena; objetivo declarado: que el lector lo viva excitandose | El sexo resumido o con sentencias que cuentan («No era intimidad. Era descarga.», «Era un dato.») no cumple el estilo; fijado como estandar tras la validacion del usuario en la escena b2d4f6a8 |

### 3.3 Documentación de flujo

| Archivo | Cambio | Motivo |
|---|---|---|
| `PIPELINE.md` | FASE 2.3 por escena con `persistir-escena.py`; 2.4 solo cruces entre escenas; gate editorial por hash; jerarquía del draft `## <stable_id> [<seq>]`; política de reintentos | Contrato de referencia del pipeline |
| `ORQUESTACION.md` | Matriz (escritor/integrador sin escritura, 64K), tabla de skills, camino 2.3/2.4, plantillas de briefing (inline, hash, incidencias) y huecos prohibidos (persistencia = director vía script) | Contrato de invocación |
| `MAPA.md` | Rutas nuevas (`escena-SID.pendiente.md`, `scripts/persistir-escena.py`, `docs/decisiones/0001-narrativa-por-escena.md`) y quién crea draft | Mapa de datos |
| `contexto.md` | Decisiones de flujo vigentes, rectificación del diagnóstico y recordatorio de reinicio | Memoria operativa del director |
| `.opencode/commands/generar.md`, `revisar-guion.md` | Frases desalineadas corregidas | Coherencia |
| `.opencode/commands/revisar.md`, `expandir.md` | Reescritos con flujo candidato/hash, corrección selectiva y sincronización | Comandos operativos coherentes |

### 3.4 Código nuevo

| Archivo | Qué hace | Motivo |
|---|---|---|
| `scripts/persistir-escena.py` | `preparar` (valida IDs/orden/cuerpos/metatexto estructural, normaliza solo newlines, guarda candidata + SHA256), `aceptar` (revisión aprobada con hash vigente, inserción/reemplazo en orden, backup atómico, no-op en reintentos), `sincronizar` (verifica todo antes de escribir, lote de embeddings solo para textos cambiados, conserva metadatos/fichas, fija `narrative_text`/`vector_source=narrativa`/`has_narrative=true`, readback) | Persistencia determinista sin orquestación nueva; el escritor no debe escribir archivos ni vectores |
| `scripts/qdrant.py` (endurecido) | `upsert-summary` y `upsert-summary-by-position` con preflight previo a escribir: exigen `--parent-id` y seq local positivo; rechazan posición duplicada, identidad divergente y colisión física con otro proyecto/nivel/padre/seq/hilo; crear L1 sin ID canónico bloquea; `--id` afirmable en el comando posicional; actualización conserva metadatos y fichas omitidas; re-embebe solo si cambia el texto; no-op sin cambios; escritura no confirmada = error | Prevenir el defecto NAR-004 (identidades divergentes) en código, no solo en prompt |
| `tests/test_persistir_escena.py` | 54 pruebas offline (fixtures neutras, backend/embedding simulados) | Regresión |
| `tests/test_narrative_contracts.py` | 16 pruebas: frontmatter/permisos/64K/headings/ausencia de reasoning/escaneo léxico + validación con el **schema oficial** de OpenCode | Regresión de configuración |
| `tests/verify-venice-request.mjs` | 17 casos con **fetch MOCK** (doGenerate/generateText/doStream/streamText del paquete real): comprueba `max_completion_tokens: 64000` (fallback 32.000), ausencia de `tools` y de parámetros de reasoning no soportados, 0 red | Verificación de serialización del adaptador real |
| `tests/test_summary_identity.py` | 22 pruebas offline del preflight de summaries: creación canónica, no-op, duplicados, colisiones entre proyectos, identidad no movible, conservación de metadatos/fichas/vector, recuperación beat → L1 → L2 | Regresión del endurecimiento NAR-004 |

### 3.5 Registro

| Archivo | Contenido |
|---|---|
| `docs/decisiones/0001-narrativa-por-escena.md` | Decisión completa: motivo, contrato, persistencia, recuperación, pruebas, riesgos |
| `docs/decisiones/0002-contrato-editorial-beats.md` | Contrato editorial, propagacion entre agentes, casos neutrales de regresion y limites de las pruebas estaticas |
| `docs/deuda-tecnica.md` (local al workspace) | NAR-001 (reinicio/validación real pendiente), NAR-002 (sin transacción disco+Qdrant ni CAS), NAR-003 (checks mecánicos ≠ comprensión semántica); NAR-004 cerrado (migración + prevención verificada); NAR-005 (contrato editorial pendiente de uso real); NAR-006 (instrucciones heredadas de identidad aun contradictorias) |

### 3.6 Ampliacion editorial: formulacion e interpretacion de beats

La decision 0002 procede de revisiones editoriales del capitulo 02, no de una nueva medicion del proveedor. Detecto microcoreografia, pausas impuestas, inferencias convertidas en listas o preguntas, y ejemplos elevados a frases obligatorias. Tambien hubo fallos de ejecucion y validacion: no todo dialogo artificial se explica por el guion.

**Reglas que deben replicarse como conjunto:**

1. Un beat compromete un acontecimiento, decision, descubrimiento o inferencia atribuida y su consecuencia. Puede contener varios gestos o intercambios subordinados; no se divide por puntuacion, verbos, mezcla tonal ni cuotas de beats.
2. Separar **Obligatorio / Libre / Ejemplos opcionales** en objetivos y contexto existentes, sin nuevos campos del payload. Obligatorio fija compromisos, restricciones y literalidad justificada; Libre abarca ejecucion compatible; los ejemplos no son canon ni una lista acumulativa.
3. Distinguir lo dicho, sabido, inferido y confirmado, con sujeto y certeza. Saber no obliga a preguntar ni inferir exige una confesion. Una explicacion de un personaje no acredita su verdad.
4. El escritor desarrolla una escena continua. Los encabezados son trazabilidad, no cortes de conversacion; conserva IDs, orden y cuerpos no vacios. Saludos, despedidas y enlaces ordinarios caben en beats existentes cuando proceden, sin un beat por gesto ni ceremonia obligatoria.
5. La interioridad conserva la voz del personaje: indicar una deduccion no obliga a escribir listas ni resumen editorial en cursiva. Son validos pensamiento directo, indirecto libre o narracion indirecta compatibles con el POV.
6. `⚡` conserva literalidad real, pero su uso nuevo exige palabras exactas solicitadas por el usuario o funcion causal documentada y aprobada. Una frase vigente incompatible se devuelve al director antes de generar; no se elimina ni se recoloca a la fuerza. No migrar automaticamente las marcas del destino.
7. El integrador repara el mecanismo del defecto en el intercambio minimo autorizado, con texto completo de las secciones y ambos extremos. Devuelve completas las secciones solicitadas; si falta alcance/contexto o el guion impide el arreglo, devuelve `BLOQUEO:` al director, sin reconstruir texto ausente ni cambiar el guion.
8. Los tonos orientan expresion, no conducta ni conocimiento. Una conversacion normal puede resultar opresiva por lo que comprende el POV. No exigir reacciones por etiqueta ni inventariar cada objeto ordinario compatible como condicion de coherencia.
9. El validador comprueba naturalidad y cobertura semantica con evidencia, no solo IDs. Las skills respetan el contrato del consumidor: candidato/hash para revision de prosa, diagnostico sin hash para auditoria de guion. El checkpoint del usuario es siempre obligatorio tras cada narrativa, conforme a 0003.

**Inventario adicional que hay que adaptar conjuntamente:**

| Archivos | Responsabilidad editorial |
|---|---|
| `.opencode/agents/guionista.md`, `auditor-beats.md` | Formular y auditar unidades dramaticas; eliminar cuotas y divisiones por puntuacion; preservar contenido interior sin redactar su prosa |
| `.opencode/agents/director.md` | Preparar contexto separado en obligatorio/libre/ejemplos; no volver literales sus propias sugerencias; resolver conflictos de guion y respetar checkpoints |
| `.opencode/agents/escritor.md`, `integrador.md` | Interpretar compromisos con libertad de ejecucion, escena continua, interioridad propia y limites de canon/alcance |
| `.opencode/agents/validador.md` | Revisar naturalidad, atribucion de informacion y mecanismo corregido, sin aprobar solo por estructura |
| `.opencode/skills/beats-estructura/SKILL.md`, `contexto-subagente/SKILL.md` | Contrato comun y transmision inline a escritor/integrador sin herramientas |
| `.opencode/skills/hechos-estructura/SKILL.md`, `hechos-distribuidos/SKILL.md`, `estructura-narrativa/SKILL.md`, `plantilla-guion/SKILL.md` | Cobertura por consecuencias, sin cuotas ni beat limitado a accion fisica; distinguir ejemplos y literalidad |
| `.opencode/skills/mecanica-prosa/SKILL.md`, `tonos-beat/SKILL.md` | Interioridad y parrafos sin listas/cortes automaticos; literalidad justificada; tonos sin conducta impuesta |
| `.opencode/skills/consistencia-narrativa/SKILL.md`, `validacion-geometria/SKILL.md`, `validacion-tono/SKILL.md`, `validacion-coherencia/SKILL.md` | Evaluacion coherente con libertad de ejecucion, elipsis e inferencias; props ordinarios no exigen inventario; salida segun consumidor |
| `PIPELINE.md`, `ORQUESTACION.md` | Resumen del contrato y plantillas de briefing alineados; `atomizar` conserva nombre pero cambia criterio |
| `tests/test_beat_contracts.py` | 11 comprobaciones estaticas de salvaguardas y ausencia de instrucciones regresivas concretas |

No basta con copiar el nuevo guionista: las skills cargadas y los briefings del director pueden reintroducir las restricciones retiradas. Esta ampliacion no cambia modelos, presupuestos, permisos, scripts, IDs, payloads ni prosa existente.

**Refuerzo posterior (2026-09-10): redaccion sin ejecucion y explicititud mostrada.** Tras detectar que el guionista y la revision volvian a admitir gestos, ambiente y valoraciones dentro de las acciones («sin levantar la vista», «con afabilidad», «ausente, mas en su cabeza que en la mesa», «cruza el trafico de carretillas»), se fijo en `guionista.md` y `auditor-beats.md`:

- La accion declara el acontecimiento y su consecuencia, sin gestos, miradas, posiciones, adverbios de modo, detalles de ambiente ni valoraciones. El espacio, la utileria y el cast viven en la cabecera de escena y en las fichas; la ejecucion es del escritor. Prueba de libertad: dos ejecuciones distintas deben poder cumplir el mismo beat.
- El auditor reporta esas infiltraciones como microcoreografia y propone la accion sin el detalle (reubicando el detalle util en la cabecera o descartandolo). El ejemplo de beat correcto del guionista se sustituyo por uno neutral sin ejecucion.
- `validacion-crudeza` incorpora el criterio **mostrar, no contar**: en escenas explicitas el acto se muestra con precision fisica (lengua, clitoris, circulos, dedo dentro, fluidos, sonidos); los resumenes («con pasion») que dejan la accion fuera de camara son `corregir`, y el detalle no se compensa con un termino crudo.

Replicar este refuerzo junto con el contrato 0002 y sus regresiones (`tests/test_beat_contracts.py` incluye las salvaguardas «la ejecucion es del escritor» y «cabecera de escena» para guionista y auditor). La regla aplica tambien al auditor: sus indicaciones deben coincidir con las del guionista para beats concretos sin guiar al escritor.

### 3.7 Ampliacion editorial (2026-09-10, segunda ronda): nivel de detalle en escenas explicitas

Detectado en la escena b2d4f6a8 (cap-03) durante su validacion con el usuario: la primera version del sexo explicito salio resumida — correcta en hechos, pero con sentencias que contaban en lugar de mostrar («No era un cumplido. Era un dato.», «No era intimidad. Era descarga.») y sin recrearse en la secuencia. El usuario fijo que las escenas explicitas deben mostrar con detalle y progresion, y que el objetivo de esas escenas es que el lector las viva intensamente excitandose. Reglas fijadas en `estilo-explicito/SKILL.md` (seccion «Nivel de detalle en escenas explícitas»):

1. Objetivo declarado: el lector vive la escena desde dentro y se excita con el cuerpo y la progresion; no se narra para informar de que hubo sexo.
2. Secuencia de actos (desnudarse → preliminares → penetracion → climax → despues), cada acto con arranque, progresion y salida; el sexo se narra, no se resume.
3. Progresion interna de cada acto (la mamada va de lengua a succion a profundidad, con la polla creciendo; las embestidas van de ritmo marcado a circulos a mas rapido e intenso).
4. Transiciones entre actos con puentes fisicos concretos.
5. Reaccion del POV en cada fase: respiracion, espasmos, manos, sonidos, tension muscular.
6. Sensacion concreta, no juicio: calor, humedad, textura, sabor, olor, sonido de los cuerpos; prohibidas las frases que cuentan en lugar de mostrar.
7. Espacio real: se recrea, no se abrevia; la extension sigue a la secuencia de actos, no a un recuento de palabras.
8. Creatividad y criterio por el momento de la escena: no es una plantilla; el escritor elige detalle, ritmo y foco segun el tono, la pareja y el momento narrativo (rutina fria, sexo calido, violencia, hambre) para producir excitacion creciente. La meta es que el lector lo viva, no marcar una casilla por acto.

Lecciones operativas del ciclo de revision (aplicables a cualquier escena, no solo explicitas):

- Resolver la cronologia como canon antes de generar: el escritor asumio «dias despues» cuando la escena anterior implicaba la misma noche; las ambiguedades temporales se fijan en el briefing, no se delegan a la primera candidata.
- Si el texto debe tocarse por una incidencia `corregir`, las incidencias `opcional` concretas del validador se aplican en la misma pasada como ajustes mecanicos del director (sin llamada creativa) y se pide revision focalizada del hash nuevo. No se integra por rutina si no hay que tocar nada.
- El usuario puede pedir al director que redacte la propuesta directamente, sin delegar en escritor/integrador; el flujo de persistencia y checkpoints no cambia (preparar → presentar → esperar conformidad → revision focalizada → aceptar/sincronizar).
- Marcar los beats en `guion.md` solo tras sincronizacion correcta; si se detectan escenas anteriores sincronizadas sin marca, regularizarlas en la misma operacion.

Replicar junto con `estilo-explicito/SKILL.md` (backup previo) y la fila correspondiente de la tabla 3.2. No cambia modelos, permisos, scripts, IDs ni payloads. Las escenas explicitas ya aceptadas de capitulos anteriores no se reescriben por este refuerzo salvo orden expresa del usuario.

---

## 4. Contrato de persistencia (operación)

### 4.1 Parada humana obligatoria antes de persistir (0003)

Secuencia: **generar/corregir -> preparar -> presentar la escena completa y esperar al usuario -> revision editorial -> ambas aprobaciones para el mismo hash -> aceptar/sincronizar**. No continuar invocando agentes despues de preguntar mientras la respuesta humana este pendiente. Si la revision cambia texto, volver a preparar, presentar y esperar antes de revision focalizada/aceptacion.

La aprobacion de una version no autoriza la siguiente escena. Se puede preguntar por texto y avance juntos, identificando la escena destino; sin ese alcance explicito, preguntar de nuevo y esperar. Tras el cierre de un capitulo, pedir autorizacion para iniciar el siguiente, incluida memoria y guion. No trabajar en siguientes escenas/capitulos de forma especulativa. El checkpoint de estructura y un `/generar` inicial no aprueban prosa futura.

Registrar en `contexto.md` escena, hash/version, decision del usuario y alcance de avance; al reanudar sin evidencia, presentar la candidata existente y preguntar. Cualquier cambio textual invalida la conformidad anterior y el avance asociado; una orden de corregir no aprueba el texto resultante. Reintentos de sincronizacion del mismo texto aprobado no requieren otra generacion ni otra aprobacion.

Replicar conjuntamente `.opencode/agents/director.md`, `PIPELINE.md`, `ORQUESTACION.md`, `.opencode/skills/contexto-subagente/SKILL.md` y `.opencode/commands/{generar,revisar,expandir}.md`, con las regresiones de checkpoint en `tests/test_beat_contracts.py`. No basta anadir una pregunta de cierre dejando el bucle automatico del siguiente capitulo.

El helper sigue validando el review editorial y su hash; **no verifica por codigo la aprobacion humana ni el permiso de avance**. La pausa efectiva debe comprobarse con el director tras reinicio (NAR-007). No se cambian argumentos ni payloads del helper.

### 4.2 Comandos mecanicos

```text
python scripts/persistir-escena.py preparar    --capitulo capitulos/cap-NN-slug --escena SID --entrada <archivo-UTF-8> --finish stop
python scripts/persistir-escena.py aceptar     --capitulo capitulos/cap-NN-slug --escena SID --revision '<JSON>'
python scripts/persistir-escena.py sincronizar --capitulo capitulos/cap-NN-slug --escena SID --revision '<JSON>'
```

JSON de revisión (también admite campos extra del informe editorial):

```json
{
  "escena_stable_id": "a1b2c3d4",
  "candidato_sha256": "<sha256 real devuelto por preparar>",
  "estado": "aprobado",
  "incidencias": []
}
```

Reglas esenciales:

1. `preparar` solo acepta `--finish stop`; el director obtiene la terminación de la ejecución real, no de la declaración del escritor.
2. El validador recibe el **mismo archivo** cuyo hash cita; la decisión queda ligada a ese hash. Una corrección produce hash nuevo y exige revisión vigente.
3. `aceptar` conserva el resto del draft byte a byte y hace backup con timestamp solo cuando cambia algo.
4. `sincronizar` no recrea puntos: verifica proyecto/identidad/padre/seq de todos antes de escribir; repara `has_narrative` sin re-embebber si el texto ya es idéntico.
5. No hay transacción conjunta disco+Qdrant: **serializar** operaciones por capítulo/beats; un fallo de red se repara con `sincronizar`, nunca regenerando prosa.
6. Solo tras sincronización correcta el director marca los beats completos en `guion.md`.
7. Antes de `aceptar`/`sincronizar`, el director debe contar con conformidad humana de esa misma version ademas del review editorial; el JSON del validador por si solo no satisface el checkpoint 0003.

---

## 5. Adaptación a otros workspaces

### Advertencia posterior: identidad de escena y L1

**Defecto detectado y resuelto (NAR-004, 2026-09-09). No replicar la convencion defectuosa que lo causo.** El cronista del cap-01 uso `upsert-summary-by-position` cuando aun no existian sus L1; el helper genero IDs nuevos, distintos de los que ya tenian las escenas del guion y los `parent_id` de sus beats (30 beats apuntaban a padres sin L1 correspondiente; `query-chapters-by-beat` saltaba silenciosamente los resultados).

La busqueda por `(proyecto, nivel, parent_id, seq)` encontraba los resumenes, pero no reparaba los enlaces: `scripts/qdrant.py` implementa `query-chapters-by-beat` recorriendo `beat.parent_id -> punto L1 -> parent_id del capitulo`. El helper guarda las referencias como UUID5 fisicos derivados; no confundir esa representacion con una identidad logica independiente del resumen.

**Reparacion aplicada:** migracion controlada (backup de payloads/vectores, creacion de puntos canonicos preservando vector, borrado de los divergentes tras verificacion) y contrato fijado en el cronista y en la plantilla de `ORQUESTACION.md`:

- Si el guion declara `<!-- ESCENA <stable_id>: Nombre -->`, crear el L1 con `upsert-summary --id <stable_id_escena> --nivel L1 --parent-id <capitulo> --seq <N>`.
- El helper ahora comprueba ANTES de escribir: posicion unica, misma identidad y ausencia de colision fisica con otro proyecto/nivel/padre/seq/hilo. Si hay conflicto, falla sin crear embeddings ni puntos. La comprobacion posterior no sustituye esta proteccion previa.
- `upsert-summary-by-position` admite `--id` como identidad esperada y usa el mismo guard. Crear un L1 sin identidad canonica queda prohibido: hay que obtenerla del guion, no generar una nueva. Un L1 existente puede actualizarse sin `--id` conservando su identidad, pero el cronista debe pasarlo siempre para contrastarlo con el guion.
- Tras crear, verificar que la posicion devuelve un unico resultado con ese `stable_id` y que los beats enlazan al L1 y al L2 correcto. Reportar `discrepancias_qdrant` separadas de `discrepancias_neo4j`; no cerrar capitulo con discrepancias pendientes.

Verificacion posterior a la migracion: `query-summary-by-position` devuelve los IDs del guion; `query-chapters-by-beat` resuelve beat → L1 → L2 (smoke test hacia el capitulo); 30 beats sin padres sin L1. Backups: `renacer-qdrant-export-20260909-110638.json` y `l1-backup-20260909.json` en el temporal aprobado.

**Verificacion independiente y endurecimiento posterior:** comparados los datos actuales con ambos backups: payload de los cinco L1 identico salvo stable_id, vectores exactamente iguales, 30 beats y 20 entidades sin alteraciones, 28 summaries totales (los otros 23 intactos), IDs viejos ausentes. La revision detecto que el contrato original solo comprobaba despues de escribir; esto se corrigio tambien en codigo, no solo en el prompt.

Cambios adicionales a replicar: `scripts/qdrant.py`, `.opencode/agents/cronista.md`, la persistencia temprana de `.opencode/agents/director.md`, `.opencode/skills/cronista-ops/SKILL.md` y `.opencode/skills/qdrant/SKILL.md`. Incluir `tests/test_summary_identity.py`: 22 pruebas offline de creacion canonica, duplicados, colisiones, no-op, conservacion de metadatos y recuperacion beat -> L1 -> L2. Reejecutadas tambien las 54 pruebas de persistencia de escena, todas aprobadas.

Compatibilidad del helper: L1/L2/L3 requieren padre y seq local positivo. L2/L3 sin identidad previa mantienen la posibilidad de asignarla; L4 mantiene su tratamiento de raiz unica. Actualizar texto de L1/L2/L3 por posicion ya re-embebe el resumen (antes solo cambiaba payload); metadata adicional y fichas omitidas se conservan. Si no cambia texto ni metadata es no-op, y si solo cambian fichas no se re-embebe. No es una migracion del formato fisico de parent_id ni cambia los IDs de beats.

El preflight no es un constraint atomico remoto ni protege dos procesos que escriben simultaneamente la misma posicion. Sigue siendo obligatorio serializar operaciones (NAR-002). No copiar ni reejecutar el script puntual de migracion sobre otro workspace; obtener y validar su propio mapa de identidades.

```text
python -B -m unittest discover -s tests -p test_summary_identity.py -v
```

**Variables a ajustar (no copiar ciegas):**

| Elemento | En este workspace | A adaptar |
|---|---|---|
| Modelo/proveedor de escritor e integrador | `venice/qwen-3-8-max` | Usar el modelo de cada workspace. El **64.000 es específico** de esta elección: para otro modelo, consultar su máximo publicado (`/models` del proveedor) y su soporte de `reasoning_effort`. Nunca configurar un esfuerzo no soportado (HTTP 400) ni `disableThinking` suponiendo ahorro. |
| Lugar de los 64K | `options.maxCompletionTokens` en el frontmatter del agente (opción que el adaptador traduce a `max_completion_tokens`) | Comprobar con un **fetch mock** que el parámetro efectivo del proveedor cambia (ver `tests/verify-venice-request.mjs` como plantilla). |
| Permisos del validador | `read` + `skill` (consulta archivos si falta evidencia) | Si el validador de otra escala necesita leer Qdrant, ampliar solo eso y documentarlo; jamás `edit`/`bash`. |
| Estilo y restricciones | `estilo-explicito` + `thriller`; AGENTS.md propio | El director incorpora las reglas de voz/POV/mecánica al contexto preparado de ese workspace. |
| Slug/estructura | `capitulos/cap-NN-slug/guion.md` con marcadores `<!-- ESCENA SID: Nombre -->` y beats `⬜/🔄/✅ id [seq] acción` | `persistir-escena.py` lee `config.json.slug` y espera ese formato. Otras escalas (relato, multi-hilo) requieren adaptar el parser del guion o no usar este script. |
| Presupuesto `small`/variantes | Sin variantes | Si el workspace usa variantes del modelo, verificar que `maxCompletionTokens` sobrevive al merge de opciones (base < model < agent < variant). |
| Reinicio del backend | Obligatorio aquí | Igual en cualquier workspace: la configuración se carga al iniciar. |

**Pasos de replicación recomendados:**

1. Revisar contratos, decisiones y estado del destino; hacer backup. No copiar datos, IDs, guiones ni prosa de este workspace. Separar la adopcion del flujo tecnico (0001) de la ampliacion editorial (0002).
2. Si se adopta el flujo tecnico, adaptar escritor, integrador, validador, director y `scripts/persistir-escena.py` a la escala/proveedor del destino; ejecutar sus pruebas offline. No reemplazar modelos, permisos o presupuestos que requiera el destino solo por copiar esta guia.
3. Para el contrato editorial, adaptar juntos los seis agentes y las doce skills de 3.6, mas el refuerzo de detalle explicito de 3.7. Retirar reglas contradictorias en lugar de acumular disclaimers: cuotas, microacciones, literalidad automatica, pensamientos como listas y conducta exigida por tono. Conservar el canon, intensidad y restricciones propios.
4. Alinear `PIPELINE.md`, `ORQUESTACION.md`, `contexto-subagente` y comandos del destino. El director debe pasar el contrato inline a escritor/integrador, no ordenarles que carguen skills. Replicar el checkpoint obligatorio de narrativa 0003 y retirar el avance automatico tras el validador o al siguiente capitulo; mantener formato tecnico sin convertirlo en cortes literarios.
5. Adaptar y ejecutar `tests/test_beat_contracts.py` junto a las regresiones de configuracion/persistencia pertinentes. Las aserciones textuales son salvaguardas, no una evaluacion de comprension o naturalidad. Revisar los casos neutrales de la decision 0002 y las instrucciones activas que cargan los agentes.
6. Si cambian parametros de proveedor, comprobar su serializacion con un mock (plantilla `verify-venice-request.mjs`). La ampliacion editorial por si sola no cambia parametros ni requiere otra configuracion del adaptador.
7. Reiniciar el backend y verificar el primer uso real: terminacion/presupuesto si se adopto 0001, y calidad editorial con el usuario si se adopto 0002. No declarar mejora literaria por pasar regex ni copiar los resultados medidos aqui como evidencia del destino.
8. Registrar la decision y riesgos propios en `docs/decisiones/` y deuda tecnica del destino. Las contradicciones heredadas de identidad de este workspace (NAR-006) no forman parte del modelo a replicar: contrastar seq local, padre escena y recorrido beat-L1-L2 contra el contrato del destino, sin migraciones implicitas.

**Qué NO hacer (lecciones aprendidas):**

- No reintentar a ciegas ante `length`; inspeccionar salida parcial y presupuesto.
- No tratar `stripThinkingResponse` como ahorro de cómputo.
- No eliminar la revisión independiente por completo (evita errores factuales reales).
- No aprobar por promedio ni «arbitrar» errores de canon como opciones estilísticas.
- No subir el límite globalmente para todos los agentes: es una decisión por agente y por proveedor.
- No cambiar solo el guionista dejando al auditor, las skills o el director imponiendo la microcoreografia anterior.
- No convertir ejemplos en canon ni inferencias en preguntas/confesiones para exhibir cobertura.
- No retirar una literalidad vigente sin resolverla con el director ni mantenerla inventando una confrontacion.
- No exigir hash de candidata a un auditor de guion: respetar el formato del consumidor de cada skill.

---

## 6. Verificación

### 6.1 Verificacion historica del flujo tecnico y NAR-004

Comandos exactos de esa verificacion; las rutas temporales corresponden a este entorno, no al destino:

```powershell
$deps = 'C:/Users/migue/AppData/Local/Temp/opencode/venice-contract-d79ccd6c25f44a05b5c20be998020385'
$schema = "$deps/opencode-config-schema-20260909.json"

python -B -m unittest discover -s tests -p test_persistir_escena.py -v
python -B tests/test_narrative_contracts.py --schema "$schema" -v
node tests/verify-venice-request.mjs --deps "$deps" --schema "$schema"
node --check tests/verify-venice-request.mjs
python -B -m unittest discover -s tests -p test_summary_identity.py -v
```

- 54 pruebas de persistencia, 16 de contratos/schema, 17 del adaptador (8 streaming), 22 de identidad de summaries. 0 intentos de red real durante los runners.
- Node 22.21.0 · `venice-ai-sdk-provider@2.1.1` · `ai@6.0.90` · PyYAML 6.0.3 · jsonschema 4.24.1.
- Schema OpenCode SHA256: `e8cb6e287a3852ee3403f4803be5ad6b19db94948037eaa9672125c333427922`.
- Schema Models.dev SHA256: `f4f900c13c0d56d8a48c3e3b56bec3cacf929e278ec3d5e230d6cbb7404e464d`.
- Dependencias/schemas instaladas en el temporal preaprobado, **no** en `package.json`/`node_modules` del workspace.
- Backups de contratos previos: `C:/Users/migue/AppData/Local/Temp/opencode/renacer-flujo-antes-20260909.tar`, `renacer-comandos-antes-20260909.tar`, `renacer-nar004-preflight-20260909-111857.tar` y `renacer-nar004-referencias-20260909-*.tar`.
- Backups de la migración NAR-004: `renacer-qdrant-export-20260909-110638.json` (proyecto completo) y `l1-backup-20260909.json` (cinco L1 con vectores), ambos en el temporal aprobado.

### 6.2 Verificacion de la ampliacion editorial 0002

```powershell
python -B tests/test_beat_contracts.py -v
python -B tests/test_narrative_contracts.py -v
python -B -m unittest discover -s tests -p test_persistir_escena.py -v
python -B -m unittest discover -s tests -p test_summary_identity.py -v
```

Resultado de esta ronda: **99 aprobadas** = 11 de contratos de beats + 12 de configuracion local + 54 de persistencia + 22 de identidad. Las cuatro opcionales de esquema oficial se omitieron porque no se paso `--schema`; no contradice el resultado historico de 6.1. No se repitieron las 17 pruebas del adaptador en esta ronda ni se generaron escenas como prueba.

Revision independiente y `diff --check` completados. Las pruebas nuevas detectan presencia/ausencia de instrucciones concretas, no demuestran calidad literaria ni comprension de los agentes. La validacion real tras reinicio sigue pendiente (NAR-005); revisar con el usuario dialogo natural, inferencia sin confesion y correccion del mecanismo del defecto, usando los casos de la decision 0002.

Backup editorial previo: `C:/Users/migue/AppData/Local/Temp/opencode/renacer-beats-antes-20260909.tar`. No usarlo para sobrescribir un destino: es evidencia local para comparar cambios.

---

### 6.3 Verificacion del checkpoint obligatorio 0003

```powershell
python -B tests/test_beat_contracts.py -v
python -B tests/test_narrative_contracts.py -v
```

Resultado de esta ampliacion: **26 aprobadas** (14 de beats/checkpoints + 12 de configuracion); cuatro opcionales de schema omitidas sin `--schema`. La suite de beats crecio desde las 11 pruebas de 0002 para detectar paradas condicionales, avance implicito, conformidades reutilizadas tras cambios y comandos que eludan la validacion humana. No se repitieron persistencia/identidad ni el runner del proveedor, pues sus implementaciones no cambiaron. Comprobar la parada real tras reinicio sigue pendiente (NAR-007).

## 7. Referencias

- [Decision 0001: narrativa por escena](decisiones/0001-narrativa-por-escena.md).
- [Decision 0002: compromiso narrativo y libertad de ejecucion](decisiones/0002-contrato-editorial-beats.md).
- [Decision 0003: checkpoint obligatorio tras cada narrativa](decisiones/0003-checkpoint-narrativa-usuario.md).

- OpenCode v1.18.29 — límite de salida: `packages/opencode/src/provider/transform.ts` (`OUTPUT_TOKEN_MAX = 32_000`, `maxOutputTokens`).
- OpenCode v1.18.29 — preparación de petición: `packages/opencode/src/session/llm/request.ts` (merge base < model.options < agent.options < variant).
- Venice provider 2.1.1: `src/venice-chat-language-model.ts` (`maxCompletionTokens ?? maxTokens ?? maxOutputTokens`), `src/venice-chat-options.ts`, `src/venice-prepare-parameters.ts`.
- Docs Venice — reasoning: `https://docs.venice.ai/overview/guides/reasoning-models` (presupuesto compartido, `finish_reason: length`, `reasoning.enabled: false` como vía recomendada donde aplica).
- Catálogo Venice: `GET https://api.venice.ai/api/v1/models?type=text` (`maxCompletionTokens: 131072`, thinking-only, sin reasoningEffort para qwen-3-8-max).
- Schema oficial de configuración: `https://opencode.ai/config.json`.
- Evidencia local: `~/.local/share/opencode/opencode.db` (sesiones/mensajes/partes) y `~/.local/share/opencode/log/opencode.log`.

> Nota sobre costes: las cifras `$` de OpenCode son estimaciones registradas por la aplicación, no una conciliación con la factura del proveedor.
