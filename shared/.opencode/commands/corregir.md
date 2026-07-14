---
description: Ejecuta una pasada de corrección completa sobre una edición derivada de relato.
agent: director
---

# /corregir

Corrige una edición derivada de un relato sin alterar el workspace publicado del que procede.

## Sintaxis

```text
/corregir [completa|coherencia|tono|crudeza|ritmo|sensorial|estructura] [instrucciones]
```

## Requisitos

- Solo está disponible por ahora para relatos con `config.json.estado = "correccion"` y metadatos `edicion`.
- Lee `EDICION.md`, `correcciones.md` y `relato-edicion-anterior.md` antes de modificar nada.
- Nunca modifica `relato-edicion-anterior.md` ni el workspace de origen.

## Flujo

1. Crea backup del draft y de los archivos que vaya a modificar.
2. Ejecuta una validación global del draft contra `guion.md`, fichas y el manuscrito de referencia.
3. Si detecta problemas estructurales, revisa el tramo de guion afectado con el guionista y reescribe/valida los beats afectados.
4. Corrige la prosa beat a beat con el integrador y revalida cada cambio.
5. Registra alcance, beats y resultado en `correcciones.md`; mantiene el estado `correccion`.

Cuando el usuario considere cerrada la edición, ejecuta `/publicar`. El director generará un nuevo `relato.md` y dejará el workspace en `finalizado` para que el hub pueda compilarlo como una edición nueva.
