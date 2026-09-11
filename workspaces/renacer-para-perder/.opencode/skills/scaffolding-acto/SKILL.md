---
name: scaffolding-acto
description: Esquema de un acto narrativo. Define los campos obligatorios y opcionales que debe contener un acto en el brief de Forja. Lo carga el scaffolder en Fase 5 y lo lee el guionista del workspace.
---

# Acto narrativo — esquema

Un **acto** es un bloque narrativo de alto nivel que agrupa hechos bajo un mismo arco emocional y de tensión. El scaffolder lo propone al final de la conversación de estructura; el guionista lo usa como entrada para generar escenas y beats.

## Campos

| Campo | Tipo | Obligatorio | Descripción |
|-------|------|:---:|-------------|
| `acto` | string | ✅ | Nombre del acto. No genérico ("Acto I"). Usar nombre descriptivo: "El shock", "La caída", "La reconstrucción". |
| `objetivo` | string | ✅ | Qué debe conseguir este acto narrativamente. Una frase. |
| `efecto_lector` | string | ✅ | Qué debe sentir el lector al terminar este acto. Emoción, no argumento. |
| `tension` | string | ✅ | Qué está en juego en este acto. El conflicto activo. |
| `hechos` | string[] | ✅ | Lista de hechos narrativos de este acto. Ver skill `scaffolding-hecho`. |

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
| **scaffolder** (hub) | Fase 5 | Proponer estructura al usuario. Rellenar `hechos` en el brief JSON. |
| **guionista** (workspace) | Modo estructura | Leer `_actos.md`. Analizar hechos. Agruparlos en escenas. Proponer cambios estructurales. |
| **director** (workspace) | Fase 1 | Presentar las propuestas del guionista al usuario. Confirmar acuerdos. Actualizar `_actos.md` si se modifica la estructura. |

## Potestad del guionista

El brief del scaffolder es un punto de partida, no una ley. El guionista puede proponer cualquier cambio que sirva a la historia: fusionar actos, dividirlos, reordenar hechos, refinar hechos vagos, ajustar objetivos narrativos, incluso redefinir la tensión de un acto si al desarrollarlo descubre que no funciona como se planeó. El director presenta la propuesta al usuario. Si el usuario aprueba, se aplica. La última palabra la tiene quien escribe.

## Relación con otros skills

- `scaffolding-hecho`: define el esquema de cada hecho individual.
- `scaffolding-relato`, `scaffolding-novela-simple`, `scaffolding-multi-hilo`: guían la conversación de estructura según escala.
