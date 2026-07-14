---
description: Revisa y ajusta hechos y recurrencias de un relato antes de diseñar beats.
agent: director
---

# /refinar-hechos — Relato

Disponible solo en `diseno`. Lee `_actos.md`, `BRIEF.md` y `config.json`.

- Un hecho lineal debe declarar una acción o cambio narrable.
- Un `[D]` debe tener rango válido, tipo posible (`evento`, `patrón`, `progresión` o `motivo`) e intención reconocible.
- Si una culminación de `[D]` necesita una escena, debe existir un hecho lineal que la respalde.

Presenta problemas concretos. Con aprobación del usuario, ajusta los hechos mediante:

```powershell
pwsh -NoProfile -File scripts/relato-transaccion.ps1 -Accion Preparar -Operacion hechos
```

Trabaja solo en el staging. Conserva los IDs existentes; si la aprobación requiere añadir un hecho, asígnale el siguiente `H_XXXX` y actualiza `config.json.ultimo_hecho_seq` en la misma transacción. Confirma únicamente cuando `_actos.md` y el contador sean consistentes. Desde `fichas` en adelante no modifica hechos: informa del impacto y dirige a una edición estructural cuando corresponda.
