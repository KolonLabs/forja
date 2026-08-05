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

Un capítulo tiene **dos vistas independientes** sobre los mismos beats, no una jerarquía mixta.

**En el GUION (planificación):**

```
Capítulo
 ├── [Modo exclusivo/puente/espejo]
 ├── Hecho (H_NNNN)
 │    └── Beat (B_NNNN)
 └── Hecho (H_NNNN)
      └── Beat (B_NNNN)
```

**En el DRAFT (prosa):**

```
Capítulo
 ├── [Modo exclusivo/puente/espejo]
 ├── Escena (L1 en Qdrant)
 │    └── Beat (B_NNNN)
 └── Escena (L1 en Qdrant)
      └── Beat (B_NNNN)
```

Un beat pertenece a **UN** hecho (en el guion) y a **UNA** escena (en el draft). El hecho y la escena no tienen relación entre sí. La agrupación de beats en escenas se hace con independencia total del hecho de origen, en FASE 3.2.2.

#### Capítulos

- Identificador: `cap-NN-slug` (ej: `cap-07-el-sotano`)
- Cada capítulo tiene una **función narrativa** y pertenece a uno o más hilos según la tabla de trenzado
- **Capítulo exclusivo**: un solo hilo ocupa todo el capítulo. Usar para desarrollo profundo
- **Capítulo puente**: dos o más hilos se alternan dentro del mismo capítulo (cambio de sección con `---`). Usar cuando las acciones de distintos hilos convergen temáticamente
- **Capítulo espejo**: dos hilos se narran en paralelo mostrando la misma acción/objeto en épocas distintas. Usar para revelaciones y simbolismo

#### Hechos narrativos (H_NNNN)

- Identificador de 4 dígitos, global a toda la novela: `H_0001`
- Unidad intermedia entre capítulo y beat
- Cada hecho pertenece a un hilo específico
- En capítulos puente, los hechos se alternan entre hilos

#### Beats (B_NNNN)

- Identificador de 4 dígitos, global a toda la novela: `B_0001`
- Unidad mínima de narración — una acción concreta y narrable
- Siguen las reglas del skill `beats-estructura`
- Cada beat declara su hilo con `[Hilos: hilo-<slug>]`

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
[Hilo-sumer, H_0012]: Naamah entierra una losa con un sigilo.
[Hilo-sello, H_0045]: La abadesa descubre la misma losa 4400 años después.
```

### Formato de párrafos — reglas obligatorias

Estas reglas aplican a todo texto generado, independientemente del estilo, el tono del beat o el hilo.

#### Diálogos en párrafos independientes

Cada intervención de diálogo va en su propio párrafo, separado del texto narrativo por una línea en blanco. Nunca embebido en medio de un bloque narrativo.

```
MAL:
Fernando se giró despacio. —Ya lo sé —dijo, con la voz plana. Lucía no respondió.

BIEN:
Fernando se giró despacio.

—Ya lo sé —dijo, con la voz plana.

Lucía no respondió.
```

Los diálogos ultracortos (`—Más.`, `—No pares.`, `—Quieto.`) van siempre solos en su párrafo, sin narración en la misma línea.

#### División de bloques narrativos largos

Cuando la narración cambia de foco (acción → sensación, sensación → reacción interna, un cuerpo → otro cuerpo, presente → recuerdo, **un hilo → otro hilo**), parte en un nuevo párrafo. Un bloque de más de 6-7 líneas sin corte probablemente fusiona focos que deberían estar separados.

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
| Hecho | beats | `guion-hilo.md`, tabla de Trenzado en `guion-novela.md` | FASE 0.2 (guionista modo `hilo`) |
| Escena | beats | `draft.md` (y L1 en Qdrant) | FASE 3.2.2 (guionista modo `capitulo`, pasada 2) |

**Hecho = unidad de planificación.** Agrupa beats por intención dramática en el guion. No se persiste como nivel en Qdrant.

**Escena = unidad de prosa.** Agrupa beats por coherencia de lectura en el draft. Se persiste como L1 en Qdrant al cerrar el capítulo (FASE 3.5).

**La procedencia del hecho es irrelevante al agrupar beats en escenas.** Una misma escena puede contener beats de varios hechos del mismo hilo porque el hecho ya cumplió su función (planificar) y no existe en el momento de la agrupación. En un **capítulo puente**, cada escena es un bloque de hilo delimitado por `---`. En un **capítulo espejo**, las escenas de los dos hilos se alternan.

### Beats (B_NNNN)

Cada beat debe ser:
- **Factual**: declara QUÉ ocurre físicamente — quién hace qué a quién
- **Ordenado**: sigue el orden cronológico del hecho y del hilo
- **Sin sensoriales**: temperatura, olfato, textura, emociones internas son del escritor
- **Diálogo solo si es crítico de trama**: marcado con ⚡, máximo 1 por beat

### Hechos (H_NNNN)

Cada hecho debe tener:
- **Propósito**: qué avanza en la trama o en el arco del hilo
- **Hilo**: a qué hilo pertenece este hecho
- **Beats**: mínimo 3-8 beats que formen una unidad dramática
- **Transición** (en planificación): cómo enlaza con el siguiente hecho (mismo hilo u otro hilo si es capítulo puente)

### Escenas

Cada escena debe tener:
- **Beats**: los beats agrupados en ella, con independencia del hecho de origen
- **Coherencia de contexto**: mismo espacio, tiempo y cast; o corte explícito (cambio de hilo, elipsis temporal, cambio de POV)
- **Tamaño razonable**: ni 1-2 beats ni >12 beats por escena
- **En multi-hilo**: respeta el límite de hilo — una escena no mezcla hilios

### Capítulos

Cada capítulo debe tener:
- **Beats**: todos los beats de sus hechos, agrupados en escenas tras FASE 3.2.2
- **Función narrativa**: qué aporta al arco del acto y al trenzado global
- **Hilos activos**: qué hilos aparecen y en qué modo (exclusivo, puente o espejo)

## Integración con agentes

- El agente `guionista` usa este skill para estructurar el argumento, los actos y el trenzado
- El agente `escritor` usa este skill para generar texto bien estructurado, adaptando la voz a cada hilo
- Los agentes de validación usan este skill como referencia de calidad, incluyendo `validacion-cross-hilo`
- El agente `memoria` consulta la estructura y el trenzado para contextualizar capítulos
