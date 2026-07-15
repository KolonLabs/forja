---
description: Genera o continúa un relato según su estado, usando beats globales y escenas operativas.
agent: director
---

# /generar — Relato

Lee `config.json`, `PIPELINE.md` y `ORQUESTACION.md`. Recupera o retoma tú mismo un staging pendiente antes de abrir otro. Avanza por el estado actual sin reiniciar fases cerradas. La recuperación correcta es interna: no delegues ese comando al usuario.

```text
diseno: H → mapa global B provisionales (patrones y contraste incluidos) → diagnóstico único → E → confirmar diseno
fichas: fichas necesarias → confirmar componentes
escritura: recorrer todas las E pendientes en orden; una E completa validada → confirmar su transacción → continuar automáticamente con la siguiente
```

El director decide autónomamente dentro del brief. En `escritura`, no termina tras una confirmación normal ni pide otra invocación para continuar: solo se detiene ante un bloqueo factual, una restricción imposible, un fallo de herramienta o una interrupción externa. Solo pide dirección si modificaría un hecho, desenlace, restricción o relación fijada. En `correccion`, usa `/corregir`, `/revisar` o `/expandir`; no reinicia el pipeline.
