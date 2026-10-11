---
name: validacion-cross-hilo
description: Criterios de validación de coherencia entre hilos narrativos. Detecta contradicciones entre líneas temporales, duplicación de revelaciones y rupturas de continuidad cross-hilo, con incidencias y gravedad. Úsalo en revisión editorial por escena o en modo global de novelas multi-hilo.
user-invocable: false
---

# Skill: validacion-cross-hilo

## Cuándo usar

El validador carga este skill cuando el capítulo revisado tiene **dos o más hilos** (revisión por escena) o en **modo global** al cierre. También puede invocarse como auditoría de guion sobre las costuras ya ensambladas. No sustituye la revisión de la escena: añade los hallazgos de coherencia entre bloques de hilo como incidencias.

Respeta el contrato del consumidor: en prosa se informa sobre el candidato y su hash; en auditoría de guion se devuelve diagnóstico sin exigir hash de candidata inexistente.

---

## Criterios de validación cross-hilo

### Criterio 1: Consistencia temporal

**¿Los eventos de un hilo respetan lo establecido en otro hilo sobre la misma época/objeto?**

Verificar:
- Fechas: si un hilo establece que el sello se hizo en 2800 a.C., otro hilo no puede decir "hace 2000 años" (serían ~4400).
- Duraciones: si un hilo fija que el ritual debía repetirse cada 414 años, otro no puede decir 400.
- Edad de objetos: si la losa tiene 4800 años en 2026, en 1612 tenía ~4400, no "milenaria".

Reportar cada inconsistencia con la cifra exacta y la fuente. Una contradicción factual es `corregir`; si exige reescribir canon ya aceptado, `bloqueante`.

### Criterio 2: Consistencia de objetos compartidos

**¿Los objetos que aparecen en varios hilos mantienen propiedades y descripciones coherentes?**

Verificar:
- Descripción física: la losa es de basalto negro en un hilo; debe serlo también en los demás.
- Propiedades: si en un hilo emite frío, en el otro también debe emitirlo.
- Estado: si está intacta en un hilo, no puede aparecer agrietada en otro sin explicación.

Cada contradicción en propiedades es `corregir`; cita el fragmento y la corrección.

### Criterio 3: Consistencia de personajes cross-hilo

**¿Los personajes que aparecen en varios hilos mantienen coherencia de presencia y estado?**

Solo aplica a personajes que trascienden épocas.

Verificar:
- Presencia: quien está sellado o muerto en un hilo no puede aparecer libre y vivo en otro sin mediación establecida.
- Estado: si un personaje se fortalece o debilita, el cambio debe ser coherente con los eventos de su hilo.
- La misma persona no puede estar en dos lugares incompatibles a la vez sin explicación.

Contradicción de presencia o estado: `corregir`; si rompe el canon estructural, `bloqueante`.

### Criterio 4: No duplicación de revelaciones

**¿Una misma información se revela en dos hilos distintos como si fuera nueva?**

Si el lector ya sabe X por un hilo y en otro el narrador presenta X como descubrimiento inédito, hay duplicación. El personaje puede descubrirla (no leyó el otro hilo); el narrador no puede actuar sorprendido.

Verificar:
- "Daniel nunca había oído ese nombre" → correcto (él no lo sabe).
- "Nadie en el mundo sabía que..." → incorrecto (el lector ya lo sabe).
- "Era un secreto que había permanecido oculto durante milenios" → correcto si lo piensa el personaje, incorrecto como voz del narrador omnisciente.

Reportar la duplicación como `corregir` cuando la narración la presente como nueva; `opcional` cuando sea un eco deliberado mal calibrado.

### Criterio 5: Trazabilidad de conexiones

**¿Las conexiones entre hilos son trazables y están soportadas por el texto?**

Cada punto de conexión declarado en el guion debe ser verificable en el texto o estar diferido con plazo:
- Si el guion dice "la losa viaja de un lugar a otro", debe existir un beat o capítulo que lo muestre, mencione o difiera explícitamente.
- Si un personaje lee sobre un ritual, el texto debe reflejar lo que el lector ya vio.

Un punto de conexión declarado e incumplido sin plan: `corregir`; si es una elipsis deliberada y comprensible, `opcional` o ninguna incidencia.

---

## Formato de salida

Devuelve incidencias con el contrato del validador, marcando el área cross-hilo:

```json
{
  "incidencias": [
    {
      "beat_stable_id": "b117",
      "area": "cross-hilo",
      "gravedad": "corregir",
      "fragmento": "La losa de piedra caliza...",
      "problema": "El objeto se describe como basalto en el hilo A y caliza aquí.",
      "correccion": "Unificar a «basalto negro» según el hilo A."
    }
  ]
}
```

- En prosa: el JSON acompaña al candidato y su `candidato_sha256`.
- En auditoría de guion: diagnóstico sin candidato ni hash, con `stable_id` y evidencia.

---

## Reglas de prioridad

1. **Contradicción factual o de canon** (fechas, propiedades, presencia) → `corregir`; `bloqueante` si exige cambiar canon aprobado.
2. **Duplicación de revelación** → `corregir` si la narración la presenta como nueva; nunca se compensa con una media.
3. **Punto de conexión no trazable** → `corregir` si estaba fijado en el guion; `opcional` si el director puede decidir diferirlo.
4. **Sin incidencias**: no emitir bloques de puntuación ni "todo correcto" extensos.
