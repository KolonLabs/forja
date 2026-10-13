# ADR 0034: Catálogo de tonos de beat comprobado y tono Contemplativo

- Estado: aceptada
- Fecha: 2026-10-13
- Ámbito: `shared/skills/tonos-beat` (novela), `etiquetas-guion.py`, `relato-transaccion.ps1`, directores de novela.
- Relaciona: ADR 0020 (contrato editorial de beats), ADR 0033 (etiquetas de guion).

## Contexto

El guionista asigna a cada beat de novela `[Tono — EXTENSIÓN]` del catálogo de `tonos-beat`, y en relato `[registro: …]` y `[peso: …]` del catálogo de relato, pero nada lo comprobaba. Al revisar las obras alineadas, `canida-2` tenía 203 de sus 429 beats con el tono «Contemplativo», que el catálogo no definía, de modo que escritor y validador lo interpretaban a su manera; `renacer-para-perder` también lo había necesitado y lo resolvió con Clínico e Hipnótico. *El tío Vicente I* tenía un `[registro: rudo]` ajeno al catálogo de relato, y la propia skill ponía como ejemplo `Hipnótico / Erótico` sin definir «Erótico».

## Decisión

1. **«Contemplativo» y «Sumiso» entran en el catálogo de novela**, con la misma ficha que el resto (ritmo, registro, foco sensorial, vocabulario, diálogos, atmósfera y ejemplo neutro). «Sumiso» completa la asimetría que solo cubría «Dominante»: un beat contado desde quien cede el control lleva el tono de su POV, sin establecer consentimiento ni añadir actos de sumisión. El ejemplo de tono compuesto pasa a `Hipnótico / Explícito`.
2. **Novela:** `etiquetas-guion.py` lee el catálogo de la skill `tonos-beat` de la obra y devuelve en `fuera_de_catalogo` los beats sin etiqueta de tono, con tonos o extensiones ajenos al catálogo o con más de dos tonos. El director pide al guionista que los corrija, o consulta a la persona usuaria si hace falta un tono nuevo.
3. **Relato:** `relato-transaccion.ps1` rechaza, al confirmar `diseno` o `guion`, los registros y pesos ajenos al catálogo de la skill `tonos-beat` de relato.
4. El `[registro: rudo]` de *El tío Vicente I* pasa a `explícito / visceral`.

## Consecuencias

- Un tono nuevo se añade al catálogo con su ficha, no se inventa en el guion.
- La comprobación lee el catálogo de la obra: si una obra amplía su skill, sus tonos nuevos se aceptan.
