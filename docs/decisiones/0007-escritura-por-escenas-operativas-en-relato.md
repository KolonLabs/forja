# ADR 0007: Escritura por escenas operativas en relato

- Estado: aceptada
- Fecha: 2026-07-14
- Complementa y sustituye parcialmente: ADR 0006 en escritura, validación, recurrencias y formato de salida.

## Contexto

ADR 0006 eliminó la identidad opaca y estableció beats globales antes de escenas. La revisión posterior detectó que su ejecución seguía fragmentando la prosa beat a beat, imponía extensiones y auditorías repetidas, y convertía toda escena de trabajo en un separador visible. Eso favorece relleno, pérdida de ritmo y validación orientada a puntuaciones en lugar de calidad narrativa.

## Decisión

- `B_XXXX` sigue siendo la unidad de acción y corrección localizada, pero la unidad de escritura y validación editorial pasa a ser `E_XXXX`.
- Cada `E_XXXX` es una escena operativa manejable. Una situación amplia puede contener varias escenas operativas sin una jerarquía adicional.
- La escena define su arco tonal; un beat usa `[registro: ...]` solo como override. Se eliminan extensiones, cuotas de palabras y mínimos de beats.
- Los beats no contienen etiquetas de hecho ni de recurrencia. La cobertura `H → B` se genera temporalmente en diseño.
- `cola_d.md` modela recurrencias por tipo, curva, límites y función. Se cierra al terminar diseño. Los motivos son directrices de escena, no beats.
- La publicación distingue `Salida: continua` de `Salida: separador`; solo la segunda crea `---`.
- La validación no asigna puntuaciones ni bloquea preferencias estéticas. Los bloqueos quedan reservados a contradicciones factuales o restricciones imposibles.
- Los comandos específicos de relato sobrescriben los genéricos al crear un workspace, para evitar instrucciones de novela o ejemplos contaminantes.

## Consecuencias

- El escritor recibe una escena completa y conserva libertad de ritmo, prosa, sensorialidad y diálogo dentro de las acciones fijadas.
- Los beats siguen permitiendo reemplazos quirúrgicos en correcciones y ediciones derivadas.
- El scaffolding copia `shared/pipelines/relato/commands/` después de los comandos comunes; las otras escalas mantienen sus contratos actuales.
- Los workspaces ya creados no cambian automáticamente.

## Referencias

- [ADR 0006](0006-beats-globales-y-escenas-derivadas-en-relato.md)
- [Pipeline de relato](../../shared/pipelines/relato/PIPELINE.md)
- [Inyección de pipeline](../../scripts/lib/common.ps1)
