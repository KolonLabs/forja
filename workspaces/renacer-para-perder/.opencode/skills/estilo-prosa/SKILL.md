---
name: estilo-prosa
description: Meta-skill que define la estructura que debe tener un skill de estilo narrativo. El guionista y el director lo usan para crear o validar nuevos estilos.
compatibility: opencode
---

# Skill: estilo-prosa

## Qué es

Define la anatomía de un skill de estilo narrativo. Cada estilo concreto (`estilo-noir`, `estilo-erotico`, etc.) sigue esta estructura. Un estilo es una **voz completa** que contiene su propio vocabulario, ritmo, tratamiento del cuerpo y ejemplos canónicos. No hereda de otros estilos — es autocontenido.

---

## Estructura de un skill de estilo

```markdown
---
name: estilo-<nombre>
description: Voz narrativa <nombre>: vocabulario, ritmo, tratamiento del cuerpo, crudeza y ejemplos.
compatibility: opencode
---

# Estilo: <Nombre>

## Carácter de la voz
[2-3 frases que capturen la esencia del estilo. No reglas — atmósfera, intención, sensación.]

## Vocabulario
- **Campo semántico:** [callejero, poético, técnico, sensorial, seco...]
- **Verbos:** [energía y registro: cortantes, fluidos, quirúrgicos...]
- **Adjetivación:** [densidad y tipo: escasa y funcional, abundante y sensorial...]
- **Prohibido:** [lo que esta voz nunca haría: metáforas florales, tecnicismos, etc.]

## Ritmo
- **Carácter de frase:** [cortante, fluida, entrecortada, pausada...]
- **Alternancia:** [cómo respira el texto: frase larga + frase corta + silencio...]

## Tratamiento del cuerpo
- **Distancia de cámara:** [fría, cómplice, quirúrgica, obscena, elíptica...]
- **Vocabulario anatómico:** [registro específico para esta voz: directo, clínico, metafórico...]
- **Acciones sexuales:** [cómo esta voz describe el sexo: enumerativo, sensorial, atmosférico...]

## Crudeza
- **Nivel base:** [1-5]
- **Carácter:** [integrado en la voz, no añadido: "la crudeza es parte del paisaje, no el paisaje"]

## Escenas
- **Tensión:** [cómo construye y libera tensión esta voz]
- **Geometría:** [tratamiento del espacio y los cuerpos: preciso, sugerido, coreográfico...]

## Ejemplos canónicos
[2-3 fragmentos que muestren la voz, no que la expliquen. Cada ejemplo ilustra un aspecto distinto: diálogo, descripción, escena explícita.]
```

---

## Reglas para skills de estilo

1. **Autocontenido.** Un estilo no referencia a otro. Si comparten vocabulario, cada uno lo define.
2. **Voz, no manual.** No hay límites numéricos ("máximo 3 adjetivos"). Hay carácter ("adjetivación escasa").
3. **Ejemplos que muestran.** No explicar el estilo — mostrarlo con fragmentos canónicos.
4. **Un archivo por estilo.** `estilo-noir/SKILL.md`, `estilo-erotico/SKILL.md`, etc.
5. **Carga independiente.** El director o escritor carga el estilo activo sin cargar otros.
