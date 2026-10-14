# imagenes/

Imágenes de la obra para la publicación. Se versionan con la obra (a diferencia de
`publicacion/`, cuyo libro se regenera en cada `/compilar`). Formato JPG o PNG; el
nombre fija el uso.

| Archivo | Uso | Lo usa |
|---|---|---|
| `portada.jpg` (o `.png`) | Cubierta frontal del EPUB y de las tiendas | `/compilar --epub` y `/borrador --epub` |
| `contraportada.jpg` (o `.png`) | Cubierta trasera (contracubierta, sinopsis) | Reservado: ningún script la usa todavía |

## Portada del EPUB

- JPG en RGB, proporción 1:1,6. Recomendado: 1600 × 2560 px. Algunas tiendas
  rechazan imágenes de menos de 1000 px de ancho.
- El título y el autor deben estar dibujados en la propia imagen: es lo único que
  muestran tiendas y bibliotecas.
- Sin `portada.*`, el EPUB se genera sin cubierta y `/compilar` lo avisa. También
  avisa si la portada mide menos de 1000 px de ancho.

## Cubierta impresa

La cubierta de papel (KDP u otra imprenta) es un PDF aparte, con portada, lomo y
contraportada a tamaño de pliego, y el lomo depende del número de páginas. No forma
parte del PDF interior que genera `/compilar --pdf`; si la preparas, guárdala aquí
(p. ej. `cubierta-impresa.pdf`).
