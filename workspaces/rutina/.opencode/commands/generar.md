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

## Fases por escala

### Relato (4 fases)
- **FASE 1 — Diseño**: guionista genera `guion.md` (actos → escenas → hechos → beats)
- **FASE 2 — Componentes**: entidades crea fichas en `fichas/`, director reconcilia, crea `contexto_narrativo.md` + `relato-draft.md`
- **FASE 3 — Beat a beat**: escritor → validador → ±integrador por cada beat. Director actualiza `contexto_narrativo.md` por escena
- **FASE 4 — Publicar**: `/publicar` genera `relato.md` limpio

### Novela simple (6 fases)
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
- El usuario puede interrumpir en cualquier fase para ajustar dirección
