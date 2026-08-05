---
description: Revisa y mejora un beat específico de un relato o novela. Scope unificado (completa/media/ligera + alias de usuario).
agent: director
---

# /revisar

Revisa un beat de un proyecto existente. El director localiza el beat, aplica correcciones, valida y guarda.

## Sintaxis

```
/revisar [B_NNN] [instrucciones opcionales]
```

## Ejemplos

```
/revisar B_07 la geometría no es clara
/revisar B_14 falta más detalle sensorial, especialmente olfato
/revisar B_29 el diálogo suena pasivo, dale más tensión
/revisar cuando Elena se arrodilla la posición no queda clara
```

## Scope

El director deduce el scope según las instrucciones del usuario:

| Si el usuario habla de... | Scope aplicado |
|--------------------------|----------------|
| vocabulario, crudeza, eufemismos | `crudeza` sola |
| fluidez, ritmo, frases, puntuación | `geometria` sola |
| descripción, sentidos, sensorial | `sensorial` sola |
| diálogo, voces, personajes hablando | `geometria + tono` |
| varios temas o no especifica | `completa` (5 dimensiones) |

**Scope canónico** (compatible con `/generar --revision`):
- `completa` → crudeza, tono, geometria, coherencia, sensorial
- `media` → crudeza, coherencia, sensorial
- `ligera` → corrección directa sin validador

## Flujo

1. Identificar proyecto y beat
2. Backup automático
3. Corrección → validador → ±integrador
4. Reemplazo quirúrgico del beat en el draft (solo ese bloque)

## Ediciones derivadas de relato

En un relato con `estado: correccion`, `/revisar` opera sobre la edición derivada. Debe preservar `relato-edicion-anterior.md`, mantener el estado `correccion`, actualizar `ultima_modificacion` y anotar el beat y el resultado en `correcciones.md`. Para un relato `finalizado` o `publicado`, no edites el texto: abre primero `/nueva-edicion` desde el hub. Las novelas mantienen su contrato actual hasta su migración específica.

## Notas

- El director mantiene coherencia: si el beat corregido afecta a fichas de entidades, propone actualizarlas
- En novelas, las correcciones se reflejan en Qdrant en la siguiente ejecución del cronista
