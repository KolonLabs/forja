---
description: Genera salida limpia (relato.md, capitulo.md, novela.md) y opcionalmente compila EPUB con portada.
agent: director
---

# /publicar

Genera la versión limpia publicable del proyecto actual. Con `--epub`, compila un EPUB con portada generada por IA.

## Sintaxis

```
/publicar [--epub]
```

## Qué hace

### Relato
1. Lee `relato-draft.md`
2. Conserva título, convierte separadores de escena (`<!-- ESCENA -->` → `---`), elimina headings de beat (`## B_XX`)
3. Verifica: sin headings residuales, sin dobles separadores, archivo > 0
4. Sobreescribe `relato.md`

### Novela (sin --epub)
1. Publica el capítulo activo: `cap-XX/draft.md` → `cap-XX/capitulo.md`

### Novela (con --epub)
1. Publica todos los capítulos individualmente
2. Concatena en `novela.md`
3. Invoca al agente `epub` para compilar EPUB con:
   - Portada generada por Civitai (loop interactivo hasta aprobación)
   - Overlay de título y autor con Pillow
   - Tabla de contenidos
   - Metadatos completos

## Modo EPUB

El agente epub guía al usuario por:
1. Título de la publicación
2. Selección de relatos/capítulos a incluir
3. Diseño de portada (briefing → generación → loop de aprobación)
4. Overlay de texto (título, autor, tagline)
5. Compilación con Pandoc
6. Verificación del archivo resultante

## Notas

- En modo `--epub`, los archivos compilados se mueven a `publicados/[titulo]/`
- La portada se genera una sola vez por publicación (se reutiliza si ya existe y el usuario no pide nueva)
- El EPUB incluye tabla de contenidos automática
