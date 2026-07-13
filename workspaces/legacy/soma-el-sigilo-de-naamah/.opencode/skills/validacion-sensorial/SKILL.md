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

## Variedad léxica entre beats

Cuando recibas los beats anteriores como contexto, comprueba si alguna palabra sensorial concreta del beat actual (un olor, una textura, un sonido específico) ya apareció en los últimos 3 beats. Si una misma palabra sensorial se repite en beats consecutivos, penaliza la dimensión `variedad_lexica` aunque cada beat sea individualmente correcto. La repetición de vocabulario sensorial específico es un problema de calidad aunque la densidad sensorial sea alta.

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
  "sugerencias": []
}
```