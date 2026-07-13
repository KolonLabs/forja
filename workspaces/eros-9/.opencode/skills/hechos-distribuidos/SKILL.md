---
name: hechos-distribuidos
description: Algoritmo de procesamiento de hechos [D] para inyectar beats mediante stable_id, mantener cola_d.md y reordenar seq de forma atómica.
---

# Hechos distribuidos [D]

Un hecho marcado `[D · H_XX–H_YY]` en `_actos.md` describe un patrón recurrente, rutina o evolución que no ocurre en un solo momento. No genera escenas propias: sus beats se inyectan en escenas de hechos lineales dentro de su rango.

## Formato de la marca

```text
H_NN [D · H_XX–H_YY]: descripción del hecho
```

| Componente | Significado |
|------------|-------------|
| `[D]` | Hecho distribuido; no genera escenas propias |
| `H_XX–H_YY` | Rango de hechos lineales donde se despliega |

El director puede usar `[D · beats]` sin rango cuando delega la decisión del tramo al workspace.

## Identidad de los puntos de inserción

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

## Algoritmo para el guionista, modo `estructura`

### Fase A — Escaneo inicial

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

### Fase B — Pasada 1: hechos lineales

Procesa `_actos.md` en orden:

1. Si el hecho es `[D]`, anótalo en `cola_d.md`; no generes escenas ni beats.
2. Si es lineal, genera sus escenas y beats normalmente en `guion.md`.

Al terminar, `guion.md` contiene solo escenas de hechos lineales y `cola_d.md` contiene los `[D]` pendientes.

### Fase C — Intervención del director

El director revisa las escenas reales y, para cada `[D]` pendiente:

1. Decide cuántas instancias necesita: 2-3 por defecto; 3-4 si abarca más de cinco hechos lineales, salvo criterio editorial distinto.
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

### Gate obligatorio

Cada instancia debe contener un `stable_id` válido en la fórmula `tras <stable_id> (B_NNNN) en Escena N`.

- El gate valida `stable_id`.
- No valida la posición usando `B_NNNN`.
- Si falta `stable_id`, el pipeline se detiene aunque exista display.
- Si display y `seq` actual discrepan, se recalcula el display; no se cambia `stable_id`.

### Fase D — Pasada 2: inyección

Para cada `[D]` anotado:

1. Localiza el beat ancla mediante `stable_id`.
2. Verifica que pertenece a la escena indicada.
3. Inyecta el beat en la posición definida.
4. Lee el beat anterior y posterior; ajusta solo el beat insertado si hay fricción.
5. Reordena los hermanos afectados cambiando `seq` local al mismo `parent_id`.
6. Marca el `[D]` como `procesado` en `cola_d.md`.

No crees escenas nuevas. Los beats `[D]` se insertan en escenas lineales existentes.

## Operaciones atómicas

Carga `skill({ name: "cronista-ops" })` antes de persistir inserciones, eliminaciones o reordenamientos.

- Usa las operaciones atómicas descritas en `cronista-ops`.
- Para abrir o cerrar huecos, aplica `renumber-siblings` desde el primer `seq` afectado.
- Filtra por `parent_id`; en multi-hilo, incluye también `hilo` cuando aplique.
- Persiste el beat nuevo con su propio `stable_id`.
- Reintentar una operación debe ser idempotente y no crear duplicados.

## Reglas estrictas

### 1. Sin escenas propias

Un `[D]` nunca genera una escena dedicada exclusivamente a él.

```text
Correcto: escena del hecho H_13 con un beat de H_14-D7 inyectado.
Incorrecto: escena "Interludio" formada solo por beats distribuidos.
```

### 2. Instancias intercaladas

Las instancias del mismo `[D]` no pueden ser beats consecutivos. Pueden compartir escena si quedan separadas por beats lineales.

```text
Correcto: inserciones tras a1b2c3d4 (B_0120) y e5f6a7b8 (B_0122), separadas por un beat lineal.
Incorrecto: tres instancias seguidas sin beats lineales entre ellas.
```

Dos `[D]` distintos pueden coincidir en una escena si el director lo justifica.

### 3. Sin hechos inventados

El guionista no crea hechos nuevos para anclar un `[D]`. El beat inyectado se vincula al hecho lineal de la escena receptora.

### 4. Respetar el rango

Cada instancia de `[D · H_XX–H_YY]` solo puede aparecer en escenas de hechos lineales dentro de ese rango.

### 5. Reparto equilibrado

Distribuye las instancias a lo largo del rango. Evita concentrarlas al inicio o final salvo justificación editorial.

| Situación | Inserción recomendada |
|-----------|-----------------------|
| Rutina doméstica | Transiciones entre escenas |
| Estado emocional | Beats introspectivos |
| Evolución de actitud | Inicio o final de interacciones |
| Encuentros recurrentes | Transiciones entre ubicaciones |

## Revisión ligera

Tras cada inserción:

1. Comprueba la transición desde el beat anterior.
2. Comprueba la transición hacia el beat posterior.
3. Ajusta el tono del beat insertado si no encaja.
4. No modifiques los beats adyacentes.

## Renumeración

- `stable_id` es inmutable.
- Renumerar cambia solo `seq`.
- `seq` siempre es local a `parent_id`; en multi-hilo puede filtrarse además por `hilo`.
- Displays como `B_0001` se recalculan a partir de `seq` en presentación.
- Las anotaciones de `cola_d.md` sobreviven porque referencian `stable_id`.
- Los IDs de hechos no se cambian como efecto colateral de una inserción de beats.
- Toda renumeración persistente se ejecuta mediante las operaciones atómicas de `cronista-ops`.

## Casos borde

### Varios `[D]` con el mismo fin de rango

Procesa en el orden de `_actos.md`. Inserta uno, aplica la operación atómica de reordenamiento y continúa con el siguiente usando los `seq` actuales.

### Rangos solapados

Procesa primero el hecho cuyo cierre corresponda. Las anotaciones siguen válidas porque apuntan a `stable_id`, aunque los displays hayan cambiado.

### `[D]` al inicio de un acto

No se inyecta hasta que exista al menos una escena lineal del rango.

### `[D]` al final de un acto

Se inyecta antes de pasar al acto siguiente.

### Acto sin `[D]`

`cola_d.md` queda vacío y no se ejecutan operaciones de inserción.

## Quién lo carga

| Agente | Modo | Cuándo |
|--------|------|--------|
| `guionista` | `estructura` | Si `_actos.md` contiene `[D]` |
| `director` | Diseño/guion | Para anotar puntos exactos y validar el gate |
| `director` o `cronista` | Operación atómica | Para cargar `cronista-ops` al persistir y reordenar |

