---
name: validacion-cross-hilo
description: Criterios de validación de coherencia entre hilos narrativos. Detecta contradicciones entre líneas temporales, duplicación de revelaciones y rupturas de continuidad cross-hilo. Úsalo en modo global de novelas multi-hilo.
---

# Skill: validacion-cross-hilo

## Cuándo usar

El validador carga este skill en **modo global** cuando el proyecto es una novela multi-hilo. Se evalúa como un criterio adicional (criterio 7) en la dimensión `coherencia`.

---

## Criterios de validación cross-hilo

### Criterio 1: Consistencia temporal
**¿Los eventos de un hilo respetan lo establecido en otro hilo sobre la misma época/objeto?**

Verificar:
- Fechas: si el hilo-sumer establece que el sello se hizo en 2800 a.C., el hilo-sello no puede decir "hace 2000 años" (serían ~4400, no 2800)
- Duraciones: si el hilo-sello dice que el ritual debía repetirse cada 414 años, el hilo-soma no puede decir 400
- Edad de objetos: si la losa tiene 4800 años en 2026, en 1612 tenía ~4400, no "milenaria"

Score 1-10. Penaliza cada inconsistencia numérica en -2.

---

### Criterio 2: Consistencia de objetos compartidos
**¿Los objetos que aparecen en varios hilos mantienen propiedades y descripciones coherentes?**

Verificar:
- Descripción física: la losa es de basalto negro en Sumer, debe serlo también en 1612 y 2026
- Propiedades: si en Sumer la losa emite frío, en 2026 también debe emitirlo
- Estado: si en 1612 la losa está intacta, en 2026 no puede aparecer agrietada sin explicación

Score 1-10. -2 por cada contradicción en propiedades de objeto compartido.

---

### Criterio 3: Consistencia de personajes cross-hilo
**¿Los personajes que aparecen en varios hilos mantienen coherencia?**

Solo aplica a personajes que trascienden épocas (Naamah, la abadesa como retrato/ancestro).

Verificar:
- Naamah sellada en Sumer → no puede aparecer libre en 1612 o antes de 2026
- La abadesa muere en 1612 (o poco después) → no puede aparecer viva en 2026 salvo como fantasma/sombra
- Si un personaje cambia (Naamah se fortalece, se debilita), el cambio debe ser coherente con los eventos de su hilo

Score 1-10. -3 por cada contradicción de presencia/estado de personaje cross-hilo.

---

### Criterio 4: No duplicación de revelaciones
**¿Una misma información se revela en dos hilos distintos como si fuera nueva?**

Si el lector ya sabe X por el hilo-sumer, y en el hilo-soma Daniel "descubre" X, la narración debe reconocer que es información conocida. El personaje puede descubrirla (él no ha leído el hilo-sumer), pero el narrador no puede actuar sorprendido.

Verificar:
- "Daniel nunca había oído ese nombre" → OK (él no lo sabe)
- "Nadie en el mundo sabía que Naamah..." → FALSO (el lector ya lo sabe por Sumer)
- "Era un secreto que había permanecido oculto durante milenios" → OK si es el personaje quien lo piensa, no el narrador omnisciente

Score 1-10. -1 por cada duplicación no intencionada de revelación.

---

### Criterio 5: Trazabilidad de conexiones
**¿Las conexiones entre hilos son trazables y están documentadas?**

Cada punto de conexión declarado en el guion (`**Puntos de conexión**`) debe ser verificable en el texto:
- Si el guion dice "la losa viaja de Sumer a Hispania", debe haber un beat o capítulo que muestre o mencione ese viaje
- Si dice "Daniel lee sobre el ritual", el texto de la tesis debe reflejar lo que el lector ya vio en Sumer

Score 1-10. -2 por cada punto de conexión declarado pero no verificado en el texto.

---

## Formato de evaluación

En el JSON de salida del validador, añadir un bloque `cross_hilo` dentro de `coherencia`:

```json
{
  "coherencia": {
    "score": 7.2,
    "criterios": {
      "accion_completa": 8,
      "continuidad_fisica": 7,
      "consistencia_personajes": 8,
      "logica_narrativa": 7,
      "coherencia_entidades": 7,
      "cross_hilo": {
        "score": 6.5,
        "criterios": {
          "consistencia_temporal": 7,
          "consistencia_objetos": 8,
          "consistencia_personajes_cross": 6,
          "no_duplicacion_revelaciones": 5,
          "trazabilidad_conexiones": 7
        },
        "problemas": [
          "La losa se describe como 'basalto' en Sumer pero como 'piedra caliza' en B_089",
          "Revelación del origen de Naamah duplicada: B_045 (Sumer) y B_117 (Soma) la presentan como nueva"
        ],
        "sugerencias": [
          "Unificar descripción de la losa: usar siempre 'basalto negro'",
          "En B_117, cambiar el tono de 'descubrimiento' a 'confirmación' — Daniel confirma lo que el lector ya sabe"
        ]
      }
    },
    "contradicciones": [...],
    "entidades_no_declaradas": [...],
    "sugerencias": [...]
  }
}
```

---

## Reglas de prioridad

1. **Contradicción factual** (fechas, propiedades) → bloquear el beat, requiere reescritura
2. **Duplicación de revelación** → sugerencia fuerte, no bloquea el beat pero degrada la experiencia
3. **Punto de conexión no trazable** → advertir, el director decide si añadir escena de transición o aceptar elipsis
