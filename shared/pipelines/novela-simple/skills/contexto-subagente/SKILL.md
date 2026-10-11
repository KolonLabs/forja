---
name: contexto-subagente
description: Define el contexto mínimo para subagentes de novela simple usando proyecto, stable_id, parent_id, nivel y seq local al padre.
user-invocable: false
---

# Contexto de subagentes — Novela Simple

## Contrato común

Todo briefing comienza con `proyecto` y, para cada beat, incluye:

```text
stable_id, seq, parent_id, acción, tono, extensión
```

- `stable_id` es inmutable.
- `seq` siempre es local a `parent_id`.
- `i9j0k1l2 [34]` se deriva de `seq: 34` en presentación y nunca es identidad persistida.
- Renumerar cambia solo `seq` mediante las operaciones de `cronista-ops`.
- Summaries se describen por `nivel`, `parent_id` y `seq`; el UUID físico nunca es entrada.

### Contrato editorial comun

Aplica `beats-estructura`: cada beat es una unidad dramatica con compromiso verificable, no una microaccion ni un parrafo. No dividir por puntuacion, verbos, etiquetas tonales o cuotas. El director pasa estas reglas inline a escritor/integrador, sin pedirles lecturas ni herramientas.

En el contexto existente separa **Obligatorio** (hechos, decisiones, consecuencias, restricciones, POV y literalidad justificada), **Libre** (ejecucion compatible: palabras, gestos, pausas y enlaces ordinarios) y **Ejemplos opcionales** (no canon ni lista a completar). No son campos nuevos del payload. No convertir sugerencias en texto literal ni copiar todas las alternativas al mensaje como exigencias.

Distingue lo dicho, sabido, inferido y confirmado, por quien y con que certeza. Saber no obliga a preguntar; una inferencia del POV no exige confesion ajena. Una indicacion de deduccion no prescribe una lista de pensamientos. El tono no impone conducta: una conversacion normal puede resultar opresiva por lo que comprende el personaje focal.

La escena se lee continua: los encabezados son trazabilidad, se conservan IDs/seq y cuerpos no vacios, pero no reinician el dialogo. Saludos, despedidas y transiciones ordinarias caben en los beats existentes cuando procede. Si un compromiso o literalidad vigente impide la revision autorizada, escritor/integrador devuelven `BLOQUEO:` al director; no cambian el guion ni fuerzan prosa para salvarlo.

## Guionista

### Modo estructura-novela

1. `proyecto`.
2. Hechos de `_actos.md`, con `stable_id`, `seq` y `parent_id` cuando estén materializados.
3. `BRIEF.md`.
4. `config.json` y estilo.

### Modo capítulo — pasada 1 (beats)

1. `proyecto`.
2. Capítulo: `stable_id`, `seq`, `parent_id` y función narrativa.
3. Hechos del capítulo por `stable_id [seq]`.
4. Últimos 5-8 beats del capítulo anterior con contrato común.
5. Briefing de memoria.
6. Estilo activo.
7. **Sin marcadores `<!-- ESCENA ... -->`**. Salida: beats en bruto, sin agrupar en escenas.

### Modo capítulo — pasada 2 (escenas)

1. `proyecto`, capítulo actual.
2. `capitulos/cap-NN-slug/guion.md` con los beats ya generados en pasada 1.
3. Criterio de agrupación: coherencia de contexto (mismo espacio, tiempo y cast). Una escena puede envolver beats de varios hechos; un hecho largo puede fraccionarse en dos escenas si hay corte de contexto.
4. Generar `stable_id` opaco para cada escena nueva.
5. Insertar `<!-- ESCENA <stable_id>: Nombre -->` antes del primer beat de cada escena. **No modificar los beats** — solo agrupar.
6. No hay renumeración: la posición de los beats no cambia.

## Escritor

### Modo escena (contexto preparado, ADR 0019)

1. `proyecto`.
2. Guion de la escena COMPLETA (objetivo + todos los beats con `stable_id`, `seq`, `parent_id`, acción, tono, extensión).
3. Fichas relevantes inline por `stable_id`.
4. Prosa de transicion y antecedentes necesarios (sin cuota fija de beats ni notas historicas irrelevantes).
5. Paquete de capitulo preparado una vez: memoria de lo ocurrido, distinta de planes futuros; sin duplicar contenido en cada campo.
6. Personajes, zonas y props declarados de la escena.
7. Reglas de voz, POV, mecanica de prosa y extension orientativa ya resueltas por el director. En escenas explícitas, además, las reglas de detalle: acto a acto con progresión y transiciones, reacción del POV y sensación concreta; sin sentencias que cuentan en lugar de mostrar.
8. Restricciones pertinentes del proyecto, inline. Escritor sin herramientas: no se le dan ordenes de leer archivos ni cargar skills.
9. Contrato editorial comun inline: Obligatorio, Libre y Ejemplos opcionales; escena continua, distincion de conocimiento y libertad de ejecucion sin alterar canon.

Output: solo prosa de TODOS los beats con marcador de escena e identidades, sin notas rutinarias. Contexto insuficiente o canon contradictorio -> BLOQUEO. El director prepara la candidata pendiente, presenta la escena completa con hash/version y se detiene para validacion explicita del usuario (checkpoint obligatorio de narrativa). Despues obtiene revision editorial por hash; ambas aprobaciones son necesarias antes de aceptar/sincronizar. Aprobar una escena no autoriza la siguiente escena ni capitulo. No se indexa narrativa no aceptada.

### Modo beat (revisiones puntuales)

1. `proyecto`.
2. Beat actual: `stable_id`, `seq`, `parent_id`, acción, tono y extensión.
3. Guion de la escena y contexto necesario de ambos lados del fragmento, todo inline.
4. Fichas relevantes, briefing de memoria, estilo.
5. Personajes, zona y props declarados.
6. Display derivado opcional, nunca usado para lookup.

### Modo expansión

Añade el beat siguiente del draft para conservar la transición. La expansión mantiene `stable_id` y `seq`.

## Validador

### Modo escena (revision editorial, ADR 0019)

1. `proyecto`.
2. Escena candidata completa, SHA256 real de `preparar`, guion y contexto de transicion pertinente.
3. Una revision: cobertura, continuidad, personajes/POV, prosa y restricciones. Sin cuotas sensoriales ni cinco scores por beat.
4. Output JSON compacto: escena_stable_id, candidato_sha256, estado (aprobado/corregir/bloqueado), incidencias con gravedad (opcional/corregir/bloqueante), evidencia y correccion concreta. Sin elogios rutinarios.
5. Fichas y reglas de voz pertinentes. Briefing neutral: no anticipar el veredicto ni justificar previamente contradicciones.
6. Contrato editorial comun: cobertura semantica y naturalidad de la conversacion completa, no checklist de gestos o ejemplos. Distinguir voz interna del personaje y resumen del narrador.

### Modo revision focalizada

1. `proyecto`.
2. Texto del beat.
3. Beat de guion: `stable_id`, `seq`, `parent_id`, acción, tono y extensión.
4. Fichas relevantes.
5. Contexto suficiente de las transiciones anterior y posterior. Si hay impacto transversal, incluir los tramos implicados.
6. Candidato completo y hash actualizado tras correcciones; lista de cambios y las incidencias a comprobar. El resto ya aprobado no se reevalua por rutina.

### Modo global

1. `proyecto`.
2. Version del capitulo y hash, escenas aceptadas y antecedentes necesarios.
3. Summary L4 y sección de arco, con `nivel`, `stable_id`, `seq` y `parent_id` en el resultado.
4. Cronologia, objetos, conocimientos y arco transversal; no repetir evaluacion estilistica por beat.
5. Fichas pertinentes. Devuelve solo incidencias entre escenas, sin media que oculte errores factuales.

## Integrador

1. `proyecto`.
2. Fragmentos localizados por `stable_id` y texto actual inline.
3. Incidencias concretas del validador, no tablas de scores ni defensas del texto.
4. Guion con contrato comun y contexto de ambos extremos de los cambios.
5. Fichas, voz/POV, mecanica y restricciones ya preparadas: integrador sin herramientas ni cargas de skills.
6. `instruccion_usuario` y alcance autorizado si aplica.
7. Texto COMPLETO de las secciones solicitadas, con ambos extremos. Reparar el mecanismo del defecto en el intercambio minimo autorizado, no solo sustituir una palabra; si falta alcance o contexto, devolver `BLOQUEO:` antes de reconstruirlo.

No cambia `stable_id`; devuelve solo secciones corregidas, sin duplicar original, JSON ni notas. El director ensambla y prepara la escena completa, la presenta y se detiene para validacion del usuario; obtiene revision focalizada antes de aceptar/sincronizar. Cualquier cambio textual invalida la conformidad anterior: el permiso para corregir no aprueba prosa aun no vista. No cambia canon para reparar prosa.

## Memoria

1. `proyecto`.
2. Capítulo: `stable_id`, `seq`, `parent_id`.
3. Entidades relevantes por `stable_id`.
4. `stable_id` del hilo implícito si existe como entidad.
5. Objetivo del capítulo.
6. Referencias `tipo=referencia` relevantes al objetivo del capítulo (máx. 2; resumen, no contenido completo).

Output: briefing estructurado por L4 → L3 → L2 → entidades → relaciones → referencias, mostrando stable IDs y posición.

## Cronista — modo único

1. `proyecto`.
2. `Instrucción` concreta; no selector de submodo.
3. `Leer`: `draft.md`, `guion.md`, `config.json` y fichas relevantes.
4. Capítulo, arco y escenas con `stable_id`, `seq`, `parent_id` y `nivel`.
5. Entidades relevantes por `stable_id`.

Carga `cronista-ops`, `qdrant` y `auditoria-neo4j`. Los summaries se persisten por `(nivel, parent_id, seq)`.

## Entidades

1. `proyecto`, nombre, tipo y descripción.
2. `stable_id` si actualiza; UUID nuevo opaco si crea.
3. Contexto narrativo.
4. Campos y registro de desarrollo.
