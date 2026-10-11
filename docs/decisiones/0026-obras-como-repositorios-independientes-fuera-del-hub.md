# ADR 0026: Obras como repositorios independientes fuera del hub

- Estado: aceptada
- Fecha: 2026-10-11
- Ámbito: hub (creación, compilación, ediciones, rehidratación, importación), `shared/` (las tres escalas) y workspaces existentes.
- Relaciona: ADR 0001, ADR 0023, ADR 0024. Sustituye parcialmente ADR 0003 y ADR 0004 (lugar y agente de la compilación de una obra única).

## Contexto

Los workspaces viven en `Forja/workspaces/` y se versionan, en parte, en el repositorio del hub:

- El historial del hub mezcla cambios del pipeline con avances de escritura (`feat(renacer-para-perder): avance de cap-05…`) y la revisión previa a commit pierde sentido cuando el diff incluye prosa.
- El `.gitignore` del hub excluye `draft.md` y `relato-draft.md`: los borradores nunca se han versionado. Algunos workspaces ni siquiera están trackeados.
- Para suplir esa falta, los directores y `persistir-escena.py` crean una copia con fecha antes de cada cambio. Al decidir esta ADR había 301 copias (`*.bak-*`, `*_backup_*`, `guion.backup.*`, `draft.md.<fecha>.bak`) en cinco workspaces. Son ruido y no sustituyen a un historial: cada cambio genera una copia, aunque la persona usuaria haga varios cambios antes de considerar un punto de guardado.
- opencode sube hasta la raíz de git y descubre los agentes y skills del hub desde un workspace. ADR 0023 lo parchea desactivando los agentes del hub en el `opencode.json` de cada workspace, sin poder ocultar sus skills.
- Una obra no puede compilarse a EPUB/PDF sin pasar por el hub.

## Decisión

1. **Una obra = un workspace = un repositorio git local.** Las obras viven fuera del hub, en una raíz de obras. Cada una tiene su propio `.git`, creado al generar el workspace. Subirla a un remoto (GitHub u otro) es opcional y se decide por obra.
2. **Raíces configurables.** La raíz de obras es `FORJA_OBRAS` y la de libros del hub, `FORJA_PUBLICADOS`. Si no están definidas, son las carpetas hermanas del hub: `..\Obras` y `..\Publicados` (hoy `C:\Proyectos\Personal\Writting\Obras` y `C:\Proyectos\Personal\Writting\Publicados`). `scripts/lib/common.ps1` resuelve ambas y todos los scripts del hub las usan; ninguno compone `workspaces\<slug>` a mano.
3. **Los commits los decide la persona usuaria.** Ni los scripts ni los agentes hacen commits ni crean copias de seguridad. Se pueden hacer varios cambios antes de un commit; el commit es el punto de restauración. Se retiran las instrucciones «backup antes de sobrescribir» de directores, `ORQUESTACION.md`, `GUIA.md`, `/publicar` y `/corregir` en las dos capas (ADR 0024), y `persistir-escena.py` deja de escribir `draft.md.<fecha>.bak` (conserva la escritura atómica con temporal y reemplazo).
4. **Se mantienen las copias que garantizan atomicidad, no historial:** el respaldo interno de `.forja-transaccion/` en relato, que se borra al confirmar, y la copia temporal de `crear-libro`/`recompilar-libro` durante el intercambio de carpetas.
5. **Qué versiona la obra.** Todo su contenido de texto: hechos, brief, guion, fichas, contexto, borradores, manuscrito, `config.json` y los agentes, skills y scripts inyectados. Su `.gitignore` excluye `node_modules/`, `__pycache__/`, `*.pyc`, `.forja-transaccion/`, los `escena-*.pendiente.md` de novela (estado transitorio entre `preparar` y `aceptar`), `publicacion/` y las carpetas temporales `.publicacion-*/` de la compilación. No ignora copias de seguridad: si alguna reaparece, debe verse.
6. **Qdrant y Neo4j quedan fuera de git.** Son infraestructura con soporte propio. Regla: ningún dato canónico vive solo en la base de datos; lo que importe para la continuidad está en un `.md` de la obra. Los beats y la prosa se pueden reindexar desde los archivos; los resúmenes L1–L4 y las relaciones del grafo se regenerarían con LLM, equivalentes pero no idénticos.
7. **Cada obra se compila a sí misma.** Nuevo comando `/compilar [--epub] [--pdf] [--pdf-formato <formato>] [--pdf-motor <motor>] [--titulo "<título>"] [--autor "<autor>"]` en las tres escalas y en los dos entornos. Ejecuta `scripts/compilar.ps1`, que es determinista: el director solo pasa los argumentos. Lee `relato.md` o `novela.md`, sustituye su primer encabezado por la cabecera de título y autor del libro, escribe en `publicacion/` (Markdown del libro, EPUB/PDF opcionales y `manifest.json` con el hash del manuscrito, el commit de la obra y si el manuscrito tenía cambios sin commitear) y, solo si todas las salidas terminan bien, asigna `publicado`. Acepta `finalizado` y `publicado`: recompilar una obra publicada es reproducible porque el manuscrito está versionado.
8. **Herramientas de compilación compartidas.** `build-pdf.ps1`, `build.css` y `templates/forja-kdp.typ` pasan a `shared/scripts/`, junto con un `build-epub.ps1` nuevo que sustituye las dos copias de la generación de EPUB que tenían `crear-libro` y `recompilar-libro`. Se inyectan en cada obra con `compilar.ps1`, y los scripts del hub las usan desde ahí. `scripts/ruta-obra.ps1` imprime las raíces para que los agentes del hub no compongan rutas a mano.
9. **El hub conserva las antologías.** `/crear-libro` del hub ensambla antologías de dos o más relatos desde la raíz de obras y escribe en la raíz de publicados; `/recompilar-libro` sigue operando sobre esos libros. Un libro de una sola obra se compila dentro de la obra.
10. **El hub deja de versionar contenido.** `workspaces/` y `publicados/` salen del repositorio del hub y quedan en su `.gitignore` como guarda. Se retiran del `.gitignore` las reglas que solo existían para workspaces (`draft.md`, `relato-draft.md`, `*_backup_*`, `workspaces/*/.git`). El historial anterior del hub no se reescribe.

## Migración de las obras existentes (aplicada el 2026-10-11)

- Antes de la migración se borraron 301 copias de seguridad (`*.bak*`, `*_backup_*`, `*.backup.*`) de `canida-2`, `renacer-para-perder` y `la-fachada`, por decisión de la persona usuaria.
- Se trasladaron todos los workspaces de `Forja/workspaces/` a `C:\Proyectos\Personal\Writting\Obras`, `legacy/` y `canida-2 - copia` incluidas, sin cambios de contenido. Los libros de `Forja/publicados/` y `legacy/Publicados/` pasaron a `C:\Proyectos\Personal\Writting\Publicados`.
- En las once obras activas: `git init` sin commits, `.gitignore` del punto 5 (se conservan las reglas propias que no sean de copias), `scripts/compilar.ps1` con sus herramientas, `/compilar` en las capas que la obra tiene y su permiso cuando el director restringe `bash` o tiene `.claude/settings.json`. Se retiraron las instrucciones de copia de seguridad de directores, comandos, `ORQUESTACION.md`, `PIPELINE.md` y `GUIA.md`, y se añadió a cada `GUIA.md` una sección «Compilar el libro». Los registros históricos (`contexto.md`, `docs/`) no se tocaron. `persistir-escena.py` de `canida-2` y `renacer-para-perder`, idéntico al del hub, se sustituyó por la versión sin `.bak`.
- Excepciones: `legacy/` y `canida-2 - copia` se trasladaron sin git ni inyección, por ser referencia y copia que la persona usuaria conserva de momento.
- `el-tio-vicente-ii` conserva `.respaldo/2026-10-11-prosa-v1/` hasta que la persona usuaria decida si la prosa anterior entra en el historial como primer commit.

## Consecuencias

- El aislamiento de ADR 0023 deja de depender del `opencode.json`: fuera del hub y con su propio git, opencode ya no descubre agentes ni skills del hub. Se mantiene la desactivación hasta verificarlo y después se simplifica.
- El hub trabaja sobre carpetas externas. En opencode, `external_directory` es `ask` por defecto y la documentación no describe rutas absolutas de Windows ni relativas, así que el hub pide confirmación al tocarlas en lugar de llevar una regla no verificada (DT-014).
- Lo que no se haya commiteado no se puede restaurar. Los agentes ya no crean una red de seguridad propia.
- `/compilar` acepta `publicado` para regenerar formatos. Reescribir el texto de una obra publicada sigue exigiendo un paso explícito: `/nueva-edicion` (ADR 0005) o un reinicio manual. Sustituirlo por el historial git de la obra (commits o etiquetas por edición) queda para otra ADR (DT-017).
- Los tests de regresión usan raíces temporales mediante `FORJA_OBRAS` y `FORJA_PUBLICADOS`.

## Referencias

- [ADR 0001](0001-hub-y-workspaces-aislados.md), [ADR 0003](0003-publicacion-y-compilacion.md), [ADR 0004](0004-finalizado-y-recompilacion-de-formatos.md), [ADR 0005](0005-ediciones-derivadas-de-relato.md), [ADR 0023](0023-skills-compartidas-en-claude-skills-y-aislamiento-del-hub-en-opencode.md), [ADR 0024](0024-dos-entornos-equivalentes-opencode-y-claude-code.md)
- [scripts/lib/common.ps1](../../scripts/lib/common.ps1), [scripts/crear-libro.ps1](../../scripts/crear-libro.ps1)
