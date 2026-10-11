---
name: plantilla-guion
description: Estructura y campos del guion de novela simple con actos, capítulos, hechos, escenas y beats identificados por stable_id y ordenados por seq local al padre.
user-invocable: false
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

Cada beat declara un compromiso narrativo más metadatos: qué ocurre o cambia, a quién afecta y qué consecuencia debe conservarse. Es una unidad dramática, no una microacción; puede incluir una interacción, decisión, descubrimiento o inferencia atribuida. No redacta el pensamiento ni coreografía la prosa. Distingue lo dicho, lo sabido, lo inferido y lo verdadero: que un personaje afirme o sospeche algo no lo convierte en verdad del mundo.

Es obligatorio realizar el compromiso aprobado, sus participantes y condiciones causales, respetando conocimiento, conducta, consentimiento e intensidad fijados. Son libres la formulación del diálogo y la interioridad, la cadencia y los enlaces ordinarios compatibles. Un gesto, silencio o detalle sensorial solo se fija si tiene función narrativa; no para imponer la ejecución. Las etiquetas tonales no cambian esos compromisos.

Estas distinciones se expresan en el texto y las notas ya existentes: no añaden campos al formato ni al payload. El beat del guion ocupa una línea técnica, pero su unidad no depende de una sola oración o un solo verbo. Saludos, despedidas y transiciones ordinarias pueden desarrollarse en diálogo continuo sin beats propios. La prosa conserva los encabezados Markdown, IDs y cuerpo de cada beat según el contrato de salida.

Formato canónico:

```text
⬜ stable_id [seq] — acción [Tono — EXTENSIÓN] [Personajes] [Zona: nombre]
```

Ejemplo opcional de formato, no canon ni conducta obligatoria:

```text
⬜ a1b2c3d4 [34] — Laura rechaza el cierre del archivo hasta que Diego justifique la falta de documentos [Tenso — MEDIA] [Laura, Diego] [Zona: archivo]
```

- `stable_id` es opaco, inmutable y se genera al crear el beat.
- `seq` siempre es local al `parent_id` de la escena.
- `i9j0k1l2 [34]` se deriva de `seq: 34` al presentar y nunca se almacena.
- Fichas, `cola_d.md` y demás referencias usan `stable_id`.

EXTENSION: `BREVE` (concentrado) | `MEDIA` (moderado) | `EXTENSA` (amplio). Peso narrativo orientativo, sin cuota de frases ni palabras; ver `tonos-beat`.

TONO: uno o dos tonos del catálogo `tonos-beat`, separados por `/`.

PERSONAJES: nombres exactos de quienes participan activamente.

ZONA: nombre de la zona donde ocurre el beat.

PROPS _(opcional)_: solo si el beat introduce o usa un objeto específico.

Ejemplos opcionales independientes. En el último se supone aprobada y documentada una función causal: el código debe repetirse exactamente para abrir la consigna; no se usa ⚡ solo por ser diálogo importante.

```text
⬜ a1b2c3d4 [1] — Ana rechaza entregar el expediente sin un recibo y Carlos acepta dejar constancia [Tenso — MEDIA] [Ana, Carlos] [Zona: sala]
⬜ e5f6a7b8 [2] — Carlos afirma haber devuelto la llave, sin que Ana pueda comprobarlo [Clínico — BREVE] [Ana, Carlos] [Zona: sala]
⬜ 11223344 [3] — Ana infiere por la fecha del recibo que la entrega pudo retrasarse, sin confirmarlo [Revelación — MEDIA] [Ana] [Zona: archivo]
⬜ 55667788 [4] — Carlos comunica a Ana el código que deberá repetir para abrir la consigna ⚡ "Faro siete" [Clínico — BREVE] [Ana, Carlos] [Zona: vestíbulo] [Props: consigna]
```

Al insertar, eliminar o reordenar beats, usa `renumber-siblings` desde el primer `seq` afectado. Solo cambia `seq`; `stable_id`, `parent_id` y las referencias externas permanecen intactos.

**Transición**: [Relación con el siguiente hecho o escena; puede ser elipsis, no exige acciones de enlace ni beat puente]

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

Solo se completan cuando el usuario exige palabras exactas o la literalidad tiene una función causal documentada y aprobada. La importancia de una revelación o decisión no basta. ⚡ significa literalidad REAL obligatoria, no ejemplo; se aplica `mecanica-prosa`. Una frase vigente incompatible con la revisión se remite al director para resolver antes de generar: no se parafrasea, omite ni reclasifica por iniciativa del escritor. Si no hay literalidad aprobada, esta sección no impone ninguna frase.

**Tensión sexual**:
- [Solo elementos aprobados pertinentes; sin obligación de completar una lista ni añadir tensión a una escena que no la contiene]

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

[Compromisos aprobados que deben realizarse y, para detalles o gestos concretos, su función narrativa. No convertir ejemplos de ejecución en obligaciones. No exige palabras exactas salvo literalidad aprobada según ⚡.]
-
-

## Notas adicionales

[Restricciones aprobadas y orientaciones de ritmo o enfoque. Identificar como opcionales los ejemplos de ejecución: no son canon ni obligaciones. Estas notas pertenecen al guion, no se reproducen como metatexto en la prosa.]
