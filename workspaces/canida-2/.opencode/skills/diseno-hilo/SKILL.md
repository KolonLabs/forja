---
name: diseno-hilo
description: Estructura y criterios para persistir las decisiones de diseño de un hilo narrativo durante la conversación. El director lo usa para escribir diseno-hilo.md; el guionista lo carga en modo hilo para interpretarlo.
---

# Skill: diseno-hilo

## Qué es

`diseno-hilo.md` es el documento vivo donde se registran las decisiones de diseño de un hilo narrativo **durante la conversación con el usuario**. No es el guion final — es el cuaderno de trabajo que el `guionista modo: hilo` usará como entrada para generar `guion-hilo.md`.

## Ubicación

```
workspaces/<slug>/hilos/<stable_id>/diseno-hilo.md
```

`<stable_id>` es un UUID8 generado al crear el hilo como entidad. No usa el slug semántico `hilo-sumeria` — eso es solo el `nombre` del hilo en Qdrant.

## Cuándo escribir

El director decide autónomamente. Escribe cuando se produce una **decisión**, no cuando se explora una posibilidad.

| Disparador | Ejemplo |
|-----------|---------|
| Se define una entidad nueva del hilo | "Naamah tendrá un Sumo Sacerdote" |
| Se toma una decisión estructural | "3 actos: ascenso, apogeo, caída" |
| Se identifica un punto de conexión con otro hilo | "La losa viaja en barco fenicio a Hispania → conecta con hilo-sello" |
| Se resuelve una duda de diseño | "7 sacerdotisas, no 3 — mejor para el ritual" |
| Se descarta una idea relevante | "Descartado: Naamah no tiene hermana" |
| El usuario confirma explícitamente | "Perfecto, 8 capítulos para Sumer" |

**NO escribir:**
- Preguntas sin resolver
- Opciones barajadas pero no decididas
- Información que ya está en las fichas de entidades (Qdrant)
- Cada línea de conversación — solo las decisiones

---

## Formato del archivo

```markdown
# Diseño del hilo: [nombre del hilo]

**ID:** hilo-<slug>
**Época:** [año/período]
**Protagonista(s):** [nombres]
**Género dominante:** [fantasia oscura | gotico historico | thriller erotico | ...]
**Capítulos estimados:** [N]
**Última actualización:** [YYYY-MM-DD HH:MM]

---

## Conflicto central

[1-2 frases. Qué tensión mueve este hilo. Responde a: ¿qué quiere el protagonista y qué se lo impide?]

---

## Estructura prevista

[División en actos o bloques. Solo lo decidido, no lo especulativo.]

- **Acto 1 — [nombre]:** [qué ocurre, 1-2 frases]
- **Acto 2 — [nombre]:** [qué ocurre]
- ...

---

## Personajes del hilo

[Referencia a fichas existentes + notas específicas de este hilo.]

- **[Nombre]** (`per-<id>`): rol en este hilo, conflicto personal. Estado de la ficha: [básica | detallada].
- ...

## Lugares del hilo

- **[Nombre]** (`lug-<id>`): función narrativa, atmósfera. Estado de la ficha: [básica | detallada].

## Objetos del hilo

- **[Nombre]** (`obj-<id>`): función narrativa. Estado de la ficha: [básica | detallada].

---

## Puntos de conexión con otros hilos

[Conexiones explícitas con otros hilos. Cada punto de conexión será usado en el trenzado.]

- **[objeto/personaje/evento]:** aparece en este hilo en [contexto] → conecta con `<stable_id>` en [contexto del otro hilo]
- ...

---

## Decisiones tomadas

[Log cronológico inverso de decisiones. Cada entrada = fecha + qué se decidió.]

| Fecha | Decisión |
|-------|----------|
| 2026-07-01 | [qué se decidió] |
| 2026-07-01 | [otra decisión] |

---

## Pendientes

[Lo que queda por decidir o desarrollar. No es un TODO técnico — son preguntas narrativas.]

- [ ] [pregunta por resolver]
- [ ] [aspecto por desarrollar]

---

## Descartado

[Ideas consideradas y rechazadas, con motivo. Evita repetir discusiones.]

- **[idea]:** descartado porque [motivo] (YYYY-MM-DD)
```

---

## Reglas

1. **Editar, no reescribir.** Usa `edit` para añadir entradas. No regeneres el archivo entero.
2. **No duplicar con Qdrant.** Si la información ya está en una ficha de entidad, referencia el ID. No copies el contenido.
3. **Decisiones, no opciones.** Si algo no está decidido, va en `Pendientes`. Si se barajaron opciones y se descartó una, va en `Descartado`.
4. **Un archivo por hilo.** Cada hilo tiene su propio `diseno-hilo.md`.
5. **El guionista lo lee.** En `modo: hilo`, el guionista carga este archivo como entrada antes de generar `guion-hilo.md`.

