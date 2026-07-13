# ADR 0001: Hub y workspaces aislados

- Estado: aceptada
- Fecha: 2026-07-13

## Contexto

Forja agrupa proyectos de ficcion con escalas y necesidades diferentes. Un cambio en un proyecto no debe alterar el pipeline, los agentes ni los datos de otro proyecto existente.

## Decision

El hub solo conduce el briefing, crea workspaces y compila libros. Cada workspace recibe una copia autonoma de los componentes necesarios para su escala y no depende de directorios superiores durante su operacion.

`shared/` es la fuente de verdad para crear workspaces nuevos, pero una mejora posterior no se propaga automaticamente a los ya creados. Cualquier actualizacion de un workspace existente requiere una accion deliberada y permiso para modificarlo.

## Consecuencias

- Los comandos de escritura se ejecutan dentro del workspace, no desde el hub.
- Los cambios de pipeline se validan primero en el hub y se aplican manualmente a workspaces existentes cuando proceda.
- Las revisiones del hub deben excluir workspaces hijos salvo que se solicite expresamente lo contrario.

## Referencias

- [AGENTS.md](../../AGENTS.md)
- [Guia operativa](../operacion-hub.md)
