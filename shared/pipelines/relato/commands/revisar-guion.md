---
description: Audita y, antes de escribir, ajusta el guion de relato con beats globales y escenas operativas.
agent: director
---

# /revisar-guion — Relato

En `diseno`, todavía no existe un guion canónico: lee `_actos.md`, `BRIEF.md` y `config.json`, informa de problemas de hechos y de contexto insuficiente para el diseño de beats, y dirige a `/generar`. Los hechos solo cambian con autorización.

En `fichas`, lee además `guion.md`. Comprueba cobertura causal, atomicidad sin prosa, intercalado de patrones con beats de contraste, agrupación de `E_XXXX`, tono y extensión de cada beat y `Salida`. Aplica autónomamente las reparaciones que respeten el brief mediante:

```powershell
pwsh -NoProfile -File scripts/relato-transaccion.ps1 -Accion Preparar -Operacion guion
```

Trabaja solo en `.forja-transaccion/siguiente/`, conserva `config.json.estado = "fichas"` y confirma. Solicita dirección solo si cambiaría un hecho, desenlace, restricción o relación fijada; si el usuario lo autoriza, el hecho se ajusta con `/refinar-hechos` antes de revisar el guion.

Si `config.json.hechos_revision_pendiente` contiene hechos, la revisión de sus beats es prioritaria: repara solo los tramos que los realizan, pide el diagnóstico de `auditor-beats` sobre ese tramo y, en la misma transacción `guion`, retira de la lista los hechos ya cubiertos.

En `escritura` o `correccion`, es auditoría: una corrección estructural se realiza con `/corregir estructura <instrucción>`. En `finalizado`, el manuscrito está cerrado: compílalo con `/compilar`; para cambiar el texto después, vuelve al hub y ejecuta `/nueva-edicion <origen> <slug-edicion>`, que exige la obra ya `publicado`. En `publicado`, indica volver al hub y ejecutar `/nueva-edicion <origen> <slug-edicion>`.
