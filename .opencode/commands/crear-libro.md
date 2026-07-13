---
name: crear-libro
description: Crea un libro (EPUB/PDF) desde uno o varios workspaces. Una novela = un libro. Varios relatos = antología.
agent: scaffolder
---

# /crear-libro

Ensambla un libro desde los archivos limpios (`relato.md` / `novela.md`) de los workspaces indicados.

## Sintaxis

```
/crear-libro <slug-libro> <workspace1> [workspace2 ...] [--epub]
```

## Ejemplos

```
/crear-libro cronicas-del-deseo rutina la-fachada --epub
/crear-libro mi-novela mi-novela --epub
```

## Qué hace

1. Lee `relato.md` o `novela.md` de cada workspace fuente
2. Ensambla el contenido en `publicados/<slug-libro>/<slug-libro>.md`
3. Opcionalmente compila EPUB con `--epub`
4. Marca `config.json.estado = "publicado"` en los workspaces fuente

## Requisitos

- Los workspaces fuente deben tener su contenido publicado (`/publicar` ejecutado previamente)
- El archivo `relato.md` o `novela.md` debe existir en la raíz de cada workspace
- Pandoc debe estar instalado para la opción `--epub`

## Flujo interno

El comando ejecuta:
```powershell
.\scripts\crear-libro.ps1 -Libro "<slug>" -Fuentes @("<ws1>","<ws2>") [-Epub]
```
