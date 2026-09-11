---
description: Expande un tramo de prosa anclado de un relato sin alterar su acción nuclear.
agent: director
---

# /expandir — Relato

Solicitud recibida: $ARGUMENTS

Disponible solo en `escritura` o `correccion`. En `diseno` o `fichas`, dirige a `/revisar-guion` o `/generar`. En `finalizado` o `publicado`, indica volver al hub y ejecutar `/nueva-edicion <origen> <slug-edicion>`.

Extrae un `B_XXXX`; si falta, pide esa referencia antes de modificar. Solo actúa si la `E_XXXX` correspondiente ya existe en el prefijo de `relato-draft.md`; una escena pendiente se genera antes con `/generar`.

El director prepara `correccion`, normaliza headings heredados solo en staging y entrega al escritor su tramo anclado, vecinos y enfoque. Añade desarrollo sin alterar acción nuclear, hechos, arco tonal ni salida. Reemplaza el tramo en staging, actualiza contexto y `correcciones.md`, confirma y comprueba continuidad; no usa cuotas de palabras ni puntuaciones. Si la expansión requiere otra acción o un cambio estructural, dirige a `/corregir estructura <instrucción>`.
