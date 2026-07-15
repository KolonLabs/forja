---
description: Corrige prosa o estructura de un relato en curso o una edición derivada.
agent: director
---

# /corregir — Relato

Disponible en `escritura` y `correccion`. En `correccion`, lee además `EDICION.md`, `correcciones.md` y `relato-edicion-anterior.md`. En ambos estados lee guion, draft y contexto.

Alcance e instrucciones solicitados: $ARGUMENTS

Sin argumento, ejecuta una pasada `completa`. Con `estructura`, limita el trabajo a la corrección estructural indicada; con otro alcance explícito, aplícalo sin inventar requisitos adicionales.

1. Audita escenas y localiza `E_XXXX`/`B_XXXX` afectados. Si la prosa afectada pertenece a una escena aún ausente del draft, no la reescribas: genera primero esa escena.
2. Ejecuta `pwsh -NoProfile -File scripts/relato-transaccion.ps1 -Accion Preparar -Operacion correccion` y trabaja solo en `.forja-transaccion/siguiente/`.
3. Si el draft heredado contiene headings `## B_XXXX — ...`, sustitúyelos allí por las anclas equivalentes antes de corregir prosa.
4. Para prosa, corrige solo tramos señalados por ancla y comprueba continuidad de su escena. Para estructura, actualiza guion, el prefijo ya escrito, contexto y config desde la primera escena afectada.
5. Al dividir una escena, conserva el ID de la primera parte; al fusionar, conserva el primero. Recalcula `Salida: continua|separador`.
6. Crea o actualiza `correcciones.md` en staging con fecha, alcance, IDs y resultado. Confirma; el helper exige registro no vacío y un prefijo de draft válido.

En una edición derivada no modifica el manuscrito anterior ni el workspace de origen. `/publicar` solo finaliza cuando la obra completa supera sus gates.
