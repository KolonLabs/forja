---
description: Amplía un bloque B_XXXX de relato manteniendo su acción y escena.
agent: director
---

# /expandir — Relato

```text
/expandir B_XXXX [enfoque]
```

Solicitud recibida: $ARGUMENTS

Disponible solo en `escritura` o `correccion`. En `diseno` o `fichas`, dirige a `/revisar-guion` o `/generar`; en `finalizado` o `publicado`, abre primero una edición derivada.

Extrae un `B_XXXX` de la solicitud; si falta, pide esa referencia antes de modificar. El escritor recibe su tramo anclado, la `E_XXXX`, los tramos vecinos y el enfoque. Añade desarrollo sin alterar acción nuclear, hechos, arco tonal ni salida de la escena. El director reemplaza el tramo y comprueba continuidad; no usa cuotas de palabras ni puntuaciones.

Si la expansión requiere otra acción o un cambio estructural, detiene esa modificación y dirige a `/corregir estructura <instrucción>` en el mismo workspace cuando está en `escritura` o `correccion`.
