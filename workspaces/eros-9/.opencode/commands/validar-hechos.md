---
description: Valida la coherencia narrativa entre hechos en _actos.md. Busca incoherencias, problemas de interpretación y propone mejoras estructurales.
agent: director
---

# /validar-hechos

Complemento de `/refinar-hechos`. Mientras `/refinar-hechos` evalúa si los hechos son concretos y narrables, `/validar-hechos` evalúa si **cuentan bien la historia**: coherencia, consistencia, ritmo y posibles mejoras.

## Sintaxis

```
/validar-hechos
```

## Proceso

El director:

1. Lee `_actos.md` y `BRIEF.md`
2. Carga los skills `consistencia-narrativa`, `desarrollo-narrativa` y `hechos-distribuidos`
3. **Consulta `memoria` condicional:** si `config.json.estado != "diseno"` (es decir, ya hay capítulos escritos o entidades creadas), invoca al `memoria` para obtener el estado actual del mundo narrativo. Cruza los hechos propuestos contra el estado acumulado de personajes, relaciones y summaries. Si `estado == "diseno"`, salta este paso — no hay datos que consultar.
4. **Separa hechos lineales y `[D]`.** La validación de coherencia aplica a AMBOS, pero los `[D]` tienen criterios específicos adicionales por ser patrones que se despliegan en el tiempo.

### Checklist A — Coherencia general (lineales + `[D]`)

- **Continuidad causal**: ¿cada hecho es consecuencia del anterior o está justificado? ¿Hay saltos sin motivación?
- **Consistencia de personajes**: ¿los personajes actúan según su caracterización? ¿Algún comportamiento contradice lo establecido? ¿Los arcos de Laura, Miguel y Diego son coherentes con sus motivaciones declaradas en BRIEF.md?
- **Tono y atmósfera**: ¿hay hechos que rompen el tono establecido? ¿La progresión de tensión es sostenida o decae en algún tramo?
- **POV**: ¿el foco variable (Laura/Miguel) es sostenible en todos los hechos? ¿Hay alguno donde el POV forzaría una solución torpe?
- **Vacío o exceso**: ¿falta algún evento necesario para que la historia fluya? ¿Sobra algún hecho que no aporta nada al arco?

### Checklist B — Validación específica de `[D]`

Los hechos `[D]` son patrones que se despliegan entre varios hechos lineales. No basta con evaluarlos individualmente: hay que validar cómo interactúan con su entorno.

- **Compatibilidad con el rango**: para cada `[D · H_XX–H_YY]`, revisa los hechos lineales H_XX a H_YY. ¿El patrón del `[D]` contradice o hace incoherente algún hecho lineal de su rango? Ej: si H_12 dice «coacción cotidiana» y H_15 dice «Miguel nota cambios», ¿los beats de H_12 harían inexplicable que Miguel tarde tanto en notar nada?
- **Solapamiento entre `[D]`**: si dos `[D]` comparten rango (ej: H_12 [H_11–H_16] y H_14 [H_13–H_16]), ¿son compatibles entre sí? ¿Podrían los beats de ambos `[D]` inyectados en la misma escena crear una sobrecarga narrativa o una contradicción? ¿El guionista tendrá espacio para ambos o uno eclipsará al otro?
- **Densidad de `[D]` por tramo**: ¿hay algún tramo del acto con demasiados `[D]`? Si en un rango de 3 hechos lineales hay 3 `[D]` distintos inyectando beats, el guionista no tendrá espacio. Recomienda redistribuir rangos si hay saturación.
- **Fugas de información**: ¿un `[D]` describe algo que, al inyectarse como beat, revelaría prematuramente información que un hecho lineal posterior necesita preservar como sorpresa? Ej: si un `[D]` muestra a Laura sospechando de Diego antes de H_10, arruina la revelación del mensaje.
- **Cierre de `[D]`**: ¿cada `[D]` se completa dentro de su rango? ¿Alguno describe un patrón que naturalmente continuaría más allá de su fin_de_rango? Ej: H_24 [H_22–H_24] describe la «nueva normalidad» — ¿está bien que termine en H_24 o debería ser el último hecho y cerrar el relato?
- **`[D]` vs. arco de personaje**: ¿algún `[D]` describe una transformación interna (cambio de actitud, evolución emocional, decisión) que el lector necesita **experimentar** en escenas concretas, no inferir de beats dispersos? Si es así, sugiere convertirlo en lineal. Una evolución que solo se intuye no le ocurre al lector.
- **`[D]` como último hecho**: ¿el hecho final de la obra es un `[D]`? Si es así, el relato/novela no tendrá escena de cierre concreta — la historia terminará en un patrón distribuido sin última imagen. Advierte y sugiere añadir un hecho lineal de cierre tras él, o convertir el `[D]` en lineal.
- **Oportunidades perdidas**: ¿hay algún tramo del arco que se beneficiaría de un `[D]` pero no lo tiene? ¿Algún hecho lineal que en realidad describe un patrón y debería marcarse como `[D]`?

### Checklist C — Problemas de interpretación

- **Ambigüedad narrativa**: ¿hay hechos que admiten lecturas contradictorias? ¿El guionista podría interpretar un hecho de forma que rompa la historia?
- **Dependencias ocultas**: ¿algún hecho asume información que no se ha establecido antes? Ej: «Laura recibe un mensaje de Diego» en H_10 — ¿se ha establecido que Diego tiene su número?
- **`[D]` interpretables**: ¿algún `[D]` es tan genérico que el guionista podría desarrollarlo en una dirección que contradiga el tono o el arco? Si el director ya escribió anotaciones, ¿son suficientes para guiar sin coartar?

### Checklist D — Propuestas de mejora

- ¿Hay oportunidades de reforzar un tema o contraste?
- ¿Algún hecho ganaría impacto si se recoloca?
- ¿Los rangos de `[D]` están bien dimensionados o hay oportunidad de ajustarlos?
- ¿Hay hechos lineales que deberían ser `[D]` o viceversa?

4. Presenta diagnóstico en cuatro bloques:
   - **Problemas de coherencia** (requieren corrección)
   - **Problemas con `[D]`** (solapamientos, fugas, saturación, rangos)
   - **Problemas de interpretación** (riesgos que el guionista podría malinterpretar)
   - **Propuestas de mejora** (oportunidades, no obligatorias)

5. Para cada problema detectado, propón una solución concreta. Si la solución es compleja, sugiere invocar al guionista.

6. Con aprobación del usuario, actualiza `_actos.md`.

## Gate

- No hay contradicciones entre hechos ni con BRIEF.md
- Los hechos `[D]` son compatibles con los lineales de su rango (sin contradicciones ni fugas de información)
- Los rangos de `[D]` no están saturados (máximo 2 `[D]` activos en el mismo tramo de 3 hechos)
- No hay `[D]` solapados que compitan por el mismo espacio narrativo sin anotaciones del director que los coordinen
- El arco narrativo es coherente de principio a fin

## Cuándo usarlo

- Después de `/refinar-hechos`, antes de `/generar`
- Si durante FASE 1 el guionista detecta incoherencias al agrupar hechos
- Si tras varios ajustes en `_actos.md` quieres verificar que todo encaja

## Relación con otros comandos

| Comando | Artefacto | Evalúa |
|---------|-----------|--------|
| `/refinar-hechos` | `_actos.md` | Concreción, narrabilidad, rangos `[D]` |
| `/validar-hechos` | `_actos.md` | Coherencia narrativa, consistencia, mejoras |
| `/revisar-guion` | `guion.md` | Coherencia de escenas, arcos, ritmo, transiciones |
