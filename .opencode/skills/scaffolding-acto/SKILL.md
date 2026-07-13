---
name: scaffolding-acto
description: Esquema de un acto narrativo. Define los campos obligatorios y opcionales que debe contener un acto en el brief de Forja. Lo carga el scaffolder en Fase 5.
---

# Acto narrativo — esquema

Un **acto** es un bloque narrativo de alto nivel que agrupa hechos bajo un mismo arco emocional y de tensión. El scaffolder lo propone al final de la conversación de estructura; el workspace lo usará como entrada para generar escenas y beats.

## Campos

| Campo | Tipo | Obligatorio | Descripción |
|-------|------|:---:|-------------|
| `acto` | string | ✅ | Nombre del acto. No genérico ("Acto I"). Usar nombre descriptivo: "El shock", "La caída", "La reconstrucción". |
| `objetivo` | string | ✅ | Qué debe conseguir este acto narrativamente. Una frase. |
| `efecto_lector` | string | ✅ | Qué debe sentir el lector al terminar este acto. Emoción, no argumento. |
| `tension` | string | ✅ | Qué está en juego en este acto. El conflicto activo. |
| `hechos` | string[] | ✅ | Lista de hechos narrativos de este acto. Ver skill `scaffolding-hecho`. |
| `hilo` | string | Solo multi-hilo | Slug del hilo al que pertenece este acto. En novela-simple no se incluye. |

## Ejemplo

```json
{
  "acto": "Acto I — El shock",
  "objetivo": "El deseo irrumpe en la vida de Miguel sin que él lo busque. De voyeur involuntario a primer encuentro sexual.",
  "efecto_lector": "Incomodidad y fascinación: el lector siente que está presenciando algo prohibido que no debería estar viendo.",
  "tension": "Miguel no buscaba esto. No puede dejar de pensar en ello. No puede contárselo a nadie. La imagen lo persigue.",
  "hechos": [
    "Miguel presencia un encuentro sexual entre dos hombres en el parking de su oficina...",
    "Días después, busca deliberadamente un encuentro en un baño público..."
  ]
}
```

## Quién lo usa

| Agente | Cuándo | Para qué |
|--------|--------|----------|
| **scaffolder** (hub) | Fase 5 | Proponer estructura al usuario. Rellenar `hechos` en el brief JSON. Conocer el esquema que espera el workspace. |

## Relación con otros skills

- `scaffolding-hecho`: define el esquema de cada hecho individual.
- `scaffolding-relato`, `scaffolding-novela-simple`, `scaffolding-multi-hilo`: guían la conversación de estructura según escala.
