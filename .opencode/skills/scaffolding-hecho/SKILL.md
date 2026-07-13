---
name: scaffolding-hecho
description: Esquema de un hecho narrativo. Define qué es y qué no es un hecho en el brief de Forja. Lo carga el scaffolder en Fase 5.
---

# Hecho narrativo — esquema

Un **hecho** es un evento narrativo de alto nivel que describe QUÉ ocurre, no CÓMO se cuenta. Es la unidad más grande que define Forja: las escenas y los beats se generan en el workspace a partir de estos hechos.

**Tipos de hechos:**

| Tipo | Comportamiento | Genera |
|------|---------------|--------|
| **Lineal** (sin marca) | Evento concreto en un momento único | 1-N escenas secuenciales |
| **Distribuido** (`[D · H_XX–H_YY]`) | Patrón, rutina o evolución que se despliega entre varios hechos | Beats inyectados en escenas existentes (no escenas propias) |

## Qué es un hecho (lineal)

- ✅ Un evento concreto con sujeto, acción y consecuencia: "Miguel presencia un encuentro sexual en el parking. Uno lo mira. Se queda paralizado."
- ✅ Algo que ocurre y cambia el estado de la historia.
- ✅ Suficientemente detallado para poder descomponerlo en escenas y beats en el workspace.
- ✅ Implica acción física o decisión del personaje.

## Qué NO es un hecho (lineal)

- ❌ Un estado de ánimo sin acción: "Miguel se siente culpable."
- ❌ Un resumen de intenciones: "Miguel explora su sexualidad."
- ❌ Un evento con demasiado detalle: ubicación exacta, movimientos precisos, diálogos. Eso es trabajo que se hará después en el workspace.
- ❌ Un tema abstracto: "La dualidad entre sus dos vidas."
- ❌ Varios eventos inconexos en una misma frase.

> ⚠️ **Estas reglas aplican SOLO a hechos lineales.** Los hechos `[D]` son patrones intencionales — ver sección «Hechos lineales vs distribuidos» abajo. Un `[D]` como «La búsqueda se vuelve sistemática» es un patrón válido, no un defecto.

## Qué es un hecho distribuido `[D]`

Un hecho `[D]` describe un **patrón recurrente, rutina, evolución progresiva o estado** que no puede escribirse en una sola escena. El scaffolder lo marca con `[D · H_XX–H_YY]` indicando el rango de hechos lineales donde debe desplegarse.

- ✅ «La búsqueda se vuelve sistemática: transporte, cafeterías, parkings.» — Patrón válido.
- ✅ «La coacción escala en lo cotidiano: ascensor, bar, casa.» — Patrón válido.
- ✅ «Miguel pasa de reservado a cómplice a lo largo de semanas.» — Evolución válida.
- ✅ «La nueva normalidad se consolida: Miguel dispone, Laura obedece.» — Estado/epílogo válido.

Un `[D]` no se evalúa como un lineal. No necesita «sujeto, acción, consecuencia puntual». Su criterio de calidad es:
- ¿El patrón está claro? (el guionista entiende QUÉ debe inyectar)
- ¿El rango es coherente? (fin ≥ inicio, dentro del mismo acto, al menos 2 hechos lineales en el rango)
- ¿Da dirección suficiente? (si es demasiado genérico — «Laura cambia» — es tan inútil como un lineal vago)

## Ejemplos

### Bien definido

```
"Miguel presencia un encuentro sexual entre dos hombres en el parking de su oficina. 
Uno de ellos lo mira directamente mientras recibe sexo oral. Miguel se queda paralizado. 
Se masturba en el coche. Vuelve a casa. Esa noche no duerme."
```

→ Esto puede convertirse en una escena con varios beats: salir de la oficina, ver el encuentro, masturbarse, conducir a casa, interactuar con Elena.

### Mal definido (demasiado vago)

```
"Miguel descubre su sexualidad."
```

→ Inservible. ¿Cómo la descubre? ¿Dónde? ¿Con quién? No se pueden generar escenas a partir de esto.

### Mal definido (demasiado detallado)

```
"Miguel sale de la oficina a las 21:15, coge el ascensor hasta la planta -2, 
camina entre los coches, oye un gemido, gira a la izquierda junto al pilar B-14, 
ve a dos hombres, uno de rodillas, el otro apoyado contra la pared, etc."
```

→ Esto tiene demasiado detalle: incluye acciones concretas, movimientos y ubicaciones que corresponden a un nivel más granular. Un hecho debe ser más abstracto. El nivel de detalle de este ejemplo es trabajo del workspace.

## Longitud

Una frase o párrafo breve. Lo bastante específico para que se sepa qué escribir en el workspace, lo bastante abierto para que haya criterio sobre el CÓMO.

## Quién lo usa

| Agente | Cuándo | Para qué |
|--------|--------|----------|
| **scaffolder** (hub) | Fase 5 | Ayudar al usuario a definir los hechos de cada acto. Conocer el nivel de detalle que espera el workspace. |

## Hechos lineales vs distribuidos `[D]`

En el nivel del scaffolder, algunos hechos describen **patrones, rutinas o evoluciones** que no ocurren en un solo momento. Estos hechos no pueden escribirse como una escena secuencial: deben **respirar entre los hechos del acto**, filtrándose como beats dentro de las escenas de otros hechos.

Para marcarlos, se usa el prefijo `[D · H_XX–H_YY]` en el string del hecho:

```
H_07 [D · H_06–H_10]: La búsqueda se vuelve sistemática...
```

| Componente | Significado |
|-----------|-------------|
| `[D]` | Hecho distribuido (no genera escenas propias) |
| `H_XX–H_YY` | Rango de hechos lineales entre los que se despliega |

### Cuándo usar `[D]`

| El hecho describe... | Tipo | Ejemplo |
|---------------------|:----:|---------|
| Una acción puntual con momento único | Lineal | «Laura recibe un mensaje de Diego» |
| Un patrón recurrente, hábito o rutina | `[D]` | «La búsqueda se vuelve sistemática» |
| Una evolución progresiva (el tono cambia, la actitud muta) | `[D]` | «Miguel pasa de reservado a cómplice» |
| Varias instancias de lo mismo embutidas en una frase | `[D]` | «Diego la obliga en el ascensor, en el bar, en su casa» |
| Un estado o nueva normalidad (epílogo) | `[D]` | «La nueva normalidad se consolida» |

### Cuándo NO usar `[D]` aunque parezca patrón

| Situación | Por qué es lineal |
|-----------|-------------------|
| Una transformación interna que el lector necesita **ver** en escenas concretas, no inferir de beats dispersos | La evolución del personaje es la historia. Si el lector no la presencia, no ocurre. |
| El hecho final de la obra | El cierre necesita una viñeta concreta. Un patrón distribuido como último hecho deja la historia sin última imagen. |

### Reglas del rango

- El rango debe contener al menos 2 hechos lineales donde intercalarse.
- El `[D]` se coloca en la lista de hechos del acto **donde empieza su rango**.
- El workspace (director + guionista) decide cuántas instancias concretas y en qué escenas exactas.
- El scaffolder solo dice «esto es un patrón y va entre estos hechos».

### Ejemplo en un acto

```markdown
### Hechos

- H_06: Salidas nocturnas. Parking periférico...
- H_07 [D · H_06–H_10]: La búsqueda se vuelve sistemática...
- H_08: Diego, vecino de abajo...
- H_09: Los viernes, Miguel queda con los amigos...
- H_10: Mensaje anónimo. Es Diego...
```

## Relación con otros skills

- `scaffolding-acto`: define el acto que contiene los hechos.
- `scaffolding-relato` / `scaffolding-novela-simple` / `scaffolding-multi-hilo`: guían la conversación de estructura según escala. Todos deben conocer el formato `[D]`.
- `beats-estructura`: skill del workspace que define el formato de beats (B_NN) a partir de hechos.
- `hechos-distribuidos`: skill del workspace que el guionista carga para procesar hechos `[D]`.
