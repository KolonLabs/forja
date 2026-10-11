---
description: "Genera o continúa un relato según su estado, usando beats globales y escenas operativas."
argument-hint: "[completo]"
disable-model-invocation: true
---

# /generar — Relato

Lee `config.json`, `PIPELINE.md` y `ORQUESTACION.md`. Recupera o retoma un staging pendiente antes de abrir otro. Avanza por el estado actual sin reiniciar fases cerradas.

```text
diseno: H → mapa global B provisionales (patrones y contraste incluidos) → diagnóstico único → E → confirmar diseno
fichas: revisar beats de hechos pendientes (si los hay) → fichas necesarias → confirmar componentes
escritura: una E completa validada → confirmar escritura → parar (por defecto)
           con `completo`: repetir por cada E pendiente hasta cerrar la fase
```

Modo solicitado: $ARGUMENTS

## Escritura: por escena o completo

- **Por defecto** (`/generar` sin argumentos), el director escribe, valida y confirma **una sola** `E_XXXX` y se detiene. Informa de la escena confirmada, las correcciones del validador aplicadas y las observaciones, para que la persona usuaria la revise antes de seguir.
- **`/generar completo`** escribe todas las `E_XXXX` pendientes en orden, sin detenerse entre escenas. Cada escena sigue el mismo ciclo (escritor → validador → integrador si procede) y se confirma en **su propia** transacción `escritura` antes de pasar a la siguiente; nunca se agrupan varias escenas en una transacción.
  - Solo se detiene antes de terminar si una pregunta bloqueante afecta a la escena siguiente, si el validador devuelve un bloqueo factual que el integrador no resuelve o si el helper rechaza una confirmación. En ese caso descarta el staging abierto, conserva las escenas ya confirmadas e informa del motivo.
  - Las observaciones no bloquean: se acumulan y se presentan al final, por escena.
  - Al terminar, informa de las escenas escritas, las correcciones aplicadas en cada una y las observaciones pendientes.
- En fases anteriores (`diseno`, `fichas`) el argumento se ignora: el director cierra la fase en curso y se detiene al entrar en `escritura`.

El director decide autónomamente dentro del brief. Solo pide dirección si modificaría un hecho, desenlace, restricción o relación fijada, o si una duda pendiente puede cambiar esos elementos o condicionar la prosa de una escena aún no escrita: en tal caso presenta la pregunta al inicio y no genera la escena afectada hasta tener respuesta. Las preferencias de ejecución se resuelven autónomamente. En `correccion`, usa `/corregir`, `/revisar` o `/expandir`; no reinicia el pipeline.
