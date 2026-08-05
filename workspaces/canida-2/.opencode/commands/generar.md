---
description: Inicia o continúa el pipeline de generación desde el estado actual del workspace.
agent: director
---

# /generar

Inicia o continúa el pipeline de generación desde `config.json.estado`. El director lee `PIPELINE.md` y `ORQUESTACION.md` y orquesta los agentes según la fase actual.

## Sintaxis

```
/generar
```

## Qué hace

El director:
1. Lee `config.json.estado` para saber en qué fase está
2. Lee `PIPELINE.md` para conocer las fases y gates de su escala
3. Sigue el contrato en `ORQUESTACION.md` para spawnear subagentes
4. Avanza secuencialmente por las fases hasta completar el pipeline

Si el estado es `correccion`, no reinicia ni reescribe el pipeline: ese workspace es una edición derivada y se trabaja con `/corregir`, `/revisar` o `/expandir` antes de ejecutar `/publicar`.

## Fases por escala

### Relato (4 fases)
- **FASE 1 — Diseño**: valida `H_XXXX`, genera el mapa global de `B_XXXX`, resuelve `[D]` y después agrupa beats contiguos en `E_XXXX`
- **FASE 2 — Componentes**: entidades crea fichas en `fichas/`, director reconcilia, crea `contexto_narrativo.md` + `relato-draft.md`
- **FASE 3 — Por escena**: escritor → validador → ±integrador por cada `E_XXXX`; las anclas `B_XXXX` solo permiten localizar tramos dentro de esa prosa continua. El director actualiza `contexto_narrativo.md` al cerrar cada escena.
- **FASE 4 — Finalizar**: `/publicar` genera `relato.md` limpio y deja el estado en `finalizado`

### Novela simple (4 fases)
- **FASE 0 — Diseño**: guionista genera `guion-novela.md`
- **FASE 1 — Componentes**: entidades en Qdrant + Neo4j
- **FASE 2 — Escritura por capítulo**: memoria → guionista → beat a beat → validador global → cronista
- **FASE 3 — Publicar**: `/publicar` genera `capitulo.md` por cap + `novela.md`

### Novela multi-hilo (8 fases)
- **FASE 0 — Diseño global**: hilos, puntos de conexión
- **FASE 0.1-0.3 — Hilos + Trenzado**: guionista genera `guion-hilo.md` por hilo, luego tabla de trenzado
- **FASE 1-2 — Componentes**: entidades + conexiones cross-hilo
- **FASE 3 — Beat a beat cross-hilo**: por capítulo según trenzado
- **FASE 4 — Publicar**: `/publicar` genera `capitulo.md` por cap + `novela.md`

## Output

Cada workspace produce en su raíz:
- **Relato**: `relato.md` (texto limpio continuo)
- **Novela**: `novela.md` (capítulos concatenados)

## Notas

- El director tiene iniciativa editorial: propone cambios, detecta problemas, sugiere mejoras
- En novelas, la memoria persistente (Qdrant + Neo4j) mantiene coherencia entre capítulos
- El usuario puede interrumpir en cualquier fase para ajustar dirección. En relato, el director avanza autónomamente salvo contradicción con el brief, ambigüedad editorial material o un beat bloqueado.
