---
description: Genera el manuscrito limpio de un relato a partir de sus escenas operativas cerradas.
agent: director
---

# /publicar — Relato

1. Exige que cada `B_XXXX` de `guion.md` tenga una ancla `<!-- B_XXXX -->` en `relato-draft.md` y que no haya anclas huérfanas. Si encuentra headings heredados `## B_XXXX — ...`, los normaliza a anclas sin reescribir prosa antes de comprobar.
2. Escribe `# <config.json.titulo>`.
3. Elimina todas las anclas `<!-- B_XXXX -->`.
4. Para cada marcador `<!-- ESCENA E_XXXX: ... | salida: continua -->`, elimina el marcador sin añadir corte.
5. Para cada marcador con `salida: separador`, escribe `---` una única vez.
6. Verifica que no quedan IDs de control, separadores duplicados ni contenido vacío.

Al completarse, deja `config.json.estado = "finalizado"`. El hub asigna `publicado` al compilar.
