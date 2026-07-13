---
name: scaffolding-multi-hilo
description: Guía para la conversación de estructura de una novela multi-hilo. Cárgalo en Fase 5 cuando la escala sea novela-multi-hilo.
---

# Scaffolding — Novela Multi-hilo

## Antes de empezar

Carga `scaffolding-acto` y `scaffolding-hecho` para conocer el esquema. Lo que propongas al final debe seguir ese formato.

## Filosofía

Una novela multi-hilo tiene la complejidad añadida de múltiples líneas narrativas independientes. El usuario puede llegar con los hilos claros o con una intuición difusa de "varias épocas" o "varios puntos de vista". Tu trabajo es ayudar a darles forma sin imponer estructura prematura.

## Cómo conducir la conversación

### 1. Identificar los hilos

No preguntes "¿cuántos hilos?". Pregunta por las líneas narrativas:

- "Has mencionado que pasa en dos épocas distintas. Cuéntame cada una por separado."
- "Si tuvieras que contarle esta historia a alguien en un minuto, ¿qué pasaría en cada línea temporal?"
- "¿Los protagonistas de cada época se parecen o son opuestos?"
- "¿Hay algún personaje que aparezca en más de una época?"

Deja que el usuario describa cada línea narrativa con sus propias palabras. Tú tomas nota y luego reflejas: "Entiendo que tienes [N] hilos: [descríbelos]."

### 2. Desarrollar cada hilo

Trata cada hilo como un relato independiente:

- "Centrémonos en el hilo de [Sumer]. Cuéntame esa historia de principio a fin."
- "¿Qué conflicto mueve este hilo? ¿Qué pasaría si quitas este hilo de la novela?"
- "¿El tono de este hilo es distinto al de los otros? (más oscuro, más lento, más sensual)"

### 3. Explorar las conexiones

No preguntes "¿cuáles son los puntos de conexión?". Busca conexiones orgánicas:

- "Has mencionado una losa que aparece en Sumer y luego en 1612. ¿Qué significa ese objeto?"
- "Cuando el lector llega al capítulo donde las dos épocas se tocan, ¿qué debería sentir?"
- "¿Hay revelaciones en un hilo que cambian cómo leemos el otro?"

Las conexiones deben emerger de la historia, no ser un checklist. Si el usuario no ve conexiones claras, pregunta: "¿Qué tienen en común estas historias? ¿Por qué contarlas juntas y no por separado?"

### 4. Proponer la estructura (solo al final)

"Basado en lo que hemos hablado, propongo:"

Para cada hilo:
- **Nombre y slug**
- **Época, ubicación, protagonista, conflicto**
- **Tono específico**
- **Hechos:** los eventos que definen su arco (+ marcar `[D]` si son patrones distribuidos)

**Formato del BRIEF.json para multi-hilo:**

Los actos en el BRIEF.json se organizan por hilo. Cada acto tiene un campo `hilo` con el slug del hilo al que pertenece:

```json
{
  "hechos": [
    {
      "hilo": "hilo-madrid",
      "acto": "Acto I — La grieta",
      "objetivo": "...",
      "hechos": ["H_01: ...", "H_02: ..."]
    },
    {
      "hilo": "hilo-sumeria",
      "acto": "Acto I — El templo",
      "objetivo": "...",
      "hechos": ["H_15: ...", "H_16: ..."]
    }
  ]
}
```

**Hechos distribuidos `[D]`:** cuando un hecho describa un patrón recurrente o evolución progresiva, márcalo con `[D · H_XX–H_YY]`. En multi-hilo, un `[D]` puede distribuirse en varios hilos si el patrón es cross-hilo. Ver `scaffolding-hecho` para criterios y ejemplos.

Puntos de conexión que han emergido de la conversación.

Capítulos totales estimados (basados en lo descrito).

Partes (si la novela lo pide).

### Estructura del `_actos.md` (multi-hilo)

El archivo `_actos.md` para multi-hilo debe usar la jerarquía `Hilo → Acto → Hechos`. Esto es diferente de novela-simple (que usa `Acto → Hechos` plano).

Estructura:
```markdown
## Hilo: <nombre> — slug: hilo-<slug>
> Época: ... | Ubicación: ... | Tono: ...
> Conflicto: ...
> Personajes principales: ...

### Acto I — <nombre del acto>
> Objetivo narrativo: ...
> Tensión: ...

#### Hechos
- H_01: ...
- H_02: ...
- H_03 [D · H_05–H_10]: ...

### Acto II — <nombre del acto>
...

## Hilo: <nombre 2> — slug: hilo-<slug2>
> ...

### Acto I — ...
...
```

El scaffolder produce el `_actos.md` directamente con esta estructura. El director, en FASE 0.6, lee cada `## Hilo:` y crea la entidad de hilo en Qdrant. Por cada `### Acto I` dentro de un hilo, crea un L3 con `hilo: <stable_id del hilo>`.

**Recordatorio:** los hilos NO son un nivel estructural en la jerarquía Qdrant. Son un campo `hilo` en L1 y L3. La jerarquía sigue siendo L0 (beat) → L1 → L2 → L3 → L4.

### 5. Infraestructura

Qdrant + Neo4j por defecto. Las consultas cross-hilo requieren Neo4j.

## Cambio de escala

- A novela-simple: elegir un hilo principal, los otros como subtramas. Cargar `scaffolding-novela-simple`.
- A relato: elegir un solo hilo y condensar. Cargar `scaffolding-relato`.
