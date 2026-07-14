---
description: Corrige un bloque B_XXXX concreto de un relato sin reabrir su estructura.
agent: director
---

# /revisar — Relato

```text
/revisar B_XXXX [instrucción]
```

Solicitud recibida: $ARGUMENTS

Disponible solo en `escritura` o `correccion`. En `diseno` o `fichas`, dirige a `/revisar-guion` o `/generar`: todavía no existe un tramo de prosa anclado. En `finalizado` o `publicado`, abre primero una edición derivada.

Extrae un `B_XXXX` de la solicitud; si falta, pide esa referencia antes de modificar. El director localiza su ancla `<!-- B_XXXX -->` dentro de la `E_XXXX`, pasa al integrador la instrucción y los tramos vecinos, y reemplaza solo ese tramo. Comprueba acción nuclear, continuidad inmediata y arco tonal; no asigna notas numéricas.

No cambia hechos, beats ni estructura. Si la petición lo exige, dirige a `/corregir estructura <instrucción>` en el mismo workspace cuando está en `escritura` o `correccion`.
