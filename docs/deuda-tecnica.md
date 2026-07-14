# Deuda tecnica del hub

Este registro contiene riesgos abiertos que requieren una correccion o una validacion futura. No duplica decisiones aceptadas ni el historial de incidencias resueltas.

## Criterio de uso

- Cada entrada debe indicar alcance, impacto y condicion verificable de cierre.
- Al resolverla, se mueve a la seccion de cerradas con la fecha y la evidencia.
- Una decision que cambie el diseno se registra tambien como ADR en [decisiones/](decisiones/README.md).

## Abierta

| ID | Riesgo | Impacto | Cierre verificable |
|---|---|---|---|
| DT-001 | No hay una suite automatizada de regresion para los scripts del hub que cubra creacion por escala y compilacion Markdown, EPUB y PDF con fixtures aisladas. | Una modificacion futura puede romper contratos de briefs o empaquetado sin detectarse antes de uso manual. | Incorporar pruebas repetibles que no modifiquen workspaces reales y ejecutar todas correctamente. |
| DT-002 | La disponibilidad de Pandoc y de los motores PDF se descubre al solicitar la compilacion. | El fallo se comunica tarde, al publicar un libro con salida EPUB o PDF. | Crear un preflight explicito del hub que informe herramientas encontradas, versiones y motores disponibles. |
| DT-003 | Los workflows de novela simple y novela multi-hilo aun usan `publicacion`/`publicado`, mientras que la compilacion del hub ya exige `finalizado` y la edición derivada solo existe para relatos. | Una novela creada con los flujos actuales no podra compilarse ni abrir una nueva edición hasta migrar su contrato de estados. | Revisar ambos workflows y sus plantillas/skills para que finalicen en `finalizado`, dejando `publicado` reservado al bibliotecario y añadiendo una edición derivada equivalente. |

## Cerrada

No hay entradas cerradas en este registro todavia. Las incidencias historicas resueltas permanecen en [plan-hechos-pendientes.md](plan-hechos-pendientes.md) como referencia, no como lista activa.
