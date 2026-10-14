---
description: Genera el manuscrito limpio de un relato a partir de sus escenas operativas cerradas.
agent: director
---

# /publicar — Relato

Disponible solo en `escritura` o `correccion`. En `diseno` o `fichas`, detente: todavía no existe un draft completo. En `finalizado`, informa que el manuscrito ya está cerrado y se compila con `/compilar`. En `publicado`, no modifiques el original: indica que debe volver al hub y usar `/nueva-edicion <origen> <slug-edicion>`.

1. Ejecuta `pwsh -NoProfile -File scripts/relato-transaccion.ps1 -Accion Preparar -Operacion publicar` y trabaja solo en `.forja-transaccion/siguiente/`.
2. Lee allí la secuencia completa de `E_XXXX`, sus beats y su `Salida` en `guion.md`. Exige que todos los beats estén `✅` y que `relato-draft.md` contenga un único marcador `<!-- ESCENA E_XXXX: ... | salida: ... -->` por escena, en el mismo orden y con la misma salida.
3. Exige que cada marcador de escena contenga exactamente sus `B_XXXX`, una sola vez y en el mismo orden; rechaza escenas, anclas o beats huérfanos. Si encuentra headings heredados `## B_XXXX — ...`, los normaliza allí a anclas sin reescribir prosa antes de comprobar.
4. Genera únicamente en `.forja-transaccion/siguiente/relato.md` el título `# <config.json.titulo>` y deja allí `config.json.estado = "finalizado"`; no modifiques el draft vivo.
5. En ese manuscrito de staging, elimina todas las anclas `<!-- B_XXXX -->`.
6. En ese manuscrito, elimina todos los marcadores `<!-- ESCENA E_XXXX: ... -->`. La salida describe cómo **termina** cada escena y el marcador está al **principio**: no lo sustituyas por el corte, que quedaría una escena antes de su sitio.
7. Tras cada escena con `salida: separador`, salvo la última, añade una línea `---` entre líneas en blanco, justo antes del primer párrafo de la escena siguiente; las escenas `continua` enlazan con la siguiente sin corte. El helper rechaza separadores que falten, sobren o estén fuera de sitio.
8. Verifica que no quedan IDs de control, separadores duplicados ni contenido vacío. El helper exige además título y prosa real, no solo una cabecera, antes de ejecutar `pwsh -NoProfile -File scripts/relato-transaccion.ps1 -Accion Confirmar`. No escribas `relato.md` ni `config.json` vivos directamente.

`publicado` lo asigna `/compilar` al compilar la obra.
