@AGENTS.md

# Claude Code

- El agente principal es `director` (campo `agent` de `.claude/settings.json`). Los comandos `/generar`, `/corregir`, `/revisar`, `/expandir`, `/publicar`, `/compilar`, `/revisar-guion`, `/refinar-hechos` y `/validar-hechos` los lanza la persona usuaria y los ejecuta él.
- Agentes y comandos de Claude Code viven en `.claude/agents` y `.claude/commands`; los de opencode, en `.opencode/`. Son equivalentes: un cambio en uno se revisa en el otro.
- Las skills viven solo en `.claude/skills/` y las leen los dos entornos.
- Permisos en `.claude/settings.json` (modo `dontAsk`): el director solo edita en `.forja-transaccion/siguiente/` y `fichas/`, y solo ejecuta `scripts/relato-transaccion.ps1`. Los subagentes son de solo lectura.
