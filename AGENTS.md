# Forja Hub — Sistema multi-agente de generación de ficción con workspaces aislados

Forja Hub es un **contenedor de proyectos** de generación de ficción. No escribe ficción directamente: cada proyecto vive en su propio workspace bajo `workspaces/`, con pipeline, agentes, skills y datos aislados. El hub proporciona las herramientas para crear workspaces y compilar libros desde ellos.

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
│   │   └── scaffolding-mapa/          # Estructura de MAPA.md por escala (Fase 7)
│   └── commands/
│       ├── nuevo-proyecto.md          # /nuevo-proyecto
│       ├── crear-libro.md             # /crear-libro
│       ├── nueva-edicion.md           # /nueva-edicion (relato)
│       └── recompilar-libro.md        # /recompilar-libro
├── shared/                            # Fuente de verdad del pipeline de ficción
│   ├── GUIA.md                        # Ayuda de comandos inyectada en cada workspace nuevo
│   ├── .opencode/
│   │   ├── agents/                    # Agentes fijos: memoria, cronista (solo novelas)
│   │   ├── skills/                    # 36 skills: invariantes + exclusivos por escala
│   │   └── commands/                  # /generar, /revisar, /expandir, /publicar
│   └── pipelines/                     # Pipeline por escala
│       ├── relato/                    # agentes/ + skills/ + commands/ + PIPELINE + ORQUESTACION
│       ├── novela-simple/
│       └── novela-multi-hilo/
├── scripts/                           # Infraestructura del hub
│   ├── lib/common.ps1                 # Utilidades compartidas
│   ├── new-project.ps1                # Dispatcher: lee brief por stdin, delega en escala
│   ├── new-relato.ps1                 # Creador de workspace relato
│   ├── new-novela-simple.ps1          # Creador de workspace novela simple
│   ├── new-novela-multi-hilo.ps1      # Creador de workspace novela multi-hilo
│   ├── crear-libro.ps1                # Ensambla libro desde workspaces finalizados
│   ├── new-edicion-relato.ps1         # Deriva una edición corregible de un relato publicado
│   ├── recompilar-libro.ps1           # Regenera formatos desde un libro publicado
│   ├── build-pdf.ps1                  # Compila PDF con Pandoc y un motor local
│   ├── templates/forja-kdp.typ         # Plantilla PDF reutilizable
│   ├── build.css                      # Estilos EPUB
│   ├── qdrant.py                      # Multi-tenant (colecciones compartidas por proyecto)
│   └── neo4j.py                       # Multi-tenant (grafo compartido por proyecto)
├── workspaces/                        # Proyectos hijos (workspaces aislados)
│   ├── legacy/                        # Workspaces legacy (referencia)
│   └── <slug>/                        # Un workspace por proyecto
└── publicados/                        # Libros compilados desde workspaces
    └── <libro>/                       # Un libro = uno o varios workspaces
```

## Agentes del hub

| Agente | Modelo | Fuente | Rol |
|--------|--------|--------|-----|
| **scaffolder** | `deepseek-v4-pro` | `.opencode/agents/scaffolder.md` | Wizard de briefing editorial. NO escribe ficción. Crea workspaces. |
| **bibliotecario** | `deepseek-v4-flash` | `.opencode/agents/bibliotecario.md` | Deriva ediciones de relatos publicados, ensambla libros desde workspaces finalizados y recompila formatos. No escribe ni edita contenido narrativo. |

Ninguno de los dos **se inyecta en workspaces**. Ambos viven solo en el hub.

## Comandos del hub

| Comando | Descripción |
|---------|-------------|
| `/nuevo-proyecto` | Wizard de briefing (7 fases) + creación de workspace |
| `/crear-libro` | Ensambla un libro desde workspaces finalizados (1+ relatos o 1 novela) |
| `/nueva-edicion` | Deriva un relato publicado en un workspace de corrección independiente |
| `/recompilar-libro` | Añade o regenera EPUB/PDF desde el Markdown congelado de un libro publicado |

Los comandos de escritura (`/generar`, `/corregir`, `/revisar`, `/expandir`, `/publicar`) operan **dentro de un workspace** y los ejecuta el director de esa escala.

## Cómo crear un proyecto nuevo

```
/nuevo-proyecto
```

El scaffolder conduce un briefing editorial en 7 fases (gancho → personajes → mundo → voz → estructura → reflexión → persistir). En Fase 5 determina la escala y construye los hechos narrativos. Al finalizar, construye un JSON con el brief y lo pipea a `scripts/new-project.ps1` por stdin. El script crea el workspace con los agentes, skills y archivos correspondientes a la escala.

## Cómo publicar y compilar

**Dentro del workspace:**
```
/publicar
```
Genera `relato.md` (relato) o `novela.md` (novela) en la raíz del workspace. Sin beats, sin escenas, sin actos. Solo texto limpio con capítulos (novela) o texto continuo (relato).

**Desde el hub:**
```
/crear-libro <slug-libro> <workspace1> [workspace2...] [--epub] [--pdf] [--pdf-formato <formato>] [--pdf-motor <motor>] [--titulo "<título>"] [--autor "<autor>"]
```
Lo ejecuta el agente **bibliotecario**: lee los archivos limpios de workspaces en estado `finalizado`, los ensambla en `publicados/<libro>/` y, cuando todas las salidas solicitadas terminan correctamente, actualiza las fuentes a `config.json.estado = "publicado"`. El director nunca asigna `publicado`.

Para añadir o regenerar EPUB/PDF de un libro ya publicado se usa `/recompilar-libro <slug-libro> [--epub] [--pdf] [--pdf-formato <formato>] [--pdf-motor <motor>]`. Opera solo sobre el Markdown y `manifest.json` congelados en `publicados/<libro>/`; no modifica workspaces.

Si cambia el contenido de un relato publicado, se usa `/nueva-edicion <workspace-publicado> <slug-edicion> [--titulo "..."] [--motivo "..."]`. Crea un workspace derivado en estado `correccion`, con `relato-edicion-anterior.md` como referencia inmutable. Tras `/corregir` y `/publicar`, la edición queda `finalizado` y se compila con un slug de libro nuevo. Este flujo no está disponible todavía para novelas.

## Reglas del hub

- **Idioma**: español (todo el contenido, vocabulario e interacción).
- **Crudeza**: máximo (explícito total). Sin eufemismos. Vocabulario directo y crudo.
- **No modificar otros workspaces** sin permiso explícito del usuario.
- **Cada workspace es autónomo**: tiene su propio `.opencode/` con agentes, skills y comandos inyectados según su escala. No conoce directorios superiores.
- **shared/ es inmutable** para workspaces creados. Las mejoras al pipeline se aplican manualmente desde el hub.

## Registros persistentes

- `docs/decisiones/` conserva las decisiones arquitectonicas y operativas vigentes. Consultarlo antes de cambiar contratos, aislamiento, infraestructura o formatos de salida.
- `docs/deuda-tecnica.md` registra riesgos abiertos y sus criterios de cierre. Actualizarlo al identificar o resolver un riesgo real.
- `docs/plan-hechos-pendientes.md` es historial de incidencias resueltas, no una fuente de trabajo activa.

## shared/ como fuente de verdad

| Ubicación | Contenido |
|-----------|-----------|
| `shared/.opencode/agents/` | 2 agentes fijos: memoria, cronista (solo se inyectan en novelas) |
| `shared/.opencode/skills/` | 41 skills: invariantes + exclusivos por escala |
| `shared/GUIA.md` | Guía de decisión para la persona usuaria, copiada como `GUIA.md` en cada workspace nuevo |
| `shared/.opencode/commands/` | 8 comandos: generar, revisar, expandir, corregir, publicar, refinar-hechos, revisar-guion, validar-hechos |
| `shared/pipelines/<escala>/` | Agentes, skills y, cuando una escala lo requiere, overrides de comandos + `PIPELINE.md` + `ORQUESTACION.md` |

Al crear un workspace, el script inyecta agentes y skills de su escala y aplica, después de los comandos comunes, los overrides de comando que correspondan. Los agentes escala-específicos (director, guionista, escritor, validador, integrador, entidades) viven en `shared/pipelines/<escala>/agentes/`.

## Escalas soportadas

| Escala | Fases | Qdrant/Neo4j | Hilos | Agentes | Skills (~) |
|--------|-------|:---:|:---:|:---:|:---:|
| **relato** | 4 fases | No | No | 7 | 33 |
| **novela-simple** | 4 fases | Sí | No | 9 | 39 |
| **novela-multi-hilo** | 8 fases | Sí | Sí (mín. 2) | 9 | 45 |

## Jerarquía narrativa

Forja define **actos → hechos**. El workspace define **escenas → beats** (relato) o **capítulos → escenas → beats** (novela). Los hechos son la frontera entre el hub y el workspace.

## Infraestructura multi-tenant

Qdrant y Neo4j se usan como infraestructura compartida con aislamiento por workspace. Qdrant filtra sus colecciones compartidas por el campo `proyecto`; Neo4j aplica el slug en la propiedad `proyecto` de nodos y relaciones. Los scripts `scripts/qdrant.py` y `scripts/neo4j.py` son multi-tenant y reciben el slug en las operaciones del proyecto.

Los relatos no usan Qdrant ni Neo4j — su memoria se gestiona en `contexto_narrativo.md`.
