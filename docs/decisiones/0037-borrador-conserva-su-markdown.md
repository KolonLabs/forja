# ADR 0037: El borrador conserva su Markdown junto a EPUB y PDF

- Estado: aceptada
- Fecha: 2026-10-13
- Ámbito: `shared/scripts/borrador.ps1`, comando `/borrador` (ambos entornos).
- Modifica: ADR 0031, punto 5; ADR 0036, punto 1 (en lo que se refiere a los formatos).

## Contexto

Según el ADR 0031, `/borrador --epub` o `--pdf` dejaba solo los formatos pedidos y eliminaba el `.md` y el manifiesto como ficheros de trabajo. En la práctica el `.md` es la fuente legible del EPUB o el PDF: sirve para buscar, citar o comparar el texto sin abrir el libro, y regenerarlo exigía volver a lanzar el borrador. El cambio se hizo primero en el tío Vicente I y se lleva a `shared/` para todas las obras.

## Decisión

1. **El `.md` del borrador se conserva siempre**, también con `--epub` o `--pdf`: los formatos se generan además, a partir de él, en la misma carpeta (`publicacion/borrador/prosa/` o `publicacion/borrador/guion/`).
2. **El manifiesto sigue siendo un fichero de trabajo** cuando se piden formatos: se elimina. Sin formatos, el borrador es el `.md` y conserva su manifiesto.
3. Cada ejecución sigue sustituyendo entero el borrador anterior del mismo alcance; la limpieza automática de intermedios de escena del ADR 0031 no cambia.
