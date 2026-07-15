---
description: Revisa un tramo de prosa anclado de un relato sin cambiar su estructura.
agent: director
---

# /revisar — Relato

Solicitud recibida: $ARGUMENTS

Disponible solo en `escritura` o `correccion`. En `diseno` o `fichas`, dirige a `/revisar-guion` o `/generar`. En `finalizado` o `publicado`, indica volver al hub y ejecutar `/nueva-edicion <origen> <slug-edicion>`.

Extrae un `B_XXXX`; si falta, pide esa referencia antes de modificar. Comprueba que su `E_XXXX` ya tiene marcador en `relato-draft.md`. Si aún no fue escrita, explica que `/generar` debe confirmar esa escena primero.

El director prepara `correccion`, normaliza headings heredados solo en staging, localiza la ancla y pasa al integrador instrucción y tramos vecinos. Reemplaza únicamente ese tramo, comprueba acción nuclear, continuidad inmediata y arco tonal, actualiza contexto y `correcciones.md`, y confirma. No cambia hechos, beats ni estructura; si la petición lo exige, dirige a `/corregir estructura <instrucción>`.
