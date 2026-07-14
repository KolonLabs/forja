# ADR 0005: Ediciones derivadas para relatos publicados

- Estado: aceptada
- Fecha: 2026-07-13
- Complementa: ADR 0004

## Contexto

ADR 0004 separó una recompilación de formatos de una modificación textual, pero dejó pendiente el camino para corregir una obra ya publicada. Reabrir su workspace original rompería la inmutabilidad de la publicación y haría imposible saber qué contenido produjo cada libro.

## Decisión

Un relato en estado `publicado` solo puede cambiar de contenido mediante una edición derivada creada por `/nueva-edicion`.

El comando crea otro workspace de relato, en estado `correccion`, con los materiales de trabajo necesarios (`guion.md`, fichas, `relato-draft.md` y contexto) y el siguiente linaje en `config.json.edicion`:

- número de edición;
- obra raíz y workspace de origen;
- motivo y fecha de creación;
- nombre y hash de `relato-edicion-anterior.md`.

El manuscrito publicado anterior se conserva como `relato-edicion-anterior.md` y no se modifica. Las correcciones se aplican al draft mediante `/corregir`, `/revisar` o `/expandir`, se registran en `correcciones.md` y vuelven a pasar por `/publicar`. El resultado queda en `finalizado` y se compila con un slug de libro distinto mediante `/crear-libro`.

`/recompilar-libro` continúa limitado a los formatos de una misma edición y verifica el hash del Markdown congelado.

## Consecuencias

- Cada edición conserva un workspace, manifiesto de libro y manuscrito de origen distinguibles.
- No existe una transición de vuelta desde `publicado` al workspace original.
- La primera implementación cubre únicamente relatos; novela simple y multi-hilo se migrarán en sus revisiones específicas.

## Referencias

- [ADR 0004](0004-finalizado-y-recompilacion-de-formatos.md)
- [Script de edición derivada](../../scripts/new-edicion-relato.ps1)
- [Pipeline de relato](../../shared/pipelines/relato/PIPELINE.md)
