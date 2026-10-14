# ADR 0040: Portada, identificador estable y cambios de escena del libro

- Estado: aceptada
- Fecha: 2026-10-14
- Ámbito: `shared/scripts/` (`publicacion-comun.ps1`, `compilar.ps1`, `borrador.ps1`, `build-epub.ps1`, `build.css`), `shared/imagenes/LEEME.md`, `relato-transaccion.ps1` y `/publicar` de relato (ambos entornos), `scripts/crear-libro.ps1`, `scripts/recompilar-libro.ps1`, `scripts/lib/common.ps1` (inyección), comandos `/compilar`, `/borrador`, `/crear-libro` y `/recompilar-libro`, guías de las tres escalas.
- Modifica: ADR 0038, punto 1 (campos del frontmatter).
- Relaciona: ADR 0004 (recompilación desde el manifiesto), ADR 0026 (compilación en la obra).

## Contexto

Al preparar el tío Vicente I para publicarlo aparecieron cuatro carencias:

- El EPUB no tenía cubierta.
- Pandoc le asignaba un identificador aleatorio cada vez, así que el lector trataba cada recompilación como un libro nuevo.
- El subtítulo de la cubierta no se podía llevar a los metadatos, y las tiendas comparan ambos.
- El cambio de escena (`---`) salía en el EPUB como una línea fina, que apenas se ve y desaparece en modo oscuro.

Además, `/publicar` de relato colocaba mal los cortes. La `salida` describe cómo termina una escena, pero su marcador está al principio, así que sustituir el marcador por `---` adelantaba el corte una escena. Nada lo comprobaba, y *La ventana* llegó a `finalizado` con todos sus separadores desplazados.

## Decisión

1. **Portada.** `imagenes/portada.jpg` (o `.png`) de la obra es la cubierta del EPUB en `/compilar --epub` y `/borrador --epub`. El manifiesto registra su hash. Sin portada, el EPUB sale sin cubierta y el script avisa. `build-epub.ps1` también avisa, sin impedir nada, si la portada mide menos de 1000 px de ancho o no es un PNG o JPEG reconocible. `imagenes/` se versiona con la obra, y cada obra recibe al inyectarse su guía, `imagenes/LEEME.md` (requisitos de tiendas, contraportada reservada, cubierta impresa aparte).
2. **Identificador estable.** El frontmatter lleva `identifier`, un UUID v5 (RFC 4122, espacio URL) de `forja:obra:<slug>`. Cada borrador tiene el suyo (`forja:borrador:<base>`) y cada antología también (`forja:libro:<slug>`). Una edición derivada tiene otro slug y, por tanto, otro identificador.
3. **Subtítulo.** `config.json.subtitulo` es opcional y va en `subtitle`. En el borrador va delante de la nota del borrador.
4. **Cambio de escena en el EPUB.** Cada `---` que ocupa su propio párrafo pasa a «\* \* \*» centrado (`div.separador` con `role="separator"`), como en el PDF. `build.css` quita la sangría del primer párrafo tras un título o un corte y oculta la fecha en la portada; la fecha sigue en los metadatos.
5. **Separadores de relato.** `/publicar` elimina todos los marcadores de escena y pone `---` tras cada escena con `salida: separador`, salvo la última, justo antes del primer párrafo de la siguiente. `relato-transaccion.ps1` rechaza al confirmar los separadores que falten, sobren o estén fuera de sitio. Las novelas no tienen `salida` y no cambian.
6. **Antologías.** `crear-libro.ps1 -Portada <imagen>` congela la cubierta en el libro como `portada.<ext>`, con su hash en el manifiesto. `recompilar-libro.ps1` la reutiliza y comprueba ese hash; con `-Portada`, que exige `-Epub`, la sustituye.

## Consecuencias

- Las tiendas y los lectores reconocen una recompilación como el mismo libro, con su cubierta.
- Un relato con separadores mal colocados ya no se puede finalizar. Los que ya están en `finalizado` (*La ventana*) necesitan volver a pasar `/publicar` con el helper nuevo.
- Las obras existentes reciben el cambio al actualizar sus scripts, comandos y guías desde `shared/`.
