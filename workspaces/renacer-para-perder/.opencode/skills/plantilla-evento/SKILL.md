---
name: plantilla-evento
description: Estructura y campos obligatorios para crear una ficha de evento narrativo con cuándo, quiénes, qué ocurre y consecuencias. Secciones FIJO (inmutable) y DINÁMICO (actualizable por el cronista).
---

<!-- FIJO — No modificar tras la creación inicial -->

# [NOMBRE DEL EVENTO]

## Cuándo
- **Capítulo**: (en qué cap ocurre, o "pre-novela" si ocurrió antes)
- **Momento exacto** (si aplica): (dentro del cap, en qué escena)
- **Duración**: (cuánto dura el evento en la historia: segundos, horas, días)
- **Ubicación**: (lug-*-id o descripción libre del lugar)

## Quiénes
- **Personajes presentes**: (per-*-id, lista)
- **Personajes afectados indirectamente**: (per-*-id aunque no estaban)
- **Testigos** (si aplica): (per-*-id que vieron u oyeron sobre el evento)

## Qué ocurre
- **Hechos objetivos**: (qué pasó, sin interpretación — formato factual)
- **Decisiones clave tomadas**: (qué eligió hacer cada personaje relevante)
- **Revelaciones** (si las hay): (qué verdades salieron a la luz)
- **Acción física principal**: (el momento más significativo del evento)

## Consecuencias
- **Cambios en el estado de personajes**: (qué cambió en cada per-*-id afectado)
- **Cambios en relaciones**: (Neo4j se actualiza por el cronista al cierre del cap)
- **Cambios en lugares**: (lug-*-id: el lugar ya no es el mismo)
- **Cambios en objetos**: (obj-*-id si el evento involucró objetos)
- **Hilos que se abren**: (hilo-*-id nuevos)
- **Hilos que se cierran**: (hilo-*-id que se resuelven)
- **Arcos afectados**: (arc-*-id que avanzan o se modifican)

## Reglas del evento
- [Consistencia: "una vez ocurrido, no se puede deshacer", "los personajes reaccionan según su ficha"]
- [Reverberación: "el evento tiene consecuencias hasta N caps después"]

## Tags
[tipo: giro-revelacion-conflicto-boda-muerte-encuentro-traicion] [impacto: alto-medio-bajo] [escala: personal-intima-publica-historica] [tag]

---

<!-- DINÁMICO — Actualizado por el agente cronista tras cada capítulo -->

## Reacciones y desarrollo posterior
- **Cap-XX+1**: [qué pasó en respuesta al evento]
- **Cap-YY+2**: [cómo se siguió desarrollando]

## Estado
- **Concluido**: (sí / no / en curso)
- **Última referencia**: (cap-XX)
