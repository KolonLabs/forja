---
description: Genera la versión limpia publicable del proyecto en la raíz del workspace. Sin beats, sin escenas, sin actos. Solo capítulos (novela) o texto continuo (relato).
agent: director
---

# /publicar

Convierte el draft del workspace en un archivo limpio en la raíz del workspace.

Al terminar correctamente, el director deja `config.json.estado = "finalizado"`. `publicado` está reservado al hub: solo `/crear-libro` lo asigna después de compilar todas las salidas solicitadas.

## Sintaxis

```
/publicar
```

## Relato

1. Lee `relato-draft.md`
2. Elimina todos los headings `## B_XXXX — ...` (beats)
3. Convierte comentarios de escena `<!-- ESCENA N: ... -->` en separadores `---`
4. Conserva el título del relato como `# Título`
5. Escribe `relato.md` en la raíz del workspace
6. Gate: archivo > 0 bytes, sin headings de beat residuales

Estructura resultante (`relato.md`):
```
# Título del relato
...prosa...
---
...prosa...
```

## Novela

1. Por cada capítulo en `capitulos/cap-NN-slug/`:
   - Lee `draft.md`
   - Elimina todos los headings `## B_XXXX — ...`
   - Conserva separadores `---` entre bloques (capítulos puente)
   - Escribe `capitulos/cap-NN-slug/capitulo.md` con `# Capítulo NN — Nombre`
2. Concatena todos los `capitulo.md` → `novela.md` en la raíz del workspace
3. Gate: cada `capitulo.md` > 0 bytes, `novela.md` > 0 bytes

Estructura resultante (`novela.md`):
```
# Título de la novela

# Capítulo 1 — Nombre
...prosa...

# Capítulo 2 — Nombre
...prosa...
```
