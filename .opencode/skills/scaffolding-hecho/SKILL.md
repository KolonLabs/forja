---
name: scaffolding-hecho
description: Esquema de un hecho narrativo. Define qué es y qué no es un hecho en el brief de Forja. Lo carga el scaffolder en Fase 5.
---

# Hecho narrativo — esquema

Un **hecho** es una unidad causal de alto nivel que describe QUÉ debe hacerse visible, no CÓMO se cuenta. Puede contener un evento, una secuencia estrechamente relacionada o una pauta con su consecuencia; las escenas y los beats se generan en el workspace a partir de ese contrato.

**Regla por escala:** relato usa solo hechos `H_XXXX`, sin marcas `[D]`; sus pautas se describen dentro del hecho y el guionista decide los beats que las hacen visibles. Novela-simple y novela-multi-hilo conservan los hechos distribuidos `[D]` descritos más abajo.

**Tipos de hechos:**

| Tipo | Comportamiento | Genera |
|------|---------------|--------|
| **Lineal** (sin marca) | Evento concreto en un momento único | 1-N escenas secuenciales |
| **Distribuido** (`[D · H_XXXX–H_XXXX]`) | Patrón, rutina o evolución que se despliega entre varios hechos | Beats inyectados en escenas existentes (no escenas propias) |

## Qué es un hecho (lineal)

- ✅ Un cambio o secuencia causal con sujeto, acciones relacionadas y consecuencia: "Miguel presencia un encuentro sexual en el parking; la mirada de uno de los hombres rompe su indiferencia y vuelve a casa incapaz de retomar su rutina."
- ✅ Algo que ocurre y cambia el estado de la historia.
- ✅ Suficientemente detallado para poder descomponerlo en escenas y beats en el workspace.
- ✅ Implica acción física o decisión del personaje.

## Qué NO es un hecho (lineal)

- ❌ Un estado de ánimo sin acción: "Miguel se siente culpable."
- ❌ Un resumen de intenciones: "Miguel explora su sexualidad."
- ❌ Un evento con demasiado detalle: ubicación exacta, movimientos precisos, diálogos. Eso es trabajo que se hará después en el workspace.
- ❌ Un tema abstracto: "La dualidad entre sus dos vidas."
- ❌ Varios eventos inconexos en una misma frase.

> ⚠️ En relato, una pauta explícita también es válida dentro de un hecho si aclara qué debe hacerse perceptible y qué cambia. No se acompaña de `[D]`, rango ni orden de beats.

## Qué es un hecho distribuido `[D]`

Un hecho `[D]` describe un **patrón recurrente, rutina, evolución progresiva o estado** que no puede escribirse en una sola escena. El scaffolder lo marca con `[D · H_XXXX–H_XXXX]` indicando el rango de hechos lineales donde debe desplegarse.

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
"Miguel presencia un encuentro sexual en el parking de su oficina. La mirada de uno de los hombres convierte su curiosidad en una implicación que no puede negar; vuelve a casa incapaz de recuperar la normalidad."
```

→ Esto puede convertirse en varios beats y, si el arco lo necesita, intercalarse con beats de su rutina doméstica. No fija la coreografía, el diálogo ni el número de escenas.

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

## En novelas: hechos lineales vs distribuidos `[D]`

En el nivel del scaffolder, algunos hechos describen **patrones, rutinas o evoluciones** que no ocurren en un solo momento. Estos hechos no pueden escribirse como una escena secuencial: deben **respirar entre los hechos del acto**, filtrándose como beats dentro de las escenas de otros hechos.

Para marcarlos, se usa el prefijo `[D · H_XXXX–H_XXXX]` en el string del hecho:

```
H_0007 [D · H_0006–H_0010]: La búsqueda se vuelve sistemática...
```

| Componente | Significado |
|-----------|-------------|
| `[D]` | Hecho distribuido (no genera escenas propias) |
| `H_XXXX–H_XXXX` | Rango de hechos lineales entre los que se despliega |

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

- H_0006: Salidas nocturnas. Parking periférico...
- H_0007 [D · H_0006–H_0010]: La búsqueda se vuelve sistemática...
- H_0008: Diego, vecino de abajo...
- H_0009: Los viernes, Miguel queda con los amigos...
- H_0010: Mensaje anónimo. Es Diego...
```

## Relación con otros skills

- `scaffolding-acto`: define el acto que contiene los hechos.
- `scaffolding-relato`: aplica la excepción de relato; las pautas permanecen dentro del hecho, sin `[D]`.
- `scaffolding-novela-simple` / `scaffolding-multi-hilo`: guían el uso de `[D]` en sus escalas.
- `beats-estructura`: skill del workspace que define el formato de beats (B_XXXX) a partir de hechos.
- `hechos-distribuidos`: skill de los workspaces de novela que procesa hechos `[D]`.
