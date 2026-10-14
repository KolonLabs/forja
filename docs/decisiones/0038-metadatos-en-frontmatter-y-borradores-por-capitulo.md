# ADR 0038: Metadatos del libro en frontmatter y borradores de novela por capítulo

- Estado: aceptada
- Fecha: 2026-10-14
- Ámbito: `shared/scripts/` (`publicacion-comun.ps1`, `compilar.ps1`, `borrador.ps1`, `build-epub.ps1`, `build-pdf.ps1`, `build.css`, `templates/forja-kdp.typ`), `scripts/crear-libro.ps1`, comandos `/compilar` y `/borrador` (ambos entornos), `/crear-libro`. Todas las escalas.
- Modifica: ADR 0031, punto 5, y ADR 0036, punto 1 (carpeta de salida del borrador de novela).
- Relaciona: ADR 0026 (compilación en la obra), ADR 0037 (el borrador conserva su `.md`).

## Contexto

El Markdown de un libro o de un borrador abría con `# Título` y `## Autor` como texto. Para la portada, `build-pdf.ps1` los quitaba con una expresión regular, y `build-epub.ps1` no los quitaba: el EPUB repetía título y autor como un capítulo. El borrador añadía además una línea «*Borrador del…*» al texto. Los metadatos (título, autor, idioma) se pasaban aparte por línea de comandos, así que el `.md` conservado (ADR 0037) no los llevaba. Además, el EPUB de un relato, que no tiene capítulos, mostraba el título como encabezado visible tras la portada, y los dos formatos ponían un índice aunque solo hubiera un capítulo o ninguno.

En novela, cada capítulo genera su propio borrador. Ahora que el `.md` se queda junto al EPUB y al PDF, `prosa/` y `guion/` acumulaban tres o cuatro ficheros por capítulo mezclados en la misma carpeta. Todos tenían además el mismo título en la biblioteca del lector.

El cambio se probó primero en el tío Vicente I y se lleva a `shared/` para todas las escalas.

## Decisión

1. **Frontmatter YAML.** El Markdown de `/compilar`, `/borrador` y `/crear-libro` abre con un bloque YAML de valores entrecomillados en una sola línea: `title`, `author`, `lang`, `date` y `subject` (género y subgénero de la obra; en una antología, los géneros de sus relatos). El borrador añade `subtitle` (tipo de borrador, fecha, cobertura y «no es el texto final»). Título y autor no forman parte del texto. Lo generan `Get-ObraMetadatos` y `New-FrontMatter` (`publicacion-comun.ps1`).
2. **Los formatos leen los metadatos del frontmatter.** `build-epub.ps1` y `build-pdf.ps1` lo leen con `Read-MarkdownLibro`. `-Titulo` y `-Autor` dejan de ser obligatorios y solo sobrescriben. `lang=es` se aplica si el Markdown no declara idioma. Un Markdown sin frontmatter que abra con la cabecera `# Título` + `## Autor` de antes (las antologías ya congeladas que recompila `/recompilar-libro`) sigue siendo válido: esa cabecera pasa a la portada y no al texto.
3. **Índice solo con dos o más capítulos** (encabezados de nivel 1), en EPUB y en PDF.
4. **Relato en EPUB.** Si el texto no empieza con un encabezado de nivel 1, `build-epub.ps1` pone uno con el título y la clase `titulo-oculto`, que `build.css` oculta: da nombre a la entrada del índice de navegación y el texto empieza con la prosa.
5. **Plantilla PDF.** La portada muestra `subtitle`. El texto o el índice empiezan en página impar, y un capítulo ya no deja una página en blanco cuando sigue a la portada.
6. **Una carpeta por capítulo en los borradores de novela**, de prosa y de guion: `publicacion/borrador/prosa/cap-NN/` y `publicacion/borrador/guion/cap-NN/`. En multi-hilo, el guion de un hilo antes de ensamblar va en `publicacion/borrador/guion/hilo-<hilo>/cap-NN/`. Los nombres de fichero no cambian, y el relato, que no tiene capítulos, sigue en `prosa/` y `guion/`. Al regenerar un alcance se retiran sus versiones sueltas de estructuras anteriores: `prosa/` o `guion/` sin carpeta de capítulo, y `publicacion/borrador/`.
7. **El título del borrador de novela incluye el capítulo** (`<título> · Capítulo N (borrador)`; por hilo, `<título> · Hilo <hilo> · Capítulo N (guion, borrador)`), para distinguir los borradores en la biblioteca del lector.

## Consecuencias

- El `.md` de un libro o borrador lleva sus metadatos y se puede regenerar en EPUB o PDF sin más argumentos. Los editores Markdown muestran el frontmatter como propiedades.
- `date` es el día de la compilación: el hash del `.md` compilado cambia de un día a otro aunque el manuscrito no cambie. El manifiesto sigue congelando el hash del manuscrito.
- Las obras existentes necesitan los scripts y comandos nuevos de `shared/` para aplicar el cambio. Sus borradores de capítulo de la estructura anterior se retiran al regenerarlos.
