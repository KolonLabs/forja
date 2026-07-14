---
description: Revisa y afina los hechos de _actos.md antes de arrancar la generación. Evalúa lineales y [D] con criterios distintos.
agent: director
---

# /refinar-hechos

Revisa la calidad de los hechos narrativos en `_actos.md`. El objetivo es detectar y corregir hechos lineales vagos o no narrables, y asegurar que los hechos distribuidos `[D]` tengan rango válido y anotaciones del director. Los `[D]` son patrones por diseño — no se evalúan con criterios de concreción.

## Sintaxis

```
/refinar-hechos
```

## Proceso

El director:

1. Lee `_actos.md` y `BRIEF.md`
2. Carga el skill `scaffolding-hecho` (define qué es un hecho correcto, incluyendo hechos `[D]`)
3. **Separa hechos lineales y distribuidos.** Recorre la lista de hechos y clasifica cada uno:
   - Sin marca → **Lineal**. Se evalúa con checklist A.
   - `[D · H_XX–H_YY]` → **Distribuido**. Se evalúa con checklist B. **NUNCA uses criterios de lineal para un [D].**

### Checklist A — Hechos lineales

⚠️ **Esta checklist solo aplica a hechos SIN marca `[D]`.**

- **¿Concreto?** ¿Tiene sujeto, acción, consecuencia? ¿O es "descubre su sexualidad"?
- **¿Narrable?** ¿El guionista puede descomponerlo en beats? ¿O es demasiado abstracto?
- **¿Acotado?** ¿Cubre un solo evento? ¿O abarca demasiado (varios eventos inconexos)?

Si un hecho lineal falla en alguno de estos criterios, márcalo como problema. Propón una reformulación o división.

### Checklist B — Hechos distribuidos `[D]`

⚠️ **Los hechos `[D]` son patrones intencionales. No se espera que sean "concretos" ni "acotados".** Aplicar los criterios de la checklist A a un `[D]` es un error.

Evalúa SOLO:

- **¿El rango es coherente?** ¿El inicio y fin están dentro del mismo acto? ¿El fin ≥ inicio? ¿El rango contiene al menos 2 hechos lineales donde intercalarse?
- **¿El patrón es reconocible?** ¿El guionista entiende QUÉ tipo de beats debe inyectar? Si el patrón es demasiado genérico (ej. "Laura cambia" sin más), añade orientación en las anotaciones, no rechaces el hecho.
- **¿Hay anotaciones del director?** Si no las hay, decídelas ahora y escríbelas bajo el hecho en `_actos.md`:
  ```
  > 🎬 Director: N beats. Colócalos en escenas de H_XX y H_YY. Criterio: <específico>.
  > 🔍 Revisión: ligera | completa
  ```
  - **Nunca sugieras "reformular" un `[D]` para que sea más concreto.** Si el patrón necesita más definición, eso lo hará el guionista al inyectar los beats, con creatividad editorial propia. Tú solo aseguras rango válido + anotaciones.

### Evaluación del arco

4. Evalúa el arco completo:
   - ¿Hay vacíos narrativos entre hechos (saltos sin justificar)?
   - ¿Sobra o falta algún hecho?
   - ¿Los `[D]` están bien distribuidos (no se acumulan todos en un mismo tramo)?

5. Carga `hechos-distribuidos` si hay `[D]` pendientes de anotar.

6. Presenta diagnóstico al usuario. **Separa claramente:**
   - **Problemas en lineales:** hechos vagos, no acotados, no narrables → propón reformulaciones.
   - **`[D]` sin anotaciones:** hechos distribuidos que necesitan que el director decida granularidad.
   - **Vacíos narrativos:** saltos entre hechos que necesitan puente.

   **Prohibido:** no uses las palabras "vago", "abstracto", "resumen", "no es un hecho", "demasiado amplio" para describir un `[D]`. Son términos que solo aplican a lineales.

7. Si los cambios son complejos, invoca al `guionista` para que proponga refinamientos desde su criterio editorial. El guionista tiene libertad para expandir creativamente los `[D]`.

8. Con aprobación del usuario, actualiza `_actos.md` únicamente en `diseno`. En relato, desde `fichas` en adelante el archivo de hechos queda congelado para evitar desincronizar guion y draft; presenta el diagnóstico sin modificarlo.

### Gate

- Todos los hechos **lineales** pasan la checklist A (concretos, narrables, acotados).
- Todos los hechos **`[D]`** tienen rango válido y anotaciones del director.
- El arco narrativo no tiene vacíos inexplicados.

## Cuándo usarlo

- Después de `/nuevo-proyecto`, antes de `/generar` — recomendado
- En cualquier momento de FASE 1 si el guionista detecta hechos problemáticos al agruparlos
- Si `/generar` se ejecuta sin pasar por este comando, el guionista actuará como validador natural: al intentar agrupar un hecho vago, lo reportará al director

## Notas

- Es opcional. `/generar` puede ejecutarse directamente con los hechos tal cual vienen de Forja.
- El skill `scaffolding-hecho` está disponible en el workspace (cargado desde shared).
- **Los hechos `[D]` no son defectos.** Son el contrato entre el scaffolder (define el patrón a alto nivel) y el workspace (lo expande con creatividad editorial). No esperes que un `[D]` sea concreto — espera que sea claro en su intención y tenga rango válido.
