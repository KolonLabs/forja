---
name: contexto-subagente
description: Define el contexto mínimo de los subagentes de relato con IDs H_, B_ y E_ globales.
compatibility: opencode
---

# Contexto de subagentes — Relato

## Contrato común

Los identificadores válidos son `H_XXXX`, `B_XXXX` y `E_XXXX`. Son visibles, globales y suficientes para localizar cualquier elemento. No uses `stable_id`, `parent_id`, `seq` ni UUID.

## Guionista

- `beats`: `BRIEF.md`, `_actos.md`, último `B_XXXX` y los beats finales ya existentes si reanuda.
- `distribuidos`: `cola_d.md`, cada ancla `B_XXXX`, su beat anterior y posterior, y el rango de `H_XXXX`.
- `escenas`: mapa completo de beats ya validado; debe devolver agrupaciones, no alterar acciones de beats salvo una reparación explícita.
- `reparar`: diagnóstico, tramo delimitado por `B_XXXX`/`E_XXXX`, hechos y transiciones vecinas.

## Escritor

Pasa: bloque completo de la `E_XXXX`, beat actual `B_XXXX`, prosa previa de la escena, tres beats anteriores si existen, fichas relevantes, `contexto_narrativo.md`, tono, extensión y estilo. Devuelve solo prosa.

## Validador e integrador

Pasa: `B_XXXX`, acción de guion, bloque `E_XXXX`, texto actual, contexto y fichas relevantes, ventanas anterior/posterior y la lista exacta de dimensiones. El integrador devuelve el bloque con heading `## B_XXXX — acción`.

## Entidades y contexto

Las fichas se localizan por su ruta `fichas/<tipo>_<slug>.md` y se citan por nombre/tipo. El director actualiza el contexto al cerrar cada `E_XXXX`.
