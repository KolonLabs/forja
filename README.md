# Forja — Sistema multi-agente de generación de ficción

Forja no escribe ficción: crea **workspaces** que escriben ficción. Cada workspace es un proyecto aislado con su propio pipeline, agentes y skills.

## Empezar

```
/nuevo-proyecto         → Crear un proyecto (relato o novela)
/crear-libro            → Compilar uno o varios workspaces en un libro
opencode --cwd "workspaces/<slug>"   → Abrir un workspace existente
```

## Estructura

| Directorio | Propósito |
|-----------|----------|
| `.opencode/` | Hub: agente scaffolder, skills de scaffolding, comandos |
| `shared/` | Fuente de verdad del pipeline de ficción (agentes, skills, pipelines por escala) |
| `workspaces/` | Proyectos aislados. Cada uno con su `.opencode/` inyectado |
| `scripts/` | Infraestructura: creación de workspaces, compilación de libros |
| `publicados/` | Libros compilados (`.md`, `.epub`) |

## Documentación

`AGENTS.md` — Arquitectura completa del hub: agentes, comandos, escalas, jerarquía narrativa, infraestructura.
