---
name: validacion-geometria
description: Criterios de evaluación de ritmo, fluidez y estructura de frases. Úsalo cuando necesites validar la estructura rítmica del texto.
---

# Validación de Geometría (Ritmo y Fluidez)

## Ritmo por estilo

| Estilo | Longitud de frases | Ritmo característico |
|--------|-------------------|---------------------|
| noir | Cortas, cortantes | Rápido, entrecortado |
| erotico | Medianas-largas, pausadas | Lento, sensual |
| thriller | Cortas, urgentes | Rápido, tenso |
| romantico | Fluidas, largas | Suave, ondulante |
| fantasia | Variado | Épico y pausado |
| contemporaneo | Variado, natural | Natural, conversacional |

## Criterios de evaluación (1-10)

### 1. Longitud de frases
- ¿Las frases tienen la longitud adecuada para el estilo?
- ¿Hay variación o todas son iguales?
- ¿Frases demasiado largas que se pierden?
- ¿Frases demasiado cortas que cortan el ritmo?

### 2. Puntuación
- ¿La puntuación guía bien la lectura?
- ¿Hay comas donde deberían ser puntos?
- ¿Los puntos suspensivos se usan bien?
- ¿Los signos de exclamación son adecuados?

### 3. Cadencia
- ¿El texto fluye al leerlo en voz alta?
- ¿Hay cortes bruscos injustificados?
- ¿La cadencia es acorde al momento narrativo?
- ¿Los párrafos tienen un final satisfactorio?

### 4. Transiciones
- ¿Las frases se conectan bien entre sí?
- ¿Los cambios de idea son fluidos?
- ¿Hay saltos bruscos de una idea a otra?
- ¿Las transiciones entre escenas son adecuadas?

### 5. Diálogos
- ¿Los diálogos suenan naturales?
- ¿La distribución de diálogos y narración es equilibrada?
- ¿Las acotaciones de diálogo son adecuadas?
- ¿El ritmo de los diálogos es creíble?
- **¿Cada intervención de diálogo está en su propio párrafo, separada de la narración?** — Un diálogo embebido dentro de un párrafo narrativo es un error de formato que penaliza este criterio.
- **¿Los diálogos ultracortos (`—Más.`, `—Quieto.`, `—No pares.`) están solos en su propio párrafo?**

### 6. Párrafos narrativos
- ¿Los párrafos narrativos respetan los cambios de foco? — Cuando la narración pasa de acción a sensación, de sensación a reacción interna, o de un cuerpo a otro, debe partir en un nuevo párrafo.
- ¿Hay párrafos que superan las 6-7 líneas sin cambiar de foco? — Si es así, es probable que estén fusionando fragmentos que deberían estar separados.
- **Un bloque de más de 8 líneas continuas sin corte es un problema de geometría salvo que la cadencia acumulativa sea intencional y el tono del beat lo justifique.**

## Scoring

- **< 7**: Problemas de ritmo significativos. Reescribir.
- **7-8**: Ritmo adecuado. Ajustes menores.
- **9-10**: Excelente fluidez y ritmo.

## Formato de respuesta

```json
{
  "dimension": "geometria",
  "score": 0,
  "criterios": {
    "longitud_frases": 0,
    "puntuacion": 0,
    "cadencia": 0,
    "transiciones": 0,
    "dialogos": 0
  },
  "problemas": [],
  "sugerencias": []
}
```

## Regla

Cita siempre las frases exactas que tienen problemas de ritmo.