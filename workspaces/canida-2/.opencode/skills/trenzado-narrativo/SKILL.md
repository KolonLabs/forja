---
name: trenzado-narrativo
description: Define cómo entrelazar múltiples hilos narrativos independientes en capítulos. Criterios de alternancia, capítulos puente, puntos de conexión y reglas de ritmo cross-hilo. Úsalo al planificar el trenzado de una novela multi-hilo.
---

# Skill: trenzado-narrativo

## Qué es el trenzado

El trenzado es el proceso de decidir cómo se alternan los hilos narrativos en los capítulos de una novela. Los hilos se desarrollan primero de forma independiente y luego se entrelazan según un plan.

## Cuándo usar este skill

Se carga durante la **FASE de trenzado** (nueva fase del director, después de tener todos los hilos desarrollados con sus escenas y beats). El guionista lo usa en **modo: trenzado** para generar la tabla de alternancia.

---

## Tipos de capítulo por hilo

| Tipo | Descripción | Cuándo usarlo |
|------|-------------|---------------|
| **Exclusivo** | Un solo hilo ocupa todo el capítulo | Desarrollo profundo, clímax de hilo, presentación de personajes |
| **Puente** | Dos hilos se alternan dentro del mismo capítulo (separados por `---`) | Acciones simultáneas en distintas épocas, revelaciones conectadas |
| **Espejo** | Dos hilos narran en paralelo mostrando el mismo objeto/acción en épocas distintas | Simbolismo, conexiones temáticas, foreshadowing |

---

## Reglas de alternancia

1. **Máximo 2 hilos por capítulo.** Alternar más fragmenta la lectura.
2. **Rachas máximas.** Un hilo no debe desaparecer más de 3 capítulos seguidos. El lector olvida la tensión.
3. **Clímax en exclusivo.** El clímax de cada hilo ocurre en un capítulo exclusivo. No se comparte el foco en el momento álgido.
4. **Puentes con propósito.** Cada capítulo puente debe tener una razón narrativa clara (revelación compartida, contraste, conexión de objetos).
5. **Ritmo de alternancia.** No usar el mismo patrón todo el tiempo (ej: ABABAB). Variar: A, A, B, AB, B, A, AB... La monotonía es peor que el desorden.

---

## Proceso de trenzado

### Paso 1: Listar todos los beats de cada hilo
Tener los beats completos de cada hilo con sus IDs, escenas y extensión.

### Paso 2: Identificar puntos de conexión
Para cada hilo, marcar los beats que contienen elementos que aparecen en otros hilos:
- Objetos compartidos (la losa, el sigilo, el colgante)
- Personajes que aparecen en varias épocas (Naamah)
- Revelaciones que un hilo hace sobre otro (Daniel lee sobre Sumer)

### Paso 3: Agrupar beats en capítulos
Para cada hilo, agrupar beats en capítulos coherentes (12-18 beats por capítulo).

### Paso 4: Generar la tabla de trenzado
Alternar capítulos de cada hilo según las reglas. Priorizar:
1. Que los puntos de conexión de hilos distintos caigan en capítulos próximos (separados por 0-2 capítulos)
2. Que los clímax de hilo tengan capítulos exclusivos
3. Que ningún hilo desaparezca más de 3 capítulos

### Paso 5: Validar la tabla
Comprobar contra las reglas de alternancia. Ajustar si es necesario.

---

## Tabla de trenzado (formato de salida)

```markdown
## Trenzado

| Capítulo | Hilo(s) | Tipo | Beats | Función |
|----------|---------|------|-------|---------|
| CAP_01 | hilo-sumer | Exclusivo | B_001–B_015 | Presentación de Naamah y el templo |
| CAP_02 | hilo-sumer | Exclusivo | B_016–B_030 | El Sumo Sacerdote y el culto |
| CAP_03 | hilo-sello | Exclusivo | B_101–B_115 | La abadesa y el convento |
| CAP_04 | hilo-sello | Exclusivo | B_116–B_130 | La Inquisición se acerca |
| CAP_05 | hilo-soma | Exclusivo | B_201–B_215 | Daniel en Apex, vida antes del sigilo |
| CAP_06 | hilo-soma | Exclusivo | B_216–B_230 | Beatriz y Marcos, la oficina |
| CAP_07 | hilo-soma + hilo-sello | Puente | B_231–B_240 | Daniel activa el sigilo / Beatriz descubre el archivo |
| CAP_08 | hilo-sumer | Exclusivo | B_031–B_045 | Las sacerdotisas preparan el sellado |
| ... | ... | ... | ... | ... |
```

---

## Indicadores de calidad del trenzado

- [ ] Ningún hilo ausente por >3 capítulos
- [ ] Clímax de cada hilo en capítulo exclusivo
- [ ] Puentes justificados (no hay puentes "porque sí")
- [ ] Ritmo variado (no ABABAB monótono)
- [ ] Puntos de conexión próximos (≤2 capítulos de distancia)
- [ ] Total de capítulos dentro del objetivo (30-35)
- [ ] Cada capítulo tiene 12-18 beats

---

## Errores comunes

- **Trenzar demasiado pronto.** No se trenza hasta que cada hilo está completamente desarrollado con beats.
- **Puentes vacíos.** Un capítulo con dos hilos que no se relacionan es dos medios capítulos, no un puente.
- **Hilo olvidado.** Si un hilo desaparece 5 capítulos, el lector ha perdido el hilo emocional.
- **Clímax compartido.** El momento cumbre de un hilo no debería competir con otro clímax en el mismo capítulo.
