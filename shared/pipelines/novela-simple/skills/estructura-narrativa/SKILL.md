---
name: estructura-narrativa
description: Estructura narrativa y técnicas de escritura para novelas de una sola línea temporal. Úsalo cuando necesites generar, revisar o analizar la estructura de una novela simple.
---

# Estructura de Novela Simple

## Propósito

Este skill proporciona las reglas de estructura narrativa, técnicas de escritura y guías de desarrollo para novelas con una única línea temporal.

## Cuándo cargarlo

- Cuando se genera una novela nueva (`/generar`)
- Cuando se revisa la estructura (`/revisar`)
- Cuando se expande contenido (`/expandir`)

## Contenido

### Skills de referencia

1. **`plantilla-guion`** (skill) — Estructura para desarrollo de guiones de novela simple
2. **`hechos-estructura`** (skill) — Formato y reglas para hechos narrativos H_NNNN
3. **`beats-estructura`** (skill) — Formato y reglas para beats narrativos B_NNNN

### Estructura por actos

La novela simple se organiza en actos (I-III o I-V según complejidad):

```
ACTO I — PLANTEAMIENTO
   - Presentación del mundo
   - Introducción de personajes principales
   - Incidente incitador
   - Primer punto de giro

ACTO II — DESARROLLO
   - Escalada de conflicto
   - Subtramas y desarrollo de personajes
   - Punto medio (cambio de dirección)
   - Crisis y punto más bajo

ACTO III — RESOLUCIÓN
   - Clímax
   - Resolución de subtramas
   - Desenlace

[Si es estructura en V actos, añadir:]
ACTO IV — CONSECUENCIAS
   - Reconfiguración del mundo post-clímax
   - Cierre de arcos secundarios

ACTO V — EPÍLOGO
   - Estado final de los personajes
   - Cierre definitivo
```

### Jerarquía narrativa

Un capítulo tiene **dos vistas independientes** sobre los mismos beats, no una jerarquía mixta.

**En el GUION (planificación):**

```
Capítulo
 ├── Hecho (H_NNNN)
 │    └── Beat (B_NNNN)
 └── Hecho (H_NNNN)
      └── Beat (B_NNNN)
```

**En el DRAFT (prosa):**

```
Capítulo
 ├── Escena (L1 en Qdrant)
 │    └── Beat (B_NNNN)
 └── Escena (L1 en Qdrant)
      └── Beat (B_NNNN)
```

Un beat pertenece a **UN** hecho (en el guion) y a **UNA** escena (en el draft). El hecho y la escena no tienen relación entre sí. La agrupación de beats en escenas se hace con independencia total del hecho de origen, en FASE 2.2.2.

#### Capítulos

- Identificador: `cap-NN-slug` (ej: `cap-01-el-ascensor`)
- Cada capítulo tiene una **función narrativa** clara: presentación, desarrollo, giro, clímax parcial, transición, etc.
- Un capítulo contiene los hechos necesarios para cumplir su función, sin cuota; se delimita por desarrollo y cambio narrativo

#### Hechos narrativos (H_NNNN)

- Identificador de 4 dígitos, global a toda la novela: `H_0001`
- Unidad intermedia entre capítulo y beat
- Cada hecho agrupa beats que forman una unidad dramática coherente en el **guion**
- No se persiste como nivel en Qdrant — es planificación pura

#### Escenas

La escena es la **unidad de prosa**: agrupa beats en el `draft.md` por coherencia de lectura (mismo espacio, tiempo y cast; o corte explícito). Se persiste como L1 en Qdrant al cerrar el capítulo (FASE 2.5).

**La procedencia del hecho es irrelevante.** El hecho ya no existe en el momento de la agrupación. Una escena puede contener beats de varios hechos porque solo importa la coherencia del contexto narrativo, no el origen de planificación.

El flujo es: hechos del capítulo → beats (FASE 2.2.1, guionista pasada 1) → agrupación de beats en escenas (FASE 2.2.2, guionista pasada 2) → checkpoint del usuario → prosa.

#### Beats (B_NNNN)

- Identificador de 4 dígitos, global a toda la novela: `B_0001`
- Unidad dramática que compromete un cambio narrativo: acción, interacción, decisión, descubrimiento o inferencia atribuida con consecuencias; no una microacción
- Siguen las reglas del skill `beats-estructura`

### Longitudes recomendadas

Referencias de escala editorial, no cuotas para derivar hechos o beats. La cobertura y el desarrollo determinan la estructura real.

| Tipo | Palabras | Capítulos | Hechos |
|------|----------|-----------|--------|
| Novela corta | 30.000-50.000 | 12-20 | 60-120 |
| Novela media | 50.000-80.000 | 20-35 | 120-200 |
| Novela larga | 80.000+ | 30-50 | 180-300 |

### Técnicas narrativas

Recursos opcionales de ejecución, no canon ni obligaciones. Los ejemplos no fijan gestos, silencios, metáforas, conocimiento ni conductas; el escritor elige según función, contexto y POV.

#### In medias res
Empezar en medio de la acción, sin introducción:
```
MAL: "Elena llegó al ascensor y presionó el botón."
BIEN: "El ascensor se detuvo. Elena apoyó la frente en el metal frío."
```

#### Show don't tell
Mostrar cuando aporta experiencia o evidencia; narrar directamente una decisión o percepción también puede ser pertinente. No sustituir toda interioridad por gestos:
```
Síntesis posible: "Estaba nerviosa."
Manifestación posible: "Los dedos le temblaban contra el bolso."
```

#### Diálogos con subtexto
Lo dicho puede diferir de la intención, cuando el contexto lo sostiene; no es obligatorio ocultar el sentido de cada réplica:
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
Saltar tiempo entre capítulos o hechos sin narrar el intervalo:
```
El ascensor se cerró.
---
Tres semanas después, Elena no había vuelto a pisar el edificio.
```

#### Presagio (foreshadowing)
Sembrar pistas sutiles que cobrarán sentido más adelante. En novela, el foreshadowing puede darse a nivel de hecho o capítulo.

### Arco narrativo para novelas eróticas

```
ACTO I — DESEO
   - Tensión sexual inicial (miradas, cercanía)
   - Primer encuentro no sexual pero cargado
   - Incidente que fuerza la intimidad

ACTO II — EXPLORACIÓN
   - Primer contacto sexual
   - Escalada de intensidad y vulnerabilidad
   - Conflicto emocional paralelo al deseo

ACTO III — CRISIS
   - El deseo choca con las consecuencias
   - Separación o distanciamiento
   - Toma de conciencia

ACTO IV — RECONCILIACIÓN (o RUPTURA)
   - Reencuentro físico y emocional
   - Integración de deseo y vínculo
   - Resolución de los conflictos arrastrados

ACTO V — NUEVO EQUILIBRIO
   - Estado final de la relación
   - La intimidad como nuevo normal
```

### Formato de prosa

Aplicar `mecanica-prosa` para diálogo, interioridad y párrafos. Separar intervenciones para identificar al hablante y cortar párrafos por claridad y cadencia, no por líneas, acciones o sensaciones contadas. Los cambios de foco no exigen corte automático.

La conversación puede fluir con saludos, despedidas y transiciones ordinarias sin un beat por cada réplica o gesto. Mantener los encabezados Markdown, IDs y cuerpos por beat exigidos por el contrato técnico; esos límites no obligan a reiniciar la conversación ni a añadir pausas escénicas.

### Escenas, hechos y beats

**Hecho** (H_NNNN) y **escena** son dos unidades independientes que agrupan beats con propósitos distintos. No tienen relación entre sí:

| Unidad | Agrupa | Dónde vive | Cuándo nace |
|--------|--------|-----------|-------------|
| Hecho | beats | `guion-novela.md` | FASE 0.3 (guionista modo `estructura-novela`) |
| Escena | beats | `draft.md` (y L1 en Qdrant) | FASE 2.2.2 (guionista modo `capitulo`, pasada 2) |

**Hecho = unidad de planificación.** Agrupa beats por intención dramática en el guion. No se persiste como nivel en Qdrant.

**Escena = unidad de prosa.** Agrupa beats por coherencia de lectura en el draft. Se persiste como L1 en Qdrant al cerrar el capítulo (FASE 2.5).

**La procedencia del hecho es irrelevante al agrupar beats en escenas.** Una misma escena puede contener beats de varios hechos porque el hecho ya cumplió su función (planificar) y no existe en el momento de la agrupación. No hay límite fijo de escenas por capítulo ni de beats por escena; la coherencia de contexto (mismo espacio, tiempo y cast, o corte explícito) es el único criterio.

Cada beat debe ser:
- **Compromiso narrativo**: declara qué ocurre o cambia y a quién afecta; admite decisiones, descubrimientos e inferencias atribuidas sin redactar el pensamiento como guion
- **Ordenado**: sigue el orden cronológico del hecho
- **Preciso sobre conocimiento**: distingue lo dicho, sabido, inferido y verdadero; una afirmación o inferencia no confirma por sí sola el hecho referido
- **Ejecución libre**: el escritor decide formulación, interioridad, sensoriales y enlaces; solo se compromete un detalle concreto si cumple una función narrativa, no por adornar el tono
- **Diálogo por contenido y efecto**: no se redacta una réplica obligatoria por ser importante. ⚡ se reserva a palabras exactas exigidas por el usuario o aprobadas con función causal documentada, según `mecanica-prosa`. Si una frase ⚡ vigente es incompatible con la revisión, se pide resolución al director antes de generar, sin alterarla ni degradarla a sugerencia
- **Unidad dramática**: no se divide por puntuación, verbos o mezcla tonal; las etiquetas no modifican hechos, conducta, conocimiento, consentimiento ni intensidad fijada

Cada hecho debe tener:
- **Propósito**: qué avanza en la trama o en el arco de personaje
- **Beats**: cobertura suficiente de los compromisos y cambios del hecho, sin mínimo ni máximo numérico
- **Transición** (en planificación): relación causal o temporal con el siguiente hecho; puede resolverse mediante elipsis, sin beat puente obligatorio

Cada escena debe tener:
- **Beats**: los beats agrupados en ella, con independencia del hecho de origen
- **Coherencia de contexto**: mismo espacio, tiempo y cast; o corte explícito

Cada capítulo debe tener:
- **Beats**: todos los beats de sus hechos, agrupados en escenas tras FASE 2.2.2
- **Función narrativa**: qué aporta al arco del acto (presentación, desarrollo, giro, clímax parcial, transición, etc.)

## Integración con agentes

- El agente `guionista` usa este skill para estructurar el argumento y los actos
- El agente `escritor` usa este skill para generar texto bien estructurado
- Los agentes de validación usan este skill como referencia de calidad
- El agente `memoria` consulta la estructura para contextualizar capítulos
