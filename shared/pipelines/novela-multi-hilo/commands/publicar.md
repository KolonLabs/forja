---
description: Genera el manuscrito limpio de la novela multi-hilo a partir de sus capítulos cerrados.
agent: director
---

# /publicar — Novela multi-hilo

Disponible en `publicacion`, o en `escritura` si todos los capítulos de la tabla de Trenzado están cerrados. En `diseno`, `diseno_hilos`, `trenzado` o `fichas`, detente: todavía no existe draft. En `finalizado`, informa de que el manuscrito ya está cerrado. En `publicado`, no modifiques nada: el libro ya se compiló desde el hub.

**Esto es una operación de formateo, no de reescritura. No generes prosa nueva. No resumas. No condenses. La prosa se copia textualmente del draft.**

## Requisitos previos

1. Cada capítulo de la tabla `## Trenzado` de `guion-novela.md` tiene su directorio `capitulos/cap-NN-slug/` con `draft.md`.
2. Todos los beats de cada `guion.md` están `✅`.
3. Cada beat del guion aparece **exactamente una vez** en el `draft.md` de su capítulo, localizado por `stable_id`. Sin beats huérfanos ni duplicados.

Si algún requisito falla, detente y reporta qué capítulo y qué `stable_id` lo incumplen.

## Por cada capítulo

1. Crea backup de `draft.md` antes de derivar nada.
2. Lee `capitulos/cap-NN-slug/draft.md`.
3. Escribe `capitulos/cap-NN-slug/capitulo.md` aplicando estas transformaciones y **ninguna otra**:
   - Encabeza con `# Capítulo NN — Nombre` (nombre desde la tabla de Trenzado).
   - Elimina todos los headings de beat `## <stable_id> [<seq>] — ...`.
   - Elimina todos los marcadores de escena `<!-- ESCENA ... -->`.
   - Elimina todas las notas del escritor (`*Nota del escritor: ...*`).
   - **Conserva** los separadores `---` entre bloques de hilo en capítulos puente. Son estructura narrativa visible, no marcas de control.
   - Une los párrafos con separación natural.
4. Verifica el capítulo: sin headings `##` residuales, sin comentarios HTML, sin notas del escritor, archivo > 0 bytes y con prosa real (no solo el título).

## Novela completa

5. Concatena todos los `capitulo.md` en orden de la tabla de Trenzado → `novela.md` en la raíz del workspace, encabezado por `# <config.json.titulo>`.
6. Gate final: `novela.md` > 0 bytes, un `# Capítulo` por capítulo esperado, sin IDs de control.
7. Deja `config.json.estado = "finalizado"` y actualiza `ultima_modificacion`.

El hub asigna `publicado` al compilar con `/crear-libro`. El director nunca escribe ese estado.

## Estructura resultante

```
# Título de la novela

# Capítulo 1 — Nombre
...prosa...

# Capítulo 2 — Nombre
...prosa del hilo A...

---

...prosa del hilo B...
```
