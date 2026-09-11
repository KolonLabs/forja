---
name: hechos-estructura
description: Estructura y criterios para definir hechos narrativos (H_NNNN) en guiones de novela. Úsalo cuando el guionista necesite crear o revisar la distribución de hechos en capítulos.
---

# Skill — Estructura de Hechos

Los **hechos** (`H_NNNN`) son unidades narrativas intermedias que agrupan beats relacionados bajo un evento central. Son exclusivos de novelas — los relatos no usan hechos, solo beats directos.

## Qué es un hecho

Un hecho narrativo es el **evento concreto con consecuencia** que ocurre en un bloque narrativo. No es una descripción de escena ni un resumen de intenciones: establece qué cambia y agrupa los compromisos dramáticos necesarios para desarrollarlo, sin cuota de beats.

Ejemplo opcional de cobertura, no canon ni pauta de cantidad o ejecución:

```
- ⬜ H_0001 — Ana recibe una carta que la lleva a reabrir la búsqueda de su hermano
  - ⬜ B_0001 — Ana reconoce en la carta una referencia privada e infiere que su hermano podría seguir vivo, sin confirmarlo `[Revelación — MEDIA]`
  - ⬜ B_0002 — Ana decide comprobar la dirección de envío antes de avisar a la familia `[Tenso — BREVE]`
```

## Reglas fundamentales

- **Un sujeto o grupo de sujetos que actúan o son afectados** en el hecho
- **Un evento concreto con consecuencia narrativa**: algo cambia después del hecho
- **IDs globales de 4 dígitos** (`H_0001`, `H_0002`...) — nunca se reinician entre capítulos
- **Cobertura, no conteo**: los beats deben realizar el detonante, la presión, el cambio y la consecuencia pertinentes, sin exigir un beat separado para cada componente
- **Agrupación por desarrollo narrativo**: la cantidad de hechos por capítulo y de beats por hecho depende de sus cambios y relaciones causales, no de mínimos, máximos ni multiplicadores

## Qué debe tener un hecho

- **Sujeto claro** (quién actúa o recibe la acción)
- **Cambio narrativo concreto** en infinitivo o presente, incluida una decisión, un descubrimiento o una inferencia atribuida con consecuencias
- **Especificidad**: no "hablan" sino "Elena confronta a Carlos por la deuda"
- **Consecuencia identificable**: debe quedar claro qué cambia; el guion puede declarar el resultado necesario para planificar su desarrollo

## Qué NO debe tener un hecho

- Estados de ánimo sin evento: no "Elena se siente culpable"
- Resúmenes vacíos: no "El capítulo avanza"
- Acciones triviales sin peso narrativo: tampoco justifican por sí solas beats; su ejecución ordinaria corresponde al escritor
- Coreografía, diálogos redactados o pensamiento escrito como prosa en lugar de compromisos narrativos

## Relación con beats

El hecho declara un evento y su consecuencia. Los beats bajo él concretan **qué compromisos narrativos deben cumplirse** durante su desarrollo. El **cómo literario** corresponde al escritor: diálogo, pensamiento, cadencia, sensaciones y acciones de enlace compatibles con esos compromisos.

Un beat es una unidad dramática, no una microacción. Puede reunir varias acciones o réplicas que realizan el mismo cambio, o consistir en una decisión, descubrimiento o inferencia atribuida que modifica opciones, objetivos o conocimiento. Distingue lo dicho, lo sabido, lo inferido y lo verdadero: recibir una afirmación no prueba su contenido y una sospecha no equivale a descubrir un hecho.

Divide solo cuando haya compromisos dramáticos distintos que necesiten seguimiento separado. No dividas por puntuación, número de verbos, cambio de tono ni saludo, despedida o gesto ordinario. Revisa la granularidad por omisiones o redundancias concretas, no por cantidad. No impongas silencios, gestos o metáforas sin función narrativa.

Un diálogo relevante se compromete por su contenido y efecto, no por palabras exactas. Reserva ⚡ para literalidad exigida expresamente por el usuario o aprobada con función causal documentada, según `mecanica-prosa`; nunca por importancia o efecto estilístico. Una frase ⚡ vigente no se degrada a ejemplo: si resulta incompatible con la revisión, pide resolución al director antes de generar.

## Distribución en capítulos

**Novela multi-hilo:** los hechos se agrupan primero en **capítulos-borrador**, dentro de cada hilo, por coherencia de contexto (mismo espacio/tiempo/cast) — no por cuota fija de hechos (FASE 0.3). Cada capítulo-borrador vive en `hilos/hilo-<slug>/cap-NN/` y ahí se generan sus beats y escenas. Las escenas resultantes —no los hechos— son la unidad que se trenza después en capítulos globales reales (FASE 0.4), vía la tabla de Trenzado de `guion-novela.md`.

**Novela simple:** los hechos se asignan directamente a capítulos según la estructura de `guion-novela.md`, sin capítulos-borrador intermedios.

En ambos casos:
- Los hechos se numeran globalmente (continuando desde `config.json.ultimo_hecho_seq`)
- Los beats de cada hecho también son globales (`config.json.ultimo_beat_seq`)

## Evaluación de hechos

Al revisar un hecho, verificar:

1. ¿Tiene sujeto claro y evento o cambio concreto narrable?
2. ¿Tiene consecuencia en la trama (algo cambia)?
3. ¿Los beats cubren los compromisos y consecuencias del hecho sin omisiones ni microacciones de relleno?
4. ¿No repite lo que ya ocurrió en hechos anteriores?
5. ¿Su ID sigue la numeración global sin saltos?

## Estados

```
⬜ H_0001 — (pendiente)
🔄 H_0001 — (en progreso)
✅ H_0001 — (completado)
```
