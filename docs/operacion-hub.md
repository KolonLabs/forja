# Operacion del hub Forja

Esta guia describe como operar el hub. Los workspaces son autonomos: este documento no sustituye sus instrucciones ni modifica sus pipelines.

## Antes de empezar

Ejecuta `/nuevo-proyecto`, `/rehidratar-relato`, `/importar-proyecto`, `/nueva-edicion` y `/crear-libro` desde la raiz del hub. Todo lo que produce Forja vive fuera del hub, en `Forja-resultados/` junto al hub (`FORJA_RESULTADOS`; ADR 0026 y 0027): las obras en `Obras/` (`FORJA_OBRAS`) y las antologias en `Publicados/` (`FORJA_PUBLICADOS`). `.\scripts\ruta-obra.ps1 [-Slug <slug>] [-Publicados]` imprime esas rutas. Abre un workspace existente con:

```powershell
opencode --cwd "$(.\scripts\ruta-obra.ps1 -Slug <slug>)"
```

Cada obra es su propio repositorio git. Ni los scripts ni los agentes hacen commits ni crean copias de seguridad: haz commit cuando quieras un punto de restauracion.

Usa slugs en `kebab-case`: minusculas, numeros y guiones simples, por ejemplo `cronicas-del-deseo`.

## Elegir la escala

| Escala | Cuando usarla | Infraestructura |
|---|---|---|
| `relato` | Menos de 20 000 palabras, una lectura y una linea temporal. | No usa Qdrant ni Neo4j. |
| `novela-simple` | Una novela de una linea temporal principal. | Qdrant y Neo4j obligatorios. |
| `novela-multi-hilo` | Varias lineas temporales o POVs con al menos dos hilos narrativos. | Qdrant y Neo4j obligatorios. |

El wizard propone la escala durante el briefing. La opcion `--escala` permite adelantarla, pero no omite las fases obligatorias del briefing ni la confirmacion final.

## Flujo 1: crear un proyecto

1. Desde el hub, ejecuta `/nuevo-proyecto`.
2. Responde al briefing de siete fases: gancho, personajes, mundo, voz y limites, estructura, reflexion y persistencia.
3. Confirma explicitamente el brief final. Solo entonces se crea la obra en la raiz de obras, con `git init` y sin commits.
4. Abre el workspace y ejecuta sus comandos de escritura para desarrollar la obra.

Ejemplos:

```text
/nuevo-proyecto
/nuevo-proyecto "Una restauradora descubre que los cuadros que repara alteran los recuerdos" --titulo "Barniz de sangre" --estilo noir --escala novela-simple
```

El segundo ejemplo solo aporta datos iniciales. El wizard sigue solicitando y validando la informacion que falte.

## Flujo 2: publicar una obra

Dentro del workspace, desarrolla y revisa la obra mediante los comandos disponibles para su escala. Cuando el texto este listo, ejecuta:

```text
/publicar
```

El resultado es un manuscrito limpio en la raiz del workspace:

| Tipo de workspace | Archivo publicado |
|---|---|
| Relato | `relato.md` |
| Novela | `novela.md` |

Al terminar `/publicar`, el director deja el workspace en estado `finalizado`. La compilacion inicial solo acepta ese estado y el manuscrito limpio correspondiente. No compiles borradores, escenas ni beats de forma directa.

## Flujo 3: compilar un libro

Una obra se compila dentro de su propio workspace:

```text
/compilar [--epub] [--pdf] [--pdf-formato <formato>] [--pdf-motor <motor>] [--titulo "<titulo>"] [--autor "<autor>"]
```

Ejemplo:

```text
/compilar --epub --pdf --pdf-formato paperback --titulo "Barniz de sangre"
```

El libro se crea en `publicacion/` dentro de la obra, con `<slug>.md`, `manifest.json` (hash del manuscrito y commit de la obra) y, si se pidieron, `<slug>.epub` y `<slug>.pdf`. Acepta obras en `finalizado` o `publicado`; cuando todas las salidas terminan correctamente, la obra pasa a `publicado`. `publicacion/` no se versiona: se regenera desde el manuscrito.

### Antologias

Para reunir varios relatos, vuelve a una sesion situada en la raiz del hub y ejecuta:

```text
/crear-libro <slug-libro> <relato1> <relato2> [relato3 ...] [--epub] [--pdf] [--pdf-formato <formato>] [--pdf-motor <motor>] [--titulo "<titulo>"] [--autor "<autor>"]
```

Reglas de composicion:

- Una antologia requiere al menos dos relatos en `finalizado`.
- No admite novelas ni fuentes repetidas.

```text
/crear-libro cronicas-del-deseo rutina la-fachada --epub
```

La antologia se crea en `<raiz de publicados>/<slug-libro>/` con `<slug-libro>.md`, `manifest.json` y los formatos pedidos. Cuando todas las salidas terminan correctamente, las fuentes pasan de `finalizado` a `publicado`. Para añadir o regenerar formatos de una antologia, usa:

```text
/recompilar-libro <slug-libro> [--epub] [--pdf] [--pdf-formato <formato>] [--pdf-motor <motor>]
```

El comando recompila desde el Markdown congelado y el manifiesto del libro; no lee ni modifica obras.

## Flujo 4: corregir un relato publicado

Una corrección de contenido es una edición nueva, no una recompilación. Desde el hub:

```text
/nueva-edicion <workspace-publicado> <slug-edicion> [--titulo "Título"] [--motivo "..."]
```

Solo admite relatos en `publicado`. El original permanece intacto. El hub crea la obra `<slug-edicion>` en la raiz de obras, con su propio git y sin el historial del origen, conserva la versión de partida en `relato-edicion-anterior.md` y deja el derivado en estado `correccion`.

Abre ese workspace y ejecuta una pasada completa o puntual:

```text
/corregir completa
/revisar B_0012 ajustar la continuidad del diálogo
/expandir B_0021 hacer más visible la reacción de Laura
/publicar
```

`/publicar` genera el nuevo `relato.md` y pasa la edición a `finalizado`. Después compílala con un slug de libro distinto mediante `/crear-libro`; así la edición anterior y sus formatos permanecen congelados. Las ediciones de novela simple y multi-hilo aún no están soportadas.

## Flujo 5: rehidratar un relato legado

Usa este flujo cuando quieras descartar la producción de un relato creado con un pipeline antiguo y conservar solo su semilla editorial:

```text
/rehidratar-relato <origen> <slug-destino> [--actos actual|backup]
```

El extractor lee `config.json`, `BRIEF.md` y los actos elegidos, pero devuelve solo evidencia editorial. El scaffolder conserva los no negociables confirmados y propone una estructura nueva: puede añadir, fusionar, dividir, reordenar o descartar los hechos heredados. Cada hecho final fija situación o detonante, agencia bajo presión, cambio causal y consecuencia visible; las pautas añaden contexto de rutina o relación, variación y progresión, sin convertirse en beats ni prosa. Tras la reflexión y confirmación, crea el destino en `diseno` con `H_XXXX`, agentes, skills, comandos y transacciones vigentes. Nunca incorpora guion, draft, fichas, memoria ni manuscrito del origen, y tampoco modifica el origen.

El destino debe tener un slug nuevo. Si después quieres sustituir el workspace legado, archiva primero el origen y realiza el intercambio como una operación explícita separada.

## Flujo 6: importar fuentes narrativas libres

Usa este flujo para ideas dispersas, notas, escaletas, guiones parciales o borradores que no sean un workspace Forja:

```text
/importar-proyecto <slug-destino> --fuente "<ruta-o-url-1>" [--fuente "<ruta-o-url-2>" ...]
```

Admite archivos Markdown y texto plano, incluidos de forma recursiva dentro de las rutas autorizadas, y URL HTTPS públicas de texto, Markdown o HTML. El hub genera un paquete temporal con rutas o URL, hashes y líneas para que el scaffolder extraiga evidencias, hipótesis, conflictos y candidatas. Para una URL conserva también el destino final tras redirecciones y el tipo de contenido; rechaza hosts e IP privadas. Las fuentes nunca se modifican ni se copian como prosa al destino.

Si hay varias historias o versiones incompatibles, el scaffolder pide elegir antes de generar un brief. Con una candidata clara, usa la fuente como evidencia, no como escaleta final: propone un argumento más sólido, que puede reorganizar, ampliar o simplificar los elementos heredados. Lo que no esté respaldado se declara como propuesta razonada y se confirma antes de persistir. Tras confirmar la escala, los hechos finales deben aportar detonante, presión, cambio y consecuencia; así el guionista podrá derivar beats sin inventar el núcleo de la historia. Después solicita la reflexión editorial y confirmación habituales. Tras crear el workspace, elimina el paquete temporal salvo que se pida conservar el informe.

## Formatos y requisitos de salida

| Salida | Opcion | Requisitos |
|---|---|---|
| Markdown | Ninguna | Ninguno adicional. Siempre se genera. |
| EPUB | `--epub` | Pandoc. |
| PDF | `--pdf` | Pandoc y Typst, wkhtmltopdf o XeLaTeX. |

Para PDF, `--pdf-motor auto` es el valor predeterminado e intenta Typst, wkhtmltopdf y XeLaTeX, en ese orden. Tambien se puede fijar uno de esos motores. Los formatos validos son:

```text
paperback
paperback-5x8
hardcover
hardcover-9pt
hardcover-6x9
hardcover-6x9-9pt
```

El formato predeterminado es `paperback`. Si Pandoc no esta en el `PATH`, el compilador tambien acepta las variables de entorno `PANDOC_PATH` o `PANDOC`.

## Errores habituales

| Mensaje o situacion | Accion |
|---|---|
| El workspace no esta en estado `finalizado`. | Ejecuta `/publicar` dentro del workspace antes de compilar. |
| Quiero corregir contenido de un relato `publicado`. | Crea `/nueva-edicion`; `/recompilar-libro` no modifica texto. |
| Quiero reiniciar un relato legado desde su brief y hechos. | Usa `/rehidratar-relato`; no usa ni conserva su producción antigua. |
| Tengo notas, escaletas o guiones sin estructura Forja. | Usa `/importar-proyecto` con rutas autorizadas; primero valida la evidencia y la propuesta editorial reconstruida. |
| Falta `relato.md` o `novela.md`. | Publica la obra; no pases archivos ni rutas manuales al comando. |
| Se mezclan relatos y novelas. | Compila una novela sola o usa exclusivamente relatos para la antologia. |
| Falta Pandoc. | Instala Pandoc o define `PANDOC_PATH`/`PANDOC`. |
| No hay motor PDF. | Instala Typst, wkhtmltopdf o una distribucion que incluya XeLaTeX. |
| El slug es invalido. | Usa `kebab-case` sin espacios, mayusculas ni caracteres especiales. |

## Limites del hub

- No modifiques `shared/` para corregir un workspace ya creado: cada workspace conserva una copia aislada de su pipeline.
- No modifiques otro workspace sin permiso explicito.
- El hub crea, publica mediante los comandos del workspace y compila; el contenido narrativo se gestiona dentro de cada workspace.

## Mantenimiento de la documentacion

- Las decisiones estables se registran como ADRs en [decisiones/](decisiones/README.md).
- Los riesgos que aun requieren trabajo se registran en [deuda-tecnica.md](deuda-tecnica.md).
- `AGENTS.md` conserva las reglas y contratos que los agentes deben obedecer; no se usa como historial de cambios.
