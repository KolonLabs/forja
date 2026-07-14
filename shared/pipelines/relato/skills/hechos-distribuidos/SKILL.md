---
name: hechos-distribuidos
description: Modela recurrencias [D] de relato por función narrativa, no como una cola mecánica de inserciones.
---

# `cola_d.md` — Recurrencias de relato

Un `[D]` describe una recurrencia que atraviesa hechos lineales. `cola_d.md` solo se usa en Fase 1 y se cierra antes de escribir.

## Tipos

| Tipo | Tratamiento |
|---|---|
| `evento` | Apariciones discretas que generan beats. |
| `patrón` | Conducta o presión repetida que genera beats distintos. |
| `progresión` | Cambio gradual con hitos visibles que generan beats. |
| `motivo` | Imagen, atmósfera o eco; no genera beats y pasa como directriz de escena. |

## Entrada

```markdown
## H_0004 — La mentira doméstica

- Tipo: patrón
- Rango: H_0002–H_0007
- Curva: normalidad → presión → evidencia → coste
- Límites: no revelar el mensaje antes de H_0006
- Apariciones candidatas:
  - Tras B_0005: la mentira parece automática.
  - Tras B_0011: exige una acción concreta.
  - Tras B_0018: deja una prueba con coste.
- Estado: pendiente | resuelto | bloqueo
```

Cada aparición debe cambiar su función para lector, personaje o trama. No se fija una cantidad mínima ni máxima.

## Reglas

1. Las anclas son candidatas justificadas, no posiciones ciegas.
2. La consecutividad es una advertencia editorial: puede permitirse un montaje o una escalada con función clara.
3. Un `[D]` no obtiene una escena propia mientras sea patrón; si su culminación necesita una escena, debe estar respaldada por un hecho lineal. Si no existe, el director solicita modificar los hechos.
4. Los motivos se anotan como directrices de las `E_XXXX` pertinentes, sin crear beats.
5. Al resolverse la cobertura, la cola queda cerrada y no forma parte del contexto de escritura.
