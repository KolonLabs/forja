# ADR 0035: Mismo catálogo y marcado de tonos en todas las escalas

- Estado: aceptada
- Fecha: 2026-10-13
- Ámbito: `shared/skills/tonos-beat` (ahora común), pipeline de relato (agentes, skills, `PIPELINE.md`, `relato-transaccion.ps1`), `common.ps1`, guiones de los relatos existentes.
- Sustituye: en el ADR 0007, el marcado tonal de relato (arco de escena con `[registro: …]` solo como excepción y sin extensiones); en el ADR 0034, el punto 3 (registros y pesos de relato).

## Contexto

Relato y novela usaban dos sistemas distintos. Novela marca todo beat con `[Tono — EXTENSIÓN]` de un catálogo de tonos con ficha; relato marcaba solo las excepciones con `[registro: …]` (siete valores propios) y `[peso: breve|extenso]`, y sus arcos de escena usaban palabras libres (`sumisión`, `entrega`, `control`, `excitación`, `shock`…). La diferencia se justificó en el ADR 0007 porque relato escribe la escena completa en una llamada, pero desde el ADR 0019 novela también escribe por escena: el tono de un pasaje no depende de la escala.

## Decisión

1. **Un único catálogo**, `shared/skills/tonos-beat`, para relato, novela simple y novela multi-hilo. Relato deja de tener catálogo propio. Se añade **Íntimo**, que relato usaba y novela no tenía; queda en 13 tonos: Clínico, Hipnótico, Opresivo, Revelación, Brutal, Explícito, Visceral, Íntimo, Dominante, Sumiso, Frenético, Tenso y Contemplativo.
2. **Un único marcado:** todo beat lleva `[Tono — EXTENSIÓN]`, con uno o dos tonos y `BREVE`, `MEDIA` o `EXTENSA`. Es la única instrucción tonal del tramo: las escenas no declaran arco tonal (véase el punto 8).
3. **`[elipsis]`** deja de ser un registro: es una marca aparte, válida en cualquier escala, para un beat que salta deliberadamente un intervalo.
4. **Equivalencias para migrar relato:** `contenido` → Clínico; `tenso` → Tenso; `revelación` → Revelación; `íntimo` → Íntimo; `explícito / visceral` → Explícito / Visceral; `brutal` → Brutal; `elipsis` → `[elipsis]`; `[peso: breve]` → `BREVE`, `[peso: extenso]` → `EXTENSA`, sin marca → la extensión que corresponda al beat.
5. **Comprobación:** `relato-transaccion.ps1` rechaza, al confirmar `diseno` o `guion`, los beats sin etiqueta o con tonos o extensiones ajenos al catálogo, el formato anterior y cualquier línea de arco tonal de escena; `etiquetas-guion.py` informa en novela de los beats sin etiqueta o fuera del catálogo.
6. **La extensión significa lo mismo en todas las escalas:** mide cuánto se detiene la prosa en la acción del beat, no cuántas acciones contiene. `EXTENSA` recoge el antiguo `[peso: extenso]` de relato (una acción larga o con fases) además de los puntos de giro y el desarrollo emocional denso; se demora en esa misma acción sin añadir otras ni repetir las hechas, y `BREVE` no se infla. La tabla de `tonos-beat` lo define una vez y escritor y validador lo aplican igual en las tres escalas, sin cuotas numéricas (ADR 0020).
7. **Las mismas fuentes en todas las escalas:** el escritor de relato carga `tonos-beat`; en novela, escritor e integrador no cargan skills, así que el director les pasa inline las fichas de los tonos de la escena (solo esas), con la regla de extensión y los beats con `[elipsis]`. El auditor de beats comprueba que cada etiqueta es coherente con su acción y su peso, y el validador que la prosa materializa tono y extensión, en las tres escalas.
8. **Sin arco tonal de escena.** El arco de escena duplicaba la secuencia de tonos de sus beats y se contradecía con ella: al migrar, 40 de los 128 arcos de los relatos no se podían leer en sus beats. Se retira en todas las escalas; el recorrido tonal de una escena es la secuencia de tonos de sus beats, y el auditor y el validador revisan sus transiciones. El tono de la obra (`BRIEF.md`) sigue siendo el marco, y el tono que una estructura de novela anota por capítulo o bloque orienta al guionista al planificar, pero no se pasa al escritor como instrucción.

## Consecuencias

- El escritor recibe en relato la misma guía tonal por beat que en novela, y un tono nuevo se añade una vez para todas las escalas.
- Los guiones de relato anteriores necesitan migrar su marcado: los registros por equivalencia y el resto de beats con criterio. Hasta hacerlo, una transacción `diseno` o `guion` sobre ellos se rechaza.
