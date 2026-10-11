---
description: Genera el manuscrito limpio de la novela a partir de sus capítulos cerrados.
agent: director
---

# /publicar — Novela simple

Disponible en `publicacion`, o en `escritura` si todos los capítulos de `guion-novela.md` están cerrados. En `diseno` o `fichas`, detente: todavía no existe draft. En `finalizado`, informa de que el manuscrito ya está cerrado y se compila con `/compilar`. En `publicado`, no modifiques nada: la obra ya está compilada; para regenerar formatos usa `/compilar`.

**Esto es una operación de formateo, no de reescritura. No generes prosa nueva. No resumas. No condenses. La prosa se copia textualmente del draft.**

## Requisitos previos

1. Cada capítulo de `guion-novela.md` tiene su directorio `capitulos/cap-NN-slug/` con `draft.md`.
2. Todos los beats de cada `guion.md` están `✅`.
3. Cada beat del guion aparece **exactamente una vez** en el `draft.md` de su capítulo, localizado por `stable_id`. Sin beats huérfanos ni duplicados.

Si algún requisito falla, detente y reporta qué capítulo y qué `stable_id` lo incumplen.

## Por cada capítulo

1. Lee `capitulos/cap-NN-slug/draft.md`.
2. Escribe `capitulos/cap-NN-slug/capitulo.md` aplicando estas transformaciones y **ninguna otra**:
   - Encabeza con `# Capítulo NN — Nombre` (nombre desde `guion-novela.md`).
   - Elimina todos los headings de beat `## <stable_id> [<seq>] — ...`.
   - Elimina todos los marcadores de escena `<!-- ESCENA ... -->`.
   - Elimina todas las notas del escritor (`*Nota del escritor: ...*`).
   - Une los párrafos con separación natural.
3. Verifica el capítulo: sin headings `##` residuales, sin comentarios HTML, sin notas del escritor, sin separadores duplicados, archivo > 0 bytes y con prosa real (no solo el título).

## Novela completa

4. Concatena todos los `capitulo.md` en orden → `novela.md` en la raíz del workspace, encabezado por `# <config.json.titulo>`.
5. Gate final: `novela.md` > 0 bytes, un `# Capítulo` por capítulo esperado, sin IDs de control.
6. Deja `config.json.estado = "finalizado"` y actualiza `ultima_modificacion`.

`publicado` lo asigna `/compilar` al compilar la obra. El director nunca escribe ese estado.

## Estructura resultante

```
# Título de la novela

# Capítulo 1 — Nombre
...prosa...

# Capítulo 2 — Nombre
...prosa...
```
