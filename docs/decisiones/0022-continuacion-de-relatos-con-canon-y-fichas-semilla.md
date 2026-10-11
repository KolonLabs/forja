# ADR 0022: Continuación de relatos con canon heredado y fichas semilla

- Estado: aceptada
- Fecha: 2026-10-08
- Ámbito: escala `relato`, scaffolding.
- Relaciona: ADR 0010, ADR 0014, ADR 0015

## Contexto

Una segunda entrega de un relato (por ejemplo, «El tío Vicente — II» a partir de «I») necesita el canon de la primera: personajes, lugares, relaciones y qué sabe cada uno. El brief solo tenía campos narrativos fijos y `new-relato.ps1` creaba `fichas/` vacía, de modo que el canon se perdía o se volcaba en campos que no le caben. Las fichas de la entrega anterior tampoco sirven tal cual: contienen estado y restricciones de esa historia («no descubre nada») e identificadores `E_`/`B_` que no existen en la nueva.

## Decisión

1. El brief admite dos campos opcionales, solo en relato: `canon_previo` (Markdown, se muestra en `BRIEF.md` como «Canon heredado») y `fichas_semilla` (lista de `{ruta, contenido}`).
2. `new-project.ps1` los valida: escala relato, canon no vacío, rutas `fichas/<tipo>_<slug>.md` en minúsculas sin subdirectorios, sin duplicados y con contenido. `new-relato.ps1` las escribe y no sobrescribe.
3. El workspace anterior es evidencia de solo lectura. El scaffolder reconstruye las fichas (conserva continuidad, reinicia estado, reescribe función y uso) y las presenta al usuario antes de crear.
4. Los IDs de la nueva historia empiezan de cero y la anterior se cita por título. Los workspaces siguen siendo autónomos.
5. Las novelas no admiten estos campos: sus entidades viven en Qdrant y no leerían estas fichas.

## Consecuencias

- Una continuación nace con fichas y canon coherentes sin acoplar workspaces.
- La calidad de la reconstrucción depende del scaffolder y de la revisión del usuario; el script solo valida forma y rutas.
- Cubierto por `tests/continuacion-brief-regression.ps1`.
