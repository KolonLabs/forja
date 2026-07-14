---
description: Corrige una edición derivada de relato por escenas y bloques localizados.
agent: director
---

# /corregir — Relato

Solo para `estado = correccion`. Lee `EDICION.md`, `correcciones.md`, `relato-edicion-anterior.md`, guion, draft y contexto.

1. Audita escenas y localiza `E_XXXX`/`B_XXXX` afectados.
2. Para prosa, corrige solo bloques señalados y comprueba continuidad de su escena.
3. Para estructura, actualiza transaccionalmente guion, escenas de draft y contexto desde la primera escena afectada.
4. Al dividir una escena, conserva el ID de la primera parte; al fusionar, conserva el primero. Recalcula `Salida: continua|separador`.
5. Registra alcance, IDs y resultado en `correcciones.md`.

No modifica el manuscrito anterior ni el workspace de origen. `/publicar` finaliza la edición cuando todas las escenas afectadas son coherentes.
