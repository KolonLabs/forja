---
name: hechos-distribuidos
description: Algoritmo de procesamiento de hechos [D] para el guionista. Inyección incremental de beats, cola de pendientes, revisión ligera post-inserción y renumeración.
---

# Hechos distribuidos [D]

Un hecho marcado `[D · H_XX–H_YY]` en `_actos.md` describe un patrón recurrente, rutina o evolución que no ocurre en un solo momento. No genera escenas propias: sus beats se inyectan en las escenas de los hechos lineales dentro de su rango.

## Formato de la marca

```
H_NN [D · H_XX–H_YY]: <descripción del hecho>
```

| Componente | Significado |
|-----------|-------------|
| `[D]` | Hecho distribuido (no genera escenas propias) |
| `H_XX–H_YY` | Rango de hechos lineales donde se despliega. `XX` = primer hecho donde puede inyectarse, `YY` = último hecho donde debe haberse completado |

El director puede añadir `[D · beats]` sin rango cuando delega la decisión del tramo al workspace.

## Algoritmo (para el guionista, modo `estructura`)

### Fase A — Escaneo inicial

1. Lee `_actos.md` completo.
2. Identifica todos los hechos marcados `[D]`. Anota: ID, descripción, rango (inicio, fin).
3. Crea (o limpia) el archivo `cola_d.md` en la raíz del workspace con la lista de pendientes:

```
# Cola de hechos distribuidos
| ID | Rango | Estado | Beats inyectados |
|----|-------|--------|-----------------:|
| H_07 | H_06–H_10 | pendiente | 0 |
| H_12 | H_11–H_16 | pendiente | 0 |
```

### Fase B — Pasada 1: solo hechos lineales

Procesa los hechos **en orden secuencial** (recorriendo `_actos.md`). En esta pasada, **ignora completamente los `[D]`**:

```
Para cada hecho en orden:
  1. Si es [D] → anótalo en cola_d.md. NO generes escenas ni beats. Pasa al siguiente.
  2. Si es lineal → genera escenas y beats normalmente. Escribe en guion.md.
```

Al terminar esta pasada, `guion.md` contiene **solo** las escenas de hechos lineales, con todos sus beats. Los `[D]` están pendientes en `cola_d.md`.

### Fase C — Intervención del director

El guionista devuelve el control al director con:
- `guion.md` (escenas lineales completas, con beats)
- `cola_d.md` (lista de `[D]` pendientes con sus rangos)

El director:

1. Revisa la estructura real de escenas.
2. Para cada `[D]` pendiente, decide:
   - Cuántos beats concretos (por defecto 2-3; 3-4 si el rango abarca >5 hechos lineales).
   - En qué **escenas concretas** (por nombre) se inyectará cada beat, basándose en las escenas que YA existen en `guion.md`.
   - Criterio narrativo para la inserción (momentos introspectivos, transiciones entre ubicaciones, etc.).
3. Escribe las anotaciones en `cola_d.md`:
   ```
   H_07 | H_06–H_10 | anotado | 3 |
   > 🎬 Director:
   > - Instancia 1: Escena "El parking" (H_05+H_06), tras el beat del encuentro. Muestra la mentira automática.
   > - Instancia 2: Escena "La fachada" (H_08+H_09), al inicio. Muestra rutina doméstica normal.
   > - Instancia 3: Escena "El mensaje" (H_10), como beat de contraste justo antes de la revelación.
   > 🔍 Revisión: ligera
   ```
4. Devuelve el control al guionista con `cola_d.md` actualizado.

### Fase D — Pasada 2: inyección de `[D]`

El guionista recibe `cola_d.md` con las anotaciones del director. Para cada `[D]`:

1. Lee las anotaciones: qué escenas, cuántos beats, dónde.
2. Inyecta cada beat en la escena indicada, en la posición sugerida.
3. Revisión ligera: lee el beat anterior y posterior a cada inserción. Ajusta frases de transición si hay fricción.
4. Renunera beats desde el primer punto de inserción.
5. Marca el `[D]` como `procesado` en `cola_d.md`.

**No crees escenas nuevas.** Los beats de un `[D]` siempre se inyectan en escenas ya existentes.

## Reglas estrictas de inyección

### Regla 1 — Sin escenas propias

Un hecho `[D]` **nunca** genera una escena dedicada exclusivamente a él. Sus beats deben inyectarse en escenas de hechos **lineales** del rango. Una escena cuyo único contenido son beats de un `[D]` es una violación.

```
✅ Correcto: escena del hecho H_13, con 1 beat de H_14‑D7 inyectado
❌ Incorrecto: escena "Interludio — Las quedadas" con 3 beats, todos de H_21‑D9/D10/D11 y ningún hecho lineal
```

### Regla 2 — No consecutivas, intercaladas

Las instancias del mismo `[D]` no pueden ser **beats consecutivos** — deben estar intercaladas con beats de hechos lineales. Pero SÍ pueden compartir escena si la estructura de beats lo permite y el director lo decide editorialmente. El director determina la colocación basándose en la estructura real de beats, no en una prohibición mecánica por escena. Dos `[D]` distintos pueden coincidir en una escena si el director lo justifica en sus anotaciones.

```
✅ Correcto: H_28‑D1 inyectado tras B_0120, H_28‑D2 inyectado tras B_0122.
            Ambos en la misma escena, pero separados por beats lineales.
❌ Incorrecto: H_21‑D9, H_21‑D10, H_21‑D11 como beats consecutivos B_0091–B_0093.
```

### Regla 3 — Sin hechos inventados

El guionista **nunca** crea hechos nuevos (H_NNNN) para anclar beats `[D]`. Los beats de un `[D]` se anclan al hecho lineal de la escena donde se inyectan. Si el guionista necesita más hechos, se lo pide al director.

```
✅ Correcto: beat de H_14‑D7 inyectado en escena de H_13 → el beat pertenece a H_13 en guion.md
❌ Incorrecto: H_25 inventado para agrupar beats D12-D16
```

### Regla 4 — Respetar el rango

Cada instancia de un `[D · H_XX–H_YY]` solo puede inyectarse en escenas que contengan hechos lineales del rango H_XX a H_YY. Una instancia fuera del rango es una violación.

### Regla 5 — Reparto equilibrado

Si un `[D]` tiene N instancias y el rango tiene M hechos lineales, el reparto debe ser equitativo: máximo 1 instancia por escena, idealmente distribuidas a lo largo de todo el rango, no concentradas al principio o al final.

| Situación | Dónde insertar |
|-----------|---------------|
| El `[D]` describe una rutina doméstica | Entre escenas, como beat de transición (ej. después de «llega a casa» y antes de «cena familiar») |
| El `[D]` describe un estado emocional del personaje | En beats introspectivos (ej. personaje a solas, en el baño, de noche) |
| El `[D]` describe una evolución de actitud | Al inicio o final de escenas donde el personaje interactúa con otros |
| El `[D]` describe encuentros recurrentes | En transiciones entre ubicaciones (ej. «camina hacia el metro» → beat de inserción → «llega al trabajo») |

## Protocolo de revisión ligera

Tras cada inserción, verifica:

1. **Transición anterior**: ¿el beat que precede a la inserción termina de forma que la inserción fluya? Si no, añade 1 frase de enlace al inicio del beat insertado.
2. **Transición posterior**: ¿el beat que sigue a la inserción arranca con naturalidad? Si no, añade 1 frase de enlace al final del beat insertado.
3. **Tono**: ¿el tono del beat insertado coincide con el tono de la escena que lo contiene? Si no, ajusta solo el tono del beat insertado.
4. **No tocar adyacentes**: nunca modifiques los beats ya generados.

## Renumeración

- Los IDs de beat son secuenciales: `B_0001`, `B_0002`...
- Tras una inserción, renumera desde el primer beat afectado hacia adelante.
- No cambies los IDs de hecho (`H_NNNN`).
- Actualiza `guion.md` con los nuevos IDs.

## Casos borde

### Varios [D] con el mismo fin_de_rango

Procesa en el orden en que aparecen en `_actos.md`. Inserta primero el que aparece antes. Renumera tras cada inserción.

### Rangos solapados

Si `H_07 [D · H_06–H_10]` y `H_08 [D · H_08–H_12]`, al cerrar H_10 inyecta H_07 primero. H_08 se inyectará al cerrar H_12. Los beats de H_08 se insertan en escenas del tramo H_08–H_12, que ya incluyen los beats inyectados de H_07 si solapan.

### [D] al inicio de un acto

Si el rango empieza en `H_01`, el `[D]` no puede inyectarse hasta que el hecho `H_01` esté generado. La primera oportunidad de inserción es al cerrar su `fin_de_rango`.

### [D] al final de un acto

Si el rango termina en el último hecho del acto, se inyecta al cerrar ese hecho, antes de pasar al acto siguiente.

### Acto sin hechos [D]

Si un acto no tiene marcas `[D]`, `cola_d.md` queda vacío. El flujo es idéntico al anterior.

## Quién lo carga

| Agente | Modo | Cuándo |
|--------|------|--------|
| `guionista` | `estructura` | Al iniciar, si `_actos.md` contiene alguna marca `[D]` |
| `director` | FASE 1 | Al leer `_actos.md`, para identificar `[D]` y añadir anotaciones antes de invocar al guionista |
