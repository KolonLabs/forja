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

```
Novela
 └── Acto I, II, III...
      └── Capítulo (cap-NN-slug)
           └── Hecho narrativo (H_NNNN)
                └── Beat (B_NNNN)
```

#### Capítulos

- Identificador: `cap-NN-slug` (ej: `cap-01-el-ascensor`)
- Cada capítulo tiene una **función narrativa** clara: presentación, desarrollo, giro, clímax parcial, transición, etc.
- Un capítulo contiene entre 3 y 10 hechos narrativos

#### Hechos narrativos (H_NNNN)

- Identificador de 4 dígitos, global a toda la novela: `H_0001`
- Unidad intermedia entre capítulo y beat
- Cada hecho agrupa beats que forman una unidad dramática coherente
- Cada hecho se desarrolla en una escena (1 hecho = 1 escena), que contiene sus beats

#### Beats (B_NNNN)

- Identificador de 4 dígitos, global a toda la novela: `B_0001`
- Unidad mínima de narración — una acción concreta y narrable
- Siguen las reglas del skill `beats-estructura`

### Longitudes recomendadas

| Tipo | Palabras | Capítulos | Hechos |
|------|----------|-----------|--------|
| Novela corta | 30.000-50.000 | 12-20 | 60-120 |
| Novela media | 50.000-80.000 | 20-35 | 120-200 |
| Novela larga | 80.000+ | 30-50 | 180-300 |

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

### Formato de párrafos — reglas obligatorias

Estas reglas aplican a todo texto generado, independientemente del estilo o el tono del beat.

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

Cuando la narración cambia de foco (acción → sensación, sensación → reacción interna, un cuerpo → otro cuerpo, presente → recuerdo), parte en un nuevo párrafo. Un bloque de más de 6-7 líneas sin corte probablemente fusiona focos que deberían estar separados.

```
MAL (todo fundido):
La empujó contra la pared y le metió la mano entre las piernas, y ella notó el calor antes del contacto y recordó la primera vez que alguien la había tocado así, sin preguntar, con esa certeza de quien sabe que la respuesta va a ser sí.

BIEN (partido en cambios de foco):
La empujó contra la pared y le metió la mano entre las piernas.

Ella notó el calor antes del contacto, una fracción de segundo de anticipación que fue casi mejor que el tacto mismo.

Recordó la primera vez que alguien la había tocado así, sin preguntar.
```

### Escenas y hechos

Cada escena se compone de **beats**, agrupados en **hechos narrativos** (H_NNNN) que forman unidades dramáticas dentro del capítulo.

Cada beat debe ser:
- **Factual**: declara QUÉ ocurre físicamente — quién hace qué a quién
- **Ordenado**: sigue el orden cronológico del hecho
- **Sin sensoriales**: temperatura, olfato, textura, emociones internas son del escritor
- **Diálogo solo si es crítico de trama**: marcado con ⚡, máximo 1 por beat

Cada hecho debe tener:
- **Propósito**: qué avanza en la trama o en el arco de personaje
- **Beats**: mínimo 3-8 beats que formen una unidad dramática
- **Transición**: cómo enlaza con el siguiente hecho

Cada capítulo debe tener:
- **Hechos**: mínimo 3-10 hechos narrativos
- **Función narrativa**: qué aporta al arco del acto (presentación, desarrollo, giro, clímax parcial, transición, etc.)

## Integración con agentes

- El agente `guionista` usa este skill para estructurar el argumento y los actos
- El agente `escritor` usa este skill para generar texto bien estructurado
- Los agentes de validación usan este skill como referencia de calidad
- El agente `memoria` consulta la estructura para contextualizar capítulos
