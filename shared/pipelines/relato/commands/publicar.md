---
description: Genera el manuscrito limpio de un relato a partir de sus escenas operativas cerradas.
agent: director
---

# /publicar — Relato

1. Lee la secuencia completa de `E_XXXX`, sus beats y su `Salida` en `guion.md`. Exige en `relato-draft.md` un único marcador `<!-- ESCENA E_XXXX: ... | salida: ... -->` por escena, en el mismo orden y con la misma salida.
2. Exige que cada marcador de escena contenga exactamente sus `B_XXXX`, una sola vez y en el mismo orden; rechaza escenas, anclas o beats huérfanos. Si encuentra headings heredados `## B_XXXX — ...`, los normaliza a anclas sin reescribir prosa antes de comprobar.
3. Escribe `# <config.json.titulo>`.
4. Elimina todas las anclas `<!-- B_XXXX -->`.
5. Para cada marcador `<!-- ESCENA E_XXXX: ... | salida: continua -->`, elimina el marcador sin añadir corte.
6. Para cada marcador con `salida: separador`, escribe `---` una única vez.
7. Verifica que no quedan IDs de control, separadores duplicados ni contenido vacío.

Al completarse, deja `config.json.estado = "finalizado"`. El hub asigna `publicado` al compilar.
