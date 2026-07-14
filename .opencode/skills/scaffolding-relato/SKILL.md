---
name: scaffolding-relato
description: Guía para la conversación de estructura de un relato. Cárgalo en Fase 5 cuando la escala sea relato.
---

# Scaffolding — Relato

## Antes de empezar

Carga `scaffolding-acto` y `scaffolding-hecho` para conocer el esquema de cada acto y hecho. Lo que propongas al final debe seguir ese formato.

## Filosofía

El usuario llega con una idea, no con una estructura. Tu trabajo no es hacer un checklist de "¿cuántos actos? ¿cuántos hechos?". Es mantener una conversación editorial sobre **qué pasa en la historia**, de principio a fin, y solo al final proponer una estructura de actos y hechos que capture lo que habéis construido juntos.

## Cómo conducir la conversación

### 1. Explorar el arco narrativo

No preguntes por actos. Pregunta por lo que ocurre:

- "Cuéntame el principio. ¿Cómo empieza esto?"
- "¿Qué es lo primero que le pasa al protagonista que lo saca de su rutina?"
- "¿Y después? ¿Qué hace? ¿A dónde va? ¿Con quién se encuentra?"
- "¿Cuál es el momento de máxima tensión? ¿Dónde explota todo?"
- "¿Cómo termina? ¿O no termina? ¿Se resuelve algo o se queda abierto?"

Deja que el usuario cuente la historia en sus propias palabras. Toma notas mentales de los momentos clave que van emergiendo.

### 2. Afinar los momentos

Cuando tengas el arco completo, vuelve a los momentos que te parezcan más potentes o más débiles:

- "Ese momento del parking me parece el núcleo de todo. ¿Podrías contármelo con más detalle?"
- "Entre el primer encuentro y la aparición del mayor, ¿pasa algo más o es un salto directo?"
- "Has hablado mucho de la vida secreta pero poco de la esposa. ¿Ella solo existe como contraste o tiene peso propio?"
- "El final que describes es muy abierto. ¿El lector debe sentir esperanza, alivio, desesperación?"

### 3. Proponer la estructura (solo al final)

Cuando sientas que la historia está completa en la cabeza del usuario, propón:

"Basado en lo que hemos hablado, veo [N] bloques narrativos. Te propongo esta estructura:"

Para cada bloque (acto):
- **Nombre:** algo que capture su esencia, no genérico ("El shock", no "Acto I")
- **Objetivo narrativo:** qué debe conseguir este bloque
- **Efecto en el lector:** qué debe sentir quién lee
- **Tensión:** qué está en juego
- **Hechos:** los eventos concretos que han emergido de la conversación

**Hechos distribuidos `[D]`:** cuando un hecho describa un patrón recurrente, una evolución progresiva o una rutina que no puede escribirse en una sola escena, márcalo con `[D · H_XXXX–H_XXXX]`. El rango indica entre qué hechos lineales debe desplegarse. El workspace lo convertirá en beats intercalados, no en escenas propias. Ver `scaffolding-hecho` para criterios y ejemplos.

Pregunta: "¿Esto captura lo que tenías en mente? ¿Falta algo? ¿Sobra algo?"

Itera hasta que el usuario confirme.

### 4. Validar

- ¿La progresión de tensión es creciente?
- ¿Hay hechos intercambiables (podrían ir en cualquier orden)?
- ¿Hay vacíos narrativos (saltos sin justificar)?
- ¿El final cierra algo — aunque sea una pregunta?
- ¿Cada `[D]` tiene un rango coherente (al menos 2 hechos lineales dentro, fin ≥ inicio)?
- ¿Los `[D]` no dominan el acto? Si un acto tiene más `[D]` que lineales, probablemente la granularidad es incorrecta.

## Sin infraestructura

El relato no usa Qdrant ni Neo4j. Si el usuario pregunta, la memoria es `contexto_narrativo.md` (un archivo markdown).

## Cambio de escala

Si el usuario dice "¿y si fuera novela?":
1. Advertir que implica capítulos, Qdrant+Neo4j y más extensión.
2. Si confirma, cargar `scaffolding-novela-simple`.
3. Los hechos que habéis definido pueden ser la base de los arcos de la novela.
