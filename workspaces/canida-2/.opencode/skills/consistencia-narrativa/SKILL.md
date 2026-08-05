---
name: consistencia-narrativa
description: Use ONLY when the user requests a coherence check, gap analysis, inconsistency detection, timeline verification, or narrative audit of developed story elements across acts, chapters, or character arcs. Covers contradictions, missing links, logical problems, temporal issues. Does NOT cover beat format review. Trigger keywords: coherencia, inconsistencia, gaps, huecos, audit, verificar, contradicción, lógica narrativa, problemas de timeline, incoherencia.
---

# Skill — Consistencia Narrativa

## Protocolo de revisión

Al revisar narrativa, verificar en este orden:

### 1. Coherencia interna
- ¿Los beats se contradicen entre sí?
- ¿Un personaje sabe algo que no debería saber todavía?
- ¿Las acciones tienen consecuencias lógicas?

### 2. Coherencia con documentos maestros
- ¿Los beats reflejan `_actos.md`?
- ¿Las acciones de personajes son coherentes con sus fichas?
- ¿El tono respeta `_brainstorming.md`?

### 3. Progresión narrativa
- ¿Cada beat avanza la trama o solo describe estado?
- ¿Hay redundancia entre beats?
- ¿Faltan beats puente entre momentos clave?

### 4. Problemas comunes

**Beats-fantasma:** Describen estado sin acción. Ejemplo: *"Los días siguientes, la mirada cambia"* → no es beat, es transición.

**Desincronización temporal:** Personajes en lugares imposibles o tiempos contradictorios.

**Información quemada:** Se revela algo que debería reservarse para más adelante.

**Objetivos ausentes:** Los personajes actúan sin que el lector entienda el para qué.

### 5. Matriz de evaluación

| Problema | Urgencia | Ejemplo |
|---|---|---|
| Contradicción lógica | Alta | Un personaje muere y luego habla |
| Gap narrativo | Media | Salto de ubicación sin explicación |
| Beat-fantasma | Baja | Estado sin acción concreta |

## Formato de reporte

```
## Problemas detectados

### Críticos (requieren corrección)
- [ ] Descripción del problema
  - Ubicación: BXXX
  - Sugerencia: cómo corregir

### Medios (recomendados)
- [ ] Descripción del problema
  - Ubicación: BXXX
  - Sugerencia: cómo corregir

### Menores (opcionales)
- [ ] Descripción del problema
  - Ubicación: BXXX
  - Sugerencia: cómo corregir
```
