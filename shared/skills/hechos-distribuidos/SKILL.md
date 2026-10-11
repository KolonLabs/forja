---
name: hechos-distribuidos
description: Algoritmo de procesamiento de hechos [D] — en novela simple, cola de inyección diferida por stable_id sobre escenas ya generadas; en novela multi-hilo, una sola pasada creativa por capítulo-borrador con checkpoints, antes del trenzado.
user-invocable: false
---

# Hechos distribuidos [D]

Un hecho marcado `[D · H_XX–H_YY]` describe un patrón recurrente, rutina o evolución que no ocurre en un solo momento. No genera escenas propias: sus beats se despliegan dentro del rango de hechos lineales que indica.

**El algoritmo para resolverlo es distinto por escala — comparten el concepto, no el mecanismo.** Carga solo la sección que corresponde a tu escala actual:

- **Novela simple**: `[D]` se resuelve en escritura (FASE 3), con una cola de inyección diferida sobre escenas ya generadas (dos pasadas: lineales primero, `[D]` después). Ver `## Novela simple` abajo.
- **Novela multi-hilo**: `[D]` se resuelve por completo en FASE 0.3, antes de que exista ningún capítulo global, en una sola pasada creativa dentro de un único hilo. Ver `## Novela multi-hilo` abajo.

## Formato de la marca (común a ambas escalas)

```text
H_NN [D · H_XX–H_YY]: descripción del hecho
```

| Componente | Significado |
|------------|-------------|
| `[D]` | Hecho distribuido; no genera escenas propias |
| `H_XX–H_YY` | Rango de hechos lineales donde se despliega |

En **novela multi-hilo** el rango es siempre **intra-hilo** (un hecho vive en un solo hilo; el rango nunca cruza a otro hilo). En **novela simple** no aplica esa restricción — el rango es sobre los hechos del propio `_actos.md`.

---

## Novela simple

### Identidad de los puntos de inserción

Cada beat tiene:

- `stable_id`: identidad opaca e inmutable.
- `seq`: posición local a su `parent_id`.
- Display humano: `e5f6g7h8 [25]`, derivado de `seq` al presentar y nunca almacenado.

Las operaciones, gates y referencias cruzadas usan `stable_id`. El display aparece entre paréntesis únicamente para facilitar la lectura humana.

Formato obligatorio de anotación:

```text
tras stable_id (e5f6g7h8 [25]) en Escena 4
```

Ejemplo real:

```text
tras a1b2c3d4 (e5f6g7h8 [25]) en Escena 4
```

`e5f6g7h8 [25]` no identifica el punto de inserción: puede cambiar al renumerar. `a1b2c3d4` sí lo identifica y permanece estable.

### Algoritmo para el guionista, modo `estructura-novela`

#### Fase A — Escaneo inicial

1. Lee `_actos.md` completo.
2. Identifica todos los hechos `[D]`: stable_id o ID del hecho, descripción y rango.
3. Crea o limpia `cola_d.md`:

```text
# Cola de hechos distribuidos
| ID | Rango | Estado | Beats inyectados |
|----|-------|--------|-----------------:|
| H_07 | H_06–H_10 | pendiente | 0 |
| H_12 | H_11–H_16 | pendiente | 0 |
```

#### Fase B — Pasada 1: hechos lineales

Procesa `_actos.md` en orden:

1. Si el hecho es `[D]`, anótalo en `cola_d.md`; no generes escenas ni beats.
2. Si es lineal, genera sus escenas y beats normalmente en `guion.md`.

Al terminar, `guion.md` contiene solo escenas de hechos lineales y `cola_d.md` contiene los `[D]` pendientes.

#### Fase C — Intervención del director

El director revisa las escenas reales y, para cada `[D]` pendiente:

1. Decide cuantas instancias necesita por la evolucion y consecuencias del patron, sin cuota por longitud del rango. Cada instancia debe aportar algo distinto; su cantidad no prueba cobertura.
2. Elige cada punto por `stable_id` de beat, no por display.
3. Añade el display derivado entre paréntesis solo como ayuda visual.
4. Declara escena y criterio narrativo.

```text
H_07 | H_06–H_10 | anotado | 3 |
> Director:
> - Instancia 1: tras a1b2c3d4 (e5f6g7h8 [25]) en Escena 4 "El parking". Muestra la mentira automática al volver.
> - Instancia 2: tras e5f6a7b8 (B_0027) en Escena 5 "La fachada". Muestra rutina doméstica normal.
> - Instancia 3: tras 11223344 (B_0035) en Escena 6 "El mensaje". Contraste antes de la revelación.
> Revisión: ligera
```

#### Gate obligatorio

Cada instancia debe contener un `stable_id` válido en la fórmula `tras <stable_id> (B_NNNN) en Escena N`.

- El gate valida `stable_id`.
- No valida la posición usando `B_NNNN`.
- Si falta `stable_id`, el pipeline se detiene aunque exista display.
- Si display y `seq` actual discrepan, se recalcula el display; no se cambia `stable_id`.

#### Fase D — Pasada 2: inyección

Para cada `[D]` anotado:

1. Localiza el beat ancla mediante `stable_id`.
2. Verifica que pertenece a la escena indicada.
3. Inyecta el beat en la posición definida.
4. Lee el beat anterior y posterior; ajusta solo el beat insertado si hay fricción.
5. Reordena los hermanos afectados cambiando `seq` local al mismo `parent_id`.
6. Marca el `[D]` como `procesado` en `cola_d.md`.

No crees escenas nuevas. Los beats `[D]` se insertan en escenas lineales existentes.

### Operaciones atómicas

Carga `skill({ name: "cronista-ops" })` antes de persistir inserciones, eliminaciones o reordenamientos.

- Usa las operaciones atómicas descritas en `cronista-ops`.
- Para abrir o cerrar huecos, aplica `renumber-siblings` desde el primer `seq` afectado.
- Filtra por `parent_id`.
- Persiste el beat nuevo con su propio `stable_id`.
- Reintentar una operación debe ser idempotente y no crear duplicados.

### Reglas estrictas

**1. Sin escenas propias.** Un `[D]` nunca genera una escena dedicada exclusivamente a él.

```text
Correcto: escena del hecho H_13 con un beat de H_14-D7 inyectado.
Incorrecto: escena "Interludio" formada solo por beats distribuidos.
```

**2. Instancias intercaladas.** Las instancias del mismo `[D]` no pueden ser beats consecutivos. Pueden compartir escena si quedan separadas por beats lineales.

```text
Correcto: inserciones tras a1b2c3d4 (B_0120) y e5f6a7b8 (B_0122), separadas por un beat lineal.
Incorrecto: tres instancias seguidas sin beats lineales entre ellas.
```

Dos `[D]` distintos pueden coincidir en una escena si el director lo justifica.

**3. Sin hechos inventados.** El guionista no crea hechos nuevos para anclar un `[D]`. El beat inyectado se vincula al hecho lineal de la escena receptora.

**4. Respetar el rango.** Cada instancia de `[D · H_XX–H_YY]` solo puede aparecer en escenas de hechos lineales dentro de ese rango.

**5. Reparto equilibrado.** Distribuye las instancias a lo largo del rango. Evita concentrarlas al inicio o final salvo justificación editorial.

| Situación | Inserción recomendada |
|-----------|-----------------------|
| Rutina doméstica | Transiciones entre escenas |
| Estado emocional | Beats introspectivos |
| Evolución de actitud | Inicio o final de interacciones |
| Encuentros recurrentes | Transiciones entre ubicaciones |

### Revisión ligera

Tras cada inserción:

1. Comprueba la transición desde el beat anterior.
2. Comprueba la transición hacia el beat posterior.
3. Ajusta el tono del beat insertado si no encaja.
4. No modifiques los beats adyacentes.

### Renumeración

- `stable_id` es inmutable.
- Renumerar cambia solo `seq`.
- `seq` siempre es local a `parent_id`.
- Displays como `B_0001` se recalculan a partir de `seq` en presentación.
- Las anotaciones de `cola_d.md` sobreviven porque referencian `stable_id`.
- Los IDs de hechos no se cambian como efecto colateral de una inserción de beats.
- Toda renumeración persistente se ejecuta mediante las operaciones atómicas de `cronista-ops`.

### Casos borde

**Varios `[D]` con el mismo fin de rango.** Procesa en el orden de `_actos.md`. Inserta uno, aplica la operación atómica de reordenamiento y continúa con el siguiente usando los `seq` actuales.

**Rangos solapados.** Procesa primero el hecho cuyo cierre corresponda. Las anotaciones siguen válidas porque apuntan a `stable_id`, aunque los displays hayan cambiado.

**`[D]` al inicio de un acto.** No se inyecta hasta que exista al menos una escena lineal del rango.

**`[D]` al final de un acto.** Se inyecta antes de pasar al acto siguiente.

**Acto sin `[D]`.** `cola_d.md` queda vacío y no se ejecutan operaciones de inserción.

### Quién lo carga (novela simple)

| Agente | Modo | Cuándo |
|--------|------|--------|
| `guionista` | `estructura-novela` | Si `_actos.md` contiene `[D]` |
| `director` | Diseño/guion | Para anotar puntos exactos y validar el gate |
| `director` o `cronista` | Operación atómica | Para cargar `cronista-ops` al persistir y reordenar |

---

## Novela multi-hilo

Se resuelve por completo en **FASE 0.3** (`guionista` modo `hilo-capitulo`). Al terminar esa fase, ningún beat conserva marca `[D]`: son indistinguibles de los lineales.

### Principio: juicio narrativo, no fórmula

No existe un número fijo de instancias (2-3, 3-4, etc.). El número de instancias de un `[D]` es una **decisión narrativa contextual**, razonada caso por caso, informada por:

- El peso narrativo del patrón descrito en la prosa del hecho.
- Cuánto espacio/trama queda por delante en el rango.
- Lo que ya se escribió en capítulos-borrador anteriores del mismo `[D]` (consultar `hilos/hilo-<slug>/cola_d.md`).

Un `[D]` que describe "Elena empieza a notar pequeñas cosas" puede requerir 2 pinceladas. Uno que describe "el cuerpo de Marco se deteriora durante meses" puede requerir bastante más rastro. El director y el guionista lo deciden juntos en el Checkpoint 1 de cada capítulo-borrador afectado.

### `cola_d.md` como registro de contenido

`hilos/hilo-<slug>/cola_d.md` **no es una cola de inyección** — es un registro de lo que ya se escribió, para evitar repetición entre capítulos-borrador que comparten un mismo `[D]` de rango amplio. Lo mantiene el director tras cada Checkpoint 2.

#### Formato

```text
# Registro de [D] — hilo-<slug>

## H_09 [D · H_08-H_13]: Elena empieza a notar cosas que antes no veía

| Instancia | Cap-borrador | Escena | Beat (stable_id) | Resumen |
|-----------|-------------|--------|-------------------|---------|
| 1 | cap-02 | Escena 3 "El taller" | a1b2c3d4 | Elena nota el contraste entre cómo trata sus propias herramientas y cómo la tratan a ella — primera vez que no lo ve como normal |
| 2 | cap-03 | Escena 1 "La cocina" | e5f6a7b8 | Un comentario ajeno sobre el tema y Elena calla — algo en ese silencio es nuevo |
| 3 | cap-03 | Escena 4 "De vuelta" | 11223344 | De noche, sola, repasa mentalmente lo que ha dejado pasar — no se lo dice a nadie |

**Estado:** cerrado (último cap-borrador del rango procesado)
```

Cada entrada de instancia registra: `stable_id` del beat generado + escena donde quedó + resumen corto de qué muestra.

#### Ciclo de vida

1. Se crea (o se añade a él) tras el primer capítulo-borrador que contiene un `[D]` con instancias.
2. Se actualiza tras cada Checkpoint 2 de capítulos-borrador posteriores que tocan el mismo `[D]`.
3. Cuando un `[D]` completa su rango (último capítulo-borrador que lo toca, confirmado en el Checkpoint 2), su entrada se marca como **cerrado**.
4. Cuando **todos** los `[D]` del hilo están cerrados, `cola_d.md` se descarta — no sobrevive a FASE 0.3.

### Flujo por capítulo-borrador (FASE 0.3)

#### Si el capítulo-borrador no contiene ningún `[D]` en su rango

El `guionista` modo `hilo-capitulo` genera beats de todos los hechos del rango y los agrupa en escenas en una sola pasada. **Siempre** hay un checkpoint tras la agrupación: el director + usuario revisan la estructura de escenas (número, beats por escena, cortes) — más ligero que los checkpoints de `[D]` (no hay instancias que validar), pero necesario para que la decisión de agrupación no quede sin validación.

#### Si el capítulo-borrador contiene al menos un `[D]` en su rango

**Checkpoint 1 — Plan (guionista → director + usuario).** El guionista **propone**, para cada `[D]` del rango:

- **Qué instancias** va a escribir en este tramo: contenido aproximado, no solo número.
- **Cuántas** instancias (juicio narrativo contextual, sin fórmula fija).
- Si el `[D]` cruza varios capítulos-borrador: cuántas instancias van en este y cuántas reserva para los siguientes.

Se informa de la prosa del hecho `[D]` y de `hilos/hilo-<slug>/cola_d.md` (instancias ya escritas en capítulos-borrador anteriores del mismo `[D]`), para no repetir contenido.

El director + usuario validan o ajustan el plan. **No se avanza sin confirmación.**

**Generación + agrupación (una sola pasada).** Tras validación: el guionista genera la secuencia **completa** de beats del tramo — lineales y `[D]` entretejidos de forma natural según el plan aprobado — y luego agrupa esa secuencia en escenas. Sin inyección diferida: todo junto, en orden narrativo natural.

Las instancias del mismo `[D]` no deben ser consecutivas. Pueden compartir escena si quedan separadas por beats lineales. Dos `[D]` distintos pueden coincidir en una escena si el plan lo justifica.

**Checkpoint 2 — Resultado (director + usuario).** Revisan beats + escenas ya agrupadas, verificando:

- Que las instancias `[D]` no repiten lo ya escrito en tramos anteriores (contra `cola_d.md`).
- Que las instancias están bien distribuidas a lo largo del tramo (no concentradas al inicio o final salvo justificación).
- Que el tono y ritmo del tramo completo funcionan.

Si se detecta repetición o problemas de ritmo, se ajusta vía `guionista` modo `revision` sobre el tramo afectado.

**Registro de contenido (director).** Tras el Checkpoint 2 aprobado, el director actualiza `hilos/hilo-<slug>/cola_d.md` con las nuevas instancias (stable_id del beat + escena + resumen). Si algún `[D]` completa su rango en este capítulo-borrador, se cierra su entrada.

### Cierre del hilo

Cuando todos los capítulos-borrador del hilo están completos y todos los `[D]` del hilo tienen sus entradas **cerradas** en `cola_d.md`, el director marca `hilos[].estado = "beats_listos"`. `cola_d.md` se descarta (todas las entradas cerradas, sin contenido pendiente).

### Guías de estilo para la generación

Sin reglas fijas de cantidad, estas son guías cualitativas:

| El patrón describe... | Sugerencia |
|-----------------------|------------|
| Rutina doméstica o cotidiana | Entretejer en transiciones entre escenas, casi como ruido de fondo |
| Estado emocional o percepción | Beats introspectivos, al final de interacciones |
| Evolución de actitud | Inicio o final de interacciones con otros personajes, donde se note el contraste |
| Deterioro físico o progresión | Distribuir con ritmo creciente si se agrava, o constante si es mantenido |
| Encuentros o situaciones recurrentes | Transiciones entre ubicaciones, sin robar foco a los lineales |

### Operaciones atómicas

Carga `skill({ name: "cronista-ops" })` antes de persistir inserciones, eliminaciones o reordenamientos.

- Usa las operaciones atómicas descritas en `cronista-ops`.
- `stable_id` es inmutable.
- `seq` siempre es local a `parent_id` (la escena).
- Toda renumeración persistente se ejecuta mediante las operaciones atómicas de `cronista-ops`.

### Quién lo carga (novela multi-hilo)

| Agente | Modo | Cuándo |
|--------|------|--------|
| `guionista` | `hilo-capitulo` | FASE 0.3 — para proponer el plan de instancias (Checkpoint 1) y generar los beats entretejidos |
| `director` | — | FASE 0.3 — para validar los checkpoints y mantener `cola_d.md` como registro de contenido |
