---
name: contexto-subagente
description: Define el contexto mínimo para subagentes de novela multi-hilo usando proyecto, stable_id, parent_id, nivel, seq local e hilo.
user-invocable: false
---

# Contexto de subagentes — Novela Multi-Hilo

## Contrato común

Todo briefing comienza con `proyecto`. Todo capítulo multi-hilo declara los `stable_id` de sus hilos activos. Cada beat incluye:

```text
stable_id, seq, parent_id, acción, tono, extensión, hilo
```

- `stable_id` es inmutable.
- `seq` siempre es local a `parent_id`.
- `hilo` es el `stable_id` de una entidad `tipo=hilo`; `[Hilos: hilo-<slug>]` es solo anotación humana.
- `i9j0k1l2 [34]` se deriva de `seq: 34` para presentación y nunca es identidad.
- Renumerar cambia solo `seq`, filtrado por `parent_id` y `hilo` cuando aplique.
- Summaries se buscan por `(nivel, parent_id, seq[, hilo])`; el UUID físico nunca es entrada.

### Contrato editorial común

Cada beat es una unidad dramática con compromiso verificable, no una microacción ni un párrafo. No dividir por puntuación, verbos, etiquetas tonales, hilos ni cuotas. El director pasa estas reglas inline a escritor e integrador, sin pedirles lecturas ni herramientas.

Separa **Obligatorio** (hechos, decisiones, consecuencias, restricciones, POV y literalidad justificada), **Libre** (ejecución compatible: palabras, gestos, pausas y enlaces ordinarios) y **Ejemplos opcionales** (no canon ni lista a completar). No son campos nuevos del payload.

Distingue lo dicho, sabido, inferido y confirmado, por quién y con qué certeza. Saber no obliga a preguntar; una inferencia del POV no exige confesión ajena. El tono no impone conducta: una conversación normal puede resultar opresiva por lo que comprende el personaje focal. La acción declara acontecimiento y consecuencia; el espacio, la utilería y el cast viven en la cabecera de escena y en las anotaciones; **la ejecución es del escritor**.

La escena se lee continua: los encabezados son trazabilidad, se conservan IDs/seq y cuerpos no vacíos, pero no reinician el diálogo. Si un compromiso o literalidad vigente impide la revisión autorizada, escritor/integrador devuelven `BLOQUEO:` al director.

## Guionista

Cuatro modos: `hilo`, `hilo-capitulo`, `trenzado`, `revision`. Cada uno recibe **solo** lo que necesita — nunca `diseno-hilo.md` ni `guion-hilo.md` íntegros salvo en modo `hilo`.

### Modo `hilo`

1. `proyecto`.
2. `hilos/hilo-<slug>/diseno-hilo.md` (decisiones firmes de diseño de este hilo).
3. `BRIEF.md`.
4. `config.json`: hilos, estilo activo, `ultimo_hecho_seq`.

Salida: `hilos/hilo-<slug>/guion-hilo.md` — solo hechos `H_NNNN` agrupados por acto, sin beats.

### Modo `hilo-capitulo`

1. `proyecto`.
2. Capítulo-borrador actual: rango de hechos (`stable_id [seq]`), objetivo narrativo y tensión — campos cortos, **no** `diseno-hilo.md` ni `guion-hilo.md` íntegros.
3. Últimos beats del capítulo-borrador anterior del mismo hilo (contrato de continuidad).
4. Resumen compacto de entidades y relaciones relevantes (estilo `memoria`).
5. Si el rango contiene `[D]`: `hilos/hilo-<slug>/cola_d.md` (instancias ya escritas en capítulos-borrador anteriores del mismo `[D]`, con `stable_id` + escena + resumen — no solo el conteo).
6. IDs: asignar `seq` local a la escena; generar `stable_id` opaco para cada beat y escena nuevos.

Flujo:
- **Sin `[D]` en el rango**: una sola pasada — genera beats de todos los hechos del rango y agrúpalos en escenas por coherencia de contexto. Marcador `<!-- ESCENA <stable_id>: Nombre | hilo: <stable_id_hilo> -->`. Sin renumeración (posiciones nuevas).
- **Con `[D]` en el rango**: primero **Checkpoint 1** — propone el plan de instancias (qué y cuántas, sin fórmula fija) sin escribir beats todavía. Tras validación del director + usuario: genera la secuencia completa (lineales + `[D]` entretejidos) en una sola pasada y agrupa en escenas — **Checkpoint 2** revisa el resultado contra `cola_d.md`.

Salida: `hilos/hilo-<slug>/cap-NN/guion.md`. El director (no el guionista) actualiza `cola_d.md` tras el Checkpoint 2.

### Modo `trenzado`

1. `proyecto`.
2. Todos `hilos/hilo-*/cap-NN/guion.md` (contenido **completo**: beats, personajes, objetos — no solo metadatos; `[D]` ya resuelto).
3. `guion-novela.md`, sección `## Puntos de conexión` — pista temática escrita en FASE 0, antes de que existiera ninguna escena; no es una lista a verificar mecánicamente.
4. `config.json.hilos` (stable_id de cada hilo).
5. Reglas de alternancia (skill `trenzado-narrativo`): máx. 2 hilos/capítulo, racha máx. 3 caps sin un hilo, clímax en capítulo exclusivo.

Tarea: descubre en el contenido real dónde se materializa cada conexión —y cualquier eco orgánico no previsto—, no solo lo ya anotado.

Salida: mueve cada bloque de escena completo a `capitulos/cap-NN-slug/guion.md` (`renumber-siblings` en `parent_id`/`seq`; `stable_id` y hilo no cambian), genera la tabla `## Trenzado`, reescribe `## Puntos de conexión` con `stable_id` de escena concretos.

### Modo `revision`

1. `proyecto`.
2. Tramo: beats `[stable_id...]` con sus acciones actuales.
3. Contexto bilateral: 5-8 beats antes y después del tramo.
4. `AGENTS.md`.
5. Si `estado==escritura`: briefing ligero de `memoria` (~300 tokens).
6. Instrucción concreta: qué problema corregir (costura cross-hilo, transición brusca, cobertura insuficiente, tono inconsistente).

Salida: reemplaza solo el tramo indicado, en el mismo archivo leído (`capitulos/cap-NN-slug/guion.md` tras el trenzado, o `hilos/hilo-<slug>/cap-NN/guion.md` si es previo). Mismos `stable_id` salvo que la instrucción pida añadir/eliminar beats.

## Escritor

### Modo escena (contexto preparado, ADR 0019)

1. `proyecto`.
2. Guion de la escena COMPLETA (objetivo + todos los beats con `stable_id`, `seq`, `parent_id`, acción, tono, extensión e hilo). La escena es un bloque de un solo hilo, con su marcador `<!-- ESCENA <stable_id>: Nombre | hilo: <stable_id_hilo> -->`.
3. Contexto de hilo: época, ubicación y tono propio; si la escena abre bloque tras otra época/POV, se pide reanclaje. En capítulos puente o espejo, contexto mínimo del otro hilo y `fichas/conexion-*.md`.
4. Prosa de transición y antecedentes necesarios (sin cuota fija de beats ni notas históricas irrelevantes). Paquete de capítulo preparado una vez: memoria de lo ocurrido, separada de planes futuros.
5. Fichas relevantes inline por `stable_id`; personajes, zonas y props declarados de la escena.
6. Reglas de voz, POV, mecánica de prosa y extensión orientativa ya resueltas por el director. En escenas explícitas, además, las reglas de detalle: acto a acto con progresión y transiciones, reacción del POV y sensación concreta; sin sentencias que cuentan en lugar de mostrar. Restricciones pertinentes del proyecto, inline. Contrato editorial común: Obligatorio, Libre y Ejemplos opcionales; escena continua; distinción de conocimiento; libertad de ejecución sin alterar canon.
7. Escritor sin herramientas: no se le dan órdenes de leer archivos ni cargar skills.

Output: solo prosa de TODOS los beats con marcador de escena e identidades, sin notas rutinarias. Contexto insuficiente o canon contradictorio -> `BLOQUEO`. El director prepara la candidata pendiente, presenta la escena completa con hash/versión y se detiene para validación explícita del usuario (checkpoint obligatorio de narrativa). Después obtiene revisión editorial por hash; ambas aprobaciones son necesarias antes de aceptar/sincronizar. Aprobar una escena no autoriza la siguiente; los beats no se marcan completos hasta sincronizar. No se indexa narrativa no aceptada.

### Modo revisión o expansión puntual

Recibe el texto original, la instrucción concreta, el contrato y ambos extremos de la transición. Devuelve solo las secciones solicitadas con los mismos `stable_id` y `seq`, conservando lo que no deba cambiar. Una revisión no reasigna identidades ni cambia el hilo de la escena.

## Validador

### Modo escena (revisión editorial, ADR 0019)

1. `proyecto`.
2. Escena candidata completa, SHA256 real de `preparar`, guion y contexto de transición pertinente. Briefing neutral: no anticipar el veredicto.
3. Una revisión: cobertura, continuidad, personajes/POV, prosa y restricciones. Sin cuotas sensoriales ni cinco scores por beat.
4. Cross-hilo: si el capítulo tiene ≥2 hilos, cargar `validacion-cross-hilo` y emitir sus hallazgos como incidencias con gravedad, no como bloque de scores.
5. Fichas y reglas de voz pertinentes. Distinguir voz interna del personaje y resumen del narrador; naturalidad de la conversación completa, no checklist de gestos o ejemplos.
6. Output JSON compacto: `escena_stable_id`, `candidato_sha256`, estado (`aprobado/corregir/bloqueado`), incidencias con gravedad (`opcional/corregir/bloqueante`), evidencia y corrección concreta.

### Modo revisión focalizada

1. `proyecto`.
2. Candidato completo y hash actualizado tras correcciones; lista de cambios y las incidencias a comprobar.
3. Contexto suficiente de las transiciones anterior y posterior; si hay impacto transversal, incluir los tramos implicados.
4. El resto ya aprobado no se reevalúa por rutina; un error factual nuevo fuera del fragmento sí se reporta.

### Modo global

1. `proyecto`.
2. Versión del capítulo y hash, escenas aceptadas, L4/L3, tabla de trenzado y entidades de hilos activos.
3. Cronología, objetos, conocimientos, arco y costuras entre escenas; no repetir evaluación estilística por beat.
4. Cross-hilo al cierre; devuelve solo incidencias, sin media que oculte errores factuales.

## Integrador

1. `proyecto`.
2. Fragmentos localizados por `stable_id` y texto actual inline; incidencias concretas, no tablas de scores.
3. Hilo y contexto de ambos extremos del cambio; fichas, voz/POV, mecánica y restricciones ya preparadas.
4. `instruccion_usuario` y alcance autorizado si aplica.
5. Texto COMPLETO de las secciones solicitadas. Repara el mecanismo del defecto en el intercambio mínimo autorizado, no solo una palabra; si falta alcance o contexto, devuelve `BLOQUEO:` antes de reconstruirlo.

No cambia `stable_id` ni hilo; devuelve solo secciones corregidas, sin duplicar original ni notas. El director ensambla, prepara la escena completa, la presenta y se detiene para validación del usuario; obtiene revisión focalizada antes de aceptar/sincronizar. Cualquier cambio textual invalida la conformidad anterior.

## Memoria

1. `proyecto`.
2. Capítulo: `stable_id`, `seq`, `parent_id`.
3. Hilos activos: `stable_id`, nombre y estado.
4. Entidades relevantes por `stable_id`, filtradas por hilo.
5. Conexiones cross-hilo pendientes y objetivo del capítulo.
6. Referencias `tipo=referencia` con tag `relevancia_por_hilo:<stable_id_hilo>` (máx. 2; resumen, no contenido completo).

Output: briefing L4 → L3 → L2 → entidades → relaciones → hilos → referencias, mostrando stable IDs, posición e hilo.

## Cronista — modo único cross-hilo

1. `proyecto`.
2. `Instrucción` concreta; no selector de submodo.
3. `Leer`: `draft.md`, `guion.md`, `config.json`, fichas, diseños de hilo y conexiones.
4. Capítulo, arco y escenas con `stable_id`, `seq`, `parent_id`, `nivel` e `hilo`.
5. Entidades relevantes por `stable_id`.

Carga `cronista-ops`, `qdrant` y `auditoria-neo4j`. Persiste summaries por `(nivel, parent_id, seq[, hilo])` y usa siempre el `stable_id` canónico de la escena del guion (`upsert-summary --id` o `upsert-summary-by-position --id`); nunca inventa un ID L1. Reporta `discrepancias_qdrant` separadas de `discrepancias_neo4j` y no cierra capítulo con discrepancias pendientes.

## Entidades

1. `proyecto`, nombre, tipo y descripción.
2. `stable_id` si actualiza; UUID nuevo opaco si crea.
3. Hilos afectados por `stable_id`.
4. Contexto narrativo, campos y registro de desarrollo.
