---
name: validacion-geometria
description: Criterios de evaluación de ritmo, fluidez y estructura de frases. Úsalo cuando necesites validar la estructura rítmica del texto.
---

# Validación de Geometría (Ritmo y Fluidez)

## Ritmo por estilo

Tendencias de expresión, no moldes obligatorios ni motivos para cambiar los compromisos del beat. Valorar el pasaje en su escena; una etiqueta no impone una longitud de frase, gesto, silencio o corte.

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
- ¿La distribución de diálogos y narración sirve al pasaje, sin exigir una proporción ni gestos entre réplicas?
- ¿Las acotaciones de diálogo son adecuadas?
- ¿El ritmo de los diálogos es creíble?
- **¿Cada intervención de diálogo está en su propio párrafo, separada de la narración?** — Un diálogo embebido dentro de un párrafo narrativo es un error de formato que penaliza este criterio.
- **¿Las réplicas breves (`—Sí.`, `—Espera.`) tienen párrafo propio y hablante identificable?** Admiten atribuciones o acotaciones pertinentes según `mecanica-prosa`, sin límite por longitud.
- ¿La conversación mantiene continuidad sin reiniciarse por cada heading técnico? Saludos, despedidas y transiciones ordinarias no necesitan beats propios ni pausas o gestos añadidos.

### 6. Párrafos narrativos
- ¿Los párrafos organizan el foco con claridad y cadencia? Acción, sensación, reacción interna o cambio de sujeto pueden compartir párrafo si se siguen sin confusión; no exigir corte por cada cambio de foco.
- ¿El parrafo dificulta seguir el foco o respirar la cadencia? Cita el tropiezo concreto, no un numero de lineas que depende del ancho de pantalla.
- La longitud por si sola no es un defecto: respeta la cadencia acumulativa intencional y los cortes breves con funcion narrativa.
- No deducir nuevos beats de puntos, verbos, párrafos o cambios de tono. Conservar encabezados Markdown, IDs y cuerpos por beat no obliga a fragmentar cada movimiento dramático.

## Scoring

Solo si se solicita expresamente. En la revision por escena se devuelven incidencias concretas; no se reescribe automaticamente por una puntuacion.

- **< 7**: Problemas de ritmo significativos; identificar el fragmento y la causa antes de proponer una correccion.
- **7-8**: Ritmo adecuado. Ajustes menores.
- **9-10**: Excelente fluidez y ritmo.

## Nota de alcance (decisión del director, 2026-09-08)

La EXTENSIÓN TOTAL del beat (número de frases) NO es un criterio de geometría: las etiquetas de `tonos-beat` indican peso narrativo orientativo, no límites numéricos. Evalúa el ritmo INTERNO (variación, cadencia, cortes, párrafos), no conteos ni cuotas. Señala dilución o desproporción con evidencia del pasaje y su función en la escena, no porque una etiqueta BREVE se desarrolle más de lo esperado. No exigir justificaciones o notas del escritor por esas decisiones de ejecución.

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
