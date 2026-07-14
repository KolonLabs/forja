---
description: Reconstruye un relato legado como un workspace nuevo con el scaffolding vigente.
agent: scaffolder
---

# /rehidratar-relato

Recupera la **evidencia editorial** de un relato antiguo y, tras una reconstrucción editorial confirmada, crea otro workspace en estado `diseno` con el contrato actual de relato. No migra guion, fichas, draft, contexto ni manuscrito: esos materiales permanecen fuera del destino y se regeneran con el flujo nuevo.

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

2. Lee el JSON devuelto como **evidencia**, no como el brief final. Conserva solo los no negociables que estén confirmados; identifica lagunas, contradicciones, simplificaciones y marcas técnicas retiradas. No pidas repetir el briefing: pregunta únicamente lo que pueda cambiar la reconstrucción.

3. Carga `scaffolding-acto`, `scaffolding-hecho` y `scaffolding-relato`. Propón una nueva Fase 5, independiente de la cantidad, orden o literalidad de los actos heredados. Puedes añadir, fusionar, dividir, reordenar o descartar hechos para restituir arco, ritmo y causalidad.

   Cada hecho propuesto debe superar la **prueba de derivación**: ha de incluir situación o detonante, quién actúa bajo qué presión, qué cambio causal se produce y cuál es su consecuencia visible. Si expresa un patrón, añade el contexto de rutina o relación, variaciones significativas y su progresión o coste. El objetivo es que el guionista pueda derivar varios beats distintos sin inventar el núcleo del hecho; no redactes beats, escenas, diálogo ni prosa.

4. Realiza la **Fase 6 obligatoria**: presenta fortalezas, riesgos, decisiones conservadas y las transformaciones propuestas frente a la semilla. Pide confirmación explícita.

5. Tras la confirmación, construye el **brief JSON completo** de relato —incluidos los hechos reconstruidos, `_mapa` y `reflexion_agente`— y usa el creador canónico:

   ```powershell
   $briefJson | .\scripts\new-project.ps1
   ```

6. Indica que el destino está en `diseno` y debe abrirse para usar `/validar-hechos` y `/generar`.

## Límites

- Lee del origen solo `config.json`, `BRIEF.md` y la semilla de actos elegida.
- No lee ni copia `guion.md`, `relato-draft.md`, `relato.md`, `fichas/`, `contexto_narrativo.md`, `cola_d.md` ni instrucciones antiguas.
- El extractor no crea el destino. El scaffolder crea después un brief nuevo mediante `new-project.ps1`, que regenera `MAPA.md`, `AGENTS.md`, `.opencode/`, `GUIA.md` y los contadores con el scaffolding vigente.
- No es `/nueva-edicion`: una edición conserva y corrige una obra publicada; la rehidratación reinicia el desarrollo desde una propuesta editorial nueva, informada por la semilla.
