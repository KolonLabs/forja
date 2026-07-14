---
name: plantilla-guion
description: Plantilla del guion de relato basado en beats globales y escenas derivadas.
---

# Guion de relato

El guion se construye en dos pasos: primero se valida el mapa completo de `B_XXXX`; después se crean `E_XXXX` para agrupar beats contiguos. No incluye identificadores opacos ni secuencias locales.

```markdown
# Guion — [TÍTULO]

## Premisa

[Una frase]

## Mapa de beats y escenas

### E_0001 — [Nombre]

- Ubicación: [lugar]
- Tiempo: [momento y continuidad]
- POV: [personaje o narrador]
- Objetivo: [qué debe cambiar]
- Tensión: [conflicto activo]
- Resultado: [estado al cierre]
- Transición: [puente hacia E_0002]
- Hechos cubiertos: H_0001, H_0002

#### Beats

⬜ B_0001 — [acción causal] [Tono — BREVE] {H_0001}
⬜ B_0002 — [consecuencia] [Tono — MEDIA] {H_0001}
⬜ B_0003 — [acción puente] [Tono — BREVE] {D:H_0002}

---

### E_0002 — [Nombre]
...

## Arco verificado

- Inicio: ...
- Desarrollo: ...
- Clímax: ...
- Desenlace: ...
```

Reglas:

1. Cada `B_XXXX` aparece una sola vez y pertenece a una sola escena.
2. Los beats de una escena son contiguos en el orden narrativo.
3. Una escena no se crea por cantidad: requiere continuidad de tiempo/espacio/POV y una unidad dramática propia.
4. `H_XXXX` y `B_XXXX` no se renumeran. Una `E_XXXX` puede reagruparse en corrección, manteniendo su ID si conserva su función; una escena nueva usa el siguiente ID.
