---
name: plantilla-draft
description: Formato de borrador de relato por escena con anclas invisibles para correcciones localizadas.
---

# Draft de relato

El draft conserva una prosa continua por escena. Los beats no son secciones de prosa: se localizan mediante comentarios HTML invisibles. Al inicializar componentes, crea solo el título `# Draft — [TÍTULO]`: no adelantes marcadores de escena ni anclas hasta que la escena se haya escrito y validado.

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
6. Durante escritura, las escenas presentes forman un prefijo ordenado de `guion.md`: cada una coincide exactamente en `E_XXXX`, `Salida` y beats, pero pueden faltar escenas futuras.
7. Al publicar, la secuencia completa de marcadores `E_XXXX`, sus `Salida` y los beats contenidos debe coincidir exactamente con `guion.md`; no se admiten escenas ni anclas huérfanas.
8. Tras cada ancla debe existir prosa narrativa real. La ancla sigue siendo invisible y no convierte el tramo en una sección independiente.
