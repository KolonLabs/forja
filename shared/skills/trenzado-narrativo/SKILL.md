---
name: trenzado-narrativo
description: Define cómo entrelazar múltiples hilos narrativos independientes en capítulos, a nivel de escena. Criterios de alternancia, capítulos puente/espejo, descubrimiento de puntos de conexión y reglas de ritmo cross-hilo. Úsalo en FASE 0.4 (guionista modo trenzado).
user-invocable: false
---

# Skill: trenzado-narrativo

## Qué es el trenzado

El trenzado es el proceso de mover las **escenas** ya escritas de cada hilo —completas, con todos sus beats y con cualquier `[D]` ya resuelto— a los capítulos globales de la novela, decidiendo el orden y la alternancia entre hilos. Cada hilo se desarrolla primero de forma aislada (FASE 0.3, beats y escenas dentro del hilo) y solo entonces se entrelaza con los demás (FASE 0.4).

La **escena** (`stable_id`, sin display numérico propio) es la unidad atómica que se mueve. El beat no se toca ni se renumera globalmente; solo cambia `parent_id`/`seq` vía `renumber-siblings` al mover el bloque de escena completo.

## Cuándo usar este skill

Se carga en **FASE 0.4 — Trenzado** (`estado: trenzado`), después de que todos los hilos tengan `hilos[].estado = "beats_listos"`. El `guionista` lo usa en **modo: trenzado**; el `auditor-beats` lo usa en **modo: trenzado** para auditar la tabla ya generada (FASE 3.6).

---

## Tipos de capítulo por hilo

| Tipo | Descripción | Cuándo usarlo |
|------|-------------|---------------|
| **Exclusivo** | Un solo hilo ocupa todo el capítulo | Desarrollo profundo, clímax de hilo, presentación de personajes |
| **Puente** | Dos hilos se alternan dentro del mismo capítulo (bloques separados por `---`) | Acciones simultáneas en distintas épocas, revelaciones conectadas |
| **Espejo** | Dos hilos narran en paralelo mostrando el mismo objeto/acción en épocas distintas | Simbolismo, conexiones temáticas, foreshadowing |

---

## Reglas de alternancia

1. **Máximo 2 hilos por capítulo.** Alternar más fragmenta la lectura.
2. **Rachas máximas.** Un hilo no debe desaparecer más de 3 capítulos seguidos. El lector olvida la tensión.
3. **Clímax en exclusivo.** El clímax de cada hilo ocurre en un capítulo exclusivo. No se comparte el foco en el momento álgido.
4. **Puentes con propósito.** Cada capítulo puente debe tener una razón narrativa clara — una conexión real descubierta en el contenido, no forzada.
5. **Ritmo de alternancia.** No usar el mismo patrón todo el tiempo (ej. ABABAB). Variar: A, A, B, AB, B, A, AB... La monotonía es peor que el desorden.

---

## Los puntos de conexión son pista, no checklist

`guion-novela.md` trae una sección `## Puntos de conexión` escrita en FASE 0, **antes de que existiera ninguna escena** — es prosa temática ("Sara contacta a Vega vía un paper académico"), no una lista mecánica a verificar una por una. En FASE 0.4 ya existe el contenido real de todas las escenas de todos los hilos, con más detalle concreto del que había en el diseño original.

Tu trabajo no es solo confirmar lo ya anotado: es **leer el contenido real** y descubrir tú mismo dónde se materializa cada conexión —y cualquier eco orgánico que el diseño original no anticipó—. Al terminar, reescribes `## Puntos de conexión` sustituyendo la prosa temática por referencias concretas a `stable_id` de escena.

## Proceso de trenzado

### Paso 1: Leer el contenido íntegro de cada hilo

Lee `hilos/hilo-*/cap-NN/guion.md` completo — todas las escenas, con todos sus beats — de todos los hilos. No basta con metadatos o resúmenes: la conexión se descubre en el detalle concreto que solo existe ahora que hay beats escritos.

### Paso 2: Descubrir dónde se materializa cada conexión

Con `## Puntos de conexión` de `guion-novela.md` como pista temática, identifica en qué escena concreta (por `stable_id`) de cada hilo se materializa cada conexión anotada. Añade cualquier eco orgánico no previsto que detectes al leer el contenido real.

### Paso 3: Asignar escenas a capítulos globales

Agrupa escenas de uno o varios hilos en cada capítulo global, respetando las reglas de alternancia. Decide el tipo de cada capítulo (exclusivo, puente, espejo).

### Paso 4: Mover los bloques de escena

Para cada escena asignada: mueve el bloque completo (marcador `<!-- ESCENA <stable_id>: Nombre -->` + su encabezado `### E_NNNN` + todos sus beats; el director renumera después con `etiquetas-guion.py`) a `capitulos/cap-NN-slug/guion.md`. Aplica `renumber-siblings` sobre `parent_id`/`seq`. El `stable_id` de la escena y de cada beat **no cambia**.

### Paso 5: Generar la tabla y reescribir los puntos de conexión

Genera la tabla `## Trenzado` en `guion-novela.md` y reescribe `## Puntos de conexión` con las referencias concretas descubiertas.

### Paso 6: Validar la tabla

Comprueba contra las reglas de alternancia (máx. 2 hilos/capítulo, racha máx. 3, clímax en exclusivo, puentes con propósito). Ajusta si hace falta.

---

## Tabla de trenzado (formato de salida, en guion-novela.md)

```markdown
## Trenzado

| Cap | Hilo(s) | Escenas | Hechos | Tipo | Conexiones |
|-----|---------|---------|--------|------|------------|
| cap-01 | hilo-a | a1b2c3d4, e5f6a7b8 | H_0001, H_0002 | exclusivo | — |
| cap-02 | hilo-b | 11223344 | H_0031 | exclusivo | — |
| cap-03 | hilo-a | b2c3d4e5, c3d4e5f6 | H_0003, H_0004 | exclusivo | — |
| cap-04 | hilo-a, hilo-b | f6a7b8c9, d4e5f6a7 | H_0005, H_0032 | puente | escena f6a7b8c9 ↔ d4e5f6a7: el objeto compartido cambia de manos |
| ... | ... | ... | ... | ... | ... |
```

La columna **Escenas** es la unidad real que se movió al trenzar — siempre `stable_id`, nunca display. La columna **Hechos** es solo referencia de trazabilidad hacia `guion-hilo.md`; el trenzado no opera sobre ella.

---

## Indicadores de calidad del trenzado

- [ ] Ningún hilo ausente por >3 capítulos
- [ ] Clímax de cada hilo en capítulo exclusivo
- [ ] Puentes justificados por una conexión real descubierta en el contenido (no hay puentes "porque sí")
- [ ] Ritmo variado (no ABABAB monótono)
- [ ] Todas las escenas de todos los hilos asignadas a un capítulo global — sin escenas huérfanas
- [ ] `## Puntos de conexión` referencia `stable_id` de escena, no prosa genérica

---

## Errores comunes

- **Trenzar demasiado pronto.** No se trenza hasta que cada hilo tiene `hilos[].estado = "beats_listos"` — todos sus capítulos-borrador completos, con beats y escenas.
- **Verificar en vez de descubrir.** Tratar `## Puntos de conexión` como una lista cerrada a comprobar, en vez de leer el contenido real para encontrar dónde se materializa y qué ecos no previstos aparecieron.
- **Puentes vacíos.** Un capítulo con dos hilos que no se relacionan es dos medios capítulos, no un puente.
- **Hilo olvidado.** Si un hilo desaparece varios capítulos seguidos, el lector ha perdido el hilo emocional.
- **Clímax compartido.** El momento cumbre de un hilo no debería competir con otro clímax en el mismo capítulo.
- **Trenzar a nivel de hecho o de beat suelto.** La unidad que se mueve es la escena completa, con todos sus beats — nunca hechos ni beats individuales fuera de una escena.
