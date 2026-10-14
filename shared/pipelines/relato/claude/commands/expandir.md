---
description: "Expande un tramo de prosa anclado de un relato sin alterar su acción nuclear."
argument-hint: "<B_XXXX> <enfoque>"
disable-model-invocation: true
---

# /expandir — Relato

Solicitud recibida: $ARGUMENTS

Disponible solo en `escritura` o `correccion`. En `diseno` o `fichas`, dirige a `/revisar-guion` o `/generar`. En `finalizado`, el manuscrito está cerrado: compílalo con `/compilar`; para cambiar el texto después, vuelve al hub y ejecuta `/nueva-edicion <origen> <slug-edicion>`, que exige la obra ya `publicado`. En `publicado`, indica volver al hub y ejecutar `/nueva-edicion <origen> <slug-edicion>`.

Extrae un `B_XXXX`; si falta, pide esa referencia antes de modificar. Solo actúa si la `E_XXXX` correspondiente ya existe en el prefijo de `relato-draft.md`; una escena pendiente se genera antes con `/generar`.

El director prepara `correccion`, normaliza headings heredados solo en staging y entrega al escritor su tramo anclado, vecinos y enfoque. Añade desarrollo sin alterar acción nuclear, hechos, tono de los beats ni salida. Reemplaza el tramo en staging, actualiza contexto, sobrescribe `correcciones.md` con la entrada de esta corrección (skill `contexto-narrativo`), confirma y comprueba continuidad; no usa cuotas de palabras ni puntuaciones. Si la expansión requiere otra acción o un cambio estructural, dirige a `/corregir estructura <instrucción>`.
