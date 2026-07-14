---
description: Deriva una edición corregible de un relato publicado sin modificar el original.
agent: bibliotecario
---

# /nueva-edicion

Abre una nueva edición de un relato ya publicado. El original permanece inmutable: se crea otro workspace con el guion, fichas y draft necesarios para corregir el contenido.

## Sintaxis

```text
/nueva-edicion <workspace-publicado> <slug-edicion> [--titulo "Título"] [--motivo "..."]
```

## Reglas

- Solo admite relatos en estado `publicado`.
- `slug-edicion` debe ser distinto y usar `kebab-case`.
- Guarda el texto publicado como `relato-edicion-anterior.md`; no lo modifica.
- El nuevo workspace queda en estado `correccion`. El trabajo editorial ocurre allí, nunca en el original.
- Por ahora no admite novelas: su migración de estados y edición sigue pendiente.

## Ejemplo

```text
/nueva-edicion la-fachada la-fachada-2a-edicion --motivo "Corregir continuidad y ajustar el final"
```

## Ejecución

```powershell
.\scripts\new-edicion-relato.ps1 -Origen "<workspace-publicado>" -Slug "<slug-edicion>" [-Titulo "Título"] [-Motivo "..."]
```

Al terminar, indica la ruta del nuevo workspace y recuerda que debe abrirse allí para ejecutar `/corregir`, `/revisar`, `/expandir` y finalmente `/publicar`.
