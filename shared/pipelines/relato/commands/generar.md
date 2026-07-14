---
description: Genera o continúa un relato según su estado, usando beats globales y escenas operativas.
agent: director
---

# /generar — Relato

Lee `config.json`, `PIPELINE.md` y `ORQUESTACION.md`. Recupera o retoma un staging pendiente antes de abrir otro. Avanza por el estado actual sin reiniciar fases cerradas.

```text
diseno: H → B provisionales → cola_d propuesta → inserciones [D] → diagnóstico único → E → confirmar diseno
fichas: fichas necesarias → confirmar componentes
escritura: una E completa validada → confirmar escritura por cada llamada
```

El director decide autónomamente dentro del brief. Solo pide dirección si modificaría un hecho, desenlace, restricción o relación fijada. En `correccion`, usa `/corregir`, `/revisar` o `/expandir`; no reinicia el pipeline.
