---
name: plantilla-guion
description: Estructura y campos del guión de relato con escenas, beats y metadatos. Soporta modo simple (relato) y modo multi-hilo (novela con múltiples tramas paralelas). Úsalo al generar o revisar un guión.
---

# Guión: [TÍTULO]

## Premisa
[Una frase que resume la historia completa]

## Metadatos

| Campo | Valor |
|-------|-------|
| **Estilo** | [noir\|romantico\|erotico\|thriller\|fantasia\|contemporaneo] |
| **Longitud** | [Corto (1k-3k) \| Medio (3k-6k) \| Largo (6k-10k) \| Novela (30k+)] |
| **Modo** | [simple \| multi-hilo] |
| **Perspectiva** | [Primera persona \| Tercera persona (nombre)] |
| **Tono** | [descripción del tono] |
| **Crudeza** | [Nivel 1-5 (máximo: 5)] |
| **Revisión** | [Ligera \| Media \| Completa] |
| **Capítulos estimados** | [N] |

## Modos de guión

### Modo simple
Para relatos con una sola línea temporal. Las escenas son secuenciales. Usa la estructura de escenas estándar.

### Modo multi-hilo
Para novelas con múltiples tramas paralelas (distintas épocas, POVs o líneas argumentales). Cada hilo se desarrolla independientemente y luego se trenza. **Obligatorio rellenar la sección `## Hilos narrativos` y `## Trenzado`** al usar este modo.

---

## Hilos narrativos _(obligatorio en modo multi-hilo)_

Cada hilo narrativo es una trama con su propia época, protagonista, conflicto y género. Los hilos se desarrollan de forma independiente y luego se entrelazan en capítulos compartidos.

### Estructura de un hilo

| Campo | Descripción |
|-------|-------------|
| **ID** | `hilo-<slug>` — identificador único |
| **Nombre** | Título descriptivo del hilo |
| **Época** | Cuándo transcurre (año, período) |
| **Protagonista(s)** | Quién lleva el peso narrativo |
| **Género dominante** | Registro estilístico del hilo |
| **Conflicto central** | Qué tensión mueve este hilo |
| **Estado** | `planificado` \| `en_desarrollo` \| `completado` |
| **Capítulos** | En qué capítulos aparece |
| **Conexiones** | IDs de otros hilos con los que se cruza |
| **Puntos de conexión** | Momentos concretos donde este hilo toca otros hilos |

Ejemplo:
```
### Hilo: hilo-sumer
- **Nombre:** Naamah — El Origen
- **Época:** Sumer, 2800 a.C.
- **Protagonista:** Naamah
- **Género dominante:** Fantasía oscura / horror erótico
- **Conflicto central:** Naamah asciende como entidad de culto hasta que las Sacerdotisas de Inanna la sellan
- **Estado:** planificado
- **Capítulos:** CAP_01, CAP_04, CAP_08, CAP_12, CAP_15
- **Conexiones:** hilo-sello, hilo-soma
- **Puntos de conexión:**
  - La losa viaja de Sumer a Hispania → hilo-sello (CAP_08)
  - Daniel descubre la tesis sobre el sigilo → hilo-soma (CAP_12)
```

---

## Trenzado _(obligatorio en modo multi-hilo)_

El trenzado define cómo se alternan los hilos en los capítulos. Especifica qué hilo(s) aparecen en cada capítulo y si hay capítulos puente que mezclan dos o más hilos.

### Tabla de trenzado

| Capítulo | Hilo(s) activo(s) | Modo | Función |
|----------|-------------------|------|---------|
| CAP_01 | hilo-sumer | Exclusivo | Origen — presentación de Naamah |
| CAP_02 | hilo-sumer | Exclusivo | Desarrollo del culto |
| CAP_03 | hilo-sello | Exclusivo | Presentación de la abadesa |
| CAP_04 | hilo-sello | Exclusivo | La Inquisición cerca el convento |
| CAP_05 | hilo-soma | Exclusivo | Presentación de Daniel en 2026 |
| CAP_06 | hilo-soma | Exclusivo | Vida en Apex Creative |
| CAP_07 | hilo-soma + hilo-sello | Puente | Beatriz descubre el archivo mientras Daniel activa el sigilo |
| ... | ... | ... | ... |

### Tipos de capítulo por hilo

- **Exclusivo:** un solo hilo ocupa todo el capítulo. Usar para desarrollo profundo.
- **Puente:** dos o más hilos se alternan dentro del mismo capítulo (cambio de sección con `---`). Usar cuando las acciones de distintos hilos convergen temáticamente o temporalmente.
- **Espejo:** dos hilos se narran en paralelo mostrando la misma acción/objeto en épocas distintas. Usar para revelaciones y simbolismo.

### Reglas de trenzado

1. No alternar más de 2 hilos por capítulo (evita fragmentación)
2. Un hilo no debe desaparecer más de 3 capítulos seguidos (mantiene tensión)
3. Los capítulos puente se reservan para momentos de convergencia narrativa
4. El clímax de cada hilo debe ocurrir en un capítulo exclusivo (no se comparte el foco)
5. El trenzado se decide DESPUÉS de tener los tres hilos desarrollados con sus escenas y beats

---

## Escenas

Cada escena pertenece a un hilo. En modo simple se omite el campo `**Hilo:**`.

---

### ESCENA 1: [ESPACIO] — [Nombre de la escena]

**Hilo** _(solo modo multi-hilo)_: [hilo-sumer \| hilo-sello \| hilo-soma]

**Ubicación**: [Lugar exacto, hora, condiciones de luz]

**Personajes**: [Quién está presente]

**Objetos** _(opcional)_: [Objetos con presencia relevante en la escena — ej: "anillo de la promesa, carta doblada"]. Lista solo si hay props que importan; omite si la escena no los tiene.

**Animales** _(opcional)_: [Animales presentes — ej: "gato Mishi"]. Lista solo si hay animales en escena; omite si no.

**Objetivo de la escena**: [Qué avanza en la historia de este hilo]

**Puntos de conexión** _(solo modo multi-hilo)_: [Si esta escena contiene elementos que conectan con otro hilo — ej: "aparece la losa que viajará a Hispania", "Daniel lee sobre el ritual que vimos en Sumer"]

#### Beats

Cada beat = declaración factual de lo que ocurre físicamente + metadatos de escritura.
Sin sensoriales, sin emociones, sin adjetivos de experiencia. Solo quién hace qué.
Formato: `**B_XX** — [acción. Max 2 frases.] [⚡ "línea crítica si aplica"] \`[TONO — EXTENSIÓN]\` \`[Personaje1, Personaje2]\` \`[Zona: nombre]\` \`[Props: obj1, obj2]\` \`[Hilos: hilo1]\``

EXTENSIÓN: `BREVE` (2-3 frases) | `MEDIA` (4-7 frases) | `EXTENSA` (8-15 frases)
TONO: del catálogo del skill `tonos-beat` — uno o dos tonos separados por /
PERSONAJES: nombres exactos de los personajes que participan en ese beat (solo los activos, no todos los de la escena)
ZONA: nombre de la zona del escenario donde ocurre el beat (del campo `## Zona:` del escenario — ej: `dormitorio`, `sala`, `baño`)
PROPS _(opcional)_: solo si el beat introduce o usa un objeto específico (no listar objetos ya declarados en la escena salvo que se usen activamente en este beat)
HILOS _(opcional)_: solo si este beat cambia el estado de un hilo (abre, desarrolla, cierra). Si un hilo está presente pero sin cambio, no lo declares aquí — el validador entiende que la presencia es por contexto

1. **B_01** — [Acción física. Quién hace qué.] `[Tenso — BREVE]` `[Ana]` `[Zona: sala]`
2. **B_02** — [Acción física.] `[Opresivo — MEDIA]` `[Ana, Carlos]` `[Zona: sala]`
3. **B_03** — [Acción física. ⚡ "Solo si esta frase debe aparecer."] `[Clínico — BREVE]` `[Carlos]` `[Zona: sala]`
4. **B_04** — [Acción física.] `[Explícito / Visceral — EXTENSA]` `[Ana, Carlos]` `[Zona: dormitorio]` `[Props: anillo-promesa]`
5. **B_05** — [Acción física.] `[Dominante — MEDIA]` `[Ana, Carlos, Luis]` `[Zona: dormitorio]`
6. **B_06** — [Acción física — cierre o transición.] `[Tenso — BREVE]` `[Ana]` `[Zona: dormitorio]` `[Hilos: traicion-carlos]`

**Convención de declaración de entidades en escenas**:

- **`**Personajes**:`** — obligatorio. Nombres de los personajes presentes.
- **`**Objetos**:`** — opcional. Solo si hay objetos con presencia relevante.
- **`**Animales**:`** — opcional. Solo si hay animales.
- **`**Hilo**`** (solo multi-hilo) — obligatorio. ID del hilo al que pertenece esta escena.
- **`**Puntos de conexión**`** (solo multi-hilo) — opcional. Elementos de esta escena que conectan con otros hilos.

**Convención de declaración de entidades en capítulos/arcos** (a nivel de `## Arco narrativo`):

- **`**Hilos**:`** — obligatorio en modo multi-hilo. Lista de hilos activos con descripción. Cada hilo vive como entry en Qdrant `entidades` con `tipo=hilo` e ID `hilo-<slug>`. El guionista y el director los registran durante el desarrollo de hilos.
- **`**Objetos**` / `**Personajes**`** — NO se declaran a nivel de capítulo. Su fuente de verdad son las escenas y las fichas.

**Líneas críticas** (solo si son argumento-críticas, marcadas con ⚡ en el beat correspondiente):
- **[Personaje]**: *"[frase]"*

**Tensión sexual**:
- [Elemento de tensión 1]
- [Elemento de tensión 2]

**Transición**: [Cómo enlaza con la siguiente escena — dentro del mismo hilo o hacia otro hilo si es capítulo puente]

---

### ESCENA 2: [ESPACIO] — [Nombre de la escena]

**Hilo** _(solo modo multi-hilo)_:

**Ubicación**:

**Personajes**:

**Objetivo de la escena**:

#### Beats

1.

**Líneas críticas**:
-

**Tensión sexual**:
-

**Transición**:

---

### ESCENA N: [Según necesidad]
...

## Conflicto central
[Qué tensión o problema mueve la historia. Qué quiere cada personaje y por qué chocan.]

## Arco narrativo

### Para modo simple (relato)
- **Inicio**: [Cómo empieza. Qué situación se presenta.]
- **Desarrollo**: [Cómo evoluciona. Qué obstáculos aparecen.]
- **Clímax**: [Momento de máxima tensión. Qué se resuelve.]
- **Desenlace**: [Cómo termina. ¿Abierto o cerrado?]

### Para modo multi-hilo (novela)
Cada hilo tiene su propio arco. La novela completa tiene un arco global que los engloba.

**Arco global de la novela:**
- **Inicio**: [Presentación de los hilos. Cómo se establece el mundo en cada época.]
- **Desarrollo**: [Los hilos avanzan en paralelo. Aparecen las primeras conexiones.]
- **Convergencia**: [Los hilos empiezan a trenzarse. Las conexiones se intensifican.]
- **Clímax**: [Los tres hilos convergen en un punto común — objetos, revelaciones o eventos que los unen.]
- **Desenlace**: [Resolución de cada hilo y cierre global.]

**Arco por hilo:**
- **hilo-sumer**: Inicio → Desarrollo → Clímax (el sellado) → Desenlace (la losa parte hacia Hispania)
- **hilo-sello**: Inicio → Desarrollo → Clímax (el ritual de la abadesa) → Desenlace (el sótano sellado)
- **hilo-soma**: Inicio → Desarrollo → Convergencia → Clímax (la cosecha) → Desenlace (Madrid post-Naamah)

**Hilos** _(obligatorio en multi-hilo)_: [Lista completa de hilos narrativos con IDs. Cada hilo vive como entry en Qdrant `entidades` con `tipo=hilo`.]

- [hilo-sumer]: [Naamah en Sumer — origen y sellado original]
- [hilo-sello]: [La abadesa en 1612 — el convento y la Inquisición]
- [hilo-soma]: [Daniel/Beatriz/Marcos en 2026 — liberación y consecuencias]

**Personajes clave del arco** _(opcional)_: [Lista de per-*-id que protagonizan el arco global. La fuente de verdad de cada personaje está en su entry Qdrant `entidades` con `tipo=personaje`.]

## Detalles obligatorios
[Elementos que DEBEN aparecer en el relato]
-

-

## Notas adicionales
[Cualquier información relevante para el escritor: ritmo deseado, enfoque sensorial, elementos a evitar]
