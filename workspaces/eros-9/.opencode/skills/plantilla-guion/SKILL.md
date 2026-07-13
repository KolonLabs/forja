---
name: plantilla-guion
description: Estructura y campos del guion de novela simple con actos, capítulos, hechos, escenas y beats identificados por stable_id y ordenados por seq local al padre.
---

# Guion: [TÍTULO]

## Premisa

[Una frase que resume la historia completa]

## Metadatos

| Campo | Valor |
|-------|-------|
| **Proyecto** | [slug de `proyecto`] |
| **Estilo** | [noir\|romantico\|erotico\|thriller\|fantasia\|contemporaneo] |
| **Longitud** | [Novela corta (30k-50k) \| Novela media (50k-80k) \| Novela larga (80k+)] |
| **Perspectiva** | [Primera persona \| Tercera persona (nombre)] |
| **Tono** | [descripción del tono] |
| **Crudeza** | [Nivel 1-5 (máximo: 5)] |
| **Revisión** | [Ligera \| Media \| Completa] |
| **Capítulos estimados** | [N] |

---

## Actos

### ACTO I: [Nombre del acto]

**stable_id**: [ID opaco e inmutable; ej. `8a7b6c5d`]

**seq**: [posición local dentro del proyecto]

**parent_id**: [stable_id del padre o raíz]

**Función**: [Presentación, incidente incitador, primer giro]

---

#### Capítulo cap-01-[slug]

**stable_id**: [ID opaco e inmutable; ej. `4e3f2a1b`]

**seq**: [posición local dentro del acto]

**parent_id**: [stable_id del acto]

**Función narrativa**: [Qué aporta al arco del acto]

##### Hecho [stable_id] [seq]: [Nombre del hecho]

**stable_id**: [ID opaco e inmutable; ej. `91a2b3c4`]

**seq**: [posición local dentro del capítulo]

**parent_id**: [stable_id del capítulo]

El display humano del hecho, si se necesita, se deriva de `seq` al presentar y nunca sustituye a `stable_id`.

**Propósito**: [Qué avanza en la trama o arco de personaje]

###### Escena [seq]: [Nombre]

**stable_id**: [ID opaco e inmutable]

**parent_id**: [stable_id del capítulo o hecho padre]

**Personajes**: [Personajes presentes]

**Zona**: [Ubicación]

###### Beats

Cada beat es una declaración factual de lo que ocurre físicamente más metadatos. Sin sensoriales, emociones ni adjetivos de experiencia: solo quién hace qué.

Formato canónico:

```text
⬜ stable_id [seq] — acción [Tono — EXTENSIÓN] [Personajes] [Zona: nombre]
```

Ejemplo:

```text
⬜ a1b2c3d4 [34] — Laura se arrodilla ante Diego [Opresivo — BREVE] [Laura, Diego] [Zona: salón]
```

- `stable_id` es opaco, inmutable y se genera al crear el beat.
- `seq` siempre es local al `parent_id` de la escena.
- `i9j0k1l2 [34]` se deriva de `seq: 34` al presentar y nunca se almacena.
- Fichas, `cola_d.md` y demás referencias usan `stable_id`.

EXTENSIÓN: `BREVE` (2-3 frases) | `MEDIA` (4-7 frases) | `EXTENSA` (8-15 frases)

TONO: uno o dos tonos del catálogo `tonos-beat`, separados por `/`.

PERSONAJES: nombres exactos de quienes participan activamente.

ZONA: nombre de la zona donde ocurre el beat.

PROPS _(opcional)_: solo si el beat introduce o usa un objeto específico.

```text
⬜ a1b2c3d4 [1] — Ana cierra la puerta antes de que Carlos entre [Tenso — BREVE] [Ana] [Zona: sala]
⬜ e5f6a7b8 [2] — Carlos bloquea la salida [Opresivo — MEDIA] [Ana, Carlos] [Zona: sala]
⬜ 11223344 [3] — Ana exige que se aparte ⚡ "Déjame salir" [Clínico — BREVE] [Ana, Carlos] [Zona: sala]
⬜ 55667788 [4] — Carlos deja el anillo sobre la cama [Visceral — EXTENSA] [Ana, Carlos] [Zona: dormitorio] [Props: anillo-promesa]
```

Al insertar, eliminar o reordenar beats, usa `renumber-siblings` desde el primer `seq` afectado. Solo cambia `seq`; `stable_id`, `parent_id` y las referencias externas permanecen intactos.

**Transición**: [Cómo enlaza con el siguiente hecho o escena]

##### Hecho [stable_id] [seq]: [Nombre del hecho]

**stable_id**: [otro ID opaco e inmutable]

**seq**: [posición local dentro del capítulo]

**parent_id**: [stable_id del capítulo]

**Propósito**: [...]

###### Beats

```text
⬜ stable_id [1] — acción [Tono — EXTENSIÓN] [Personajes] [Zona: nombre]
```

`seq` vuelve a empezar para cada escena padre.

---

#### Capítulo cap-02-[slug]

**stable_id**:

**seq**:

**parent_id**:

**Función narrativa**: [...]

...

---

### ACTO II: [Nombre del acto]

**stable_id**: [ID opaco e inmutable]

**seq**:

**parent_id**:

...

---

### ACTO III: [Nombre del acto]

**stable_id**: [ID opaco e inmutable]

**seq**:

**parent_id**:

...

## Escenas

Cada capítulo contiene escenas desarrolladas mediante hechos. Las escenas son secuenciales dentro de una línea temporal. Cada escena declara `stable_id`, `seq` local y `parent_id`.

### ESCENA 1: [ESPACIO] — [Nombre]

**stable_id**: [ID opaco e inmutable]

**seq**: [posición local dentro del capítulo]

**parent_id**: [stable_id del capítulo]

**Ubicación**: [Lugar exacto, hora, luz]

**Personajes**: [Quién está presente]

**Objetos** _(opcional)_: [Objetos relevantes]

**Animales** _(opcional)_: [Animales presentes]

**Objetivo de la escena**: [Qué avanza]

**Líneas críticas** _(marcadas con ⚡ en el beat)_:
- **[Personaje]**: *"[frase]"*

**Tensión sexual**:
- [Elemento 1]
- [Elemento 2]

## Conflicto central

[Qué tensión mueve la historia. Qué quiere cada personaje y por qué chocan.]

## Arco narrativo

- **Acto I — Inicio**: [Situación e incidente incitador.]
- **Acto II — Desarrollo**: [Obstáculos, punto medio y crisis.]
- **Acto III — Clímax**: [Momento de máxima tensión.]
- **Desenlace**: [Cierre abierto o cerrado.]

## Hilo narrativo

**Hilo principal**: [Nombre y `stable_id` opaco de la entidad con `tipo=hilo`; su slug se conserva solo para presentación y archivos.]

**Personajes clave** _(opcional)_: [Entidades `tipo=personaje` referenciadas por `stable_id` en persistencia.]

## Detalles obligatorios

[Elementos que deben aparecer]
-
-

## Notas adicionales

[Información para el escritor: ritmo, enfoque sensorial y elementos a evitar]

