---
name: contexto-narrativo
description: Memoria local de relato actualizada por escena mediante IDs E_, B_ y nombres de ficha.
---

# Contexto narrativo — Relato

`contexto_narrativo.md` sustituye a la infraestructura de novelas. Solo el director lo escribe al cerrar cada `E_XXXX`.

```markdown
# Contexto narrativo — [título]

## Resumen por escena

### E_0001 — [nombre]
- Beats cerrados: B_0001–B_0004
- Resumen: [2-4 frases]

## Estado de entidades

### [Nombre] — ficha: fichas/personaje_nombre.md
[ubicación, estado, relaciones, heridas o decisiones]

## Conexiones abiertas

- [conexión y beat que la abrió]

## Próxima escena

- Escena: E_0002
- Personajes, ubicación y tensión acumulada: ...
```

Las referencias de continuidad se hacen por `B_XXXX`, `E_XXXX` y ruta/nombre de ficha. No se usan `stable_id`.
