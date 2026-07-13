# ADR 0004: Finalizado, publicación y recompilación de formatos

- Estado: aceptada
- Fecha: 2026-07-13
- Sustituye parcialmente: ADR 0003, únicamente en el contrato de estados de las fuentes y recompilación de formatos.

## Contexto

El estado `publicacion` era demasiado próximo a `publicado` y el pipeline de los workspaces llegaba a usar ambos de forma incompatible. Además, admitir una fuente ya publicada en `/crear-libro` hace indistinguible una compilación inicial de una reedición accidental.

Un libro puede tener varios artefactos de una misma edición —Markdown, EPUB y PDF— y se deben poder añadir o regenerar sin modificar el manuscrito fuente ni sus estados.

## Decisión

Los estados de una obra quedan definidos así:

```text
diseno → fichas → escritura → finalizado → publicado
```

- `finalizado`: el director del workspace ha generado y validado `relato.md` o `novela.md`. El manuscrito está listo para compilar.
- `publicado`: el bibliotecario ha ensamblado correctamente un libro con todas las salidas solicitadas. Es un estado terminal para `/crear-libro`.

`/crear-libro` acepta exclusivamente fuentes en `finalizado`. Ensambla el Markdown congelado, los formatos solicitados y un `manifest.json` de la edición. Solo tras el éxito de todas esas salidas actualiza las fuentes a `publicado`.

Los formatos son artefactos de la misma edición, no nuevas publicaciones. `/recompilar-libro` opera únicamente sobre `publicados/<libro>/<libro>.md` y `manifest.json`: añade o regenera EPUB/PDF y actualiza sus hashes e historial, sin leer ni modificar workspaces.

Una modificación textual posterior o una nueva edición debe ser un flujo explícito futuro; no se infiere al recibir una fuente en `publicado`.

## Consecuencias

- Los directores de las escalas ya migradas nunca asignan `publicado`; la migración de novela simple y multi-hilo queda pendiente.
- `/crear-libro` no puede duplicar silenciosamente una fuente ya incorporada a un libro.
- La recompilación de formatos es reproducible a partir del manuscrito congelado y queda auditada en el manifiesto.
- Relato adopta ya el contrato; novela simple y multi-hilo deberán adoptarlo cuando se revisen sus workflows.

## Referencias

- [ADR 0003](0003-publicacion-y-compilacion.md)
- [crear-libro.ps1](../../scripts/crear-libro.ps1)
- [recompilar-libro.ps1](../../scripts/recompilar-libro.ps1)
- [Pipeline de relato](../../shared/pipelines/relato/PIPELINE.md)
