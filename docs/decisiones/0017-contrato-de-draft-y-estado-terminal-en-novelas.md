# ADR 0017: Contrato de draft y estado terminal en novelas

- Estado: aceptada
- Fecha: 2026-08-05
- Complementa: ADR 0004
- Ámbito: escalas `novela-simple` y `novela-multi-hilo`.

## Contexto

Las dos escalas de novela arrastraban tres incoherencias que impedían terminar una obra.

**Estado terminal.** ADR 0004 fijó `finalizado` como estado de entrada de `/crear-libro`, y `scripts/crear-libro.ps1` lo comprueba. Pero los directores de novela seguían escribiendo `config.json.estado = "publicado"` al publicar. Una novela terminada quedaba en un estado que el hub rechaza: imposible de compilar sin editar el `config.json` a mano.

**Encabezado del draft.** Convivían tres formatos incompatibles para la misma sección. El escritor emitía `## B_XX — acción`; el director localizaba los beats por `## <stable_id> [<seq>]`; el `/publicar` compartido eliminaba `## B_XXXX`. El escritor producía un encabezado que ni el director encontraba ni el publicador limpiaba. Además emitía marcadores `<!-- ESCENA ... -->` y notas del escritor que ninguna rama de publicación eliminaba, por lo que se habrían filtrado al manuscrito.

**Contaminación de escala.** Los workspaces de novela recibían `/corregir` (que solo contempla ediciones derivadas de relato y siempre las rechaza), la skill `contexto-narrativo` (memoria Markdown sustituta de Qdrant en relato) y la `GUIA.md` de relato, que describe escenas operativas y transacciones inexistentes en novela.

## Decisión

**1. `finalizado` es el estado terminal de todo workspace, en las tres escalas.**

La cadena de novela termina en `finalizado`. `publicado` queda reservado al hub: solo `/crear-libro` lo asigna, y únicamente tras compilar correctamente todas las salidas solicitadas. Ningún director escribe `publicado`.

**2. El draft tiene un único contrato de encabezado.**

```
<!-- ESCENA <stable_id_escena>: Nombre [| hilo: <stable_id_hilo>] -->

## <stable_id> [<seq>] — acción breve
```

- El `stable_id` es la identidad; `seq` es la posición; `B_NNNN` es un display derivado de `seq` que **nunca** encabeza una sección.
- Escritor e integrador emiten ese encabezado exacto y conservan `stable_id` y `seq` sin alterarlos.
- Al publicar se eliminan encabezados de beat, marcadores de escena y notas del escritor. En multi-hilo se conservan los `---` entre bloques de hilo, que son estructura narrativa visible.

**3. Cada escala recibe solo sus artefactos.**

- `/corregir` no se inyecta en novelas.
- `contexto-narrativo` no se inyecta en novelas; su equivalente es Qdrant + Neo4j, con `contexto.md` como resumen legible del director.
- `GUIA.md` se resuelve por escala: si existe `shared/pipelines/<escala>/GUIA.md`, prevalece sobre la del hub.
- `/publicar` tiene override por escala en las dos novelas, alineado con la FASE de publicación del director correspondiente.

**4. `AGENTS.md` no puede declarar skills que no existen.**

`Write-AgentsMd` deriva la lista de lo realmente inyectado en `.opencode/skills/` y aborta la creación si el prompt declara una skill ausente. Un workspace no se crea con documentación falsa.

## Consecuencias

- Una novela terminada es compilable por el hub sin intervención manual.
- El pipeline de escritura es recuperable: cualquier agente localiza un beat por `stable_id` aunque se hayan insertado o reordenado beats.
- El manuscrito publicado no contiene identificadores, marcadores ni notas de trabajo.
- Los workspaces de novela dejan de exponer comandos que siempre fallan y documentación de otra escala.
- Los workspaces de novela ya creados conservan su copia antigua del pipeline. Migrarlos exige reescribir su `.opencode/` y su `config.json.estado`; no es automático.

## Referencias

- [ADR 0004](0004-finalizado-y-recompilacion-de-formatos.md)
- `docs/deuda-tecnica.md`, DT-003
