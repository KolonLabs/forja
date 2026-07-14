---
name: contexto-narrativo
description: Memoria local compacta de relato, actualizada por escenas operativas.
---

# Contexto narrativo — Relato

Solo el director escribe `contexto_narrativo.md`.

```markdown
# Contexto narrativo — [título]

## Secuencia actual

### E_0003 — [nombre]
- Delta: [cambio de estado, revelación o continuidad imprescindible]

## Estado acumulado

- [personaje/lugar/objeto]: [estado actual verificable]

## Próxima escena

- E_0004: [elementos necesarios para entrar]
```

- Después de cada `E_XXXX`, añade un delta breve, no un resumen exhaustivo.
- Tras una salida `separador`, compacta los deltas de esa secuencia en `Estado acumulado` y conserva solo lo relevante.
- Las referencias usan `B_XXXX`, `E_XXXX`, nombres y rutas de ficha. No se usan `stable_id`.
