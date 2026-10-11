# ADR 0025: Explicitud obligatoria y validación de crudeza por nivel

- Estado: aceptada
- Fecha: 2026-10-09
- Ámbito: scaffolding, creación de workspaces y skill `validacion-crudeza` (todas las escalas).

## Contexto

`canida-2` nació con explicitud `maximo` y sin restricciones porque su brief no traía nivel y `Write-AgentsMd`/`Write-BriefMd` lo suponían por defecto. Contradecía el canon de su precuela (sin gore, tortura ni violencia sexual). Además, `validacion-crudeza` de novela estaba escrita solo para `maximo`: exigía vocabulario sexual directo y mostrar el acto sin cortes en cualquier proyecto, empujando al validador contra un nivel menor.

## Decisión

1. `explicitud` es obligatoria en el brief. `new-project.ps1` rechaza el brief si falta; no hay valor por defecto. El scaffolder la pregunta siempre (puede recomendar según premisa o canon previo).
2. `AGENTS.md` y `BRIEF.md` escriben el nivel con su significado (`Get-ExplicitudTexto`).
3. `/nueva-edicion` conserva el nivel del origen. Si un relato antiguo no lo guarda en `config.json`, lo toma de su `AGENTS.md` (el nivel con el que se escribió); si no aparece en ninguno, falla.
4. `validacion-crudeza` aplica el criterio del nivel del proyecto: `maximo`/`alto` exigen mostrar con precisión y vocabulario directo; `medio` exige lenguaje sin eufemismos y que lo gráfico se elida; `bajo`/`minimo` comprueban que nada supere el nivel. La elipsis no es un defecto por debajo de `alto`. Las restricciones de `AGENTS.md` prevalecen.

## Consecuencias

- Ningún proyecto hereda «máximo» sin haberlo decidido.
- Los workspaces existentes conservan su nivel; `canida-2` pasa a `medio` por decisión del autor, con sexo solo puntual.
- Cubierto por `tests/continuacion-brief-regression.ps1` y `tests/relato-workflow-regression.ps1`.
