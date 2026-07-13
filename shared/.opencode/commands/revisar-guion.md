---
description: Revisa la coherencia del guion generado. Evalúa escenas, arcos, ritmo y transiciones.
agent: director
---

# /revisar-guion

Revisa la estructura generada en el guion (`guion.md` en relato, `guion-novela.md` en novela) con criterio editorial. El objetivo es detectar problemas de coherencia entre escenas, arcos de personaje inconsistentes, ritmo desequilibrado y transiciones forzadas, **antes** de empezar la escritura beat a beat.

## Sintaxis

```
/revisar-guion
```

## Proceso

El director:

1. Detecta la escala desde `config.json.escala`.
   - **Relato**: lee `guion.md`, `_actos.md`, `BRIEF.md`, `config.json`
   - **Novela simple**: lee `guion-novela.md`, `_actos.md`, `BRIEF.md`, `config.json`
   - **Novela multi-hilo**: lee `guion-novela.md`, `guion-hilo.md` (de cada hilo), `_actos.md`, `BRIEF.md`, `config.json`
2. Carga los skills `consistencia-narrativa`, `estructura-narrativa` y `validacion-coherencia`
3. Evalúa el guion con los siguientes criterios:

### Checklist de revisión de guion

- **Coherencia con el brief**: ¿todas las escenas del guion corresponden a hechos de `_actos.md`? ¿Se ha respetado la distribución de `[D]`? ¿Alguna escena se ha inventado sin respaldo en los hechos?
- **Arcos de personaje**: ¿los beats asignados a cada personaje reflejan su arco declarado en BRIEF.md?
- **Ritmo y pacing**: ¿hay actos con demasiadas o muy pocas escenas? ¿Las escenas de alta tensión están seguidas de respiros?
- **Transiciones entre escenas**: ¿las escenas consecutivas fluyen o hay saltos bruscos de tono/ubicación/POV?
- **Distribución de `[D]`**: ¿los beats de hechos distribuidos están correctamente inyectados? ¿Alguna inyección rompe el ritmo de la escena que la contiene?
- **Tono y estilo**: ¿el tono es consistente con el estilo declarado? ¿Hay escenas que se desvían del registro?
- **Balance de POV**: si hay foco variable, ¿está equilibrado?
- **Beats estimados**: ¿los beats estimados por escena/capítulo son realistas para la extensión declarada?
- **(Solo multi-hilo) Trenzado**: ¿la tabla de trenzado respeta las reglas (máx. 2 hilos/cap, racha máx. 3 sin hilo)? ¿Cada hilo tiene un arco visible en el trenzado?

4. Presenta diagnóstico estructurado:
   - **Problemas de coherencia** (contradicen el brief o los hechos)
   - **Problemas de ritmo** (desequilibrios, compresión, acelerones)
   - **Problemas de tono** (inconsistencias estilísticas)
   - **Propuestas de ajuste** (mejoras opcionales)

5. Para cada problema, propón una solución. Si requiere reestructuración, sugiere invocar al guionista en modo estructura.

6. Con aprobación del usuario, aplica los ajustes al archivo de guion correspondiente.

## Gate

- El guion refleja fielmente los hechos de `_actos.md`
- Los arcos de personaje son coherentes con BRIEF.md
- El ritmo es sostenible para la extensión estimada
- Los beats `[D]` están correctamente inyectados
- (Multi-hilo) La tabla de trenzado cumple las reglas

## Cuándo usarlo

- Después de la fase de estructura, antes de la escritura beat a beat
- Antes de `/publicar` como verificación final de coherencia
- Si durante la escritura el escritor detecta inconsistencias y las reporta al director

## Relación con otros comandos

| Comando | Artefacto | Evalúa |
|---------|-----------|--------|
| `/refinar-hechos` | `_actos.md` | Concreción, narrabilidad, rangos `[D]` |
| `/validar-hechos` | `_actos.md` | Coherencia narrativa, consistencia, mejoras |
| `/revisar-guion` | `guion.md` o `guion-novela.md` | Coherencia de escenas, arcos, ritmo, transiciones |
