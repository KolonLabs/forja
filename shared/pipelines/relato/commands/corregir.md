---
description: Corrige un relato por escenas y bloques localizados, también en una edición derivada.
agent: director
---

# /corregir — Relato

Disponible en `escritura` y `correccion`. En `escritura`, corrige el workspace en curso; en `correccion`, lee además `EDICION.md`, `correcciones.md` y `relato-edicion-anterior.md`. En ambos casos lee guion, draft y contexto.

Alcance e instrucciones solicitados: $ARGUMENTS

Sin argumento, ejecuta una pasada `completa`. Con `estructura`, limita el trabajo a la corrección estructural indicada; con otro alcance explícito, aplícalo sin inventar requisitos adicionales.

1. Audita escenas y localiza `E_XXXX`/`B_XXXX` afectados.
2. Ejecuta `pwsh -NoProfile -File scripts/relato-transaccion.ps1 -Accion Preparar -Operacion correccion` y trabaja solo en `.forja-transaccion/siguiente/`.
3. Si el draft heredado contiene headings `## B_XXXX — ...`, sustitúyelos allí por las anclas equivalentes antes de corregir prosa.
4. Para prosa, corrige solo tramos señalados por ancla y comprueba continuidad de su escena.
5. Para estructura, actualiza en ese staging guion, escenas de draft, contexto, config y registro desde la primera escena afectada.
6. Al dividir una escena, conserva el ID de la primera parte; al fusionar, conserva el primero. Recalcula `Salida: continua|separador`.
7. Registra alcance, IDs y resultado en el `correcciones.md` de staging y ejecuta `pwsh -NoProfile -File scripts/relato-transaccion.ps1 -Accion Confirmar`.

En una edición derivada no modifica el manuscrito anterior ni el workspace de origen. `/publicar` solo finaliza cuando la obra completa supera sus gates.
