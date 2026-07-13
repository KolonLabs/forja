---
name: validacion-tono
description: Criterios de evaluación de tono narrativo por estilo. Úsalo cuando necesites validar que el tono coincide con el estilo seleccionado.
---

# Validación de Tono

## Estilos y tono esperado

Consulta el skill `estilos-narrativos` para las características completas de cada estilo.

| Estilo | Tono | Crudeza | Ritmo |
|--------|------|---------|-------|
| noir | Cínico, oscuro, fatalista | Alto | Frases cortas |
| romantico | Emotivo, idealizado | Medio | Frases largas |
| erotico | Sensual, explícito | Máximo | Lento, pausado |
| thriller | Tensión constante | Alto | Rápido, cortante |
| fantasia | Épico, inmersivo | Medio | Variado |
| contemporaneo | Urbano, directo | Alto | Natural |

## Criterios de evaluación (1-10)

### 1. Coherencia tonal
- ¿El tono se mantiene consistente con el estilo?
- ¿Hay cambios de tono injustificados?
- ¿El registro lingüístico es adecuado?

### 2. Atmósfera
- ¿El párrafo crea la atmósfera adecuada?
- ¿Las descripciones contribuyen al tono?
- ¿El ambiente se siente acorde al estilo?

### 3. Voz del narrador
- ¿La voz del narrador es consistente?
- ¿El nivel de distancia/implicación es adecuado?
- ¿La perspectiva se mantiene?

### 4. Tensión emocional
- ¿El párrafo transmite la emoción adecuada?
- ¿La intensidad emocional es correcta?
- ¿Los personajes reaccionan acorde al tono?

## Scoring

- **< 7**: Tono inconsistente con el estilo. Reescribir.
- **7-8**: Tono adecuado. Mejoras menores posibles.
- **9-10**: Excelente. El tono calza perfecto con el estilo.

## Formato de respuesta

```json
{
  "dimension": "tono",
  "score": 0,
  "criterios": {
    "coherencia_tonal": 0,
    "atmosfera": 0,
    "voz_narrador": 0,
    "tension_emocional": 0
  },
  "problemas": [],
  "sugerencias": []
}
```

## Regla

Cita siempre las frases exactas que tienen problemas de tono.