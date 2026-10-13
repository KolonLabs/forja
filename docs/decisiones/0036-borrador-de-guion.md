# ADR 0036: Borrador de guion para revisión humana

- Estado: aceptada
- Fecha: 2026-10-13
- Ámbito: `shared/scripts/borrador.ps1`, comando `/borrador` (ambos entornos), guías de las tres escalas.
- Relaciona: ADR 0028 (borradores de revisión), ADR 0031 (salida en `publicacion/borrador/prosa/`), ADR 0033 (etiquetas visuales de guion), ADR 0035 (tonos).

## Contexto

`/borrador` solo producía prosa. Para revisar un guion había que leer `guion.md`, con estados, `stable_id`, `seq`, etiquetas de tono, personajes, zona e hilos en cada línea: incómodo para una lectura humana. Las etiquetas visuales `B_NNNN` y `E_NNNN` (ADR 0033) existen para que la persona usuaria comente beats concretos con el director.

## Decisión

1. **`/borrador --guion`** genera una versión de lectura del guion en `publicacion/borrador/guion/`, con el mismo mecanismo que la prosa: Markdown con manifiesto, o solo los formatos pedidos con `--epub` o `--pdf`. Nunca cambia el estado ni toca el guion.
2. **Contenido por defecto:** cada escena con su etiqueta y nombre (`## E_0031 — La planta`) y cada beat con su etiqueta visual y su acción (`**B_0220** Ana borra el aviso…`). Sin estados, `stable_id`, `seq`, etiquetas de tono, notas ni literalidad ⚡. Un beat sin etiqueta visual sale sin ella y el script avisa de que conviene ejecutar `etiquetas-guion.py`.
3. **`--anotado`** añade los datos de cada escena (ubicación, objetivo, personajes, zona…), la literalidad ⚡ y, tras cada beat, sus etiquetas (`[Tono — EXTENSIÓN]`, personajes, zona, hilos, `[elipsis]`). Se guarda con otro nombre (`…-guion-anotado-borrador`), así que no sustituye a la versión limpia.
4. **Alcance:** en relato, el guion completo. En novela, un único capítulo: el indicado con `cap-NN` o, sin él, el capítulo en curso, que para el guion es el primero con beats pendientes (si todos están cerrados, el último con guion). Si el capítulo indicado no tiene `guion.md`, falla. En multi-hilo se usan los capítulos ensamblados de `capitulos/`; antes del ensamblaje, los de un hilo con `--hilo <hilo>`, que solo es obligatorio si hay más de un hilo con guion.
5. **La estructura** (`_actos.md`, `guion-novela.md`) queda para una fase posterior.

## Consecuencias

- La persona usuaria puede leer un guion en el formato que prefiera y comentar beats por su etiqueta, que es la misma que ve el director.
- `--anotado` y `--hilo` solo se aceptan con `--guion`; `--hilo` solo en multi-hilo.
