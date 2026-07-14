# ADR 0014: Rehidratación como reconstrucción editorial de relatos

- Estado: aceptada
- Fecha: 2026-07-14
- Ámbito: `/rehidratar-relato`, su extractor, el scaffolder y el contrato de hechos de relato.

## Contexto

Los relatos legados pueden conservar una premisa válida y una sucesión de hechos útil, pero sus hechos suelen estar expresados como rótulos o como beats comprimidos. Copiarlos y normalizarlos conserva sus carencias: no fija la presión, el cambio ni la consecuencia que el guionista necesita para construir un mapa de beats variado y con ritmo.

La rehidratación no puede resolverlo leyendo la prosa o el guion antiguos, pues contaminaría el nuevo workflow y convertiría una reconstrucción en una migración encubierta.

## Decisión

La rehidratación se divide en dos responsabilidades:

- `scripts/rehidratar-relato.ps1` solo extrae evidencia de `config.json`, `BRIEF.md` y los actos elegidos. No crea un workspace. Retira de su vista los IDs H y las marcas `[D]` legadas y declara esa normalización.
- El scaffolder interpreta la evidencia como semilla, no como brief final. Propone una Fase 5 nueva que puede añadir, fusionar, dividir, reordenar o descartar actos y hechos; conserva únicamente los no negociables confirmados.
- Todo hecho final debe superar la **prueba de derivación**: situación o detonante, agencia y presión concreta, cambio causal y consecuencia visible. Si incorpora una pauta, añade contexto rutinario o relacional, variaciones significativas y progresión o coste. No incluye beats, escenas, diálogo ni prosa.
- Tras una Fase 6 y confirmación explícita, el scaffolder construye un brief completo y lo entrega a `new-project.ps1`. El destino queda aislado y se crea igual que un proyecto nuevo.

## Consecuencias

- La semilla legado conserva valor como evidencia sin imponer la cantidad, el orden ni el nivel de detalle de la estructura nueva.
- El guionista recibe hechos con suficiente entidad para proponer beats distintos, incluidos patrones intercalables con rutina, relación y consecuencias, pero mantiene libertad narrativa sobre su selección y realización.
- No se modifica el origen ni se incorporan su guion, prosa, fichas, memoria, cola o instrucciones.
- El comando requiere juicio editorial del scaffolder antes de crear; ya no existe una vía de creación directa desde la extracción.

## Referencias

- [ADR 0010](0010-rehidratacion-de-relatos-legados.md)
- [ADR 0013](0013-beats-globales-con-patrones-inferidos-en-relato.md)
- [Comando del hub](../../.opencode/commands/rehidratar-relato.md)
