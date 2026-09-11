---
name: estructura-narrativa
description: Estructura narrativa y técnicas de escritura para novelas con múltiples hilos narrativos. Úsalo cuando necesites generar, revisar o analizar la estructura de una novela multi-hilo.
---

# Estructura de Novela Multi-Hilo

## Propósito

Este skill proporciona las reglas de estructura narrativa, técnicas de escritura y guías de desarrollo para novelas con múltiples líneas temporales, POVs o tramas paralelas que se trenzan.

## Cuándo cargarlo

- Cuando se genera una novela multi-hilo nueva (`/generar`)
- Cuando se revisa la estructura (`/revisar`)
- Cuando se expande contenido (`/expandir`)
- Cuando se diseña o rediseña el trenzado de hilos

## Contenido

### Skills de referencia

1. **`plantilla-guion`** (skill) — Estructura para desarrollo de guiones multi-hilo
2. **`hechos-estructura`** (skill) — Formato y reglas para hechos narrativos H_NNNN
3. **`beats-estructura`** (skill) — Formato y reglas para beats narrativos B_NNNN
4. **`diseno-hilo`** (skill) — Estructura y criterios para diseñar un hilo narrativo
5. **`trenzado-narrativo`** (skill) — Cómo entrelazar múltiples hilos en capítulos

### Estructura por actos

La novela multi-hilo se organiza en actos (I-V), con arcos independientes por hilo y un arco global:

```
ACTO I — PRESENTACIÓN
   - Establecimiento de cada hilo en su época/contexto
   - Introducción de personajes principales por hilo
   - Incidentes incitadores independientes

ACTO II — DESARROLLO PARALELO
   - Escalada de conflicto en cada hilo
   - Primeras conexiones sutiles entre hilos (objetos, ecos, símbolos)
   - Desarrollo de personajes y subtramas

ACTO III — CONVERGENCIA
   - Intensificación de conexiones entre hilos
   - Capítulos puente y espejo
   - Punto medio global — las líneas temporales se rozan

ACTO IV — CLÍMAX
   - Clímax de cada hilo en capítulo exclusivo
   - Convergencia máxima — los hilos se tocan en un punto común
   - Revelaciones que cruzan épocas

ACTO V — DESENLACE
   - Resolución de cada hilo
   - Cierre de conexiones cross-hilo
   - Epílogo — estado final de todos los hilos
```

### Jerarquía narrativa

Un capítulo global tiene una única jerarquía, ensamblada en dos momentos distintos:

**Dentro del hilo, antes del trenzado (FASE 0.3 — `guion.md` del capítulo-borrador):**

```
Capítulo-borrador (dentro de un hilo)
 ├── Escena (stable_id, nace aquí — sin display numérico propio)
 │    └── Beat (stable_id [seq])
 └── Escena (stable_id)
      └── Beat (stable_id [seq])
```

**Capítulo global, tras el trenzado (FASE 0.4 — `guion.md`) y en prosa (FASE 3 — `draft.md`):**

```
Capítulo global
 ├── [Modo exclusivo/puente/espejo]
 ├── Escena (misma stable_id que en el hilo de origen)
 │    └── Beat (mismo stable_id que en el hilo de origen)
 └── Escena
      └── Beat
```

La escena **no nace en el draft ni en FASE 3** — nace dentro del hilo, en FASE 0.3, agrupando los beats de ese capítulo-borrador por coherencia de contexto. El trenzado (FASE 0.4) mueve el bloque de escena completo, con su `stable_id` intacto, al capítulo global. El escritor (FASE 3) solo añade prosa dentro de esa misma estructura de escenas ya existente — no la crea ni la reagrupa.

Un beat pertenece a **un** hecho (referencia de planificación en `guion-hilo.md`, para trazabilidad) y a **una** escena (unidad real de agrupación, desde que nace). El hecho de origen es irrelevante para la agrupación en escenas: una escena puede contener beats de varios hechos del mismo hilo.

#### Capítulos

- Identificador: `cap-NN-slug` (ej: `cap-07-el-sotano`)
- Cada capítulo tiene una **función narrativa** y pertenece a uno o más hilos según la tabla de trenzado
- **Capítulo exclusivo**: un solo hilo ocupa todo el capítulo. Usar para desarrollo profundo
- **Capítulo puente**: dos o más hilos se alternan dentro del mismo capítulo (cambio de sección con `---`). Usar cuando las acciones de distintos hilos convergen temáticamente
- **Capítulo espejo**: dos hilos se narran en paralelo mostrando la misma acción/objeto en épocas distintas. Usar para revelaciones y simbolismo

#### Hechos narrativos (H_NNNN)

- Identificador de 4 dígitos, global a toda la novela: `H_0001`
- Unidad de **planificación** — vive en `guion-hilo.md`, agrupa hechos que luego se convierten en capítulos-borrador
- Cada hecho pertenece a un hilo específico
- No se persiste como nivel en Qdrant; es trazabilidad, no unidad de prosa

#### Beats

- Identidad: `stable_id` opaco, inmutable, global a la novela; el display `B_NNNN` se deriva de `seq` y nunca encabeza una sección (ADR 0017).
- Unidad dramática con compromiso verificable — no una microacción ni un párrafo.
- Siguen las reglas del skill `beats-estructura`.
- Cada beat declara su hilo con `[Hilos: hilo-<slug>]`.

### Longitudes recomendadas

| Tipo | Palabras | Capítulos | Hilos |
|------|----------|-----------|-------|
| Novela corta | 50.000-70.000 | 20-35 | 2-3 |
| Novela media | 70.000-100.000 | 30-45 | 2-4 |
| Novela larga | 100.000+ | 40-60 | 3-5 |

### Múltiples líneas temporales / POVs

Cada hilo narrativo es una trama con su propia:
- **Época o contexto temporal** (pueden ser siglos distintos o días paralelos)
- **Protagonista(s)**
- **Género dominante** (un hilo puede ser noir, otro fantasía, otro contemporáneo)
- **Conflicto central**
- **Tono y registro propios** (el escritor adapta la voz a cada hilo)

Los hilos se definen usando el skill `diseno-hilo` y se trenzan siguiendo las reglas del skill `trenzado-narrativo`.

### Coherencia cross-hilo

La validación cross-hilo debe verificar:

1. **Consistencia temporal**: los eventos de un hilo no contradicen la cronología de otro
2. **Objetos puente**: los objetos que viajan entre hilos mantienen sus propiedades
3. **Revelaciones no duplicadas**: una revelación no puede ocurrir dos veces en hilos distintos sin justificación
4. **Continuidad de personajes**: si un personaje aparece en varios hilos, su caracterización es coherente
5. **Simbolismo consistente**: los elementos simbólicos compartidos mantienen su significado

### Técnicas narrativas

#### In medias res
Empezar en medio de la acción, sin introducción:
```
MAL: "Elena llegó al ascensor y presionó el botón."
BIEN: "El ascensor se detuvo. Elena apoyó la frente en el metal frío."
```

#### Show don't tell
Mostrar en vez de decir:
```
MAL: "Estaba nerviosa."
BIEN: "Se mordía el labio. Los dedos le temblaban contra el bolso."
```

#### Diálogos con subtexto
Lo que se dice no es lo que se quiere decir:
```
"¿Vienes mucho por aquí?" → Quiero saber si eres de aquí
"Depende del día" → No quiero darte información
```

#### Detalles sensoriales específicos
Especificar en vez de generalizar:
```
MAL: "Olía bien."
BIEN: "Olía a tabaco frío y a colonia barata."
```

#### Elipsis temporal
Saltar tiempo entre capítulos o hechos sin narrar el intervalo. En multi-hilo, la elipsis puede ser distinta para cada hilo.

#### Presagio cross-hilo
Sembrar pistas en un hilo que cobrarán sentido en otro hilo distinto:
```
[hilo-a, H_0012]: un personaje entierra/oculta un objeto con una marca concreta.
[hilo-b, H_0045]: otro personaje, en otra época, descubre ese mismo objeto.
```

### Formato de párrafos — criterios de ejecución

Estos criterios orientan la ejecución y la revisión; no son cuotas ni umbrales numéricos. El ancho de pantalla y el conteo de líneas no determinan la estructura.

#### Diálogos en párrafos independientes

Cada intervención de diálogo va en su propio párrafo, separado del texto narrativo por una línea en blanco. No se embebe en medio de un bloque narrativo.

```
MAL:
Fernando se giró despacio. —Ya lo sé —dijo, con la voz plana. Lucía no respondió.

BIEN:
Fernando se giró despacio.

—Ya lo sé —dijo, con la voz plana.

Lucía no respondió.
```

Los diálogos ultracortos (`—Más.`, `—No pares.`, `—Quieto.`) van en su propio párrafo; admiten atribuciones o acotaciones pertinentes sin límite por longitud, y no se les añaden gestos o silencios solo para separarlos.

#### División de bloques narrativos

Cuando la narración cambia de foco (acción → sensación, sensación → reacción interna, un cuerpo → otro cuerpo, presente → recuerdo, **un hilo → otro hilo**), valora partir en un nuevo párrafo. Un bloque que dificulte seguir el foco o respirar la cadencia probablemente fusiona focos que conviene separar; no se decide por número de líneas.

```
MAL (todo fundido):
La empujó contra la pared y le metió la mano entre las piernas, y ella notó el calor antes del contacto y recordó la primera vez que alguien la había tocado así, sin preguntar, con esa certeza de quien sabe que la respuesta va a ser sí.

BIEN (partido en cambios de foco):
La empujó contra la pared y le metió la mano entre las piernas.

Ella notó el calor antes del contacto, una fracción de segundo de anticipación que fue casi mejor que el tacto mismo.

Recordó la primera vez que alguien la había tocado así, sin preguntar.
```

### Escenas, hechos y beats

**Hecho** (H_NNNN) y **escena** son dos unidades independientes que agrupan beats con propósitos distintos. No tienen relación entre sí:

| Unidad | Agrupa | Dónde vive | Cuándo nace |
|--------|--------|-----------|-------------|
| Hecho | beats | `guion-hilo.md`, tabla de Trenzado en `guion-novela.md` (trazabilidad) | FASE 0.2 (guionista modo `hilo`) |
| Escena | beats | `hilos/hilo-<slug>/cap-NN/guion.md` (nace aquí) → `capitulos/cap-NN-slug/guion.md` (tras trenzar) → L1 en Qdrant (solo cuando hay prosa real) | FASE 0.3 (guionista modo `hilo-capitulo`) |

**Hecho = unidad de planificación.** Agrupa beats por intención dramática en el guion. No se persiste como nivel en Qdrant.

**Escena = unidad real de agrupación, desde el guion.** Nace dentro del hilo en FASE 0.3, agrupando beats por coherencia de contexto — antes de que exista prosa. Su resumen L1 se crea con el `stable_id` canónico de la escena del guion: la persistencia temprana (FASE 3.2c) puede adelantarlo y el cronista lo consolida al cerrar (FASE 3.5), pero nunca se inventa un ID. Mientras es capítulo-borrador, sin prosa, no se persiste narrativa en Qdrant.

La prosa se escribe y se valida **por escena completa después del trenzado** (FASE 3, ADR 0019), con checkpoint humano por escena antes de aceptar y sincronizar.

**La procedencia del hecho es irrelevante al agrupar beats en escenas.** Una misma escena puede contener beats de varios hechos del mismo hilo porque el hecho ya cumplió su función (planificar) y no existe en el momento de la agrupación. En un **capítulo puente**, cada escena es un bloque de hilo delimitado por `---`. En un **capítulo espejo**, las escenas de los dos hilos se alternan.

### Beats

Cada beat debe ser:
- **Unidad dramática**: declara el acontecimiento, la decisión, el descubrimiento o la inferencia atribuida y su consecuencia; no una microacción
- **Ordenado**: sigue el orden cronológico del hecho y del hilo
- **Sin sensoriales**: temperatura, olfato, textura, emociones internas son del escritor
- **Sin microcoreografía**: gestos, posiciones, adverbios de modo y valoraciones son ejecución del escritor; el espacio y la utilería viven en la anotación y la cabecera de escena
- **Literalidad justificada**: ⚡ solo para palabras exactas exigidas por el usuario o con función causal documentada; no es una cuota por beat

### Hechos (H_NNNN)

Cada hecho debe tener:
- **Propósito**: qué avanza en la trama o en el arco del hilo
- **Hilo**: a qué hilo pertenece este hecho
- **Beats**: los que la unidad dramática necesite para cubrir detonante, presión, cambio y consecuencia; sin mínimo ni máximo numérico
- **Transición** (en planificación): cómo enlaza con el siguiente hecho (mismo hilo u otro hilo si es capítulo puente)

### Escenas

Cada escena debe tener:
- **Beats**: los beats agrupados en ella, con independencia del hecho de origen
- **Coherencia de contexto**: mismo espacio, tiempo y cast; o corte explícito (cambio de hilo, elipsis temporal, cambio de POV)
- **Extensión**: la que pida la coherencia de contexto y la unidad dramática; sin mínimo ni máximo numérico de beats
- **En multi-hilo**: respeta el límite de hilo — una escena no mezcla hilos

### Capítulos

Cada capítulo debe tener:
- **Escenas**: las que el trenzado (FASE 0.4) movió desde los hilos, ya con sus beats agrupados desde FASE 0.3 — no se reagrupan al llegar al capítulo global
- **Función narrativa**: qué aporta al arco del acto y al trenzado global
- **Hilos activos**: qué hilos aparecen y en qué modo (exclusivo, puente o espejo)

## Integración con agentes

- El agente `guionista` usa este skill para estructurar el argumento, los actos y el trenzado
- El agente `escritor` usa este skill para generar texto bien estructurado, adaptando la voz a cada hilo
- Los agentes de validación usan este skill como referencia de calidad, incluyendo `validacion-cross-hilo`
- El agente `memoria` consulta la estructura y el trenzado para contextualizar capítulos
