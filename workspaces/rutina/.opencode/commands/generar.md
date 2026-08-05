---
description: Genera o continúa un relato según su estado, usando beats globales y escenas operativas.
agent: director
---

# /generar — Relato

Lee `config.json`, `PIPELINE.md` y `ORQUESTACION.md`. Recupera o retoma un staging pendiente antes de abrir otro. Avanza por el estado actual sin reiniciar fases cerradas.

```text
diseno: H → mapa global B provisionales (patrones y contraste incluidos) → diagnóstico único → E → confirmar diseno
fichas: fichas necesarias → confirmar componentes
escritura: una E completa validada → confirmar escritura por cada llamada
```

El director decide autónomamente dentro del brief. Solo pide dirección si modificaría un hecho, desenlace, restricción o relación fijada. En `correccion`, usa `/corregir`, `/revisar` o `/expandir`; no reinicia el pipeline.

## Gate de publicación (parada blanda)

`/generar` **no publica automáticamente**. Cuando la última `E_XXXX` del guion queda escrita y confirmada, el relato permanece en estado `escritura` y el director **se detiene y cede el control a la persona usuaria**. No ejecuta `/publicar` ni pasa a `finalizado` por su cuenta.

Al detenerse, el director presenta un cierre de fase:

- Confirma que el draft está completo: todas las `E_XXXX` del guion tienen su tramo en `relato-draft.md`, cada `B_XXXX` con su ancla única, y el draft es un prefijo ordenado y continuo.
- Ofrece un resumen breve del draft (número de escenas, y cualquier punto que convenga revisar antes de publicar: continuidad, arco, tiempo verbal, verosimilitud).
- Invita explícitamente a revisar y, si hace falta, a usar `/regenerar`, `/revisar`, `/corregir` o `/expandir` antes de publicar.
- Indica que la publicación es un paso manual y separado: solo cuando la persona usuaria esté conforme, ejecutará `/publicar`, que produce `relato.md` y cierra a `finalizado`.

La publicación nunca es un efecto secundario de `/generar`: es una decisión editorial explícita que la persona usuaria toma tras revisar el draft completo.
