# ADR 0009: Integridad transaccional de relato y ediciones derivadas

- Estado: aceptada
- Fecha: 2026-07-14
- Complementa: ADR 0007 y ADR 0008
- Ámbito: diseño de recurrencias, correcciones, publicación y ediciones derivadas de relato.

## Contexto

La validación posterior del contrato por escena detectó huecos operativos: `cola_d.md` no tenía una creación explícita, las correcciones estructurales solo eran alcanzables tras publicar, la publicación no verificaba la pertenencia de beats a escenas y una edición podía conservar instrucciones obsoletas del workspace de origen.

## Decisión

- Fase 1 usa un mapa lineal provisional de beats. El director comunica el rango que empieza en el contador canónico; solo el `guion.md` final y los contadores B/E se persisten juntos al cerrar diseño.
- El guionista incorpora el modo `recurrencias`: transforma los `[D]` en entradas de `cola_d.md`. El director persiste la cola antes de pedir sus inserciones y la cierra al persistir el guion.
- `/corregir estructura` funciona tanto en `escritura` como en `correccion`, siempre como actualización transaccional de guion, draft y contexto. `finalizado` y `publicado` requieren antes una edición derivada.
- Publicar exige correspondencia exacta `E_XXXX → salida → B_XXXX` entre guion y draft, además de la ausencia de IDs huérfanos.
- Una edición derivada recibe `AGENTS.md` y `MAPA.md` regenerados desde el contrato vigente. Puede normalizar headings B y marcadores de escena sin cambiar prosa, pero rechaza guiones que no tengan escenas `E_XXXX`: agrupar una obra antigua exigiría criterio editorial y no es una migración mecánica segura.

## Consecuencias

- Las recurrencias y los contadores tienen un punto único de persistencia y una recuperación clara tras una interrupción.
- Una obra no publicada puede corregir su estructura sin tener que publicarse artificialmente.
- Una edición derivada no recibe instrucciones narrativas incompatibles del origen y deja explícito cuándo una migración requiere intervención editorial.

## Referencias

- [ADR 0007](0007-escritura-por-escenas-operativas-en-relato.md)
- [ADR 0008](0008-contratos-ejecutables-de-relato.md)
- [Pipeline de relato](../../shared/pipelines/relato/PIPELINE.md)
- [Edición derivada](../../scripts/new-edicion-relato.ps1)
