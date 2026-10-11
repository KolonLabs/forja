# Registro de decisiones

Este directorio conserva decisiones arquitectonicas y operativas que deben sobrevivir a una sesion concreta. Cada ADR explica el contexto, la decision vigente y sus consecuencias.

## Uso

- Crea un ADR cuando una decision afecte contratos, aislamiento, infraestructura, formatos de salida o el comportamiento de varios scripts.
- No registres correcciones locales ni hallazgos ya resueltos que no cambien una regla durable.
- No reescribas un ADR aceptado. Si la decision cambia, crea otro ADR que lo sustituya y enlazalo.
- Actualiza [deuda-tecnica.md](../deuda-tecnica.md) cuando exista un riesgo pendiente de resolver, no cuando haya una decision ya cerrada.

## Decisiones vigentes

| ADR | Decision | Estado |
|---|---|---|
| [0001](0001-hub-y-workspaces-aislados.md) | El hub orquesta; los workspaces son autonomos. | Aceptada |
| [0002](0002-contrato-de-creacion-e-infraestructura.md) | La escala determina infraestructura y el brief es un contrato validado. | Aceptada |
| [0003](0003-publicacion-y-compilacion.md) | Publicación y compilación inicial de libros. | Sustituida parcialmente por ADR 0004 y ADR 0026 |
| [0004](0004-finalizado-y-recompilacion-de-formatos.md) | `finalizado` es la única entrada de compilación; `publicado` es terminal y los formatos se recompilan desde un manifiesto. | Sustituida parcialmente por ADR 0026 (lugar y agente de la compilación de una obra única) |
| [0005](0005-ediciones-derivadas-de-relato.md) | Los cambios de contenido de un relato publicado se hacen en una edición derivada. | Aceptada |
| [0006](0006-beats-globales-y-escenas-derivadas-en-relato.md) | Relato diseña beats globales antes de derivar escenas; usa IDs H/B/E visibles sin infraestructura. | Aceptada |
| [0007](0007-escritura-por-escenas-operativas-en-relato.md) | Relato escribe y valida por escenas operativas; su contrato de recurrencias fue sustituido por ADR 0013. | Sustituida parcialmente por ADR 0013 |
| [0008](0008-contratos-ejecutables-de-relato.md) | Relato materializa IDs, aísla sus skills y usa anclas invisibles de beat dentro de prosa por escena. | Aceptada |
| [0009](0009-integridad-transaccional-de-relato.md) | Relato persiste estructura de forma transaccional; la cola de recurrencias fue sustituida por ADR 0013. | Sustituida parcialmente por ADR 0013 |
| [0010](0010-rehidratacion-de-relatos-legados.md) | Un relato legado se reinicia desde su semilla editorial en un destino nuevo; no migra prosa ni guion. | Sustituida parcialmente por ADR 0014 |
| [0011](0011-importacion-de-fuentes-narrativas-libres.md) | Fuentes libres se analizan como evidencia trazable antes de construir un brief confirmado. | Sustituida por ADR 0012 |
| [0012](0012-importacion-general-y-extraccion-editorial.md) | La importación es transversal a escalas y usa una skill para extraer evidencia antes de proponer la escala. | Sustituida parcialmente por ADR 0015 |
| [0013](0013-beats-globales-con-patrones-inferidos-en-relato.md) | Relato integra patrones y contraste en el mapa global de beats, sin `[D]` ni `cola_d.md`. | Aceptada |
| [0014](0014-reconstruccion-editorial-en-rehidratacion-de-relatos.md) | La rehidratación extrae evidencia y el scaffolder reconstruye hechos con entidad suficiente para derivar beats. | Aceptada |
| [0015](0015-reconstruccion-editorial-en-importacion-de-proyectos.md) | La importación reconstruye un argumento confirmado desde evidencia, sin convertir hipótesis en hechos recuperados. | Aceptada |
| [0016](0016-url-publicas-como-fuentes-de-importacion.md) | La importación admite rutas locales y URL HTTPS públicas trazables, con límites de red. | Aceptada |
| [0017](0017-contrato-de-draft-y-estado-terminal-en-novelas.md) | Las novelas terminan en `finalizado`, el draft usa un único encabezado `stable_id [seq]` y cada escala recibe solo sus artefactos. | Aceptada |
| [0018](0018-aislamiento-multi-tenant-qdrant-neo4j-y-contrato-l4.md) | El L4 es único por proyecto con identidad opaca; las lecturas por ID físico verifican proyecto; el import de Neo4j escribe `r.proyecto`. | Aceptada |
| [0019](0019-narrativa-por-escena-y-checkpoint-en-novelas.md) | Las novelas escriben por escena con contexto preparado sin herramientas, persistencia con hash y checkpoint humano obligatorio. | Aceptada |
| [0020](0020-contrato-editorial-de-beats-y-detalle-explicito.md) | El beat es una unidad dramática; la ejecución es del escritor y las escenas explícitas se muestran con progresión. | Aceptada |
| [0021](0021-alcance-de-relato-sin-checkpoint.md) | Relato conserva su autonomía y solo adopta el paquete de escena explícita. | Aceptada |
| [0022](0022-continuacion-de-relatos-con-canon-y-fichas-semilla.md) | Las continuaciones de relato reciben canon heredado y fichas semilla reconstruidas, sin acoplar workspaces. | Aceptada |
| [0023](0023-skills-compartidas-en-claude-skills-y-aislamiento-del-hub-en-opencode.md) | Las skills de un workspace viven solo en `.claude/skills` y opencode desactiva los agentes del hub. | Aceptada |
| [0024](0024-dos-entornos-equivalentes-opencode-y-claude-code.md) | Cada agente y comando existe en versión opencode y Claude Code escritas a mano, con skills compartidas y modelos acordados por rol. | Aceptada |
| [0025](0025-explicitud-obligatoria-y-validacion-por-nivel.md) | La explicitud es obligatoria en el brief y `validacion-crudeza` aplica el criterio del nivel del proyecto. | Aceptada |
| [0026](0026-obras-como-repositorios-independientes-fuera-del-hub.md) | Cada obra es un repositorio git propio fuera del hub, sin copias de seguridad automáticas, y se compila a sí misma con `/compilar`; el hub solo ensambla antologías. | Aceptada; rutas por defecto sustituidas por ADR 0027 |
| [0027](0027-raiz-comun-forja-resultados.md) | Obras y publicados viven juntos en `Forja-resultados/`, hermana del hub (`FORJA_RESULTADOS`). | Aceptada |
