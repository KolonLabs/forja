---
description: Reconstruye un relato legado como un workspace nuevo con el scaffolding vigente.
agent: scaffolder
---

# /rehidratar-relato

Recupera la **semilla editorial** de un relato antiguo y crea otro workspace en estado `diseno`, con el contrato actual de relato. No migra guion, fichas, draft, contexto ni manuscrito: esos materiales se archivan fuera del destino y se regeneran con el flujo nuevo.

Argumentos recibidos: `$ARGUMENTS`

## Sintaxis

```text
/rehidratar-relato <origen> <slug-destino> [--actos actual|backup]
```

- `<origen>` y `<slug-destino>` son slugs de `workspaces/`; deben ser distintos.
- `--actos actual` usa `_actos.md` del origen (valor por defecto).
- `--actos backup` usa el único `_actos_backup_*.md` disponible. Si hay varios, detente y pide que se elija la semilla manualmente.
- El destino debe ser nuevo. Este comando nunca sustituye ni elimina un workspace existente.

## Flujo obligatorio

1. Valida los argumentos y ejecuta la vista previa, sin crear nada:

   ```powershell
   .\scripts\rehidratar-relato.ps1 -Origen "<origen>" -Destino "<slug-destino>" -Actos "<actual|backup>"
   ```

2. Lee el JSON devuelto. Las fases 1–5 ya están rellenadas por la semilla: comprueba escala, hechos, restricciones, estilo y posibles contradicciones. No pidas al usuario que repita el briefing; pregunta únicamente por lagunas o decisiones ambiguas.

3. Realiza la **Fase 6 obligatoria**: presenta fortalezas, riesgos y decisiones conservadas o ajustadas para el flujo actual. No escribas beats, escenas ni prosa. Pide confirmación explícita.

4. Tras la confirmación, construye un JSON con `fortalezas`, `riesgos` y `decisiones_usuario`, y ejecuta:

   ```powershell
   $reflexionJson = @'
   { "fortalezas": ["..."], "riesgos": ["..."], "decisiones_usuario": ["..."] }
   '@
   .\scripts\rehidratar-relato.ps1 -Origen "<origen>" -Destino "<slug-destino>" -Actos "<actual|backup>" -Crear -ReflexionJson $reflexionJson
   ```

5. Indica que el destino está en `diseno` y debe abrirse para usar `/validar-hechos` y `/generar`.

## Límites

- Lee del origen solo `config.json`, `BRIEF.md` y la semilla de actos elegida.
- No lee ni copia `guion.md`, `relato-draft.md`, `relato.md`, `fichas/`, `contexto_narrativo.md`, `cola_d.md` ni instrucciones antiguas.
- Regenera `MAPA.md`, `AGENTS.md`, `.opencode/`, `GUIA.md` y los contadores con el scaffolding vigente.
- No es `/nueva-edicion`: una edición conserva y corrige una obra publicada; la rehidratación reinicia su desarrollo desde los hechos.
