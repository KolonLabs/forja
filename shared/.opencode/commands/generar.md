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
4. Avanza solo hasta el siguiente checkpoint obligatorio; presentar la narrativa de una escena exige detenerse y esperar al usuario, no continuar hasta completar el pipeline

En este workspace el checkpoint obligatorio de narrativa se aplica siempre: tras generar y preparar cada candidata, presenta la escena completa con hash/version y espera confirmacion explicita antes de revision editorial, aceptacion o avance. La aprobacion del guion no aprueba prosa futura. Aprobar una escena no autoriza la siguiente escena; requiere autorizacion de avance al destino concreto. Tras cerrar un capitulo, pedir autorizacion explicita para iniciar el siguiente capitulo (incluidas memoria y guion). Un `/generar` inicial no elimina estas paradas. Ver `docs/decisiones/0003-checkpoint-narrativa-usuario.md`.

Si el estado es `correccion`, no reinicia ni reescribe el pipeline: ese workspace es una edición derivada y se trabaja con `/corregir`, `/revisar` o `/expandir` antes de ejecutar `/publicar`.

## Fases por escala

### Relato (4 fases)
- **FASE 1 — Diseño**: valida `H_XXXX`, genera el mapa global de `B_XXXX`, resuelve `[D]` y después agrupa beats contiguos en `E_XXXX`
- **FASE 2 — Componentes**: entidades crea fichas en `fichas/`, director reconcilia, crea `contexto_narrativo.md` + `relato-draft.md`
- **FASE 3 — Por escena**: escritor → validador → ±integrador por cada `E_XXXX`; las anclas `B_XXXX` solo permiten localizar tramos dentro de esa prosa continua. El director actualiza `contexto_narrativo.md` al cerrar cada escena.
- **FASE 4 — Finalizar**: `/publicar` genera `relato.md` limpio y deja el estado en `finalizado`

### Novela simple (4 fases)
- **FASE 0 — Diseño**: guionista genera `guion-novela.md`
- **FASE 0.1 — Refinamiento de hechos**: revisión de hechos, ingesta de `referencias/`, fichas básicas
- **FASE 1 — Componentes**: entidades en Qdrant + Neo4j
- **FASE 2 — Escritura por capítulo**: memoria y contexto preparado → guionista con checkpoint → escritor por escena → candidato/hash → presentar al usuario y detenerse → revision editorial → correccion selectiva (nuevo texto vuelve al checkpoint) → ambas aprobaciones → aceptar/sincronizar → siguiente escena solo autorizada; al terminar, revision transversal y cronista del capitulo actual
- **FASE 3 — Publicar**: `/publicar` genera `capitulo.md` por cap + `novela.md`

### Novela multi-hilo (9 fases)
- **FASE 0 — Diseño global**: hilos, puntos de conexión, entidades semilla
- **FASE 0.1 — Refinamiento de hechos**: revisión de hechos con el usuario, ingesta de `referencias/`, fichas básicas
- **FASE 0.2 — Hilos**: guionista (modo `hilo`) genera `guion-hilo.md` (solo hechos) por cada hilo, aislado
- **FASE 0.3 — Beats y escenas por hilo**: guionista (modo `hilo-capitulo`) genera beats + escenas dentro de cada hilo, con checkpoints; `[D]` se resuelve aquí por completo, antes de que exista ningún capítulo global
- **FASE 0.4 — Trenzado**: guionista (modo `trenzado`) mueve las escenas ya escritas a capítulos globales y genera la tabla de Trenzado
- **FASE 1-2 — Componentes**: verificación del guion trenzado + entidades detalladas y conexiones cross-hilo
- **FASE 3 — Beat a beat cross-hilo**: auditoría de costuras entre hilos, luego escritura por capítulo según la tabla de Trenzado
- **FASE 4 — Publicar**: `/publicar` genera `capitulo.md` por cap + `novela.md`

## Output

Cada workspace produce en su raíz:
- **Relato**: `relato.md` (texto limpio continuo)
- **Novela**: `novela.md` (capítulos concatenados)

## Notas

- El director tiene iniciativa editorial: propone cambios, detecta problemas, sugiere mejoras
- En novelas, la memoria persistente (Qdrant + Neo4j) mantiene coherencia entre capítulos
- El usuario puede interrumpir en cualquier fase para ajustar dirección. En relato, el director avanza autónomamente salvo contradicción con el brief, ambigüedad editorial material o un beat bloqueado.
