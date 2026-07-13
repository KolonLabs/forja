---
name: estructura-narrativa
description: Estructura narrativa y técnicas de escritura para relatos cortos. Úsalo cuando necesites generar, revisar o analizar la estructura de un relato.
---

# Estructura de Relato Corto

## Propósito

Este skill proporciona las reglas de estructura narrativa, técnicas de escritura y guías de desarrollo para relatos cortos explícitos.

## Cuándo cargarlo

- Cuando se genera un relato nuevo (`/generar`)
- Cuando se revisa la estructura de un relato (`/revisar`)
- Cuando se expande una escena (`/expandir`)

## Contenido

### Skills de referencia

1. **`plantilla-guion`** (skill) — Estructura para desarrollo de guiones
2. **`plantilla-personaje`** (skill) — Estructura para creación de personajes
3. **`plantilla-lugar`** (skill) — Estructura para descripción de lugares

### Estructura básica del relato corto

```
1. GANCHO (1-2 párrafos)
   - Situación inicial
   - Presentación de personajes
   - Establecimiento de tono y escenario

2. DESARROLLO (3-6 párrafos)
   - Introducción del conflicto/tensión
   - Escalada de acción
   - Desarrollo de personajes

3. CLÍMAX (2-4 párrafos)
   - Momento de máxima tensión
   - Resolución del conflicto principal
   - Punto de inflexión

4. DESENLACE (1-2 párrafos)
   - Consecuencias
   - Estado final
   - Cierre (abierto o cerrado)
```

### Longitudes recomendadas

| Tipo | Palabras | Párrafos | Escenas |
|------|----------|----------|---------|
| Corto | 1.000-3.000 | 15-30 | 1-3 |
| Medio | 3.000-6.000 | 30-60 | 2-5 |
| Largo | 6.000-10.000 | 60-100 | 4-8 |
| Máximo | 10.000-20.000 | 100+ | 6-12 |

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

### Arco narrativo para relatos eróticos

```
1. TENSIÓN SEXUAL (inicio)
   - Miradas, cercanía física
   - Descripción física atractiva
   - Tensión no resuelta

2. ESCALADA (desarrollo)
   - Primer contacto (no sexual)
   - Aumento de tensión
   - Preliminares emocionales

3. CONTACTO SEXUAL (clímax)
   - Primer contacto sexual
   - Escalada de actos
   - Orgasmo(s)

4. RESOLUCIÓN (desenlace)
   - Consecuencias emocionales
   - Estado de los personajes
   - Cierre (abierto o cerrado)
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

### Escenas clave

Cada escena se compone de **beats** — unidades mínimas de narración que el escritor desarrolla en prosa.

Cada beat debe ser:
- **Factual**: declara QUÉ ocurre físicamente — quién hace qué a quién
- **Ordenado**: sigue el orden cronológico de la escena
- **Sin sensoriales**: temperatura, olfato, textura, emociones internas son del escritor
- **Diálogo solo si es crítico de trama**: marcado con ⚡, máximo 1 por beat

Cada escena debe tener:
- **Ubicación**: Dónde ocurre
- **Personajes**: Quién está presente
- **Objetivo**: Qué avanza la historia
- **Beats**: mínimo 6-10 para relato corto, 8-14 para medio, 12-20 para largo, 15-30 para máximo — añade los que la escena necesite
- **Tensión**: Qué conflicto hay
- **Resultado**: Qué cambia

## Integración con agentes

- El agente `guionista` usa este skill para estructurar el argumento
- El agente `escritor` usa este skill para generar texto bien estructurado
- Los agentes de validación usan este skill como referencia de calidad
