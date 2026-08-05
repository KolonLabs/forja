---
name: validacion-sensorial
description: Criterios de evaluación de riqueza sensorial y detalle gráfico. Úsalo cuando necesites validar la presencia y calidad de los 5 sentidos en el texto.
---

# Validación Sensorial

## Sentidos por tipo de escena

| Tipo de escena | Sentidos prioritarios |
|----------------|----------------------|
| Follando (vaginal) | tacto (presión, calor), oído (sonidos), olfato (sudor) |
| Mamando/chupando | gusto, tacto, oído, olfato |
| Preliminares | tacto (caricias), olfato (perfume), oído (susurros) |
| Follando por el culo | tacto (presión, dolor), oído (gemidos) |
| Correrse | tacto (espasmos), oído (gritos), vista (expresión) |
| Ambiental | vista (escenario), oído (ambiente), olfato (lugar) |

## Criterios de evaluación (1-10)

### 1. Vista (visual)
- ¿Describe colores, luces, sombras?
- ¿Detalla la apariencia física de personajes?
- ¿Describe expresiones faciales y gestos?
- ¿Crea imágenes claras y vívidas?

### 2. Oído (auditivo)
- ¿Describe sonidos ambientales?
- ¿Incluye sonidos de los personajes (gemidos, respiración)?
- ¿Describe sonidos de acciones (contacto corporal, ropa)?
- ¿Usa onomatopeyas cuando es adecuado?

### 3. Tacto (táctil)
- ¿Describe texturas (piel, ropa, superficies)?
- ¿Incluye temperatura (calor corporal, frío del ambiente)?
- ¿Describe presión (apretar, acariciar, meter, clavar)?
- ¿Detalla sensaciones físicas (dolor, placer, cosquillas)?

### 4. Olfato (olfativo)
- ¿Describe olores corporales (sudor, perfume)?
- ¿Incluye olores del ambiente?
- ¿Usa olores para crear atmósfera?
- ¿Los olores son específicos o genéricos?

### 5. Gusto (gustativo)
- ¿Describe sabores cuando es relevante?
- ¿Incluye el gusto de la piel, sudor, fluidos?
- ¿Usa el gusto en escenas de besos/sexo oral?
- ¿Los sabores son específicos?

### 6. Proporción sensorial
- ¿Hay equilibrio entre los sentidos?
- ¿Depende solo de la vista?
- ¿Los sentidos se mezclan bien?
- ¿Cada escena tiene al menos 3 sentidos?

## Scoring

- **< 7**: Pobreza sensorial. Falta detalle. Reescribir.
- **7-8**: Detalle sensorial adecuado. Mejoras menores.
- **9-10**: Inmersión sensorial excelente.

## Regla especial

Si un párrafo solo tiene **1 sentido**, el score máximo es 4.

## Variedad léxica entre beats de la escena

Cuando el director te pase **todos los beats de la escena actual** como contexto (no solo los últimos N), aplica esta regla ampliada:

1. **Repetición en misma escena:** si una misma ancla sensorial (misma palabra o frase descriptiva de un sentido: «zumbido del fluorescente», «olor a café», «susurro del nailon») aparece en **2 o más beats** de la misma escena, márcalo como `repeticion_escena` y baja el score de `variedad_lexica`. Una repetición → aviso. Dos o más → penalización.

2. **Repetición entre escenas consecutivas:** si el beat actual repite una palabra sensorial que ya apareció en los últimos 3 beats (cruza escenas), aplica la misma penalización.

3. **Anclas de escenario:** cada escenario tiene anclas naturales (cocina → nevera, grifo, café; dormitorio → mesilla, sábanas, despertador). El escritor debe variarlas. Si en 4 beats de una cocina aparece 4 veces «el zumbido», hay un problema aunque cada beat sea correcto individualmente.

## Scoring actualizado

| Criterio | Peso |
|----------|------|
| `vista`, `oido`, `tacto`, `olfato`, `gusto` | individuales (0-10) |
| `proporcion` | equilibrio entre los 5 |
| `variedad_lexica` | **penaliza repetición de palabras sensoriales** dentro de la misma escena y entre escenas consecutivas |

## Formato de respuesta

```json
{
  "dimension": "sensorial",
  "score": 0,
  "criterios": {
    "vista": 0,
    "oido": 0,
    "tacto": 0,
    "olfato": 0,
    "gusto": 0,
    "proporcion": 0,
    "variedad_lexica": 0
  },
  "sentidos_presentes": [],
  "sentidos_faltantes": [],
  "palabras_repetidas": [],
  "repeticion_escena": [],
  "sugerencias": []
}
```