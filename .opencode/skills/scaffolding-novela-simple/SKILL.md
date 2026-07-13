---
name: scaffolding-novela-simple
description: Guía para la conversación de estructura de una novela simple. Cárgalo en Fase 5 cuando la escala sea novela-simple.
---

# Scaffolding — Novela Simple

## Antes de empezar

Carga `scaffolding-acto` y `scaffolding-hecho` para conocer el esquema de cada arco (acto) y hecho. Lo que propongas al final debe seguir ese formato.

## Filosofía

El usuario llega con una idea de novela. Tu trabajo es mantener una conversación editorial sobre **qué pasa en la historia** y solo al final proponer una estructura de arcos con hechos. No preguntes "¿cuántos arcos?" al principio.

## Cómo conducir la conversación

### 1. Explorar la historia completa

Igual que en relato, pero con más profundidad. Una novela tiene más espacio para subtramas, personajes secundarios y evolución:

- "Cuéntame la historia de principio a fin, con todos los giros que tengas en mente."
- "¿Hay personajes que aparecen al principio y cambian radicalmente al final?"
- "¿Qué subtramas ves? ¿Algún personaje secundario que robe protagonismo en algún momento?"

### 2. Agrupar en arcos

Conforme la conversación avanza, los bloques narrativos grandes deberían emerger de forma natural:

- "Lo que me cuentas de la primera parte suena a un arco de descubrimiento. ¿Dirías que el personaje termina esa fase transformado?"
- "Hay un punto de giro muy claro cuando [X descubre Y]. ¿Eso parte la novela en dos mitades?"
- "¿Hay algún arco que sea puramente interno? (ej. 'el arco de la culpa', 'el arco de la redención')"

No nombres "arco 1, arco 2". Habla de lo que significan: "el arco del engaño", "el arco de la caída", "el arco de la reconstrucción".

### 3. Capítulos

El scaffolder solo pregunta por el **número estimado**. El contenido de cada capítulo (qué hechos van en cuál, cómo se agrupan en escenas) lo decide el guionista en el workspace.

- "¿Cuántos capítulos aproximados imaginas para esta novela?"
- "¿Hay algún capítulo que ya tengas muy claro en la cabeza? Cuéntamelo como un hecho más, no como estructura."

No preguntes "¿qué pasa en el capítulo 3?" ni definas la estructura de capítulos. Eso es trabajo del workspace.

### 4. Proponer la estructura (solo al final)

Propón la estructura completa:

"Basado en lo que hemos hablado, propongo [N] arcos con aproximadamente [M] capítulos en total. El guionista decidirá la distribución exacta:"

Para cada arco:
- **Nombre y premisa**
- **Capítulos estimados** (basados en lo que el usuario ha descrito)
- **Hechos:** los eventos de alto nivel que han emergido

**Hechos distribuidos `[D]`:** cuando un hecho describa un patrón recurrente, una evolución progresiva o una rutina, márcalo con `[D · H_XX–H_YY]`. El rango indica entre qué hechos lineales debe desplegarse. El workspace lo convertirá en beats intercalados, no en escenas propias. Ver `scaffolding-hecho` para criterios y ejemplos.

Pregunta: "¿Refleja esto la novela que tienes en mente?"

### 5. Infraestructura

Qdrant y Neo4j son obligatorios para toda novela simple. Explica que el script los inicializa al crear el workspace y que la creación se detiene si no están operativos. No ofrezcas `_no_infra` ni una alternativa sin infraestructura.

## Cambio de escala

Si el usuario quiere bajar a relato: condensar los arcos en hechos. Cargar `scaffolding-relato`.
Si quiere subir a multi-hilo: los arcos pueden convertirse en hilos. Cargar `scaffolding-multi-hilo`.
