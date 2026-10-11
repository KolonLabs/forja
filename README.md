# Forja - Sistema multi-agente de generacion de ficcion

Forja es el hub que crea y compila proyectos de ficcion. No escribe manuscritos directamente: cada obra vive en un workspace aislado fuera del hub (por defecto en `../Forja-resultados/Obras/<slug>`), con su propio pipeline, agentes, skills y repositorio git.

## Flujo rapido

1. Desde el hub, ejecuta `/nuevo-proyecto` y completa el briefing editorial.
2. Abre el workspace creado: `opencode --cwd "<ruta que indica el hub>"`.
3. Dentro del workspace, desarrolla la obra y ejecuta `/publicar` para generar el manuscrito limpio.
4. En el mismo workspace, ejecuta `/compilar` para generar el libro en `publicacion/` (Markdown y, opcionalmente, EPUB y PDF).
5. Para reunir varios relatos en una antología, vuelve al hub y ejecuta `/crear-libro`.

Si un relato publicado requiere cambios de contenido, crea primero una edición derivada con `/nueva-edicion`; no uses `/recompilar-libro`, que solo regenera formatos.

```text
/nuevo-proyecto
opencode --cwd "../Forja-resultados/Obras/<slug>"
/publicar
/compilar --epub
/crear-libro <slug-antologia> <relato1> <relato2> [...] [--epub] [--pdf]
```

Consulta la [guia operativa del hub](docs/operacion-hub.md) para elegir escala, conocer los requisitos y ver ejemplos completos.

## Comandos del hub

| Comando | Uso |
|---|---|
| `/nuevo-proyecto` | Conduce un briefing editorial de siete fases y crea un workspace. |
| `/crear-libro` | Ensambla una antología desde dos o más relatos finalizados. |
| `/nueva-edicion` | Abre una edición corregible e independiente de un relato publicado. |
| `/recompilar-libro` | Añade o regenera formatos de una antología ya publicada sin tocar sus fuentes. |

Los comandos de escritura (`/generar`, `/corregir`, `/revisar`, `/expandir`, `/publicar`) y `/compilar` se ejecutan dentro del workspace, no desde el hub.

## Estructura

| Directorio | Proposito |
|-----------|----------|
| `.opencode/` | Hub: agentes, skills de scaffolding y comandos. |
| `shared/` | Fuente de verdad del pipeline de ficcion. |
| `scripts/` | Infraestructura para crear workspaces y compilar libros. |
| `../Forja-resultados/Obras/` (`FORJA_OBRAS`) | Fuera del hub: una carpeta y un repositorio git por obra. Los commits los decide la persona usuaria. |
| `../Forja-resultados/Publicados/` (`FORJA_PUBLICADOS`) | Fuera del hub: antologías compiladas en Markdown y, si se solicitan, EPUB y PDF. |

Cada workspace nuevo recibe `GUIA.md`, una ayuda rápida para elegir el comando adecuado según el estado de la obra y el objetivo editorial.

## Referencias

- [Guia operativa](docs/operacion-hub.md): pasos, restricciones, requisitos y solucion de errores habituales.
- [Registro de decisiones](docs/decisiones/README.md): decisiones arquitectonicas vigentes y sus consecuencias.
- [Deuda tecnica](docs/deuda-tecnica.md): riesgos abiertos y criterios para cerrarlos.
- [AGENTS.md](AGENTS.md): arquitectura, contratos internos y reglas del hub para agentes.
