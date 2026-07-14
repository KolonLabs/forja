---
description: Audita y, antes de escribir, ajusta el guion de relato con beats globales y escenas operativas.
agent: director
---

# /revisar-guion — Relato

En `diseno`, todavía no existe un guion canónico: lee `_actos.md`, `BRIEF.md` y `config.json`, informa de problemas de hechos o recurrencias y dirige a `/generar`. Los hechos solo cambian con autorización.

En `fichas`, lee además `guion.md` y `cola_d.md`. Comprueba cobertura causal, atomicidad sin prosa, agrupación de `E_XXXX`, arcos tonales y `Salida`. Aplica autónomamente las reparaciones que respeten el brief mediante:

```powershell
pwsh -NoProfile -File scripts/relato-transaccion.ps1 -Accion Preparar -Operacion guion
```

Trabaja solo en `.forja-transaccion/siguiente/`, conserva `config.json.estado = "fichas"` y la cola cerrada, y confirma. Solicita dirección solo si cambiaría un hecho, desenlace, restricción o relación fijada.

En `escritura` o `correccion`, es auditoría: una corrección estructural se realiza con `/corregir estructura <instrucción>`. En `finalizado` o `publicado`, indica volver al hub y usar `/nueva-edicion <origen> <slug-edicion>`.
