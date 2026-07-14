---
description: Corrige un bloque B_XXXX concreto de un relato sin reabrir su estructura.
agent: director
---

# /revisar — Relato

```text
/revisar B_XXXX [instrucción]
```

Solicitud recibida: $ARGUMENTS

Extrae un `B_XXXX` de la solicitud; si falta, pide esa referencia antes de modificar. El director localiza su ancla `<!-- B_XXXX -->` dentro de la `E_XXXX`, pasa al integrador la instrucción y los tramos vecinos, y reemplaza solo ese tramo. Comprueba acción nuclear, continuidad inmediata y arco tonal; no asigna notas numéricas.

No cambia hechos, beats ni estructura. Si la petición lo exige, informa de que necesita una corrección estructural. En `finalizado` o `publicado`, crea una edición derivada antes de modificar contenido.
