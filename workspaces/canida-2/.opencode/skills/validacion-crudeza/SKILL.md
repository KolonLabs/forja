---
name: validacion-crudeza
description: Criterios de evaluación de explicitud y checklist de eufemismos. Úsalo cuando necesites validar o corregir el nivel de crudeza de un texto.
---

# Validación de Crudeza

## Criterios de evaluación (1-10)

### 1. Ausencia de eufemismos
- ¿Hay términos como "miembro", "senos", "entrepierna"?
- ¿Usa "hacer el amor" en vez de "follar"?
- ¿Evita palabras crudas directamente?
- ¿Usa metáforas donde debería ser directo?

### 2. Vocabulario explícito
- ¿Usa el vocabulario correcto (polla, coño, tetas, follar, correrse)?
- ¿Varía los términos (no repite el mismo más de 2 veces)?
- ¿El vocabulario fluye natural en la narrativa?

### 3. Descripción gráfica
- ¿Describe los actos sexuales con detalle?
- ¿Incluye sensaciones físicas (tacto, temperatura, presión)?
- ¿Describe fluidos y sonidos?
- ¿Detalla la anatomía involucrada?

### 4. Sin rodeos
- ¿Describe directamente lo que pasa?
- ¿Insinúa en vez de describir?
- ¿Hay partes que se saltan o resumen?

## Scoring

- **1-3**: Texto demasiado eufemístico, reescribir con más crudeza
- **4-6**: Aceptable pero mejorable, identificar puntos débiles
- **7-8**: Buen nivel, pequeños ajustes
- **9-10**: Excelente, máximo nivel de explicitud

## Checklist de eufemismos

Si CUALQUIERA es SÍ → score < 7 → reescribir:

- ¿Usa "miembro" en vez de "polla"?
- ¿Usa "senos" en vez de "tetas"?
- ¿Usa "entrepierna" en vez de "coño"?
- ¿Usa "hacer el amor" en vez de "follar"?
- ¿Usa "mantener relaciones"?
- ¿Describe orgasmos como "clímax"?
- ¿Evita describir fluidos?
- ¿Evita describir sonidos explícitos?
- ¿Usa metáforas donde debería ser directo?
- ¿Insinúa en vez de describir?

## Formato de respuesta

```json
{
  "dimension": "crudeza",
  "score": 0,
  "criterios": {
    "ausencia_eufemismos": 0,
    "vocabulario_explicito": 0,
    "descripcion_grafica": 0,
    "sin_rodeos": 0
  },
  "eufemismos_encontrados": [
    {"termino": "", "linea": 0, "correccion": ""}
  ],
  "puntos_debiles": [],
  "sugerencias": []
}
```

## Excepciones permitidas

Solo en estos casos se permite un término menos crudo:
1. **Diálogo de personaje**: Si el personaje habla así por educación/estatus
2. **Contexto médico**: Si un personaje es médico y habla técnicamente
3. **Ironía**: Si el narrador usa un eufemismo de forma irónica
4. **Estilo específico**: Si el estilo pide un nivel menor (ej: romántico)

En cualquier otro caso: **SIEMPRE el término más crudo**.