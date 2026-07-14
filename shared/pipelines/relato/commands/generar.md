---
description: Genera o continúa un relato según su estado, usando beats globales y escenas operativas.
agent: director
---

# /generar — Relato

Lee `config.json`, `PIPELINE.md` y `ORQUESTACION.md`. Avanza por el estado actual sin reiniciar fases cerradas.

```text
diseno: H → B lineales provisionales → cola_d persistida → inserciones [D] → diagnóstico único → E → guion y contadores atómicos
fichas: fichas necesarias + memoria local
escritura: una E completa por llamada al escritor
```

El director decide autónomamente dentro del brief. Solo pide dirección si modificaría un hecho, desenlace, restricción o relación fijada. En `correccion`, usa `/corregir`, `/revisar` o `/expandir`; no reinicia el pipeline.
