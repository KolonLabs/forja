# ADR 0032: Referencias con contrato, validación y personajes heredados

- Estado: aceptada (fase 1: contrato, validación y fichas heredadas; fase 2: comandos de construcción en el hub y `/referencias` en la obra)
- Fecha: 2026-10-13
- Ámbito: `shared/skills/referencias/`, `shared/scripts/validar-referencias.py`, agentes que consultan `referencias/` en las tres escalas, plantillas de ficha, `common.ps1` (brief, AGENTS.md, carpetas) y la obra `canida-2`.
- Relaciona: ADR 0011/0015 (importación de fuentes libres), ADR 0023 (aislamiento de workspaces), ADR 0024 (dos entornos).

## Contexto

`referencias/` nació con la importación de fuentes libres: se copian los archivos locales a la obra y los agentes los leen como «material no narrativo». Sin contrato, el único caso real (`canida-2`) acumuló:

- Un resumen de *Cánida* (≈5 000 palabras) que, contrastado con el texto actual de la novela, afirma un prólogo inexistente, una frase final que no está, un «Síndrome Richter» que la novela nunca nombra y un personaje (Álvaro) retirado en la revisión; deja como pendiente a la veterinaria, que sí existe (Dra. Vega), y mezcla el canon de *Cánida 1* con propuestas para *Cánida 2*.
- Diseños de hilos anteriores a Forja, guardados como referencia sin indicar que son una guía superada por los hechos.
- Un choque de nombres: la protagonista Vega Quintana de *Cánida 2* frente a la Dra. Vega, antagonista de *Cánida 1*.

Además, el mismo nombre designa dos cosas: el campo `referencias` del brief (inspiraciones: obras, autores, películas) y la carpeta `referencias/` (material de consulta). El relato no tiene carpeta ni instrucciones, y en novela simple `memoria` solo incluía referencias etiquetadas por hilo, que esa escala no tiene.

## Decisión

1. **Tres tipos de referencia**, declarados en una cabecera obligatoria (`titulo`, `tipo`, `origen`, `fecha`, `proposito`):
   - `canon-previo`: hechos de una obra anterior del mismo universo. Nunca la obra entera: un dossier de hechos, cada uno con su cita (`[cap. N: «fragmento literal»]`) y `fuente_sha256` de la fuente usada. Sin propuestas para la obra nueva: esas van al brief o a los hechos. Contradecirlo es bloqueante.
   - `documentacion`: material técnico, científico, histórico o de mundo, por temas. Lo adoptado por la obra es canon; su precedencia es inferior a `AGENTS.md`, `BRIEF.md` y los hechos.
   - `guia-previa`: trabajo de diseño anterior que orienta la intención (por ejemplo, los esbozos de hilos de `canida-2`). Nunca es canon ni se copia su estructura; los hechos y el guion de Forja prevalecen.
2. **Validación determinista** con `shared/scripts/validar-referencias.py` (copiado a `scripts/` en las tres escalas): solo Markdown, cabecera completa, tamaño manejable (archivo ≤ 6 000 palabras; aviso por sección de más de 1 500), citas en todo hecho de `canon-previo` con fragmentos de 3 a 25 palabras. Con `--fuente`, verifica que cada fragmento existe en la fuente (y en el capítulo citado si se identifica), que la referencia no copia la fuente y que `fuente_sha256` sigue vigente. Comprueba fichas heredadas y choques de nombres.
3. **Criterio editorial** (concreción, relevancia, sin planes mezclados) en la skill común `referencias`, con confirmación de la persona usuaria antes de admitir una referencia.
4. **Personajes heredados**: la ficha de un personaje que reaparece lleva `## Canon heredado` (origen y dossier, estado al final de la obra previa, hechos que no se contradicen con cita, evolución permitida y tiempo transcurrido). El validador lo trata como canon.
5. **Choques de nombres**: el validador avisa cuando un nombre de la obra coincide con un personaje de un `canon-previo` sin ficha heredada. Se acepta de forma explícita con `colisiones_aceptadas` en la cabecera del dossier; *Cánida 2* acepta «Vega» por ahora.
6. **Uso por escala**: relato, novela simple y multi-hilo cargan la skill `referencias` cuando la carpeta tiene contenido. La lectura directa del pasaje pertinente es la vía principal; en novelas, el índice de Qdrant (`tipo=referencia`) solo ayuda a `memoria` a encontrar lo relevante (por hilo en multi-hilo; por similitud con los hechos del capítulo en novela simple). Todas las escalas crean `referencias/`.
7. **Nombres separados**: en `BRIEF.md` el campo `referencias` del brief se muestra como `## Inspiraciones`; la clave JSON se conserva por compatibilidad.
8. **Fase 2** (pendiente): comando del hub para generar un dossier `canon-previo` o heredar un personaje desde otra obra o una novela externa (las obras no se leen entre sí), paso de referencias en `/nuevo-proyecto` y `/importar-proyecto` (con conversión a Markdown e instantánea de URL), y `/referencias` en la obra para validar y reindexar.

## Consecuencias

- Una referencia sin cabecera o demasiado grande no se admite; un canon sin citas verificables tampoco.
- La fuente de verdad de un canon previo es el texto de la obra, no sus fichas ni resúmenes anteriores, que pueden estar desfasados.
- Cambiar la fuente después de generar el dossier lo deja desfasado; el validador lo detecta con `--fuente`.
- En `canida-2`, el resumen se sustituye por un dossier `canon-previo` con citas verificadas, sus propuestas para *Cánida 2* pasan al brief y los esbozos de hilos se marcan como `guia-previa`. El índice de Qdrant de esas referencias debe regenerarse.
