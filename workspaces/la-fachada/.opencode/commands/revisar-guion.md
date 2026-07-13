---
description: Revisa la coherencia del guion generado. Evalúa escenas, arcos, ritmo y transiciones.
agent: director
---

# /revisar-guion

Revisa la estructura generada en `guion.md` con criterio editorial. El objetivo es detectar problemas de coherencia entre escenas, arcos de personaje inconsistentes, ritmo desequilibrado y transiciones forzadas, **antes** de empezar la escritura beat a beat (FASE 3).

## Sintaxis

```
/revisar-guion
```

## Proceso

El director:

1. Lee `guion.md`, `_actos.md`, `BRIEF.md`, `config.json`
2. Carga los skills `consistencia-narrativa`, `estructura-narrativa` y `validacion-coherencia`
3. Evalúa el guion con los siguientes criterios:

### Checklist de revisión de guion

- **Coherencia con el brief**: ¿todas las escenas del guion corresponden a hechos de `_actos.md`? ¿Se ha respetado la distribución de `[D]`? ¿Alguna escena se ha inventado sin respaldo en los hechos?
- **Arcos de personaje**: ¿los beats asignados a cada personaje reflejan su arco declarado en BRIEF.md? ¿Laura evoluciona de control a pérdida de agencia? ¿Miguel de víctima a director? ¿Diego de poder accidental a sumisión?
- **Ritmo y pacing**: ¿hay actos con demasiadas o muy pocas escenas? ¿Las escenas de alta tensión están seguidas de respiros? ¿El Acto III está suficientemente desarrollado o comprimido?
- **Transiciones entre escenas**: ¿las escenas consecutivas fluyen o hay saltos bruscos de tono/ubicación/POV? ¿Los cambios de foco entre Laura y Miguel son naturales o forzados?
- **Distribución de `[D]`**: ¿los beats de hechos distribuidos están correctamente inyectados? ¿Alguna inyección rompe el ritmo de la escena que la contiene? ¿La revisión ligera post-inserción fue suficiente?
- **Tono y estilo**: ¿el tono es consistente con el estilo erótico + explícito? ¿Hay escenas que se desvían del registro? ¿La crudeza está dosificada o se acumula en un solo tramo?
- **Balance de POV**: si hay foco variable (Laura/Miguel), ¿está equilibrado? ¿Algún personaje secundario (Diego, Ana) roba demasiado foco?
- **Beats estimados**: ¿los beats estimados por escena son realistas para la extensión del relato (~15K)? ¿Alguna escena tiene demasiados o muy pocos?

4. Presenta diagnóstico estructurado:
   - **Problemas de coherencia** (contradicen el brief o los hechos)
   - **Problemas de ritmo** (desequilibrios, compresión, acelerones)
   - **Problemas de tono** (inconsistencias estilísticas)
   - **Propuestas de ajuste** (mejoras opcionales)

5. Para cada problema, propón una solución. Si requiere reestructuración, sugiere invocar al guionista en modo estructura.

6. Con aprobación del usuario, aplica los ajustes a `guion.md`.

## Gate

- El guion refleja fielmente los hechos de `_actos.md`
- Los arcos de personaje son coherentes con BRIEF.md
- El ritmo es sostenible para la extensión estimada
- Los beats `[D]` están correctamente inyectados

## Cuándo usarlo

- Después de FASE 1 (`/generar` completa estructura), antes de FASE 3 (escritura beat a beat)
- Antes de `/publicar` como verificación final de coherencia
- Si durante FASE 3 el escritor detecta inconsistencias y las reporta al director

## Relación con otros comandos

| Comando | Artefacto | Evalúa |
|---------|-----------|--------|
| `/refinar-hechos` | `_actos.md` | Concreción, narrabilidad, rangos `[D]` |
| `/validar-hechos` | `_actos.md` | Coherencia narrativa, consistencia, mejoras |
| `/revisar-guion` | `guion.md` | Coherencia de escenas, arcos, ritmo, transiciones |
