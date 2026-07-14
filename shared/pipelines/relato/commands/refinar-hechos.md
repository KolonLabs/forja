---
description: Revisa y ajusta hechos de un relato antes de diseñar beats.
agent: director
---

# /refinar-hechos — Relato

Disponible solo en `diseno`. Lee `_actos.md`, `BRIEF.md` y `config.json`.

- Un hecho debe declarar una acción, un cambio o una secuencia causal narrable.
- Puede incluir una pauta, evolución o ejemplos de contexto si aclaran qué debe hacerse visible; no usa marcas `[D]`, rangos ni instrucciones de colocación.
- Debe distinguir lo innegociable de los ejemplos posibles y dejar una consecuencia narrativa clara.

Presenta problemas concretos. Con aprobación del usuario, ajusta los hechos mediante:

```powershell
pwsh -NoProfile -File scripts/relato-transaccion.ps1 -Accion Preparar -Operacion hechos
```

Trabaja solo en el staging. Conserva los IDs existentes; si la aprobación requiere añadir un hecho, asígnale el siguiente `H_XXXX` y actualiza `config.json.ultimo_hecho_seq` en la misma transacción. Confirma únicamente cuando `_actos.md` y el contador sean consistentes. Desde `fichas` en adelante no modifica hechos: informa del impacto y dirige a una edición estructural cuando corresponda.
