# ADR 0041: `/compilar` conserva lo que no genera y las obras ignoran `tmp/`

- Estado: aceptada
- Fecha: 2026-10-14
- Ámbito: `shared/scripts/compilar.ps1`, comando `/compilar` (ambos entornos), `shared/imagenes/LEEME.md`, `scripts/lib/common.ps1` (`Initialize-ObraGit`), `.gitignore` de las obras existentes.
- Modifica: ADR 0026, punto 5 (contenido del `.gitignore`), y ADR 0028, punto 6 (`/compilar` conservaba solo `publicacion/borrador/`).
- Relaciona: ADR 0030 (la salida de audio vive junto al manuscrito).

## Contexto

En *El tío Vicente I* se ha generado un audiolibro con una herramienta propia de texto a voz, que vive fuera del hub. Como prevé el ADR 0030, la herramienta escribe junto al manuscrito que analiza: el mp3 final y una carpeta `temp/` con el guion de voces, el reparto, el plan de efectos editado a mano, los subtítulos y la caché de voces. Con el borrador queda en `publicacion/borrador/prosa/`, y con el libro, en `publicacion/`.

`compilar.ps1` sustituía `publicacion/` entera y solo rescataba `publicacion/borrador/`. Una recompilación borraba sin aviso el audiolibro del libro y todo su trabajo. Además, al mover la carpeta entera, un archivo abierto en otro programa partía la operación: el libro anterior quedaba en `.publicacion-anterior-*` y `publicacion/` a medias.

En *El tío Vicente II*, la persona usuaria pidió que cualquier carpeta `tmp/`, a cualquier nivel de la obra, quede fuera de git.

## Decisión

1. **`/compilar` solo sustituye lo suyo.** En `publicacion/` sustituye `<slug>.md`, `<slug>.epub`, `<slug>.pdf` y `manifest.json`, y retira un EPUB o PDF anterior que no se vuelva a pedir. No mueve nada más: los borradores y lo que otras herramientas dejen junto al libro se quedan donde están.
2. **Lo conservado se declara.** El script lista como «Conservado» lo que no genera (salvo `borrador/`) y avisa si el manuscrito ha cambiado desde la compilación anterior, comparando su hash con el del manifiesto anterior, porque lo conservado puede haberse quedado desfasado.
3. **El intercambio es reversible archivo por archivo.** Los archivos propios anteriores se apartan y los nuevos se colocan uno a uno. Si algo falla (por ejemplo, un EPUB abierto en un lector), se deshace: vuelven los anteriores, `config.json` recupera su estado y no queda ninguna carpeta temporal.
4. **`tmp/` en el `.gitignore` de las obras**, a cualquier nivel: en la plantilla de `Initialize-ObraGit` y en las obras existentes.

## Consecuencias

- Un audiolibro o cualquier salida externa sobrevive a `/compilar`. Regenerarla cuando cambie el manuscrito sigue siendo cosa de la herramienta que la produjo; `/compilar` solo lo avisa.
- Lo que deje en `publicacion/` una versión anterior de `/compilar` con otro nombre ya no se borra solo: aparece como «Conservado» y puede retirarse a mano.
- `recompilar-libro` ya copiaba el libro entero antes de recompilar, y `crear-libro` rechaza un libro existente: las antologías no cambian.
