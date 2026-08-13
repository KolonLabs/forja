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
| DT-003 | No existe edición derivada para novelas. `/nueva-edicion` solo contempla relatos, por lo que una novela `publicado` no puede corregirse sin reabrir el original. | Un cambio de contenido en una novela ya compilada obliga a editar el workspace publicado a mano, rompiendo el linaje de ediciones. | Diseñar el flujo de edición derivada de novela (referencia inmutable, estado `correccion`, `/corregir` de escala) y registrar la decisión como ADR. |
| DT-005 | Los workspaces de novela ya creados (`workspaces/dinastias-del-poder`) conservan la copia antigua del pipeline: escriben `publicado`, usan el encabezado `## B_XX` en draft y tienen inyectados `/corregir` y `contexto-narrativo`. | Si se retoman con su `.opencode/` actual, reproducen los defectos corregidos en ADR 0017 y terminan en un estado que el hub rechaza. | Reinyectar el pipeline vigente en cada workspace de novela existente y normalizar su `config.json.estado`, o recrearlos. |
| DT-006 | Los workspaces `dinastias-del-poder`, `eros-9`, `canida-2 - copia` y `legacy/*` conservan copias de `scripts/qdrant.py` y `scripts/neo4j.py` anteriores a ADR 0018: L4 con `stable_id="global"`, `query-entity` sin verificación de proyecto e `import` de Neo4j que no escribe `r.proyecto`. | Si se retoman y usan sus scripts locales, pueden pisar el L4 de otro proyecto, leer entidades ajenas por colisión de stable_id o perder relaciones en un round-trip export→import. | Reinyectar `scripts/qdrant.py` y `scripts/neo4j.py` del hub en cada workspace listado y verificar hashes. (`canida-2` quedó reinyectado en 2026-08-13.) |

## Cerrada

| ID | Resolución | Evidencia |
|---|---|---|
| DT-004 | Se añadió una regresión aislada del workflow de relato: hechos y contadores, rechazo de marcas `[D]`, diseño sin cola de recurrencias, componentes, draft parcial por escenas, corrección con registro, recuperación/descartado, publicación con prosa, inyección sin infraestructura de novela y edición derivada segura. | `pwsh -NoProfile -File tests/relato-workflow-regression.ps1` finaliza correctamente (2026-07-14). |
| DT-003 (parcial: contrato de estados) | Ambas escalas de novela terminan en `finalizado`; `publicado` queda reservado al hub. Se unificó el encabezado del draft en `## <stable_id> [<seq>]`, se añadió override de `/publicar` por escala y se dejaron de inyectar `/corregir` y `contexto-narrativo` en novelas. La parte de edición derivada sigue abierta como DT-003. | [ADR 0017](decisiones/0017-contrato-de-draft-y-estado-terminal-en-novelas.md); creación verificada de workspaces de las tres escalas (2026-08-05). |
| Aislamiento multi-tenant Qdrant/Neo4j | Auditoría de aislamiento por slug: el L4 pasó a identidad opaca única por proyecto (adiós al literal `"global"` compartido); `query-entity` y el fetch previo de `update-beat` verifican `proyecto`; el `import` de Neo4j escribe `r.proyecto` (round-trip export→import→export verificado: 22/22 relaciones); los mensajes de consola dejan de usar `→` para no reventar en cp1252. Scripts reinyectados en `canida-2` con hashes verificados; docs de `shared/` y `canida-2` alineadas. | [ADR 0018](decisiones/0018-aislamiento-multi-tenant-qdrant-neo4j-y-contrato-l4.md); smoke tests en vivo con datos de prueba limpios (2026-08-13). |

Las incidencias historicas resueltas permanecen en [plan-hechos-pendientes.md](plan-hechos-pendientes.md) como referencia, no como lista activa.
