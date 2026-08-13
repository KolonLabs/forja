# Sincronización pendiente con `shared/` (escala novela-multi-hilo)

Este documento resume el rediseño del pipeline hecho en el workspace `canida-2` y qué hace falta aplicar en el repo padre (`Forja/shared/`) para que **todos los workspaces futuros** de esta escala nazcan ya con las mejoras. `shared/` es inmutable desde dentro de un workspace (regla del hub) — esta sincronización debe ejecutarse desde la raíz de Forja.

> **Alcance: SOLO `novela-multi-hilo`.** Todo el análisis, la verificación y las recomendaciones de este documento están acotadas a esa escala. Dos de los archivos implicados (`hechos-distribuidos` y `scripts/lib/common.ps1`) son compartidos por las tres escalas (`relato`, `novela-simple`, `novela-multi-hilo`) — **este documento no analiza ni decide su impacto en las otras dos**. Eso queda explícitamente como responsabilidad de Forja (la sesión que opera desde la raíz del hub), no de este workspace. Donde eso aplica, está marcado en rojo abajo.

---

## Historial de esta sincronización

Este documento pasó por una ronda de auditoría externa (hecha desde la raíz de Forja) que encontró dos problemas graves en la versión original: (1) los archivos de agente reales (`director.md`, `guionista.md`, `auditor-beats.md`) nunca se habían tocado — solo la documentación de referencia (`PIPELINE.md`/`ORQUESTACION.md`) reflejaba el rediseño; (2) `hechos-distribuidos` es un skill compartido con `novela-simple`, y esa escala usa **activamente** el algoritmo antiguo que la reescritura de multi-hilo sustituyó por completo. Ambos hallazgos están corregidos en la versión actual de este documento: los 3 agentes ya se reescribieron en el workspace (ver tabla), y `hechos-distribuidos` queda explícitamente fuera de la sincronización automática.

---

## Tabla de aplicación rápida

| # | Archivo en el workspace | Destino en `shared/` | Estado |
|---|--------------------------|------------------------|--------|
| 1 | `PIPELINE.md` | `shared/pipelines/novela-multi-hilo/PIPELINE.md` | ✅ Seguro — copiar completo |
| 2 | `ORQUESTACION.md` | `shared/pipelines/novela-multi-hilo/ORQUESTACION.md` | ✅ Seguro — copiar completo |
| 3 | `GUIA.md` | `shared/pipelines/novela-multi-hilo/GUIA.md` | ⚠️ Copiar **con una exclusión** — ver nota abajo |
| 4 | `.opencode/skills/hechos-distribuidos/SKILL.md` | `shared/.opencode/skills/hechos-distribuidos/SKILL.md` | 🔴 **NO copiar tal cual** — compartido con `novela-simple`, ver nota abajo |
| 5 | `.opencode/skills/hechos-estructura/SKILL.md` | `shared/.opencode/skills/hechos-estructura/SKILL.md` | ✅ Seguro — ya distingue multi-hilo/simple correctamente |
| 6 | `.opencode/skills/plantilla-guion/SKILL.md` | `shared/pipelines/novela-multi-hilo/skills/plantilla-guion/SKILL.md` | ✅ Seguro — exclusivo de escala |
| 7 | `.opencode/agents/guionista.md` | `shared/pipelines/novela-multi-hilo/agentes/guionista.md` | ✅ Seguro — copiar completo (exclusivo de escala) |
| 8 | `.opencode/agents/director.md` | `shared/pipelines/novela-multi-hilo/agentes/director.md` | ✅ Seguro — copiar completo (exclusivo de escala) |
| 9 | `.opencode/agents/auditor-beats.md` | `shared/pipelines/novela-multi-hilo/agentes/auditor-beats.md` | ✅ Seguro — copiar completo (exclusivo de escala) |
| 10 | — | `scripts/lib/common.ps1` línea ~747 | ✅ Seguro — ya condicionado a `novela-multi-hilo` en el código |
| 11 | — | `scripts/lib/common.ps1` línea ~772 | 🔴 **Retirado** — no es responsabilidad de esta sincronización, ver nota abajo |

Comando sugerido para los ítems 1, 2, 5, 6, 7, 8, 9 (seguros, sin exclusiones — ejecutar desde la raíz de Forja):

```powershell
Copy-Item "workspaces\canida-2\PIPELINE.md" "shared\pipelines\novela-multi-hilo\PIPELINE.md" -Force
Copy-Item "workspaces\canida-2\ORQUESTACION.md" "shared\pipelines\novela-multi-hilo\ORQUESTACION.md" -Force
Copy-Item "workspaces\canida-2\.opencode\skills\hechos-estructura\SKILL.md" "shared\.opencode\skills\hechos-estructura\SKILL.md" -Force
Copy-Item "workspaces\canida-2\.opencode\skills\plantilla-guion\SKILL.md" "shared\pipelines\novela-multi-hilo\skills\plantilla-guion\SKILL.md" -Force
Copy-Item "workspaces\canida-2\.opencode\agents\guionista.md" "shared\pipelines\novela-multi-hilo\agentes\guionista.md" -Force
Copy-Item "workspaces\canida-2\.opencode\agents\director.md" "shared\pipelines\novela-multi-hilo\agentes\director.md" -Force
Copy-Item "workspaces\canida-2\.opencode\agents\auditor-beats.md" "shared\pipelines\novela-multi-hilo\agentes\auditor-beats.md" -Force
```

Los ítems 3 (exclusión) y 4 (no copiar) requieren la lectura de las notas siguientes antes de actuar. El ítem 11 no se aplica desde este análisis en absoluto.

---

## Ítem 3 — `GUIA.md`: copiar con una exclusión

La versión de `canida-2` refleja correctamente el pipeline nuevo (estado `hilos_beats`, diagrama "Camino habitual", sección "Cómo se construye la novela"). **Esa parte sí debe sincronizarse.**

Pero esa misma versión también **eliminó la mención a `MAPA.md`** ("Consulta `MAPA.md` para localizar el archivo correcto"), porque en `canida-2` ese archivo estaba vacío. La investigación del apéndice (ver abajo) demuestra que `MAPA.md` **funciona correctamente en otros proyectos multi-hilo** (`dinastias-del-poder` lo tiene bien poblado) — el vacío en `canida-2` fue un fallo específico de esa sesión de scaffolding, no un problema de la escala. Si se copia la versión de `canida-2` tal cual, se estaría quitando una guía útil y funcional para todos los proyectos futuros de multi-hilo basándose en un fallo de un solo proyecto.

**Acción recomendada:** sincronizar el resto de `GUIA.md` (estado `hilos_beats`, diagramas), pero **conservar** la línea "Consulta `MAPA.md` para localizar el archivo correcto" en la versión de `shared/`. Esto requiere una edición manual puntual, no una copia directa del archivo.

---

## Ítem 4 — `hechos-distribuidos`: NO copiar tal cual (compartido con `novela-simple`)

**Esto es lo más importante de este documento.**

`shared/.opencode/skills/hechos-distribuidos/SKILL.md` es un skill invariante compartido por `novela-multi-hilo` **y** `novela-simple` (confirmado: `novela-simple/PIPELINE.md` lo lista entre sus invariantes y lo usa en su FASE 0.1 y 0.3). Verificado directamente en los agentes de `novela-simple` (`shared/pipelines/novela-simple/agentes/{director,guionista,auditor-beats}.md`): esa escala usa **hoy, activamente**, el algoritmo original de `hechos-distribuidos` — cola de inyección diferida (`cola_d.md`), FASE 2.2b "Distribución de `[D]`" con posiciones decididas por el director, estructura "Fase A-D". No es legado muerto: es el flujo correcto y vigente para `novela-simple`.

La reescritura hecha en `canida-2` sustituyó ese algoritmo por completo con el modelo nuevo de multi-hilo (una sola pasada por capítulo-borrador, checkpoints, `hilos/hilo-S/cola_d.md` como registro de contenido, sin fórmula fija de instancias). Es **100% correcta y necesaria para multi-hilo**, pero si se copia tal cual a `shared/`, cualquier proyecto futuro de `novela-simple` con hechos `[D]` recibiría instrucciones inaplicables (referencias a hilos, capítulos-borrador y rutas que esa escala no tiene).

**Lo que SÍ puedo confirmar (acotado a multi-hilo):** la sección de multi-hilo, tal como quedó en el workspace, es correcta y está lista.

**Lo que corresponde a Forja decidir (fuera de este análisis):** cómo reconciliar un único archivo compartido que debe servir a ambos modelos — por ejemplo, separarlo en secciones explícitas `## Novela simple` / `## Novela multi-hilo` (siguiendo el patrón que ya funciona en `hechos-estructura`, confirmado seguro), o cualquier otra estructura que Forja considere mejor. La versión aún intacta de `shared/.opencode/skills/hechos-distribuidos/SKILL.md` conserva el algoritmo original de `novela-simple` sin cambios — no hace falta recuperarlo de ningún backup.

---

## Ítem 11 (antes ítem 8) — `common.ps1` línea ~772: retirado de este análisis

La línea `**Escala:** $Escala | **PIPELINE.md** (fases) | **MAPA.md** (rutas de datos) | **ORQUESTACION.md** (spawn agentes)` vive en un heredoc común a las **tres** escalas (no está condicionada por `$Escala` en el código, a diferencia de `$hiloSection` unas líneas más abajo). Cualquier cambio ahí afecta a `relato` y `novela-simple` también.

Dado que este documento se acota a multi-hilo, **no propongo ninguna acción sobre esta línea**. Además, la investigación del apéndice muestra que el mecanismo de `MAPA.md` funciona bien en general — no hay evidencia de que haga falta tocar código compartido por esto. Queda completamente en manos de Forja decidir si esta línea necesita algún cambio, evaluando las tres escalas.

---

## Qué cambió y por qué (resumen por tema)

### 1. Beats y escenas se generan por hilo, antes del trenzado (cambio estructural mayor)

Antes: el guionista generaba beats **después** de trenzar, directamente sobre el capítulo global ya ensamblado por hechos (`modo: capitulo`, pasada 1/2).

Ahora: cada hilo se desarrolla **aislado** hasta tener sus propios beats y escenas completos, agrupando hechos en **capítulos-borrador** por coherencia de contexto (no por cuota fija). Solo entonces el trenzado mueve escenas ya escritas a capítulos globales reales.

- Nueva **FASE 0.3** — Beats y escenas por hilo (`estado: hilos_beats`), entre "Hilos" (0.2) y "Trenzado" (ahora 0.4).
- Nueva jerarquía de archivos: `hilos/hilo-<slug>/cap-NN/guion.md` (capítulo-borrador, sin prosa, no persiste en Qdrant).
- Nuevo estado de hilo: `hilos[].estado = "beats_listos"`.
- El pipeline pasa de **8 a 9 fases**.
- Nuevo modo de guionista: `hilo-capitulo` (genera beats + agrupa en escenas, dentro de un hilo).
- **Modo `capitulo` eliminado por completo** — ya no tiene función (ver punto 2).
- **Checkpoint universal**: todo capítulo-borrador, tenga `[D]` o no, pasa por un checkpoint de usuario tras agruparse en escenas (más ligero si no hay `[D]`, ya que no hay instancias que validar).

### 2. Hechos `[D]` resueltos por completo en FASE 0.3, sin fórmula fija (cambio estructural mayor, exclusivo de multi-hilo)

Antes (en multi-hilo): `[D]` se resolvía en escritura (FASE 3), con una cola de inyección diferida (`cola_d.md` a nivel de capítulo global), un paso separado donde el director decidía posiciones exactas, y una fórmula numérica fija (2-3 instancias por defecto, 3-4 si el rango era largo).

Ahora (solo multi-hilo — `novela-simple` conserva su propio modelo, ver Ítem 4):
- `[D]` es siempre **intra-hilo** (verificado: ningún caso real lo necesita cross-hilo, y el modelo de datos no lo soporta — un hecho vive en un solo hilo).
- Se resuelve **enteramente en FASE 0.3**, antes de que exista ningún capítulo global.
- **Una sola pasada creativa** por capítulo-borrador: beats lineales y `[D]` se generan entretejidos juntos, y luego se agrupan en escenas — no hay inyección diferida sobre escenas ya cerradas.
- **Sin fórmula numérica fija**: el número de instancias de un `[D]` es juicio narrativo contextual (puede ser 2, puede ser 10), decidido en un Checkpoint 1 (plan) antes de escribir.
- **Checkpoint 2** tras escribir: el director + usuario verifican que las instancias no repiten contenido de tramos anteriores.
- `cola_d.md` cambia de naturaleza: de "cola de inyección" a **registro de contenido** (`stable_id` + escena + resumen de cada instancia ya escrita), vive en `hilos/hilo-S/cola_d.md` (no en el capítulo global), es efímero por hilo y se descarta al cerrar el hilo.
- El skill `hechos-distribuidos` **del workspace** (no de `shared/`) refleja este modelo — ver Ítem 4 para por qué no se sincroniza tal cual.

### 3. El trenzado descubre conexiones del contenido real, no consume una lista pre-tageada (cambio de diseño)

Antes: el trenzado leía una lista de "puntos de conexión" declarada en diseño (antes de que existiera ningún beat) y se esperaba que la respetara mecánicamente.

Ahora: el trenzado (FASE 0.4) lee el **contenido real** de todas las escenas de todos los hilos, usa el `## Puntos de conexión` de `guion-novela.md` solo como **pista temática** (no como lista a verificar), y descubre él mismo dónde se materializa cada conexión — incluidos ecos orgánicos no previstos en el diseño original. Al terminar, **reescribe** esa sección de `guion-novela.md` con referencias concretas por `stable_id` de escena.

Motivo del cambio: evitar "arrastrar" un trenzado a nivel de hecho hacia el trenzado a nivel de escena — con el contenido real ya escrito, el trenzado tiene mejor información para decidir que en el momento del diseño.

### 4. El trenzado ahora opera sobre escenas, no sobre hechos (consecuencia directa de 1 y 3)

- Unidad atómica del trenzado: la **escena** (con su `stable_id`), no el hecho.
- Tabla `## Trenzado` de `guion-novela.md`: columna `Escenas` añadida junto a `Hechos` (esta última solo como referencia de trazabilidad).
- FASE 3 (escritura) simplificada: como los beats ya existen y `[D]` ya se resolvió, ya no hace falta "pasada 1/2" de generación ni inyección de `[D]` en escritura. La antigua FASE 3.2 (generar beats del capítulo) se sustituyó por una **auditoría de costuras cross-hilo** (las escenas de distintos hilos se escribieron en llamadas independientes y pueden no encajar en la transición) + checkpoint + corrección puntual si hace falta.

### 5. Los agentes ejecutables se sincronizaron con el diseño (hallazgo crítico de la auditoría externa)

La primera versión de este documento solo cubría la documentación de referencia (`PIPELINE.md`/`ORQUESTACION.md`). Una auditoría externa detectó que los archivos de agente reales — `director.md`, `guionista.md`, `auditor-beats.md`, los que un subagente carga de verdad al invocarse — seguían siendo **byte a byte idénticos** a la versión antigua en `shared/`, sin ningún backup previo. El pipeline documentado y el pipeline ejecutado estaban desincronizados: un workspace nuevo habría arrancado con `PIPELINE.md` describiendo 9 fases y un `guionista.md` todavía instruyendo el modo `capitulo` inexistente.

Corregido en el workspace: los 3 agentes se reescribieron por completo (con backup previo), ver ítems 7-9 de la tabla. Verificado que los otros 6 agentes (`escritor`, `validador`, `integrador`, `memoria`, `cronista`, `entidades`) no tenían ninguna referencia al modelo antiguo y no necesitaron cambios.

### 6. Correcciones de bugs objetivos (introducidos por mí durante la reescritura de esta sesión, no preexistentes en `shared/`)

- `ORQUESTACION.md`: llave `{{/if}}` sobrante en la plantilla de briefing del guionista (desbalance real: 7 aperturas vs 8 cierres en ese bloque, introducido al escribir el contenido nuevo). Corregido.
- `PIPELINE.md`: una fila de tabla (`0.3.3`) quedó flotando tras dos tablas de columnas distintas durante la reescritura — Markdown no la habría renderizado como continuación de la tabla original. Reestructurado con encabezados de sección en vez de numeración de fila.
- `AGENTS.md` (plantilla en `common.ps1`, ítem 10 arriba): faltaba `beats_listos` en la enumeración de estados de hilo — este sí es un hueco real preexistente, no algo que yo introdujera.
- `hechos-estructura`: la sección "Distribución en capítulos" describía el modelo viejo (hechos → tabla de trenzado directamente) — hueco preexistente. Ahora distingue multi-hilo (hechos → capítulos-borrador → trenzado por escena) de novela simple (hechos → capítulos directamente).
- `plantilla-guion`: el campo de escena `Puntos de conexión` no estaba marcado opcional — hueco preexistente que podía sugerir que el trenzado lo consume mecánicamente (ya no es el caso, ver punto 3). Marcado `(opcional, informal)` con nota aclaratoria.

---

## Qué NO se migra (específico de Canida-2, no pertenece a `shared/`)

- `config.json` (estado, hilos, puntos de conexión concretos del proyecto)
- `guion-novela.md` (hilos, conexiones y trenzado de esta novela)
- `hilos/hilo-*/diseno-hilo.md` y `hilos/hilo-*/guion-hilo.md` (contenido narrativo real de Canida-2)
- `AGENTS.md` de este workspace (generado a partir de la plantilla de `common.ps1` + el brief específico — solo la plantilla en el script se sincroniza, ítem 10)
- `.opencode/skills/hechos-distribuidos/SKILL.md` del workspace, **tal cual** (ver Ítem 4 — es multi-hilo puro, necesita reconciliación antes de ir a `shared/`)

---

## Apéndice — hallazgo de `MAPA.md`, investigado con evidencia real

La primera versión de este documento dejó esto sin investigar ("posiblemente un fallo puntual, no lo comprobé"). Una auditoría externa señaló que la evidencia ya estaba disponible en el propio repo. Investigado ahora:

| Workspace | Escala | `MAPA.md` |
|---|---|---|
| `canida-2` | multi-hilo | Stub vacío: `"Consultar MAPA.md generado por new-project.ps1"` |
| `canida-2 - copia` | multi-hilo | **Mismo stub literal**, creado ~90 segundos después que `canida-2` |
| `dinastias-del-poder` | multi-hilo | Bien poblado (jerarquía narrativa real, específica del proyecto) |
| `eros-9` | novela-simple | Bien poblado (jerarquía narrativa real, específica del proyecto) |

`common.ps1` tiene una función `Write-MapaMd` que escribe contenido real desde `$Brief._mapa`, poblado por el skill `scaffolding-mapa` durante la Fase 7 del scaffolder. El texto stub encontrado no aparece en ningún script del hub — no es un fallback conocido del código.

**Conclusión:** el mecanismo de `MAPA.md` funciona correctamente en general (confirmado en un proyecto multi-hilo y uno novela-simple, ambos no relacionados con Canida-2). El fallo es específico de la sesión/conversación de scaffolding que generó "canida-2" y su variante "canida-2 - copia" — probablemente algo en cómo se desarrolló esa conversación concreta de Fase 7, no un bug sistémico del pipeline ni de la escala multi-hilo. No amerita ningún cambio de código (de ahí el retiro del antiguo ítem 8, ver arriba). Si se quiere profundizar en la causa exacta, es una revisión del comportamiento del `scaffolder`/`scaffolding-mapa` en esa sesión concreta — posiblemente valga una nota en `docs/deuda-tecnica.md`, a criterio de Forja.
