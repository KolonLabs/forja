---
description: "Expande un fragmento por criterio editorial, conservando identidades y revisando sus transiciones."
argument-hint: "[B_NNN o stable_id o descripción] [enfoque]"
disable-model-invocation: true
---

# /expandir

`/expandir [B_NNNN, E_NNNN, stable_id o descripcion] [enfoque]`

1. Localiza el fragmento (una etiqueta `B_NNNN`/`E_NNNN` se traduce al `stable_id` leyendo su línea en el guion) y conserva la escena aceptada sin tocarla.
2. Prepara original, guion, enfoque solicitado, canon/voz y las transiciones anterior/posterior, todo inline.
3. Escritor en expansion puntual: sin herramientas ni cuotas de frases, devuelve solo secciones solicitadas con stable_id y seq intactos. No cambia acciones ni canon.
4. Ensambla la candidata con el resto intacto y ejecuta `preparar`. Presenta la escena completa con hash/version y detente en el checkpoint obligatorio de narrativa; espera conformidad explicita del usuario y despues solicita revision focalizada. Integrador solo ante incidencias concretas.
5. Solo con ambas aprobaciones para el mismo hash: `aceptar` -> `sincronizar`; actualiza estados tras exito. Cualquier cambio textual invalida la conformidad anterior y vuelve al checkpoint. Expandir no autoriza generar otra escena o capitulo. No persistas prosa pendiente en Qdrant ni regeneres por un fallo de red.

Contrato y comandos en `PIPELINE.md` y `ORQUESTACION.md`.
