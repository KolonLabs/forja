# ADR 0023: Skills compartidas en `.claude/skills` y aislamiento del hub en opencode

- Estado: aceptada
- Fecha: 2026-10-08
- Ámbito: creación de workspaces (todas las escalas).
- Relaciona: ADR 0022

## Contexto

Los workspaces se usan desde opencode y desde Claude Code. Las comprobaciones hechas en `el-tio-vicente-ii` (opencode 1.18.35, Claude Code 2.1.293) mostraron:

- opencode descubre skills en `.opencode/skills/` **y** en `.claude/skills/`, las deduplica por nombre y no hay garantía de cuál prevalece (13 de 16 salieron de `.claude/`, 3 de `.opencode/`). Con dos copias, una edición en una puede quedar tapada por la otra.
- Claude Code solo lee `.claude/skills/`.
- opencode sube hasta la raíz de git y hereda del hub sus agentes (`scaffolder`, `bibliotecario`) y sus skills (`scaffolding-*`, `importacion-fuentes`), lo que contradice la autonomía del workspace. Claude Code no hereda nada del hub.
- Una regla `permission.skill` en `opencode.json` no puede denegar skills a un agente cuyo frontmatter declara `skill: allow`: la regla del agente se evalúa después y prevalece.

## Decisión

1. Las skills de un workspace viven **solo en `.claude/skills/`**, que leen los dos entornos. `Inject-Pipeline` las copia ahí y `.opencode/skills/` ya no se crea. Las plantillas de skills de `shared/` llevan `user-invocable: false` para que Claude Code no las ofrezca como comandos; opencode ignora el campo.
2. Cada workspace recibe un `opencode.json` generado por `Write-OpencodeConfig`, con `default_agent: director` y los agentes del hub desactivados (`agent.<nombre>.disable: true`), calculados desde `.opencode/agents/` del hub.
3. Los agentes y comandos siguen en `.opencode/` (fuente) y, cuando el workspace tiene espejo Claude, en `.claude/`. El `sync-claude.ps1` de un workspace **no regenera skills**.
4. Las ediciones derivadas de relatos (`new-edicion-relato.ps1`) reciben el mismo layout y su `opencode.json` aislado.

## Límite conocido

Las skills del hub siguen siendo descubribles desde un workspace en opencode. No se pueden denegar desde `opencode.json` (ver Contexto). Su impacto es bajo: añaden unas pocas descripciones al listado de skills. La alternativa que lo evitaría del todo, un repositorio git propio por workspace, se descarta por ahora porque los workspaces se versionan dentro del hub.

## Consecuencias

- Una sola copia de cada skill, sin riesgo de divergencia entre entornos.
- Los workspaces anteriores conservan `.opencode/skills/`; no se migran. `el-tio-vicente-ii` sí está migrado.
- Quien lance opencode con `OPENCODE_DISABLE_CLAUDE_CODE=1` pierde las skills del workspace (es la variable que desactiva todo soporte `.claude`).
- Cubierto por `tests/relato-workflow-regression.ps1`.
