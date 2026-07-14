---
description: Corrige una edición derivada de relato por escenas y bloques localizados.
agent: director
---

# /corregir — Relato

Solo para `estado = correccion`. Lee `EDICION.md`, `correcciones.md`, `relato-edicion-anterior.md`, guion, draft y contexto.

Alcance e instrucciones solicitados: $ARGUMENTS

Sin argumento, ejecuta una pasada `completa`. Con `estructura`, limita el trabajo a la corrección estructural indicada; con otro alcance explícito, aplícalo sin inventar requisitos adicionales.

1. Audita escenas y localiza `E_XXXX`/`B_XXXX` afectados.
2. Si el draft heredado contiene headings `## B_XXXX — ...`, sustitúyelos por las anclas equivalentes antes de corregir prosa.
3. Para prosa, corrige solo tramos señalados por ancla y comprueba continuidad de su escena.
4. Para estructura, actualiza transaccionalmente guion, escenas de draft y contexto desde la primera escena afectada.
5. Al dividir una escena, conserva el ID de la primera parte; al fusionar, conserva el primero. Recalcula `Salida: continua|separador`.
6. Registra alcance, IDs y resultado en `correcciones.md`.

No modifica el manuscrito anterior ni el workspace de origen. `/publicar` finaliza la edición cuando todas las escenas afectadas son coherentes.
