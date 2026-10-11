@AGENTS.md

# Claude Code

- El agente principal es `director` (campo `agent` de `.claude/settings.json`). Los comandos `/generar`, `/revisar`, `/expandir`, `/publicar`, `/compilar`, `/revisar-guion`, `/refinar-hechos` y `/validar-hechos` los lanza la persona usuaria y los ejecuta él.
- Agentes y comandos de Claude Code viven en `.claude/agents` y `.claude/commands`; los de opencode, en `.opencode/`. Son equivalentes: un cambio en uno se revisa en el otro.
- Las skills viven solo en `.claude/skills/` y las leen los dos entornos.
- Punto de reanudación: `config.json` (`estado`, `hilos[].estado`, `capitulos_completados`, `ultimo_beat_seq`) y `contexto.md`. No repitas pasos ya cerrados.
- Checkpoint de narrativa obligatorio: presenta cada escena completa con su hash y espera conformidad explícita; no encadenes escenas ni capítulos sin autorización. Los subagentes se ejecutan en primer plano (`CLAUDE_CODE_DISABLE_BACKGROUND_TASKS`).
- Permisos en `.claude/settings.json`: `python scripts/*` permitido; editar `draft.md`, `.opencode/` o `.claude/` pide confirmación (el `draft.md` solo cambia con `persistir-escena.py aceptar`); sin acceso web. La primera vez, acepta el diálogo de confianza de la carpeta: hasta entonces Claude Code ignora las reglas `allow`.
- Scripts desde la raíz del workspace: `python -X utf8 scripts/qdrant.py …`, `python -X utf8 scripts/neo4j.py …`, `python -X utf8 scripts/persistir-escena.py <preparar|aceptar|sincronizar> …`. La entrada de `preparar` se guarda dentro del capítulo.
