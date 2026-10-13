---
name: plantilla-guion
description: Plantilla mínima de guion de relato con beats globales y escenas operativas.
user-invocable: false
---

# Guion — [TÍTULO]

El guion se construye en dos pasos: beats globales primero; escenas operativas después. Los `H_XXXX` se validan en diseño, pero no se imprimen en cada beat.

```markdown
## Escenas

### E_0001 — [Nombre]

- Ubicación: [lugar]
- Tiempo y POV: [momento y foco]
- Objetivo: [qué intenta ocurrir]
- Resultado: [qué ha cambiado al cierre]
- Salida: continua | separador

#### Beats

⬜ B_0001 — [acción causal]. [Clínico — MEDIA]
⬜ B_0002 — [acción que modifica la situación]. [Revelación — BREVE]
⬜ B_0003 — [acción en la que la escena se detiene]. [Tenso — EXTENSA]
```

## Reglas

1. Cada `B_XXXX` aparece una sola vez y pertenece a una `E_XXXX`.
2. Los beats de una escena son contiguos.
3. Cada `E_XXXX` es una unidad dramática y de generación manejable; una situación amplia puede abarcar varias escenas operativas.
4. Una salida `continua` no crea separador visible en el manuscrito; `separador` sí.
5. No hay mínimos de beats ni cuotas de palabras. Todo beat lleva `[Tono — EXTENSIÓN]` del catálogo de `tonos-beat`; la extensión es relativa a la escena y nunca lleva cifras.
6. Al dividir una escena, conserva el ID en la primera parte y asigna otro a la siguiente. Al fusionar, conserva el ID de la primera.
