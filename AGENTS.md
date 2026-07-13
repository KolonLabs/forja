# Forja Hub — Sistema multi-agente de generación de ficción con workspaces aislados

Forja Hub es un **contenedor de proyectos** de generación de ficción. No escribe ficción directamente: cada proyecto vive en su propio workspace bajo `workspaces/`, con pipeline, agentes, skills y datos aislados. El hub proporciona las herramientas para crear workspaces y compilar libros desde ellos.

## Arquitectura

```
Forja/
├── AGENTS.md                          # Constitución del hub (este archivo)
├── opencode.json                      # Config compartida MCP + permisos
├── .opencode/                         # Hub: solo scaffolding y creación de libros
│   ├── agents/
│   │   └── scaffolder.md              # Wizard de briefing editorial (7 fases)
│   ├── skills/
│   │   ├── scaffolding-acto/          # Esquema de acto narrativo
│   │   ├── scaffolding-hecho/         # Esquema de hecho narrativo
│   │   ├── scaffolding-relato/        # Conversación de estructura (relato)
│   │   ├── scaffolding-novela-simple/ # Conversación de estructura (novela)
│   │   └── scaffolding-multi-hilo/    # Conversación de estructura (multi-hilo)
│   └── commands/
│       ├── nuevo-proyecto.md          # /nuevo-proyecto
│       └── crear-libro.md             # /crear-libro
├── shared/                            # Fuente de verdad del pipeline de ficción
│   ├── .opencode/
│   │   ├── agents/                    # Agentes fijos: memoria, cronista (solo novelas)
│   │   ├── skills/                    # 36 skills: invariantes + exclusivos por escala
│   │   └── commands/                  # /generar, /revisar, /expandir, /publicar
│   └── pipelines/                     # Pipeline por escala
│       ├── relato/                    # agentes/ + skills/ + PIPELINE + ORQUESTACION
│       ├── novela-simple/
│       └── novela-multi-hilo/
├── scripts/                           # Infraestructura del hub
│   ├── lib/common.ps1                 # Utilidades compartidas
│   ├── new-project.ps1                # Dispatcher: lee brief por stdin, delega en escala
│   ├── new-relato.ps1                 # Creador de workspace relato
│   ├── new-novela-simple.ps1          # Creador de workspace novela simple
│   ├── new-novela-multi-hilo.ps1      # Creador de workspace novela multi-hilo
│   ├── crear-libro.ps1                # Ensambla libro desde workspaces publicados
│   ├── build.css                      # Estilos EPUB
│   ├── qdrant.py                      # Multi-tenant (colecciones por workspace)
│   └── neo4j.py                       # Multi-tenant (grafos por workspace)
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

El scaffolder **no se inyecta en workspaces**. Solo vive en el hub.

## Comandos del hub

| Comando | Descripción |
|---------|-------------|
| `/nuevo-proyecto` | Wizard de briefing (7 fases) + creación de workspace |
| `/crear-libro` | Ensambla un libro desde workspaces publicados (1+ relatos o 1 novela) |

Los comandos de escritura (`/generar`, `/revisar`, `/expandir`, `/publicar`) operan **dentro de un workspace** y los ejecuta el director de esa escala.

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
/crear-libro <slug-libro> <workspace1> [workspace2...] [--epub]
```
Lee los archivos limpios de los workspaces, los ensambla en `publicados/<libro>/`, y actualiza `config.json.estado = "publicado"` en los workspaces fuente.

## Reglas del hub

- **Idioma**: español (todo el contenido, vocabulario e interacción).
- **Crudeza**: máximo (explícito total). Sin eufemismos. Vocabulario directo y crudo.
- **No modificar otros workspaces** sin permiso explícito del usuario.
- **Cada workspace es autónomo**: tiene su propio `.opencode/` con agentes, skills y comandos inyectados según su escala. No conoce directorios superiores.
- **shared/ es inmutable** para workspaces creados. Las mejoras al pipeline se aplican manualmente desde el hub.

## shared/ como fuente de verdad

| Ubicación | Contenido |
|-----------|-----------|
| `shared/.opencode/agents/` | 2 agentes fijos: memoria, cronista (solo se inyectan en novelas) |
| `shared/.opencode/skills/` | 41 skills: invariantes + exclusivos por escala |
| `shared/.opencode/commands/` | 7 comandos: generar, revisar, expandir, publicar, refinar-hechos, revisar-guion, validar-hechos |
| `shared/pipelines/<escala>/` | 7 agentes + 4 skills + PIPELINE.md + ORQUESTACION.md por escala |

Al crear un workspace, el script inyecta solo los agentes y skills que corresponden a la escala detectada. Los agentes escala-específicos (director, guionista, escritor, validador, integrador, entidades) viven en `shared/pipelines/<escala>/agentes/`.

## Escalas soportadas

| Escala | Fases | Qdrant/Neo4j | Hilos | Agentes | Skills (~) |
|--------|-------|:---:|:---:|:---:|:---:|
| **relato** | 4 fases | No | No | 7 | 33 |
| **novela-simple** | 4 fases | Sí | No | 9 | 39 |
| **novela-multi-hilo** | 8 fases | Sí | Sí | 9 | 45 |

## Jerarquía narrativa

Forja define **actos → hechos**. El workspace define **escenas → beats** (relato) o **capítulos → escenas → beats** (novela). Los hechos son la frontera entre el hub y el workspace.

## Infraestructura multi-tenant

Qdrant y Neo4j se usan como infraestructura compartida con aislamiento por workspace. Cada novela tiene sus propias colecciones/grafos identificados por slug. Los scripts `scripts/qdrant.py` y `scripts/neo4j.py` son multi-tenant y reciben el slug como parámetro.

Los relatos no usan Qdrant ni Neo4j — su memoria se gestiona en `contexto_narrativo.md`.
