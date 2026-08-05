---
name: desarrollo-narrativa
description: Use ONLY when the user is developing narrative content, writing scenes, confirming story beats, advancing character arcs, or progressing the plot. Trigger keywords: escribir, narrar, desarrollar, avanzar, confirmar beats, escena, párrafo, capítulo, continuar la historia, siguiente beat.
---

# Skill — Desarrollo Narrativo

## Regla fundamental

**Cada vez que se confirman beats o se escribe prosa narrativa, actualizar las fichas de los personajes afectados.**

Las fichas son el estado operativo de los personajes. Reflejan quién es el personaje AHORA, no su destino completo.

---

## ¿Qué actualizar en las fichas?

### 1. Estado Actual
- ¿Qué forma tiene ahora?
- ¿Qué función cumple en este momento?
- ¿Dónde está ubicado/a?
- ¿Qué relaciones activas tiene?

### 2. Bitácora de desarrollo
- Añadir entrada con referencia al beat o escena reciente
- Registrar el cambio observable: comportamiento, decisión, contacto
- Fecha/beat de referencia para trazabilidad

**Formato:**
```markdown
## Bitácora de desarrollo

- Post-B024: NEXUS se presenta como Andrés en empresa de Ricardo, acceso abierto
- Post-B029: Intensidad del encuentro con Ricardo desborda umbral de conciencia colectiva
```

### 3. Notas operativas del momento
- Preguntas abiertas sobre el personaje que surgen de lo último escrito
- Dudas o tensiones narrativas actuales
- NO respuestas futuras ni spoilers de actos posteriores

**Ejemplo:**
```markdown
## Notas operativas

- ¿Ricardo siente que Andrés le resulta familiar o lo ignora?
- ¿HELIX repetirá la forma de mujer explosiva o buscará otra variable?
```

---

## ¿Qué NO incluir en las fichas?

- ❌ Arcos completos por actos (eso vive en `_actos.md`)
- ❌ Destinos finales o spoilers
- ❌ Eventos de actos posteriores no desarrollados todavía
- ❌ Información que el personaje no conoce todavía

---

## Protocolo de actualización

1. Identificar qué personajes aparecen en los beats o escena reciente
2. Leer sus fichas actuales
3. Añadir entrada en bitácora con referencia al beat
4. Actualizar estado actual si ha cambiado forma, función o ubicación
5. Añadir notas operativas si surgen nuevas preguntas
6. NO modificar secciones de identificación o perfil base sin consultar

---

## Ejemplo de ficha evolutiva

```markdown
# Ficha — NEXUS (CALIMA-1)

## Identificación
[Datos fijos: nombre de misión, clase, serie, identificador]

## Estado Actual (Acto I — post B029)
- Forma humana: Andrés, hombre 35-42 años, aspecto discreto
- Función: colaborador informal en empresa de Ricardo Montalvo
- Ubicación: Madrid, oficina de Ricardo y entornos de cruising
- Relaciones activas: vínculo sexual con Ricardo, STRIX como pareja operativa

## Bitácora de desarrollo
- Post-B007: Descubrimiento del cruising en polígono de Villaverde
- Post-B010: Recibe tarjeta de Ricardo durante encuentro en cruising
- Post-B017: Construye identidad de Andrés a partir de la tarjeta
- Post-B024: Se presenta como Andrés en empresa de Ricardo
- Post-B029: Encuentro sexual en oficina de madrugada, desborda conciencia colectiva

## Notas operativas
- ¿Ricardo reconoce algo familiar en Andrés o lo ignora completamente?
- ¿La excusa laboral resiste o necesita refuerzo narrativo?
```

---

## Cuándo actualizar fichas de personajes secundarios

Los personajes de `secundarios.md` solo se actualizan si:
- Aparecen en más de una escena
- Su rol cambia de fondo a relevante
- Necesitan ficha individual propia

Si un secundario gana peso narrativo, extraerlo a ficha individual.
