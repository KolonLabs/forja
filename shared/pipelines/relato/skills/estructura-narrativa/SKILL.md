---
name: estructura-narrativa
description: Criterio de agrupación de beats y escenas para relatos sin imponer prosa ni cuotas.
user-invocable: false
---

# Estructura narrativa — Relato

## Jerarquía

```text
Hechos H_XXXX → beats B_XXXX → escenas operativas E_XXXX → prosa
```

Los beats fijan acciones. Las escenas agrupan acciones para que formen una unidad dramática y una generación manejable.

## Cuándo abrir una `E_XXXX`

Abre una nueva escena cuando ocurra un giro reconocible de:

- objetivo inmediato;
- información disponible;
- relación de poder;
- foco o punto de vista;
- ritmo dominante;
- resultado o consecuencia.

No abras una escena solo por la cantidad de beats. Una situación continua puede contener varias `E_XXXX` si esas fases tienen función propia.

## Tono

La escena no declara arco tonal: su recorrido es la secuencia de `[Tono — EXTENSIÓN]` de sus beats, del catálogo de `tonos-beat` (ADR 0035). Cuida las transiciones entre beats contiguos, especialmente hacia o desde contenido explícito.

El tono orienta al escritor; no dicta frases, longitud, detalle sensorial ni diálogo. Excepción: una escena explícita activa el nivel de detalle de `estilo-explicito` (acto mostrado con progresión), que prevalece sobre la contención en ese tramo.

## Salida

- `continua`: la siguiente escena sigue la situación y el manuscrito no muestra `---`.
- `separador`: hay un corte narrativo visible y el manuscrito muestra `---`.

## Libertad del escritor

El guion no prescribe ritmo de frase, imágenes, monólogo, sensorialidad ni vocabulario. Esas decisiones pertenecen al escritor dentro de los hechos, acciones y tonos pactados.
