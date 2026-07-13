---
name: validacion-coherencia
description: Criterios de evaluación de consistencia narrativa y lógica interna. Úsalo cuando necesites validar que el texto es coherente con guion, personajes y escena.
---

# Validación de Coherencia

## Criterios de evaluación (1-10)

### 1. Acción completa del beat
- ¿La acción definida en el beat del guión está completamente desarrollada en el texto?
- ¿Se omitió o alteró algún elemento de la acción definida por el guionista?
- ¿El texto desarrolla el beat sin sustituirlo por algo diferente?

### 2. Consistencia de personajes
- ¿El personaje actúa según su personalidad?
- ¿Dice cosas que diría según su perfil?
- ¿Su comportamiento es creíble?
- ¿Respeta sus límites y motivaciones?

### 2. Continuidad física
- ¿Los personajes están donde deberían estar?
- ¿Su posición corporal es consistente (sentado, de pie, etc.)?
- ¿La ropa está correcta (puesta, quitada, etc.)?
- ¿Los objetos están donde deberían?

### 3. Temporalidad
- ¿El tiempo avanza correctamente?
- ¿Hay saltos temporales injustificados?
- ¿Las acciones tienen el orden lógico?
- ¿La duración de las acciones es realista?

### 4. Espacialidad
- ¿El escenario se mantiene consistente?
- ¿Los personajes se mueven de forma lógica?
- ¿Los objetos mencionados existen en el escenario?
- ¿Las distancias y tamaños son coherentes?

### 5. Lógica narrativa
- ¿Lo que pasa tiene sentido con lo anterior?
- ¿Hay contradicciones con lo establecido?
- ¿Las acciones tienen consecuencias lógicas?
- ¿Los diálogos son coherentes con la situación?

### 6. Coherencia de entidades mencionadas vs declaradas (GAP-34 / GAP-36)
- **¿Aparecen en el texto personajes no declarados en el beat?** Compara los nombres propios y pronombres del texto contra `[Personajes: ...]`. Si el texto menciona un personaje, objeto, lugar o hilo NO declarado en las anotaciones del beat, es una **incoherencia de entidad**:
  - **Personaje no declarado en `[Personajes:]`**: el texto lo nombra o actúa, pero no está en el cast del beat
  - **Objeto no declarado en `[Props:]`**: el texto lo usa o menciona, pero no está anotado
  - **Lugar no declarado en `[Zona:]`**: el texto describe otro escenario, o un cambio de ubicación no marcado
  - **Hilo no declarado en `[Hilos:]`**: el texto activa/desarrolla un hilo no anotado en este beat
- **Severidad**:
  - Mención incidental (un personaje que solo pasa por el fondo) → ⚠️ advertencia
  - Participación activa (un personaje que actúa, habla, decide) → ❌ incoherencia seria
  - Activación de hilo no declarado → ❌ incoherencia seria (rompe trazabilidad)
- **Acción si falla**: el validador reporta el hallazgo en la dimensión `coherencia` con score reducido. El director o el usuario decide si (a) actualizar las anotaciones del beat, (b) reescribir el texto para que coincida, o (c) si es error del escritor, descartar la mención
- **Excepción legítima**: las menciones incidentales (un personaje de fondo que pasa) no requieren aparecer en `[Personajes:]` — solo flaggear si tienen participación real

## Scoring

- **< 7**: Incoherencias significativas. Reescribir.
- **7-8**: Coherencia aceptable. Pequeños ajustes.
- **9-10**: Excelente coherencia narrativa.

## Regla especial

Si hay una **contradicción grave** (ej: personaje aparece en dos sitios a la vez, ropa que desaparece), el score máximo es 5.

## Formato de respuesta

```json
{
  "dimension": "coherencia",
  "score": 0,
  "criterios": {
    "accion_completa": 0,
    "consistencia_personajes": 0,
    "continuidad_fisica": 0,
    "temporalidad": 0,
    "espacialidad": 0,
    "logica_narrativa": 0,
    "coherencia_entidades": 0
  },
  "contradicciones": [
    {"tipo": "", "problema": "", "linea": 0, "correccion": ""}
  ],
  "entidades_no_declaradas": [
    {"tipo": "personaje|objeto|lugar|hilo", "mencion": "texto exacto", "severidad": "incidental|activa"}
  ],
  "sugerencias": []
}
```

## Regla

Cita siempre las frases exactas que contradicen lo anterior.