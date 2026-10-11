# ADR 0024: Dos entornos equivalentes, opencode y Claude Code

- Estado: aceptada
- Fecha: 2026-10-08
- Ámbito: `shared/` y creación de workspaces (las tres escalas).
- Relaciona: ADR 0019, ADR 0023. Sustituye para workspaces nuevos el espejo generado por `sync-claude.ps1` y el fork manual de `renacer-para-perder` (su ADR local 0004).

## Contexto

`el-tio-vicente-i` usaba un espejo Claude generado por script y `renacer-para-perder` un fork manual que ya divergía. Ningún workspace multihilo tenía versión Claude. El objetivo es que todo workspace nuevo nazca usable desde opencode y desde Claude Code con comportamiento equivalente, y que cada entorno use sus mecanismos nativos en lugar de una traducción automática.

## Decisión

1. **Capas escritas a mano por entorno.** Cada agente y comando tiene versión opencode (`shared/pipelines/<escala>/agentes`, `commands`, `shared/.opencode/`) y versión Claude Code (`shared/pipelines/<escala>/claude/agents`, `commands`, `shared/.claude/`). Comparten cuerpo; las únicas diferencias son de entorno: carga de skills («carga la skill `X`» en vez de `skill({ name })`), tabla de modelos del director y presupuesto de salida (Claude Code no tiene `maxCompletionTokens`). En relato los cuerpos son idénticos.
2. **Skills neutras y únicas** en `shared/skills/`, inyectadas en `.claude/skills/` (ADR 0023). Se inyectan solo los estilos activos en todas las escalas.
3. **Frontmatter equivalente.** Las `tools` de Claude reflejan los permisos de opencode. Escritor e integrador de novela no tienen herramientas (`tools: []` ↔ `"*": deny`); el validador de novela solo `Read, Skill`. El director restringe sus subagentes con `Agent(...)` ↔ `permission.task`. Escritor e integrador **no** llevan `omitClaudeMd`: en opencode ven `AGENTS.md` y así se conserva la equivalencia.
4. **Guionista de novela sin acceso a prosa, manuscrito ni hechos.** En opencode, `edit` deniega `draft.md`, `capitulo.md`, `novela.md` y `_actos.md` (regla que ya tenía multihilo, extendida a novela-simple). En Claude Code, donde `tools` no admite rutas, lo impone un hook `PreToolUse` en el frontmatter del guionista (`.claude/hooks/proteger-guionista.ps1`), activo cuando la carpeta es de confianza.
5. **Frontmatter opencode de novela corregido**: `name`, `mode`, `hidden` y permisos explícitos (antes el director de novela no tenía límites y varios agentes se trataban como `all`). El director: edición libre salvo `draft.md`, `.opencode/` y `.claude/` (confirmación), Bash solo `python scripts/*` (resto con confirmación), sin web, `task` limitado a sus subagentes.
6. **Modelos en Claude Code:** escritor e integrador `claude-opus-5-5`; director, guionista, auditor-beats, validador y cronista `claude-sonnet-5-5`; entidades y memoria `claude-haiku-5-5`. `effort: high` en guionista y validador. Si el coste de Opus es excesivo o aparecen rechazos con contenido explícito, se baja ese agente a Sonnet.
7. **Permisos de Claude Code** en `claude/settings.json` por escala, con `agent: director`. Relato: `dontAsk` con lista mínima y `deny` sobre artefactos canónicos. Novelas: edición y `python scripts/*` permitidos, confirmación para `draft.md`, `.opencode/` y `.claude/`, sin web y `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1` por el checkpoint secuencial.
8. **Documentos compartidos neutros:** `ORQUESTACION.md` con columna «Modelo (opencode · Claude Code)», `PIPELINE.md` sin modelos concretos, `GUIA.md` con las dos rutas de comandos.

## Decisiones de renacer revisadas

Se conservan: modelos por rol (salvo auditor-beats, que sube a Sonnet), `tools: []` en escritor e integrador, `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS`, `disable-model-invocation` en comandos y la política de permisos. Se descartan: auditor-beats sin `Skill` (error: su cuerpo carga skills), Glob/Grep en el validador, `omitClaudeMd`, `skillOverrides` (innecesario con estilos filtrados), `additionalDirectories` a `Temp/opencode` (`persistir-escena.py` acepta la entrada dentro del workspace) e `initialPrompt` (llamada en cada arranque sin equivalente en opencode).

## Verificación

- `claude plugin validate` en todas las carpetas `agents` y `commands` de la capa Claude.
- Workspaces de prueba por escala: opencode lista director como único primario y los subagentes de su escala, con los permisos en el orden correcto; Claude Code carga los mismos subagentes con los modelos y herramientas acordados.
- `tests/paridad-entornos-regression.ps1`: inventario, restos de un entorno en el otro, modelos y, en relato, cuerpos idénticos.

## Consecuencias

- Cambiar un agente o comando exige revisar su par en el otro entorno. La equivalencia editorial la juzga una revisión; el test solo cubre lo mecánico.
- Los workspaces existentes no se migran. `el-tio-vicente-ii` usa el espejo de transición con el mismo reparto.
- Riesgos abiertos en `docs/deuda-tecnica.md` (DT-012, DT-013).
