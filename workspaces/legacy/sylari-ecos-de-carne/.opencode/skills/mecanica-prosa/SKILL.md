---
name: mecanica-prosa
description: Mecánica invariable de formato narrativo: guiones de diálogo (—), división de párrafos, líneas críticas (⚡), cursiva interior. Sin vocabulario ni crudeza. El escritor y el integrador lo cargan siempre.
compatibility: opencode
---

# Skill: mecanica-prosa

## Qué es

Define la mecánica invariable de formato para cualquier prosa narrativa. No contiene vocabulario, estilo ni reglas de crudeza — solo formato. Es agnóstico al contenido.

---

## Formato de diálogo

### Párrafo independiente

Cada intervención de diálogo va en su propio párrafo, separado de la narración por una línea en blanco. Con guion largo (—).

```
Fernando se puso en pie con los hombros tensos.

—Cállate —dijo, y la miró fijo.
```

Diálogos ultracortos (`—Métela.`, `—Más.`, `—No pares.`) van solos en su párrafo, sin acotación salvo atributo brevísimo (`—Más —dijo ella.`).

### Líneas críticas (⚡)

Si el beat del guion contiene una línea marcada con ⚡, esa frase exacta DEBE aparecer en el texto. Puede expandirse con acotación o reacción, pero la frase en sí no se altera.

### Reflexión interior en cursiva

Los pensamientos del personaje se escriben en cursiva, en párrafo propio:

```
Daniel apartó la vista de la losa.

*No es tinnitus. Es ella.*
```

---

## División de párrafos narrativos

Partir en párrafo nuevo cuando la narración cambia de foco:
- Acción → sensación
- Sensación → reacción interna
- Un cuerpo → otro cuerpo

Si un párrafo supera 6-7 líneas, buscar el cambio de foco y partir.

---

## Nota del escritor

Cuando el escritor toma una decisión que se desvía del beat original (extensión, contenido, ritmo), lo documenta al final del texto, entre el último párrafo y el siguiente heading:

```markdown
*Nota del escritor: extendí de BREVE a MEDIA por clímax emocional.*
```

Esta nota se elimina en `/publicar`. Sirve para trazabilidad durante el pipeline.

---

## Estructura del beat generado

### Beat normal
```
## B_XX — Acción breve

...texto del beat...
```

### Primer beat de escena nueva
```
<!-- ESCENA N: Nombre -->

## B_XX — Acción breve

...texto del beat...
```
