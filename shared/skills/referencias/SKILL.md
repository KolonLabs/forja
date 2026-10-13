---
name: referencias
description: Contrato de la carpeta referencias/ (canon previo, documentación y guía previa), su validación y las fichas de personajes heredados de otra obra. Cárgala al consultar, añadir o validar referencias y al tratar un personaje que reaparece.
user-invocable: false
---

# Referencias

`referencias/` guarda material de consulta aportado por la persona usuaria. No es el brief: las obras, autores o películas que inspiran el tono son **inspiraciones** y viven en `BRIEF.md` (`## Inspiraciones`). Precedencia: `AGENTS.md` > `BRIEF.md` > hechos y guion > `referencias/`.

## Tipos

Cada archivo es Markdown y empieza con una cabecera:

```markdown
---
titulo: Canon de Cánida 1
tipo: canon-previo            # canon-previo | documentacion | guia-previa
origen: Cánida (novela, 45 capítulos), texto de capitulos/ a fecha 2026-10-13
fecha: 2026-10-13
proposito: continuidad de personajes, mundo y desenlace de Cánida 1
fuente_sha256: <hash de la fuente usada>     # obligatorio en canon-previo
colisiones_aceptadas: [Vega]                 # opcional, solo canon-previo
---
```

| Tipo | Qué es | Cómo se usa |
|---|---|---|
| `canon-previo` | Hechos de una obra anterior del mismo universo: quién es cada personaje, qué pasó, cómo quedó. | Es canon: contradecirlo es bloqueante. Cada hecho lleva cita. Nunca contiene propuestas para la obra nueva. |
| `documentacion` | Material técnico, científico, histórico o de mundo, por temas. | Lo que la obra adopta es canon, por debajo del brief y los hechos. |
| `guia-previa` | Trabajo de diseño anterior que orienta la intención (esbozos de hilos, notas previas). | Solo orienta el espíritu. Nunca es canon ni se copia su estructura, sus escenas o su orden; los hechos y el guion prevalecen. |

## Qué se admite

Una referencia es válida si es **concreta** (hechos, nombres, fechas, reglas; no prosa vaga), **relevante** para esta obra (lo dice `proposito`) y **manejable**: un archivo no supera 6 000 palabras y una sección `##` debería caber como pasaje (≈1 500). Nunca se incluye una obra entera ni capítulos copiados: de una novela relacionada se hace un dossier `canon-previo`.

En `canon-previo`, cada hecho es una viñeta con al menos una cita al final: `[cap. 24: «Ciento cincuenta mil euros para cada uno»]`. El fragmento es literal, de 3 a 25 palabras, y existe en la fuente. La fuente de verdad es el **texto** de la obra previa, no sus fichas ni resúmenes anteriores, que pueden estar desfasados. Los personajes van en `## Personajes`, uno por `### Nombre`, con su estado al final de la obra.

`scripts/validar-referencias.py` comprueba cabecera, tamaño, citas y choques de nombres; con `--fuente <ruta>` verifica además que cada fragmento citado existe, que la referencia no copia la fuente y que `fuente_sha256` sigue vigente. Una referencia nueva se valida y la persona usuaria confirma antes de usarla.

## Cómo se consulta

- Lee solo el pasaje pertinente (la sección del tema), nunca el archivo entero en un briefing.
- **Guionista**: consulta antes de diseñar lo que toque al capítulo (o al hilo). `canon-previo` acota lo posible; `guia-previa` orienta la intención sin dictar estructura.
- **Director**: pasa el pasaje pertinente al escritor y, como canon, al validador. Nunca envía una `guia-previa` como canon.
- **Validador**: un `canon-previo` o un `## Canon heredado` contradicho es incidencia `bloqueante`.
- **Memoria (novelas)**: el índice de Qdrant (`tipo=referencia`) solo sirve para encontrar qué es relevante; el contenido se lee del archivo (`fijo.origen`).

## Personajes heredados

Si un personaje de una obra previa reaparece, su ficha lleva esta sección, que no se modifica salvo decisión de la persona usuaria:

```markdown
## Canon heredado
- Origen: Cánida (dossier `referencias/canon-canida-1.md`)
- Tiempo transcurrido: dos años y medio desde el epílogo
- Estado al final de la obra previa: declaró contra Silex en el juicio [cap. 40: «…»]
- No contradecir:
  - Padre de Clara y Martín [cap. 11: «…»]
- Evolución permitida: ha cambiado de trabajo; conserva su culpa hacia las familias
```

Las edades y situaciones se calculan desde el estado final más el tiempo transcurrido. Un nombre de la obra que coincida con un personaje de un `canon-previo` sin ficha heredada es un choque: se renombra o se acepta en `colisiones_aceptadas` y se deja explícito en la ficha que no es el mismo personaje.
