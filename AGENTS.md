# Forja Hub — Sistema multi-agente de generación de ficción con workspaces aislados

Forja Hub es un **contenedor de proyectos** de generación de ficción. No escribe ficción directamente: cada proyecto vive en su propio workspace fuera del hub (`FORJA_OBRAS`, por defecto `../Forja-resultados/Obras/<slug>`), con pipeline, agentes, skills, datos y repositorio git aislados (ADR 0026). El hub proporciona las herramientas para crear workspaces y compilar libros desde ellos.

## Arquitectura

```
Forja/
├── AGENTS.md                          # Constitución del hub (este archivo)
├── opencode.json                      # Config compartida MCP + permisos
├── .opencode/                         # Hub: solo scaffolding y creación de libros
│   ├── agents/
│   │   ├── scaffolder.md              # Wizard de briefing editorial (7 fases)
│   │   └── bibliotecario.md           # Deriva ediciones, ensambla libros y recompila formatos
│   ├── skills/
│   │   ├── scaffolding-acto/          # Esquema de acto narrativo
│   │   ├── scaffolding-hecho/         # Esquema de hecho narrativo
│   │   ├── scaffolding-relato/        # Conversación de estructura (relato)
│   │   ├── scaffolding-novela-simple/ # Conversación de estructura (novela)
│   │   ├── scaffolding-multi-hilo/    # Conversación de estructura (multi-hilo)
│   │   ├── scaffolding-mapa/          # Estructura de MAPA.md por escala (Fase 7)
│   │   └── importacion-fuentes/       # Extracción trazable desde fuentes libres
│   └── commands/
│       ├── nuevo-proyecto.md          # /nuevo-proyecto
│       ├── crear-libro.md             # /crear-libro
│       ├── nueva-edicion.md           # /nueva-edicion (relato)
│       ├── recompilar-libro.md        # /recompilar-libro
│       ├── rehidratar-relato.md       # /rehidratar-relato (relato legado)
│       └── importar-proyecto.md       # /importar-proyecto (fuentes libres)
├── shared/                            # Fuente de verdad del pipeline de ficción
│   ├── GUIA.md                        # Ayuda de comandos inyectada en cada workspace nuevo
│   ├── skills/                        # 43 skills invariantes, neutras para ambos entornos
│   ├── scripts/                       # Utilidades para todas las escalas (renumerar.ps1)
│   ├── .opencode/                     # Capa opencode común
│   │   ├── agents/                    # Agentes fijos: memoria, cronista (solo novelas)
│   │   └── commands/                  # /generar, /revisar, /expandir, /publicar…
│   ├── .claude/                       # Capa Claude Code común (mismos agentes y comandos)
│   │   ├── agents/
│   │   └── commands/
│   └── pipelines/                     # Pipeline por escala
│       ├── relato/                    # agentes/ + skills/ + commands/ (opencode) + claude/ + PIPELINE + ORQUESTACION
│       ├── novela-simple/
│       └── novela-multi-hilo/
├── scripts/                           # Infraestructura del hub
│   ├── lib/common.ps1                 # Utilidades compartidas
│   ├── new-project.ps1                # Dispatcher: lee brief por stdin, delega en escala
│   ├── new-relato.ps1                 # Creador de workspace relato
│   ├── new-novela-simple.ps1          # Creador de workspace novela simple
│   ├── new-novela-multi-hilo.ps1      # Creador de workspace novela multi-hilo
│   ├── crear-libro.ps1                # Ensambla antologías desde relatos finalizados
│   ├── new-edicion-relato.ps1         # Deriva una edición corregible de un relato publicado
│   ├── rehidratar-relato.ps1          # Extractor de evidencia editorial legado
│   ├── preparar-importacion-proyecto.ps1 # Empaqueta fuentes libres para análisis editorial
│   ├── recompilar-libro.ps1           # Regenera formatos desde un libro publicado
│   ├── ruta-obra.ps1                  # Imprime la raíz de obras, la de una obra o la de publicados
│   ├── qdrant.py                      # Multi-tenant (colecciones compartidas por proyecto)
│   └── neo4j.py                       # Multi-tenant (grafo compartido por proyecto)
└── (fuera del hub, ADR 0026 y 0027)
    ../Forja-resultados/               # FORJA_RESULTADOS: todo lo que produce Forja
    ├── Obras/                         # FORJA_OBRAS: un workspace y un repositorio git por obra
    │   ├── legacy/                    # Workspaces legacy (referencia)
    │   └── <slug>/                    # Cada obra compila su libro en publicacion/ con /compilar
    └── Publicados/                    # FORJA_PUBLICADOS: antologías compiladas en el hub
```

## Agentes del hub

| Agente | Modelo | Fuente | Rol |
|--------|--------|--------|-----|
| **scaffolder** | `deepseek/deepseek-flash` | `.opencode/agents/scaffolder.md` | Wizard de briefing editorial, rehidratación e importación de fuentes libres. NO escribe ficción. Crea workspaces. |
| **bibliotecario** | `deepseek-v4-flash` | `.opencode/agents/bibliotecario.md` | Deriva ediciones de relatos publicados, ensambla antologías de relatos finalizados y recompila sus formatos. No escribe ni edita contenido narrativo. |

Ninguno de los dos **se inyecta en workspaces**. Ambos viven solo en el hub.

## Comandos del hub

| Comando | Descripción |
|---------|-------------|
| `/nuevo-proyecto` | Wizard de briefing (7 fases) + creación de workspace |
| `/crear-libro` | Ensambla una antología desde dos o más relatos finalizados (una obra única se compila dentro con `/compilar`) |
| `/nueva-edicion` | Deriva un relato publicado en un workspace de corrección independiente |
| `/recompilar-libro` | Añade o regenera EPUB/PDF desde el Markdown congelado de una antología publicada |
| `/rehidratar-relato` | Extrae evidencia de un relato legado y reconstruye un workspace nuevo de diseño tras validación editorial |
| `/importar-proyecto` | Extrae evidencia de archivos libres y reconstruye un argumento confirmado antes de crear el workspace |

Los comandos de escritura (`/generar`, `/corregir`, `/revisar`, `/expandir`, `/publicar`) operan **dentro de un workspace** y los ejecuta el director de esa escala.

## Cómo crear un proyecto nuevo

```
/nuevo-proyecto
```

El scaffolder conduce un briefing editorial en 7 fases (gancho → personajes → mundo → voz → estructura → reflexión → persistir), con un pre-flight editorial obligatorio de hechos y brief (Fase 7.1) antes de crear el workspace. En Fase 5 determina la escala y construye los hechos narrativos. Al finalizar, construye un JSON con el brief y lo pipea a `scripts/new-project.ps1` por stdin. El script crea la obra en la raíz de obras (`FORJA_OBRAS`, por defecto `../Forja-resultados/Obras/<slug>`; `scripts/ruta-obra.ps1` la imprime) con los agentes, skills, scripts y archivos de su escala, su `.gitignore` y `git init` sin commits (ADR 0026).

## Cómo publicar y compilar

**Dentro del workspace:**
```
/publicar
```
Genera `relato.md` (relato) o `novela.md` (novela) en la raíz del workspace. Sin beats, sin escenas, sin actos. Solo texto limpio con capítulos (novela) o texto continuo (relato).

**Dentro del workspace, para compilar el libro:**
```
/compilar [--epub] [--pdf] [--pdf-formato <formato>] [--pdf-motor <motor>] [--titulo "<título>"] [--autor "<autor>"]
```
Ejecuta `scripts/compilar.ps1`, determinista: lee el manuscrito limpio y escribe `publicacion/` (Markdown, EPUB/PDF opcionales y `manifest.json` con hash y commit); lo demás que haya en `publicacion/` (borradores, un audiolibro) se conserva (ADR 0041). Acepta `finalizado` o `publicado` y, solo si todas las salidas terminan correctamente, asigna `publicado`. El director nunca escribe ese estado a mano.

**Desde el hub, solo antologías:**
```
/crear-libro <slug-libro> <relato1> <relato2> [relato3...] [--epub] [--pdf] [--pdf-formato <formato>] [--pdf-motor <motor>] [--titulo "<título>"] [--autor "<autor>"] [--portada "<imagen>"]
```
Lo ejecuta el agente **bibliotecario**: lee dos o más relatos en estado `finalizado`, los ensambla en `<raíz de publicados>/<libro>/` y, cuando todas las salidas solicitadas terminan correctamente, actualiza las fuentes a `publicado`.

Para añadir o regenerar EPUB/PDF de una antología se usa `/recompilar-libro <slug-libro> [--epub] [--pdf] [--pdf-formato <formato>] [--pdf-motor <motor>] [--portada "<imagen>"]`. Opera solo sobre el Markdown y `manifest.json` congelados del libro; no modifica obras.

Si cambia el contenido de un relato publicado, se usa `/nueva-edicion <workspace-publicado> <slug-edicion> [--titulo "..."] [--motivo "..."]`. Crea un workspace derivado en estado `correccion`, con `relato-edicion-anterior.md` como referencia inmutable. Tras `/corregir` y `/publicar`, la edición queda `finalizado` y se compila con un slug de libro nuevo. Este flujo no está disponible todavía para novelas.

Para reiniciar un relato legado con el pipeline vigente, se usa `/rehidratar-relato <origen> <slug-destino> [--actos actual|backup]` desde el hub. El extractor solo recupera `config.json`, `BRIEF.md` y los actos indicados como evidencia; el scaffolder propone después una estructura nueva y hechos con detonante, presión, cambio y consecuencia suficientes para derivar beats. No migra prosa ni guion, nunca modifica el origen y solo crea el destino tras reflexión y confirmación explícitas.

Para recuperar ideas desde notas, escaletas o guiones libres se usa `/importar-proyecto <slug-destino> --fuente "<ruta-o-url>" [--fuente "<ruta-o-url>" ...]`. Admite rutas locales y URL HTTPS públicas, que se empaquetan en modo lectura con hash y URL final trazable. Analiza esas fuentes como evidencia y separa evidencia de hipótesis. Tras elegir una candidata, el scaffolder puede reconstruir un argumento más sólido —sin copiar la escaleta— y debe señalar las propuestas no respaldadas antes de confirmarlas. Con la escala confirmada, los hechos finales aportan detonante, presión, cambio y consecuencia suficientes para derivar beats. Solo entonces se crea el workspace.

## Reglas del hub

- **Idioma**: español (todo el contenido, vocabulario e interacción).
- **Crudeza**: máximo (explícito total). Sin eufemismos. Vocabulario directo y crudo.
- **No modificar otros workspaces** sin permiso explícito del usuario.
- **Cada obra es un repositorio git propio** fuera del hub (ADR 0026). Los commits los decide la persona usuaria: ni scripts ni agentes hacen commits ni crean copias de seguridad.
- **Cada workspace es autónomo**: tiene su propio `.opencode/` con agentes y comandos y su propio `.claude/skills/` con las skills (las leen opencode y Claude Code), inyectados según su escala. No conoce directorios superiores; su `opencode.json` desactiva los agentes del hub (ADR 0023).
- **shared/ es inmutable** para workspaces creados. Las mejoras al pipeline se aplican manualmente desde el hub.
- **Secretos**: nunca en un repositorio. Viven en `~/.forja/secretos.env` (o `FORJA_SECRETOS`) y se leen solo con `Get-ForjaSecreto` / `obtener_secreto` de `shared/scripts`, que no muestran valores (ADR 0029).
- **Revisión previa a commit**: antes de `git commit` y `git push`, presentar el `git diff --stat` y un resumen breve de los cambios al usuario para su validación. No commitear si el usuario pide ajustes o marca un problema.

## Registros persistentes

- `docs/decisiones/` conserva las decisiones arquitectonicas y operativas vigentes. Consultarlo antes de cambiar contratos, aislamiento, infraestructura o formatos de salida.
- `docs/deuda-tecnica.md` registra riesgos abiertos y sus criterios de cierre. Actualizarlo al identificar o resolver un riesgo real.
- `docs/plan-hechos-pendientes.md` es historial de incidencias resueltas, no una fuente de trabajo activa.

## shared/ como fuente de verdad

| Ubicación | Contenido |
|-----------|-----------|
| `shared/skills/` | 43 skills: invariantes + exclusivos por escala. Neutras: se inyectan en `.claude/skills/`, que leen opencode y Claude Code |
| `shared/.opencode/agents/`, `shared/.claude/agents/` | 2 agentes fijos (memoria, cronista), uno por entorno; solo se inyectan en novelas |
| `shared/scripts/` | Utilidades que se copian a `scripts/` en todas las escalas: `renumerar.ps1` (renumera definiciones `H_`/`E_`/`B_` y devuelve la tabla viejo → nuevo; la skill `renumeracion-ids` guía al LLM en la revisión de referencias) y la compilación de la obra (`compilar.ps1`, `borrador.ps1`, `publicacion-comun.ps1`, `build-epub.ps1`, `build-pdf.ps1`, `build.css`, `templates/forja-kdp.typ`), que el hub también usa para las antologías, la lectura de secretos (`secretos.ps1`, `secretos.py`; ADR 0029) y la validación de `referencias/` (`validar-referencias.py`; ADR 0032) |
| `shared/GUIA.md` | Guía de decisión por defecto (relato). Si la escala define `shared/pipelines/<escala>/GUIA.md`, prevalece esa |
| `shared/imagenes/LEEME.md` | Guía de `imagenes/` de la obra (portada del EPUB y sus requisitos; ADR 0040); se inyecta en todas las escalas |
| `shared/.opencode/commands/`, `shared/.claude/commands/` | 10 comandos por entorno: generar, revisar, expandir, corregir, publicar, compilar, borrador, refinar-hechos, revisar-guion, validar-hechos. `corregir` solo se inyecta en relato |
| `shared/pipelines/<escala>/` | Agentes (`agentes/`), skills, scripts y overrides de comandos propios de escala + `PIPELINE.md` + `ORQUESTACION.md` |
| `shared/pipelines/<escala>/claude/` | Capa Claude Code de la escala: `agents/`, `commands/`, `settings.json` y `CLAUDE.md` |

Al crear un workspace, el script inyecta agentes y comandos de su escala en `.opencode/` y en `.claude/`, las skills en `.claude/skills/` (solo los estilos activos) y aplica, después de los comandos comunes, los overrides de comando que correspondan.

**Dos entornos equivalentes (ADR 0024).** Cada agente y comando existe en versión opencode y en versión Claude Code, escritas a mano. Comparten cuerpo salvo las adaptaciones de entorno (carga de skills, modelos, presupuesto de salida). Un cambio en una capa se revisa en la otra; `tests/paridad-entornos-regression.ps1` detecta desfases de inventario, restos de un entorno en el otro y modelos fuera del reparto. Los agentes escala-específicos (director, guionista, escritor, validador, integrador, entidades) viven en `shared/pipelines/<escala>/agentes/`.

## Escalas soportadas

| Escala | Fases | Qdrant/Neo4j | Hilos | Agentes | Skills (~) |
|--------|-------|:---:|:---:|:---:|:---:|
| **relato** | 4 fases | No | No | 7 | 15 (+1 por estilo secundario) |
| **novela-simple** | 4 fases | Sí | No | 9 | 34 (+1 por estilo secundario) |
| **novela-multi-hilo** | 8 fases | Sí | Sí (mín. 2) | 9 | 38 (+1 por estilo secundario) |

## Jerarquía narrativa

Forja define **actos → hechos**. El workspace define **escenas → beats** (relato) o **capítulos → escenas → beats** (novela). Los hechos son la frontera entre el hub y el workspace.

## Infraestructura multi-tenant

Qdrant y Neo4j se usan como infraestructura compartida con aislamiento por workspace. Qdrant filtra sus colecciones compartidas por el campo `proyecto`; Neo4j aplica el slug en la propiedad `proyecto` de nodos y relaciones. Los scripts `scripts/qdrant.py` y `scripts/neo4j.py` son multi-tenant y reciben el slug en las operaciones del proyecto.

Los relatos no usan Qdrant ni Neo4j — su memoria se gestiona en `contexto_narrativo.md`.
