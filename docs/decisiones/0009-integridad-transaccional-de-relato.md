# ADR 0009: Integridad transaccional de relato y ediciones derivadas

- Estado: aceptada
- Fecha: 2026-07-14
- Complementa: ADR 0007 y ADR 0008
- Ámbito: diseño de recurrencias, correcciones, publicación y ediciones derivadas de relato.

## Contexto

La validación posterior del contrato por escena detectó huecos operativos: `cola_d.md` no tenía una creación explícita, las correcciones estructurales solo eran alcanzables tras publicar, la publicación no verificaba la pertenencia de beats a escenas y una edición podía conservar instrucciones obsoletas del workspace de origen.

## Decisión

- Fase 1 usa un mapa lineal provisional de beats. El director comunica el rango que empieza en el contador canónico y prepara `cola_d.md`, `guion.md` y los contadores B/E bajo `.forja-transaccion/siguiente/`; solo el helper local los confirma juntos al cerrar diseño.
- El guionista incorpora el modo `recurrencias`: transforma los `[D]` en entradas de `cola_d.md`. El director la guarda en staging antes de pedir sus inserciones y la cierra al confirmar el guion.
- `/corregir estructura`, `/revisar` y `/expandir` funcionan tanto en `escritura` como en `correccion`; las modificaciones se preparan en staging y confirman guion, draft, contexto, config y registro como conjunto recuperable. `finalizado` y `publicado` solo indican volver al hub para abrir una edición derivada.
- Publicar exige beats `✅`, correspondencia exacta `E_XXXX → salida → B_XXXX` entre guion y draft, y ausencia de IDs huérfanos o marcadores en el manuscrito limpio.
- `scripts/relato-transaccion.ps1` conserva una copia de respaldo antes de aplicar un conjunto. Al reanudar, recupera un commit interrumpido o descarta un staging sin confirmar.
- Una edición derivada recibe `AGENTS.md` y `MAPA.md` regenerados desde el contrato vigente. Puede normalizar headings B y marcadores de escena sin cambiar prosa, pero rechaza guiones que no tengan escenas `E_XXXX`: agrupar una obra antigua exigiría criterio editorial y no es una migración mecánica segura.

## Consecuencias

- Las recurrencias y los contadores tienen un punto único de persistencia ejecutable y una recuperación clara tras una interrupción.
- Una obra no publicada puede corregir su estructura sin tener que publicarse artificialmente.
- Una edición derivada no recibe instrucciones narrativas incompatibles del origen y deja explícito cuándo una migración requiere intervención editorial.

## Referencias

- [ADR 0007](0007-escritura-por-escenas-operativas-en-relato.md)
- [ADR 0008](0008-contratos-ejecutables-de-relato.md)
- [Pipeline de relato](../../shared/pipelines/relato/PIPELINE.md)
- [Helper transaccional](../../shared/pipelines/relato/scripts/relato-transaccion.ps1)
- [Edición derivada](../../scripts/new-edicion-relato.ps1)
