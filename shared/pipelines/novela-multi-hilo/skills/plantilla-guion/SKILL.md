---
name: plantilla-guion
description: Estructura y campos del guion de novela multi-hilo con actos, capítulos, trenzado, hechos, escenas y beats identificados por stable_id y ordenados por seq local al padre.
---

# Guion: [TÍTULO]

## Premisa

[Una frase que resume la historia completa]

## Metadatos

| Campo | Valor |
|-------|-------|
| **Proyecto** | [slug de `proyecto`] |
| **Estilo** | [noir\|romantico\|erotico\|thriller\|fantasia\|contemporaneo] |
| **Longitud** | [Novela corta (50k-70k) \| Novela media (70k-100k) \| Novela larga (100k+)] |
| **Perspectiva** | [Primera persona \| Tercera persona (nombre)] |
| **Tono** | [descripción del tono] |
| **Crudeza** | [Nivel 1-5 (máximo: 5)] |
| **Revisión** | [Ligera \| Media \| Completa] |
| **Capítulos estimados** | [N] |

---

## Hilos narrativos

Cada hilo es una entidad `tipo=hilo` con `stable_id` opaco e inmutable. Su nombre y slug son datos de presentación; las referencias persistidas usan `stable_id`.

### Estructura de un hilo

| Campo | Descripción |
|-------|-------------|
| **stable_id** | Identidad opaca e inmutable |
| **seq** | Posición local dentro del proyecto |
| **parent_id** | Padre o raíz del proyecto |
| **Slug** | Etiqueta humana, por ejemplo `hilo-sumer`; nunca sustituye al `stable_id` |
| **Nombre** | Título descriptivo |
| **Época** | Año o período |
| **Protagonista(s)** | Quién lleva el peso narrativo |
| **Género dominante** | Registro estilístico |
| **Conflicto central** | Tensión del hilo |
| **Estado** | `planificado`, `en_desarrollo` o `completado` |
| **Capítulos** | Capítulos donde aparece |
| **Conexiones** | `stable_id` de otros hilos |
| **Puntos de conexión** | Momentos donde toca otros hilos |

Ejemplo:

```text
### Hilo: Naamah — El Origen
- stable_id: a1b2c3d4
- seq: 1
- parent_id: raiz
- Slug de presentación: hilo-sumer
- Época: Sumer, 2800 a.C.
- Protagonista: Naamah
- Género dominante: Fantasía oscura / horror erótico
- Conflicto central: Naamah asciende como entidad de culto hasta que las Sacerdotisas de Inanna la sellan
- Estado: planificado
- Capítulos: 1, 4, 8, 12, 15
- Conexiones: e5f6a7b8, 11223344
```

---

## Trenzado

El trenzado define cómo se alternan los hilos en los capítulos. Las etiquetas `hilo-S` son ayudas humanas; la persistencia usa el `stable_id` de la entidad hilo.

| Capítulo | Hilo(s) activo(s) | Modo | Función |
|----------|-------------------|------|---------|
| 1 | hilo-sumer (`a1b2c3d4`) | Exclusivo | Origen — presentación de Naamah |
| 2 | hilo-sumer (`a1b2c3d4`) | Exclusivo | Desarrollo del culto |
| 3 | hilo-sello (`e5f6a7b8`) | Exclusivo | Presentación de la abadesa |
| 4 | hilo-sello (`e5f6a7b8`) | Exclusivo | La Inquisición cerca el convento |
| 5 | hilo-soma (`11223344`) | Exclusivo | Presentación de Daniel |
| 7 | hilo-soma + hilo-sello | Puente | Acciones convergentes |

### Tipos de capítulo

- **Exclusivo**: un hilo ocupa todo el capítulo.
- **Puente**: dos o más hilos alternan en bloques separados por `---`.
- **Espejo**: dos hilos muestran en paralelo acciones u objetos equivalentes.

### Reglas de trenzado

1. No alternar más de dos hilos por capítulo.
2. Un hilo no desaparece más de tres capítulos seguidos.
3. Los capítulos puente se reservan para convergencias.
4. El clímax de cada hilo ocurre preferentemente en capítulo exclusivo.
5. El trenzado se decide después de desarrollar cada hilo.

---

## Actos

### ACTO I: [Nombre]

**stable_id**: [ID opaco e inmutable; ej. `8a7b6c5d`]

**seq**: [posición local dentro del proyecto]

**parent_id**: [raíz]

**Función**: [Presentación de hilos e incidentes incitadores]

---

#### Capítulo cap-01-[slug]

**stable_id**: [ID opaco e inmutable; ej. `4e3f2a1b`]

**seq**: [posición local dentro del acto]

**parent_id**: [stable_id del acto]

**Hilos activos**: [hilo-sumer (`a1b2c3d4`)] (Exclusivo)

**Función narrativa**: [Aporte al acto y al trenzado]

##### Hecho [stable_id] [seq]: [Nombre]

**stable_id**: [ID opaco e inmutable]

**seq**: [posición local dentro del capítulo]

**parent_id**: [stable_id del capítulo]

**Hilo**: [stable_id del hilo; slug humano opcional]

**Propósito**: [Qué avanza en el hilo]

###### Escena [seq]: [Nombre]

**stable_id**: [ID opaco e inmutable]

**parent_id**: [stable_id del capítulo o hecho padre]

**Hilo**: [stable_id del hilo]

**Personajes**: [Presentes]

**Zona**: [Ubicación]

###### Beats

Cada beat es una declaración factual de lo que ocurre físicamente más metadatos. Sin sensoriales, emociones ni adjetivos de experiencia: solo quién hace qué.

Formato canónico:

```text
⬜ stable_id [seq] — acción [Tono — EXTENSIÓN] [Personajes] [Zona: nombre] [Hilos: hilo-S]
```

Ejemplo:

```text
⬜ a1b2c3d4 [34] — Laura se arrodilla ante Diego [Opresivo — BREVE] [Laura, Diego] [Zona: salón] [Hilos: hilo-S]
```

- `stable_id` es opaco, inmutable y se genera al crear el beat.
- `seq` siempre es local al `parent_id` de la escena o bloque.
- `i9j0k1l2 [34]` se deriva de `seq: 34` al presentar y nunca se almacena.
- Fichas, `cola_d.md` y demás referencias usan `stable_id`.

EXTENSIÓN: `BREVE` (2-3 frases) | `MEDIA` (4-7 frases) | `EXTENSA` (8-15 frases)

TONO: uno o dos tonos del catálogo `tonos-beat`, separados por `/`.

PERSONAJES: nombres exactos de quienes participan activamente.

ZONA: ubicación concreta.

PROPS _(opcional)_: objetos introducidos o usados.

HILOS: anotación humana `[Hilos: hilo-S]`; el briefing y la persistencia incluyen también el `stable_id` del hilo.

```text
⬜ 91a2b3c4 [1] — Ana cierra la puerta antes de que Carlos entre [Tenso — BREVE] [Ana] [Zona: sala] [Hilos: hilo-soma]
⬜ 52d3e4f5 [2] — Carlos bloquea la salida [Opresivo — MEDIA] [Ana, Carlos] [Zona: sala] [Hilos: hilo-soma]
⬜ 63e4f5a6 [3] — Ana exige que se aparte ⚡ "Déjame salir" [Clínico — BREVE] [Ana, Carlos] [Zona: sala] [Hilos: hilo-soma]
⬜ 74f5a6b7 [4] — Carlos deja el anillo sobre la cama [Visceral — EXTENSA] [Ana, Carlos] [Zona: dormitorio] [Props: anillo-promesa] [Hilos: hilo-soma, hilo-sello]
```

Al insertar, eliminar o reordenar beats, usa `renumber-siblings` desde el primer `seq` afectado, filtrando por `parent_id` y por `hilo` cuando aplique. Solo cambia `seq`; `stable_id`, `parent_id`, hilo y referencias externas permanecen intactos.

**Transición**: [Cómo enlaza con el siguiente hecho, escena o hilo]

##### Hecho [stable_id] [seq]: [Nombre]

**stable_id**: [otro ID opaco]

**seq**: [posición local dentro del capítulo]

**parent_id**: [stable_id del capítulo]

**Hilo**: [stable_id]

**Propósito**: [...]

###### Beats

```text
⬜ stable_id [1] — acción [Tono — EXTENSIÓN] [Personajes] [Zona: nombre] [Hilos: hilo-S]
```

La secuencia vuelve a empezar para cada padre.

---

#### Capítulo cap-07-[slug] (Puente)

**stable_id**: [ID opaco]

**seq**: [posición local dentro del acto]

**parent_id**: [stable_id del acto]

**Hilos activos**: [stable_id de hilo-soma, stable_id de hilo-sello]

**Función narrativa**: [Convergencia]

Cada bloque de hilo declara su `parent_id` y su hilo. Los `seq` son locales al padre; no se renumeran globalmente entre bloques independientes.

---

### ACTO II: [Nombre]

**stable_id**:

**seq**:

**parent_id**:

...

## Escenas

Cada escena pertenece a un hilo. Las escenas del mismo hilo son secuenciales; las de hilos distintos siguen el trenzado.

### ESCENA 1: [ESPACIO] — [Nombre]

**stable_id**: [ID opaco]

**seq**: [posición local dentro del capítulo o bloque]

**parent_id**: [stable_id del capítulo o bloque]

**Hilo**: [stable_id; slug humano opcional]

**Ubicación**: [Lugar exacto, hora y luz]

**Personajes**: [Quién está presente]

**Objetos** _(opcional)_: [Objetos relevantes]

**Animales** _(opcional)_: [Animales presentes]

**Objetivo de la escena**: [Qué avanza en este hilo]

**Puntos de conexión**: [Conexiones con otros hilos]

**Líneas críticas** _(marcadas con ⚡)_:
- **[Personaje]**: *"[frase]"*

**Tensión sexual**:
- [Elemento 1]
- [Elemento 2]

## Conflicto central

[Qué mueve la historia y cómo se manifiesta en cada hilo.]

## Arco narrativo

**Arco global:**
- **Inicio**: [Presentación de los hilos.]
- **Desarrollo**: [Avance paralelo.]
- **Convergencia**: [Conexiones crecientes.]
- **Clímax**: [Punto común.]
- **Desenlace**: [Resolución global y por hilo.]

**Arco por hilo:**
- **hilo-sumer** (`stable_id`): Inicio → Desarrollo → Clímax → Desenlace.
- **hilo-sello** (`stable_id`): Inicio → Desarrollo → Clímax → Desenlace.
- **hilo-soma** (`stable_id`): Inicio → Desarrollo → Convergencia → Clímax → Desenlace.

## Hilos

Cada entrada declara `stable_id`, nombre y slug humano:

- `stable_id` — hilo-sumer: [descripción]
- `stable_id` — hilo-sello: [descripción]
- `stable_id` — hilo-soma: [descripción]

**Personajes clave** _(opcional)_: [Entidades `tipo=personaje`; la persistencia las referencia por `stable_id`.]

## Detalles obligatorios

[Elementos que deben aparecer]
-
-

## Notas adicionales

[Información para el escritor: ritmo, enfoque sensorial y elementos a evitar]

