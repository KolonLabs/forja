---
description: "Revisa y ajusta hechos de un relato antes de escribir, en diseño o en fichas."
disable-model-invocation: true
---

# /refinar-hechos — Relato

Disponible en `diseno` y en `fichas`. Lee `_actos.md`, `BRIEF.md` y `config.json`; en `fichas`, también `guion.md`.

- Un hecho debe declarar una acción, un cambio o una secuencia causal narrable.
- Puede incluir una pauta, evolución o ejemplos de contexto si aclaran qué debe hacerse visible; no usa marcas `[D]`, rangos ni instrucciones de colocación.
- Debe distinguir lo innegociable de los ejemplos posibles y dejar una consecuencia narrativa clara.

Presenta problemas concretos. Con aprobación del usuario, ajusta los hechos mediante:

```powershell
pwsh -NoProfile -File scripts/relato-transaccion.ps1 -Accion Preparar -Operacion hechos
```

Trabaja solo en el staging. Conserva los IDs existentes; si la aprobación requiere añadir un hecho, asígnale el siguiente `H_XXXX` y actualiza `config.json.ultimo_hecho_seq` en la misma transacción. Confirma únicamente cuando `_actos.md` y el contador sean consistentes.

## En `fichas`

El guion ya existe y depende de los hechos, así que un cambio obliga a revisar los beats afectados antes de escribir:

1. Antes de modificar, identifica en `guion.md` los `B_XXXX` y `E_XXXX` que realizan cada hecho afectado y presenta el impacto al usuario junto con el cambio propuesto.
2. Con aprobación, prepara `hechos`, edita `_actos.md` en staging y añade los `H_XXXX` modificados o nuevos a `config.json.hechos_revision_pendiente` (lista). Conserva `estado = "fichas"`. No se puede retirar un hecho existente. El helper rechaza la transacción si un hecho cambia sin quedar registrado.
3. A continuación, revisa los beats afectados: pide al guionista en modo `reparar` solo los tramos que realizan esos hechos (con sus escenas vecinas), y un diagnóstico de `auditor-beats` limitado a ese tramo y a los criterios de los hechos modificados.
4. Persiste la revisión con una transacción `guion`: actualiza `guion.md` (y contadores si hay IDs nuevos) y retira de `hechos_revision_pendiente` los hechos cuyos beats ya cumplen. El helper exige que `guion.md` cambie al cerrar una revisión.
5. Mientras `hechos_revision_pendiente` no esté vacía, `componentes` no puede confirmar el paso a `escritura`.

Desde `escritura` en adelante no modifica hechos: informa del impacto y dirige a una edición estructural cuando corresponda.
