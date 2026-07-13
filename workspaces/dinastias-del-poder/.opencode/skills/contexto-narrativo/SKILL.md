---
name: contexto-narrativo
description: Define el formato y protocolo de actualización de contexto_narrativo.md, el archivo de memoria ligera usado en relatos (sin Qdrant/Neo4j). Lo mantiene el director al cerrar cada escena.
---

El `contexto_narrativo.md` es la memoria del relato. Sustituye a Qdrant + Neo4j en la escala `relato`. Lo crea el director en FASE 2 y lo actualiza en FASE 3 tras cada escena completada.

## Formato

```markdown
# Contexto narrativo — [título del relato]

## Resumen por escena
(Escenas completadas, en orden)

### Escena 1: [nombre o slug]
[2-4 frases de resumen: qué ocurrió, quiénes participaron, qué cambió]

### Escena 2: [nombre o slug]
[resumen]

## Estado de entidades
(Cambios relevantes en personajes, lugares, objetos desde el inicio)

### [Nombre personaje] (stable_id: XXXXXXXX)
[estado actual: ubicación, estado emocional, relaciones, heridas, decisiones tomadas]

### [Nombre lugar] (stable_id: XXXXXXXX)
[cambios: quién está allí, atmósfera actual, eventos recientes]

## Conexiones activas
(Relaciones o hilos narrativos abiertos que deben recordarse)

- [Personaje A] sabe que [Personaje B] hizo X, pero no lo ha confrontado
- El objeto [nombre] está en posesión de [personaje], pero [personaje C] lo busca
- [Hecho distribuido D] ha aparecido 2 de 4 veces — próxima instancia en rango H_XX–H_YY

## Próxima escena
(Preparación para el escritor: qué esperar)

- **Personajes presentes**: [lista]
- **Ubicación**: [nombre]
- **Tensión acumulada**: [breve descripción del estado emocional colectivo]
```

## Protocolo de actualización

1. **FASE 2 — Creación**: el director crea `contexto_narrativo.md` con la cabecera y las secciones vacías. Sin resúmenes aún.

2. **FASE 3 — Por escena**: al terminar todos los beats de una escena (último beat marcado ✅), el director añade:
   - Una entrada en «Resumen por escena» con 2-4 frases.
   - Actualizaciones en «Estado de entidades» para personajes/lugares/objetos que hayan cambiado.
   - Nuevas entradas en «Conexiones activas» si se abren tramas.
   - La sección «Próxima escena» se reescribe completa cada vez.

3. **No se borra**: el archivo acumula la historia. Las escenas antiguas no se eliminan; sirven como referencia para el escritor y el validador.

## Quién lo usa

| Agente | Cómo lo usa |
|--------|-------------|
| **director** | Lo crea y mantiene |
| **escritor** | Lo recibe inline en el briefing de cada beat (FASE 3) |
| **validador** | Lo lee para verificar coherencia (dimensión `coherencia`) |
| **integrador** | Lo consulta para no romper continuidad al reescribir |

## Reglas

- Solo el **director** escribe en `contexto_narrativo.md`.
- Cada actualización es **incremental** (append, no reemplazo).
- Las referencias a entidades usan `stable_id`.
- Si el relato tiene hechos `[D]`, registrar cuántas instancias llevan y cuántas faltan.
