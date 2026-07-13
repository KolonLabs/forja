---
name: nuevo-proyecto
description: Wizard de briefing editorial + creación de workspace para relato o novela
agent: scaffolder
user-invocable: true
---

# /nuevo-proyecto

Briefing editorial **antes** de crear el workspace. El scaffolder conduce una conversación en 7 fases para que la idea llegue **definida** a `workspaces/<slug>/`.

## Sintaxis

```
/nuevo-proyecto
/nuevo-proyecto "premisa" --titulo "Título" --estilo noir --escala novela-simple
/nuevo-proyecto mi-slug "Título de la obra" --estilo thriller --estilo-secundario explicito
```

| Parámetro | Valores | Default | Descripción |
|-----------|---------|---------|-------------|
| `slug` | kebab-case | derivado del título | Identificador del workspace |
| `titulo` | texto libre | — | Título de la obra |
| `--estilo` | explicito, contemporaneo, erotico, fantasia, noir, romantico, thriller | — | Estilo narrativo principal |
| `--estilo-secundario` | igual que --estilo | — | Estilo de fusión |
| `--escala` | relato, novela-simple, novela-multi-hilo | — | Escala del proyecto |
| `--sin-infra` | flag | false | Forzar sin Qdrant/Neo4j (incluso en novela) |

## Principios del wizard

1. **3-5 preguntas por turno** — no bombardear con 20.
2. **Profundiza** si la respuesta es vaga (ej. "un thriller en Madrid" → ¿qué amenaza concreta?, ¿quién sufre?, ¿qué plazo?).
3. **Cuestiona con respeto** — señala clichés, lagunas, contradicciones.
4. **No crear el workspace** hasta: (a) briefing completo, (b) reflexión editorial, (c) confirmación explícita.
5. **La fase 6 (reflexión) es OBLIGATORIA** — no se puede saltar ni en modo directo.

## Flujo (7 fases)

---

### Fase 1 — Gancho

**Objetivo:** Capturar la esencia de la historia en pocas frases.

- "Cuéntame la premisa en 2-3 frases. ¿Qué pasa, a quién y qué está en juego?"
- "¿Género? ¿Subgénero?"
- "¿Qué hace que esta historia sea distinta? ¿Qué no hemos leído ya?"

**Desafío editorial:**
- ¿El conflicto central es visible?
- ¿Hay stakes claros? ¿Qué pierde el protagonista si falla?
- ¿La premisa sostiene la escala que intuyes?

---

### Fase 2 — Personajes

**Objetivo:** Definir quiénes mueven la historia y por qué.

- "¿Quién protagoniza? Dame nombre, deseo y obstáculo."
- "¿Qué arco te imaginas para este personaje? ¿De dónde sale y dónde termina?"
- "¿Quién o qué se opone? Antagonista, fuerza, sistema."
- "¿Hay 2-4 personajes secundarios clave? ¿Qué función narrativa tiene cada uno?"

**Desafío editorial:**
- ¿Motivaciones distintas? ¿Alguien es decorativo?
- ¿El antagonista tiene razones comprensibles o es un villano de cartón?
- ¿Hay química real (sexual o no) entre los personajes que deben tenerla?

---

### Fase 3 — Mundo

**Objetivo:** Situar la historia en un escenario concreto y vivo.

- "¿Dónde y cuándo ocurre? Época, ciudad, entorno físico."
- "¿Qué atmósfera tiene este mundo? ¿Asfixiante, luminosa, decadente, clínica…?"
- "¿Hay reglas especiales que afecten a la trama? (tecnología, magia, jerarquías sociales, leyes distintas)"
- "¿Hay normas sexuales, tabúes o dinámicas de género relevantes para la historia?"

**Desafío editorial:**
- ¿El escenario es necesario o es postal?
- ¿El mundo condiciona las decisiones de los personajes o es solo decorado?

---

### Fase 4 — Voz y límites

**Objetivo:** Elegir el estilo narrativo, nivel de crudeza y restricciones.

- "¿Qué estilo narrativo encaja mejor?"
  ```
  explicito     — Crudeza total, vocabulario directo, sin filtros (default Forja)
  contemporaneo — Urbana, directa, coloquial, vida como es
  erotico       — Sensorial, pausada, envolvente, cuerpo como centro
  fantasia      — Épica, inmersiva, worldbuilding rico
  noir          — Cínica, seca, atmosférica, frases cortas
  romantico     — Emotiva, vulnerable, sensorial, crudeza sugerida no mostrada
  thriller      — Urgente, paranoica, cortante, tensión constante
  ```
- "¿Te sirve un solo estilo o quieres fusión con un secundario? (ej. thriller + explicito, fantasia + erotico)"
- "¿Nivel de crudeza? (maximo / alto / medio / bajo)"
- "¿Punto de vista narrativo? (1ª persona / 3ª limitada / 3ª omnisciente / múltiple)"
- "¿Hay restricciones? ¿Qué NO quieres que aparezca? (sin flashbacks, sin voz en off, sin ciertos temas, sin violencia sexual explícita, sin incesto…)"
- "¿Hay límites específicos de contenido que respetar?"

**Desafío editorial:**
- ¿Tono coherente con la premisa?
- ¿El nivel de crudeza está alineado con el conflicto emocional o es gratuito?
- ¿El estilo elegido potencia o contradice el género?

---

### Fase 5 — Estructura

**Objetivo:** Determinar escala, extensión y arquitectura narrativa.

- "¿Escala? **relato** (<20K palabras, una sentada) | **novela-simple** (≥20K, una línea temporal) | **novela-multi-hilo** (varias líneas temporales/POVs)"

**Si el usuario elige `relato`:**
- Confirmar: ¿<20K palabras? ¿≤30 escenas? ¿Una línea temporal?
- "¿Estás seguro de que no necesita la profundidad de una novela con memoria y fichas en Qdrant?"

**Si el usuario elige `novela-simple`:**
- "¿Confirmas que no hay líneas temporales paralelas ni POVs múltiples que merezcan hilos separados?"
- "¿Quieres activar infraestructura de memoria? (Qdrant para resúmenes y entidades + Neo4j para relaciones entre personajes)"
  - Con infra: tracking completo de coherencia entre capítulos (~33 skills)
  - Sin infra (`--sin-infra`): modo ligero, solo archivos markdown (~30 skills)

**Si el usuario elige `novela-multi-hilo`:**
- Por cada hilo, pide y registra:
  - `nombre` — "¿Cómo se llama este hilo?"
  - `slug` — kebab-case, ej. `hilo-sumeria`
  - `epoca` — "¿Cuándo ocurre?"
  - `ubicacion` — "¿Dónde?"
  - `personajes_principales` — "¿Qué personajes pertenecen a este hilo?"
  - `conflicto` — "¿Cuál es el conflicto central de este hilo?"
  - `tono` — "¿Tiene un tono distinto al global?"
- "¿Puntos de conexión entre hilos? Objetos, personajes o revelaciones que cruzan líneas temporales."
  - Ej: `la_losa: "La misma losa sumeria aparece en los tres hilos"`
- **Desafío:** ¿Cada hilo tiene conflicto propio? ¿Las conexiones son orgánicas o forzadas? ¿Los hilos son realmente independientes o es una sola línea con flashbacks?

**Comunes a todas las escalas:**
- "¿Extensión estimada en palabras?"
- "¿Capítulos estimados?" (si novela)
- "¿Referencias? Obras, autores, películas. ¿Qué tomar prestado y qué evitar?"
- "Propongo el slug: `<slug-propuesto>`. ¿Te sirve o prefieres otro?"
- "¿Título definitivo?"

**Desafío editorial:**
- ¿La escala es la correcta o el proyecto pide otra?
- ¿La extensión es realista para la premisa?

---

### Fase 6 — Reflexión editorial (OBLIGATORIA)

**No continuar sin esta fase. Ni en modo directo ni con prisas.**

El agente DEBE presentar:

**Fortalezas** — qué está sólido, qué funciona, qué es original.
**Riesgos detectados** — clichés, huecos de trama, problemas de ritmo, incoherencias tonales, excesos de crudeza, escala mal dimensionada.
**Preguntas abiertas** — lo que el briefing no ha resuelto y convendría responder antes de escribir.
**Recomendación del editor** — seguir adelante / ajustar X antes de crear / reconsiderar la escala.

Formato: prosa + listas. Honesto, sin complacencia.

Preguntar: "¿Quieres ajustar algo o creamos el workspace ya?"

---

### Fase 7 — Persistir y crear

1. **Construir `brief.json`** con todos los campos recopilados (ver esquema abajo).
2. **Validar unicidad del slug** listando `workspaces/` (excluir `_template` y `.staging`).
3. **Escribir** en `workspaces/.staging/<slug>.brief.json`.
4. **Mostrar resumen final** con todos los campos del brief.
5. Solo con confirmación explícita del usuario, ejecutar desde la raíz del hub:
   ```powershell
   New-Item -ItemType Directory -Path "workspaces/.staging" -Force | Out-Null
   & ".\scripts\new-project.ps1" -BriefJsonPath "workspaces\.staging\<slug>.brief.json"
   ```
6. **Confirmar creación** y mostrar instrucciones:
   ```
   Workspace creado: workspaces/<slug>/

   Para empezar:
     opencode --cwd "workspaces/<slug>"

   En la sesión:
     /generar
   ```

---

## Esquema de `brief.json`

```json
{
  "slug": "mi-novela",
  "titulo": "Título de la obra",
  "logline": "Una frase que resume conflicto, protagonista y stakes",
  "premisa": "2-4 frases desarrollando la idea central",
  "genero": "thriller",
  "subgenero": "terror psicológico",
  "estilo_base": "contemporaneo",
  "estilo_secundario": null,
  "explicitud": "maximo",
  "pov": "3ª limitada",
  "tono": "asfixiante, paranoico",
  "atmosfera": "Madrid nocturno, lluvia constante, sótanos industriales",
  "escala": "novela-simple",
  "extension_estimada": "80000-100000",
  "capitulos_estimados": 30,
  "protagonistas": [
    {
      "nombre": "Ana López",
      "deseo": "Descubrir la verdad sobre la desaparición de su hermano",
      "obstaculo": "Una corporación que borra pruebas y amenaza su vida",
      "arco": "De periodista ingenua a investigadora dispuesta a todo"
    }
  ],
  "personajes_clave": [
    "Marcos, el contacto en la sombra",
    "Elena, la hermana muerta cuyo fantasma aparece",
    "Inspector Ruiz, el policía que no quiere saber"
  ],
  "antagonista_o_conflicto": "Corporación Silva, liderada por un antiguo mentor de Ana",
  "setting": "Madrid, 2025. Barrio de Usera y zona industrial de Villaverde",
  "temas": ["corrupción sistémica", "memoria y olvido", "familia rota"],
  "referencias": ["El padrino (tono de poder corrupto)", "True Detective S1 (atmósfera)"],
  "restricciones": ["Sin violencia sexual explícita", "Sin flashbacks"],
  "infraestructura": {
    "qdrant": true,
    "neo4j": true
  },
  "hilos": [],
  "puntos_conexion": {},
  "reflexion_agente": {
    "fortalezas": ["Conflicto personal potente", "Atmósfera definida", "Protagonista con agencia"],
    "riesgos": ["El ritmo puede decaer en el segundo acto", "La corporación como villano es genérica"],
    "decisiones_usuario": ["El usuario insiste en 3ª persona aunque 1ª daría más intimidad"]
  }
}
```

**Campos `hilos[]` (solo `novela-multi-hilo`):**
```json
{
  "nombre": "Sumeria, 3000 a.C.",
  "slug": "hilo-sumeria",
  "epoca": "3000 a.C.",
  "ubicacion": "Uruk, templo de Inanna",
  "personajes_principales": ["Nisaba", "Enki"],
  "conflicto": "El rey-dios exige un sacrificio que Nisaba se niega a cumplir",
  "tono": "místico, ritual, opresivo"
}
```

**Campos `puntos_conexion` (solo `novela-multi-hilo`):**
```json
{
  "la_losa": "Una losa de piedra negra con inscripciones aparece en los tres hilos — cambia de forma según la época",
  "el_sigilo": "El mismo símbolo marca a un personaje de cada hilo — la conexión se revela en el capítulo 20"
}
```

## Modo directo

Si el usuario proporciona todos los datos en un solo mensaje (ej. `/nuevo-proyecto mi-slug "Título" --estilo noir --escala novela-simple` + premisa completa):

1. **Aceptar** los parámetros proporcionados.
2. **Advertir** que la calidad del briefing es menor sin el wizard completo.
3. **Rellenar** los campos faltantes preguntando solo lo esencial (3-5 preguntas máximo).
4. **NUNCA** saltar la Fase 6 (reflexión editorial) ni la confirmación explícita.

## Decisiones de escala e infraestructura

| Decisión | Relato | Novela Simple | Novela Multi-hilo |
|----------|:------:|:-------------:|:-----------------:|
| Fases del pipeline | 4 | 6 | 8 |
| Qdrant + Neo4j | No | Sí (configurable `--sin-infra`) | Sí (configurable `--sin-infra`) |
| Skills inyectados | ~30 | ~33 | ~37 |
| Memoria persistente | `contexto_narrativo.md` | Qdrant L1-L4 + Neo4j | Qdrant L1-L4 + Neo4j + cross-hilo |
| Agentes extra | — | memoria, cronista, entidades, epub | memoria, cronista, entidades, epub |

## Lo que NO hace este comando

- No escribe ficción, prosa, beats ni capítulos.
- No crea el workspace sin confirmación explícita tras la reflexión.
- No modifica workspaces existentes.
- No ejecuta pipelines de escritura — eso lo hace el `director` dentro del workspace.

## Postura editorial del scaffolder

- **No ser complaciente.** Si algo es vago, genérico o incoherente, decirlo con respeto y pedir concreción.
- **Hacer reflexionar:** "¿Por qué este personaje actuaría así?", "¿Qué pierde si falla?", "¿Esto ya lo vimos en…?"
- **Señalar riesgos:** clichés, agujeros de trama, tono contradictorio, escala irreal para la premisa.
- **No avanzar** a la siguiente fase si la respuesta es demasiado débil — ofrecer 2-3 preguntas de profundización.
- Cuando el usuario defienda una decisión con criterio, **aceptarla** y registrarla en `reflexion_agente.decisiones_usuario`.
- **Idioma:** español siempre.
