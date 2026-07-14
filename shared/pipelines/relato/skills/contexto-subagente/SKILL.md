---
name: contexto-subagente
description: Define el contexto mínimo de agentes de relato para no sobrecargar la generación.
compatibility: opencode
---

# Contexto de subagentes — Relato

Usa solo `H_XXXX`, `B_XXXX` y `E_XXXX`. No uses identidad opaca ni secuencias locales.

## Guionista

- `beats`: brief, hechos, último beat y cualquier tramo ya diseñado.
- `distribuidos`: la entrada concreta de `cola_d.md`, ancla y beats vecinos.
- `escenas`: mapa completo de beats validado; devuelve escenas, no reescribe acciones.
- `reparar`: problema bloqueante, tramo y escenas vecinas.

## Escritor

Recibe una `E_XXXX` completa, todas sus acciones `B_XXXX`, escena anterior/siguiente, fichas necesarias y solo los deltas de contexto relevantes. Devuelve todos los bloques de la escena.

## Validador e integrador

Reciben la escena completa y, para una corrección, los bloques señalados más sus vecinos inmediatos. El validador señala problemas por beat; el integrador devuelve solo reemplazos.

## Memoria

El director actualiza un delta por escena. Tras `Salida: separador`, compacta los deltas de la secuencia. No entrega al escritor memoria irrelevante.
