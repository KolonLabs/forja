---
name: contexto-subagente
description: Define el contexto mínimo de agentes de relato para no sobrecargar la generación.
compatibility: opencode
---

# Contexto de subagentes — Relato

Usa solo `H_XXXX`, `B_XXXX` y `E_XXXX`. No uses identidad opaca ni secuencias locales.

## Guionista

- `beats`: brief, hechos, último beat y cualquier tramo ya diseñado. Diseña el mapa global, incluidas las pautas y sus beats de contraste, antes de devolverlo. Los ejemplos de un hecho orientan la pauta o el contexto; solo se convierten en beats obligatorios si el hecho los fija expresamente como núcleo no negociable.
- `escenas`: mapa completo de beats validado; devuelve escenas, no reescribe acciones.
- `reparar`: problema bloqueante, tramo y escenas vecinas.

## Escritor

Recibe una `E_XXXX` completa, todas sus acciones `B_XXXX`, escena anterior/siguiente, fichas necesarias y solo los deltas de contexto relevantes. Devuelve una prosa de escena continua con anclas invisibles `<!-- B_XXXX -->`. No recibe ni necesita escenas futuras completas.

## Validador e integrador

Reciben la escena completa y, para una corrección, los tramos señalados por ancla más sus vecinos inmediatos. El validador señala problemas por beat; el integrador devuelve solo reemplazos.

## Memoria

El director actualiza un delta por escena. Tras `Salida: separador`, compacta los deltas de la secuencia. No entrega al escritor memoria irrelevante.
