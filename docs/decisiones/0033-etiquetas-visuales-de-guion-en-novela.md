# ADR 0033: Etiquetas visuales de lectura en los guiones de novela

- Estado: aceptada
- Fecha: 2026-10-13
- Ámbito: guiones de novela simple y multi-hilo (`capitulos/*/guion.md`, `hilos/*/cap-*/guion.md`), `persistir-escena.py`, `borrador.ps1`, nuevo `etiquetas-guion.py`, guionista, director, `/revisar`, `/expandir` y skills de formato; obras `renacer-para-perder` y `canida-2`.
- Relaciona: ADR 0018 (identidad opaca en Qdrant y Neo4j), ADR 0019 (narrativa por escena).

## Contexto

En novela, la identidad de beats y escenas es un `stable_id` opaco, invariante en Qdrant y Neo4j: insertar o reordenar no puede cambiarla. Conversar con el director sobre esos identificadores es incómodo («cambia el 4c1e7a2d»). `shared/` se contradecía: `ORQUESTACION.md` y `PIPELINE.md` hablaban de IDs globales `B_NNNN` que no se reutilizan, mientras el guionista decía que el display se deriva del `seq` y nunca se almacena, cosa imposible porque el `seq` de un beat es local a su escena. Cada obra lo resolvió a su manera: `renacer-para-perder` añadió a cada capítulo una tabla `## Mapeo de IDs globales` con números fijos (el beat inyectado del capítulo 9 quedó como `B_0237` entre `B_0231` y `B_0232`); `canida-2` no mostraba ninguno. `/revisar` y `/expandir` aceptaban `B_NNN` sin decir cómo traducirlo.

## Decisión

1. **Etiquetas de lectura.** Cada beat lleva delante `B_NNNN · ` (`⬜ B_0220 · 4c1e7a2d [1] — …`) y cada escena, tras su marcador, un encabezado `### E_NNNN — Nombre`. No son identidad: no se guardan en Qdrant ni en Neo4j ni se pasan a scripts o subagentes como referencia.
2. **Correlativas en orden de lectura y renumerables.** Numeración global de la novela en `capitulos/`, capítulo tras capítulo; en multi-hilo, mientras se trabaja por hilos, cada hilo numera por su cuenta. «Entre B_0015 y B_0022» designa siempre un tramo real.
3. **Las pone un script, no el modelo.** `scripts/etiquetas-guion.py` inserta las que falten, sincroniza el nombre de la escena con su marcador y renumera; es idempotente y tiene `--simular`. El guionista escribe `stable_id [seq]`; el director ejecuta el script tras cada escritura de guion. El script devuelve también las referencias sueltas (etiquetas sin `stable_id`) que han quedado desfasadas, con su etiqueta nueva y su `stable_id`, y el director las revisa en ese momento; no las cambia el script porque pueden ser historial o citar otra obra. `--tabla` da la tabla completa de etiquetas antiguas y nuevas.
4. **Traducción al conversar.** Cuando la persona usuaria cita una etiqueta o un tramo, el director lo traduce al `stable_id` leyendo el guion.
5. **Referencias según el lector.** En archivos para el modelo (`contexto.md`, `cola_d.md`, fichas) se cita solo el `stable_id`, que es lo que entienden Qdrant y Neo4j. En notas para revisión humana (`notas*.md` de cada capítulo) se cita la pareja `B_NNNN · stable_id` (o `E_NNNN · stable_id`), útil para la persona usuaria y para el modelo; `etiquetas-guion.py` actualiza su etiqueta al renumerar (también en las notas del propio guion, y normaliza la forma invertida «`stable_id` (B_NNNN)» a la canónica) y avisa de las que apuntan a un beat que ya no existe.
6. **Analizadores.** `persistir-escena.py` y `borrador.ps1` aceptan la etiqueta opcional y la ignoran; exigen el separador `·`, de modo que una etiqueta mal escrita no se confunde con la identidad.
7. **El `seq` del beat es su posición dentro de la escena** (local al padre), como ya exigía `persistir-escena.py`; los hechos conservan su `seq` global y su display `H_NNNN`.

## Consecuencias

- Insertar, borrar o reordenar beats solo cambia etiquetas en el guion; Qdrant y Neo4j no se tocan.
- Una etiqueta suelta (sin su `stable_id`) queda desfasada al renumerar; por eso las notas citan la pareja, que el script mantiene, y los archivos para el modelo solo el `stable_id`.
- `renacer-para-perder` pierde su tabla de mapeo, sustituida por las etiquetas en línea (renumeradas en orden de lectura); `canida-2` recibe etiquetas por hilo.
- `config.json.ultimo_beat_seq` deja de servir para numerar beats en novela; queda como recuento.
