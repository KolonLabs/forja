---
name: hechos-estructura
description: Estructura y criterios para definir hechos narrativos (H_NNNN) en guiones de novela. Úsalo cuando el guionista necesite crear o revisar la distribución de hechos en capítulos.
---

# Skill — Estructura de Hechos

Los **hechos** (`H_NNNN`) son unidades narrativas intermedias que agrupan beats relacionados bajo un evento central. Son exclusivos de novelas — los relatos no usan hechos, solo beats directos.

## Qué es un hecho

Un hecho narrativo es el **evento concreto** que ocurre en un bloque narrativo. No es una descripción de escena ni un resumen de intenciones: es algo que pasa, tiene consecuencia y puede agrupar 3-8 beats.

```
- ⬜ H_0001 — Elena recibe la carta de su hermano desaparecido
  - ⬜ B_0001 — Lee el sobre con manos temblorosas `[Tenso — BREVE]`
  - ⬜ B_0002 — Reconoce la letra pero no el remitente `[Clínico — MEDIA]`
  - ⬜ B_0003 — Tira la carta al suelo. ⚡ "No puede ser él" `[Revelación — EXTENSA]`
```

## Reglas fundamentales

- **Un sujeto o grupo de sujetos que actúan o son afectados** en el hecho
- **Un evento concreto con consecuencia narrativa**: algo cambia después del hecho
- **IDs globales de 4 dígitos** (`H_0001`, `H_0002`...) — nunca se reinician entre capítulos
- **3-8 beats por hecho** como referencia. Hechos con 1-2 beats son demasiado granulares; con más de 10, demasiado extensos
- **12-20 hechos por capítulo** como referencia (junto con los 12-18 beats por hecho = 150-360 beats por capítulo)

## Qué debe tener un hecho

- **Sujeto claro** (quién actúa o recibe la acción)
- **Verbo de acción narrativa** en infinitivo o presente
- **Especificidad**: no "hablan" sino "Elena confronta a Carlos por la deuda"
- **Consecuencia implícita**: el lector debe poder intuir qué cambia

## Qué NO debe tener un hecho

- Estados de ánimo sin evento: no "Elena se siente culpable"
- Resúmenes vacíos: no "El capítulo avanza"
- Acciones triviales que no tienen peso narrativo (esas son beats directamente)
- Spoilers del desarrollo (el hecho declara qué ocurre, no cómo termina)

## Relación con beats

El hecho es el **qué**. Los beats bajo él son el **cómo**.

Un hecho que no se puede descomponer en al menos 3 beats narrativos distintos probablemente es ya un beat, no un hecho. Un hecho que genera 15+ beats probablemente debe dividirse en dos hechos.

## Distribución en capítulos

Los hechos se agrupan en capítulos según la tabla de trenzado (novela multi-hilo) o la estructura de `guion-novela.md` (novela simple). Cada capítulo tiene:

- Un bloque de hechos asignados desde el guion global
- Los hechos se numeran globalmente (continuando desde `config.json.ultimo_hecho_seq`)
- Los beats de cada hecho también son globales (`config.json.ultimo_beat_seq`)

## Evaluación de hechos

Al revisar un hecho, verificar:

1. ¿Tiene sujeto claro y acción concreta narrable?
2. ¿Tiene consecuencia en la trama (algo cambia)?
3. ¿Admite al menos 3 beats distintos de desarrollo?
4. ¿No repite lo que ya ocurrió en hechos anteriores?
5. ¿Su ID sigue la numeración global sin saltos?

## Estados

```
⬜ H_0001 — (pendiente)
🔄 H_0001 — (en progreso)
✅ H_0001 — (completado)
```

