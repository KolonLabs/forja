# ADR 0002: Contrato de creacion e infraestructura por escala

- Estado: aceptada
- Fecha: 2026-07-13

## Contexto

La creacion de un workspace parte de un brief editorial. Si sus datos estructurales no son completos o si la infraestructura es opcional en una novela, el pipeline recibe configuraciones incompatibles y falla mas adelante.

## Decision

El brief es un contrato validado antes de delegar en el creador de la escala. Debe incluir slug, titulo, escala, estilo base, hechos y `MAPA.md` inicial. Los proyectos multi-hilo requieren al menos dos hilos, con slugs canonicos `hilo-<kebab-case>` y actos asociados de forma exacta a esos hilos.

La infraestructura depende exclusivamente de la escala:

| Escala | Qdrant y Neo4j |
|---|---|
| `relato` | No se inicializan. |
| `novela-simple` | Obligatorios. |
| `novela-multi-hilo` | Obligatorios. |

No existe una opcion para desactivar la infraestructura de una novela. El parametro heredado `--sin-infra` y el campo `_no_infra` no son compatibles.

## Consecuencias

- Los fallos de contrato se rechazan al crear el proyecto, no durante la escritura.
- Los relatos conservan una memoria local sin requerir servicios externos.
- Las novelas se crean siempre con la infraestructura que necesita su pipeline.

## Referencias

- [scripts/new-project.ps1](../../scripts/new-project.ps1)
- [Guia operativa](../operacion-hub.md)
