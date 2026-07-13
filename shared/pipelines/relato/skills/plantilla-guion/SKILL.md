---
name: plantilla-guion
description: Estructura y campos del guion de relato con escenas y beats identificados por stable_id y ordenados mediante seq local al padre.
---

# Guion: [TÍTULO]

## Premisa

[Una frase que resume la historia completa]

## Metadatos

| Campo | Valor |
|-------|-------|
| **Proyecto** | [slug de `proyecto`] |
| **Estilo** | [noir\|romantico\|erotico\|thriller\|fantasia\|contemporaneo] |
| **Longitud** | [Corto (1k-3k) \| Medio (3k-6k) \| Largo (6k-10k) \| Máximo (10k-20k)] |
| **Perspectiva** | [Primera persona \| Tercera persona (nombre)] |
| **Tono** | [descripción del tono] |
| **Crudeza** | [Nivel 1-5 (máximo: 5)] |
| **Revisión** | [Ligera \| Media \| Completa] |

---

## Escenas

Cada escena pertenece a una línea temporal única. Las escenas son secuenciales. Cada escena tiene `stable_id` inmutable, `seq` local a su padre y `parent_id`.

### ESCENA 1: [ESPACIO] — [Nombre de la escena]

**stable_id**: [ID opaco e inmutable; ej. `e5f6a7b8`]

**seq**: [posición local dentro del padre]

**parent_id**: [stable_id del padre]

**Ubicación**: [Lugar exacto, hora, condiciones de luz]

**Personajes**: [Quién está presente]

**Objetos** _(opcional)_: [Objetos con presencia relevante en la escena]

**Animales** _(opcional)_: [Animales presentes]

**Objetivo de la escena**: [Qué avanza en la historia]

#### Beats

Cada beat es una declaración factual de lo que ocurre físicamente más sus metadatos de escritura. Sin sensoriales, emociones ni adjetivos de experiencia: solo quién hace qué.

Formato canónico:

```text
⬜ stable_id [seq] — acción [Tono — EXTENSIÓN]
```

Ejemplo:

```text
⬜ a1b2c3d4 [34] — Laura se arrodilla ante Diego [Opresivo — BREVE]
```

- `stable_id` es opaco, inmutable y se genera al crear el beat.
- `seq` siempre es local al `parent_id` de la escena.
- El display `i9j0k1l2 [34]` se deriva de `seq: 34` al presentar y nunca se almacena.
- Fichas, `cola_d.md` y demás referencias usan `stable_id`, no el display.

EXTENSIÓN: `BREVE` (2-3 frases) | `MEDIA` (4-7 frases) | `EXTENSA` (8-15 frases)

TONO: uno o dos tonos del catálogo `tonos-beat`, separados por `/`.

```text
⬜ a1b2c3d4 [1] — Ana cierra la puerta antes de que Carlos entre [Tenso — BREVE]
⬜ e5f6a7b8 [2] — Carlos bloquea la salida con el cuerpo [Opresivo — MEDIA]
⬜ 11223344 [3] — Ana exige que se aparte ⚡ "Déjame salir" [Clínico — BREVE]
⬜ 55667788 [4] — Carlos retrocede y deja libre el umbral [Tenso — BREVE]
```

Al insertar, eliminar o reordenar beats, aplica `renumber-siblings` desde el primer `seq` afectado. Solo cambia `seq`; `stable_id`, `parent_id` y las referencias externas permanecen intactos.

**Líneas críticas** _(solo si son argumento-críticas y llevan ⚡ en el beat)_:
- **[Personaje]**: *"[frase]"*

**Tensión sexual**:
- [Elemento de tensión 1]
- [Elemento de tensión 2]

**Transición**: [Cómo enlaza con la siguiente escena]

---

### ESCENA 2: [ESPACIO] — [Nombre de la escena]

**stable_id**:

**seq**:

**parent_id**:

**Ubicación**:

**Personajes**:

**Objetivo de la escena**:

#### Beats

```text
⬜ stable_id [1] — acción [Tono — EXTENSIÓN]
```

La secuencia vuelve a empezar porque `seq` es local a esta escena.

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

- **Inicio**: [Cómo empieza. Qué situación se presenta.]
- **Desarrollo**: [Cómo evoluciona. Qué obstáculos aparecen.]
- **Clímax**: [Momento de máxima tensión. Qué se resuelve.]
- **Desenlace**: [Cómo termina. ¿Abierto o cerrado?]

**Personajes clave del arco** _(opcional)_: [Lista de personajes que protagonizan el arco.]

## Detalles obligatorios

[Elementos que deben aparecer en el relato]
-
-

## Notas adicionales

[Información relevante para el escritor: ritmo, enfoque sensorial y elementos a evitar]

