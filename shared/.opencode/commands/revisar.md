---
description: Revisa un fragmento de novela con corrección selectiva, candidato verificable y revisión focalizada.
agent: director
---

# /revisar

`/revisar [B_NNNN, E_NNNN, stable_id o descripcion] [instrucciones opcionales]`

1. Resuelve el fragmento y su escena por `stable_id`: una etiqueta `B_NNNN`/`E_NNNN` se traduce leyendo su línea en el guion; no la uses como identidad persistente.
2. Copia la escena aceptada a un candidato sin modificar el draft original. Prepara canon, instruccion y ambos extremos de la transicion.
3. Cambio mecanico exacto: aplica y comprueba el cambio. Correccion de prosa: una llamada al integrador, contexto inline, sin herramientas, solo fragmentos afectados.
4. Ensambla la candidata completa conservando secciones intactas. `persistir-escena.py preparar` comprueba estructura y devuelve hash nuevo.
5. Presenta la escena completa con hash/version y detente en el checkpoint obligatorio de narrativa; espera conformidad explicita del usuario. Despues revision editorial focalizada sobre cambios y transiciones; canon contradictorio exige decision, no inventar una ficha para justificarlo.
6. Solo con ambas aprobaciones para el mismo hash -> `aceptar` -> `sincronizar`; actualiza estados tras exito. Cualquier cambio textual invalida la conformidad anterior y vuelve al checkpoint. Revisar no autoriza generar otra escena o capitulo. Falla de red del mismo texto no exige regeneracion.

Contrato y comandos en `PIPELINE.md` y `ORQUESTACION.md`. No se migran ni reescriben otros capitulos por defecto.
