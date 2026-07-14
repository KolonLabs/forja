# ADR 0008: Contratos ejecutables y borrador por escena en relato

- Estado: aceptada
- Fecha: 2026-07-14
- Complementa: ADR 0006 y ADR 0007
- Ámbito: creación, edición derivada e inyección de workspaces de relato.

## Contexto

La revisión del flujo de relato detectó tres desajustes entre su contrato narrativo y su ejecución: `_actos.md` no materializaba IDs de hecho, se inyectaban skills de novela incompatibles y el draft almacenaba headings por beat pese a que el escritor ya generaba una escena completa.

## Decisión

- El script de creación asigna `H_XXXX` globales al escribir `_actos.md`. Los contadores `ultimo_hecho_seq`, `ultimo_beat_seq` y `ultimo_escena_seq` son canónicos; nunca se reconstruyen desde IDs activos ni se reutilizan IDs retirados.
- Relato recibe una allowlist de skills comunes: el nombre `mecanica-prosa` y solo los estilos activos. La versión de relato de `mecanica-prosa` sobrescribe la global para impedir que contratos de prosa por beat contaminen la escritura por escena. Todo contrato de guion, ficha, contexto o validación procede de `shared/pipelines/relato/skills/`.
- `relato-draft.md` guarda una prosa continua por `E_XXXX`. Cada beat se localiza con una ancla invisible `<!-- B_XXXX -->`, no con un heading ni con una prosa independiente.
- `/publicar` elimina las anclas. Una edición derivada normaliza automáticamente los headings heredados sin cambiar la prosa antes de iniciar la corrección.
- Todo comando que acepte argumentos los declara con `$ARGUMENTS` para que OpenCode los entregue al director o al bibliotecario.

## Consecuencias

- El escritor conserva continuidad de escena y libertad expresiva; el director mantiene localización quirúrgica por beat.
- El validador de relato no hereda puntuaciones, etiquetas de hilos, cronista ni infraestructura de novela.
- Los workspaces ya creados no se migran en bloque. Las ediciones derivadas sí adoptan el formato de anclas al abrirse.

## Referencias

- [ADR 0006](0006-beats-globales-y-escenas-derivadas-en-relato.md)
- [ADR 0007](0007-escritura-por-escenas-operativas-en-relato.md)
- [Inyección de pipeline](../../scripts/lib/common.ps1)
- [Edición derivada](../../scripts/new-edicion-relato.ps1)
