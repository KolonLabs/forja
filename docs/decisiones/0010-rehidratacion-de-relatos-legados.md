# ADR 0010: Rehidratación de relatos legados

- Estado: aceptada
- Fecha: 2026-07-14
- Ámbito: operaciones del hub sobre relatos creados antes del contrato vigente.

## Contexto

Un relato legado puede conservar una premisa y unos hechos útiles, pero tener guion, draft, instrucciones y estados incompatibles con el contrato actual de escenas operativas, contadores canónicos e integridad transaccional. Una edición derivada no resuelve ese caso: protege una publicación existente y exige un guion con escenas `E_XXXX`.

## Decisión

El hub ofrece `/rehidratar-relato <origen> <destino> [--actos actual|backup]`.

- Lee únicamente `config.json`, `BRIEF.md` y la semilla de actos seleccionada.
- Trata la semilla como briefing ya documentado: valida las fases 1–5, realiza una Fase 6 editorial nueva y exige confirmación antes de crear.
- Crea siempre un destino con slug distinto, en `diseno`, mediante el creador canónico de relato. Por tanto recibe el pipeline, agentes, skills, comandos, `MAPA.md`, IDs `H_XXXX` y contadores vigentes.
- Nunca modifica el origen ni copia su guion, prosa, fichas, contexto, cola o instrucciones. Un archivado o intercambio posterior es deliberado y externo a la rehidratación.

## Consecuencias

- Un relato legado puede reiniciarse sin contaminar el flujo nuevo con contratos de beats o estados obsoletos.
- La producción existente se conserva solo en el origen o en un archivo que decida la persona usuaria; el resultado narrativo deberá regenerarse.
- No se promete una reconstrucción byte a byte del scaffold histórico: se genera el equivalente funcional del scaffolding vigente y se actualizan fechas y `MAPA.md`.

## Referencias

- [ADR 0001](0001-hub-y-workspaces-aislados.md)
- [ADR 0006](0006-beats-globales-y-escenas-derivadas-en-relato.md)
- [ADR 0008](0008-contratos-ejecutables-de-relato.md)
- [Comando del hub](../../.opencode/commands/rehidratar-relato.md)
