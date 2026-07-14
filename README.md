# Forja - Sistema multi-agente de generacion de ficcion

Forja es el hub que crea y compila proyectos de ficcion. No escribe manuscritos directamente: cada obra vive en un workspace aislado, con su propio pipeline, agentes y skills.

## Flujo rapido

1. Desde el hub, ejecuta `/nuevo-proyecto` y completa el briefing editorial.
2. Abre el workspace creado: `opencode --cwd "workspaces/<slug>"`.
3. Dentro del workspace, desarrolla la obra y ejecuta `/publicar` para generar el manuscrito limpio.
4. Vuelve al hub y ejecuta `/crear-libro` para ensamblar Markdown y, opcionalmente, EPUB y PDF.

Si un relato publicado requiere cambios de contenido, crea primero una edición derivada con `/nueva-edicion`; no uses `/recompilar-libro`, que solo regenera formatos.

```text
/nuevo-proyecto
opencode --cwd "workspaces/<slug>"
/publicar
/crear-libro <slug-libro> <workspace1> [workspace2 ...] [--epub] [--pdf]
```

Consulta la [guia operativa del hub](docs/operacion-hub.md) para elegir escala, conocer los requisitos y ver ejemplos completos.

## Comandos del hub

| Comando | Uso |
|---|---|
| `/nuevo-proyecto` | Conduce un briefing editorial de siete fases y crea un workspace. |
| `/crear-libro` | Compila una novela o una antologia desde workspaces finalizados. |
| `/nueva-edicion` | Abre una edición corregible e independiente de un relato publicado. |
| `/recompilar-libro` | Añade o regenera formatos de un libro ya publicado sin tocar sus fuentes. |

Los comandos de escritura (`/generar`, `/corregir`, `/revisar`, `/expandir`, `/publicar`) se ejecutan dentro del workspace, no desde el hub.

## Estructura

| Directorio | Proposito |
|-----------|----------|
| `.opencode/` | Hub: agentes, skills de scaffolding y comandos. |
| `shared/` | Fuente de verdad del pipeline de ficcion. |
| `workspaces/` | Proyectos aislados, cada uno con su propia configuracion. |
| `scripts/` | Infraestructura para crear workspaces y compilar libros. |
| `publicados/` | Libros compilados en Markdown y, si se solicitan, EPUB y PDF. |

## Referencias

- [Guia operativa](docs/operacion-hub.md): pasos, restricciones, requisitos y solucion de errores habituales.
- [Registro de decisiones](docs/decisiones/README.md): decisiones arquitectonicas vigentes y sus consecuencias.
- [Deuda tecnica](docs/deuda-tecnica.md): riesgos abiertos y criterios para cerrarlos.
- [AGENTS.md](AGENTS.md): arquitectura, contratos internos y reglas del hub para agentes.
