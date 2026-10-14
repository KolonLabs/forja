---
name: contexto-narrativo
description: Memoria local compacta de relato, actualizada por escenas operativas, con las notas para escenas pendientes y el registro de la última corrección.
user-invocable: false
---

# Contexto narrativo — Relato

Solo el director escribe `contexto_narrativo.md` y `correcciones.md`.

```markdown
# Contexto narrativo — [título]

## Secuencia actual

### E_0003 — [nombre]
- Delta: [cambio de estado, revelación o continuidad imprescindible]

## Estado acumulado

- [personaje/lugar/objeto]: [estado actual verificable]

## Próxima escena

- E_0004: [elementos necesarios para entrar]

## Notas transversales para el briefing

- [indicación que vale para varias escenas: una frase vetada, cómo leer una nota de `_actos.md`…]

## Notas por escena pendiente

Se borran en la transacción `escritura` de cada escena.

- **E_0007:** [indicación para el escritor o el validador]
```

- Después de cada `E_XXXX`, añade un delta breve, no un resumen exhaustivo.
- Tras una salida `separador`, compacta los deltas de esa secuencia en `Estado acumulado` y conserva solo lo relevante.
- Las referencias usan `B_XXXX`, `E_XXXX`, nombres y rutas de ficha. No se usan `stable_id`.

## Notas para escenas pendientes

Las dos secciones de notas solo existen si tienen contenido. Recogen lo que una corrección, una reparación del guion o una decisión de la persona usuaria deja dicho para escenas aún no escritas.

- Al encargar una escena, pasa al escritor y al validador, como notas del director, sus notas y las transversales que le afecten.
- En la transacción `escritura` que persiste la escena, borra sus notas. Las transversales se quedan mientras sigan aplicando.
- Una pregunta bloqueante que surge al escribir queda como nota de la escena afectada hasta que se resuelve.
- Una regla de la obra no es una nota: va a `config.json.restricciones`. `AGENTS.md` y `BRIEF.md` los edita la persona usuaria; proponle el texto y, hasta que lo añada, recoge la regla también como nota transversal.

## Registro de la última corrección (`correcciones.md`)

Cada transacción `correccion` sobrescribe `correcciones.md` con su propia entrada: el registro no crece. El historial está en el git de la obra; si la persona usuaria quiere conservar el detalle de una corrección, hace commit antes de la siguiente.

```markdown
# Correcciones — [título]

> **Uso de este archivo.** Solo contiene la última corrección: cada transacción `correccion` lo sobrescribe con su propia entrada. El historial está en git. Lo que deba durar más allá de una corrección va a `config.json.restricciones` o a las notas de `contexto_narrativo.md`.

## AAAA-MM-DD — [alcance]

**Motivo.** [qué se pidió o qué se detectó]

**Cambios:** [por archivo, con los `E_XXXX`/`B_XXXX` afectados]

**Resultado.** [qué queda resuelto y qué no]

## Decisiones pendientes

- [pregunta abierta, sus lecturas y qué cambia cada una]
```

- Antes de sobrescribir, lee la entrada anterior. Lo que deba durar más allá de ella (una regla, una nota para una escena pendiente) pasa a su sitio en la misma transacción.
- `Decisiones pendientes` solo existe si hay alguna abierta. Se conservan de una corrección a otra hasta que se resuelven. Al resolverse, la decisión va donde dure: una regla, a `config.json.restricciones`; una indicación para una escena no escrita, a sus notas; un cambio de hecho, guion o prosa, a la entrada de la corrección que lo aplica.
