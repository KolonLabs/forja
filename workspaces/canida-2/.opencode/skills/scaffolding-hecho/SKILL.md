---
name: scaffolding-hecho
description: Esquema de un hecho narrativo. Define qué es y qué no es un hecho en el brief de Forja. Lo carga el scaffolder en Fase 5 y lo lee el guionista del workspace.
---

# Hecho narrativo — esquema

Un **hecho** es un evento narrativo de alto nivel que describe QUÉ ocurre, no CÓMO se cuenta. Es la unidad más grande que define Forja: las escenas y los beats los genera el guionista en el workspace a partir de estos hechos.

## Qué es un hecho

- ✅ Un evento concreto con sujeto, acción y consecuencia: "Miguel presencia un encuentro sexual en el parking. Uno lo mira. Se queda paralizado."
- ✅ Algo que ocurre y cambia el estado de la historia.
- ✅ Suficientemente detallado para que el guionista pueda descomponerlo en escenas y beats.
- ✅ Implica acción física o decisión del personaje.

## Qué NO es un hecho

- ❌ Un estado de ánimo sin acción: "Miguel se siente culpable."
- ❌ Un resumen de intenciones: "Miguel explora su sexualidad."
- ❌ Una escena ya definida (con ubicación, personajes y beats).
- ❌ Un tema abstracto: "La dualidad entre sus dos vidas."
- ❌ Varios eventos inconexos en una misma frase.

## Ejemplos

### Bien definido

```
"Miguel presencia un encuentro sexual entre dos hombres en el parking de su oficina. 
Uno de ellos lo mira directamente mientras recibe sexo oral. Miguel se queda paralizado. 
Se masturba en el coche. Vuelve a casa. Esa noche no duerme."
```

→ El guionista puede convertir esto en una escena con ~5 beats: salir de la oficina, ver el encuentro, masturbarse, conducir a casa, interactuar con Elena.

### Mal definido (demasiado vago)

```
"Miguel descubre su sexualidad."
```

→ Inservible. ¿Cómo la descubre? ¿Dónde? ¿Con quién? El guionista no puede generar escenas a partir de esto.

### Mal definido (demasiado detallado)

```
"Miguel sale de la oficina a las 21:15, coge el ascensor hasta la planta -2, 
camina entre los coches, oye un gemido, gira a la izquierda junto al pilar B-14, 
ve a dos hombres, uno de rodillas, el otro apoyado contra la pared, etc."
```

→ Esto ya es una escena con beats. No es un hecho: es trabajo del guionista.

## Longitud

Una frase o párrafo breve. Lo bastante específico para que el guionista sepa qué escribir, lo bastante abierto para que tenga criterio sobre el CÓMO.

## Quién lo usa

| Agente | Cuándo | Para qué |
|--------|--------|----------|
| **scaffolder** (hub) | Fase 5 | Ayudar al usuario a definir los hechos de cada acto. |
| **guionista** (workspace) | Modo estructura | Agrupar hechos en escenas por coherencia espacio-temporal. Puede refinar un hecho si es demasiado vago o dividirlo si abarca demasiado. |
| **guionista** (workspace) | Modo escena | Descomponer cada hecho en beats con tono y extensión. |

## Potestad del guionista

El guionista **puede** refinar los hechos del brief. Si un hecho es demasiado vago ("descubre su sexualidad"), debe pedir más detalle al director o al usuario. Si un hecho es demasiado amplio, puede dividirlo en dos hechos más manejables para generar beats. Si dos hechos de actos distintos comparten espacio y tiempo, puede proponer fusionarlos en una sola escena puente. En todos los casos, debe informar al director.

## Relación con otros skills

- `scaffolding-acto`: define el acto que contiene los hechos.
- `beats-estructura`: el guionista lo usa para generar beats a partir de hechos (formato B_NN).
