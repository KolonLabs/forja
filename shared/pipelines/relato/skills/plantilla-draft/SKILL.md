---
name: plantilla-draft
description: Formato de borrador de relato por escena con anclas invisibles para correcciones localizadas.
---

# Draft de relato

El draft conserva una prosa continua por escena. Los beats no son secciones de prosa: se localizan mediante comentarios HTML invisibles.

```markdown
# Draft — [TÍTULO]

<!-- ESCENA E_0001: [nombre] | salida: continua -->
<!-- B_0001 -->
Prosa que inicia la escena y realiza la primera acción.
<!-- B_0002 -->
La misma prosa continúa y realiza la siguiente acción.
```

## Reglas

1. Cada escena tiene un único marcador `ESCENA` y una prosa cohesionada.
2. Cada beat tiene una única ancla `<!-- B_XXXX -->`, situada antes del primer pasaje que realiza su acción.
3. Las anclas no son headings, no añaden pausas narrativas y se eliminan al publicar.
4. El tramo de un beat va desde su ancla hasta la siguiente; puede continuar una frase o un párrafo iniciado antes si la continuidad lo exige.
5. Un draft legado con `## B_XXXX — ...` se normaliza sustituyendo cada heading por la ancla equivalente, sin reescribir prosa.
