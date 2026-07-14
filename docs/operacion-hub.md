# Operacion del hub Forja

Esta guia describe como operar el hub. Los workspaces son autonomos: este documento no sustituye sus instrucciones ni modifica sus pipelines.

## Antes de empezar

Ejecuta `/nuevo-proyecto`, `/rehidratar-relato`, `/importar-relato`, `/nueva-edicion` y `/crear-libro` desde la raiz del hub. Abre un workspace existente con:

```powershell
opencode --cwd "workspaces/<slug>"
```

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
3. Confirma explicitamente el brief final. Solo entonces se crea `workspaces/<slug>/`.
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

Vuelve a una sesion situada en la raiz del hub y ejecuta:

```text
/crear-libro <slug-libro> <workspace1> [workspace2 ...] [--epub] [--pdf] [--pdf-formato <formato>] [--pdf-motor <motor>] [--titulo "<titulo>"] [--autor "<autor>"]
```

Reglas de composicion:

- Una novela forma un libro y requiere exactamente un workspace fuente.
- Una antologia admite uno o varios relatos.
- No se pueden mezclar relatos y novelas ni repetir un workspace fuente.

Ejemplos:

```text
/crear-libro cronicas-del-deseo rutina la-fachada --epub
/crear-libro barniz-de-sangre barniz-de-sangre --epub --pdf --pdf-formato paperback --titulo "Barniz de sangre" --autor "Amaro Alba"
```

El libro se crea en `publicados/<slug-libro>/` con `<slug-libro>.md`, `manifest.json` y, si se pidieron, `<slug-libro>.epub` y `<slug-libro>.pdf`. Cuando todas las salidas solicitadas terminan correctamente, las fuentes pasan de `finalizado` a `publicado`.

Un workspace `publicado` no puede volver a entrar en `/crear-libro` de forma implicita. Para añadir o regenerar formatos de ese mismo libro, usa:

```text
/recompilar-libro <slug-libro> [--epub] [--pdf] [--pdf-formato <formato>] [--pdf-motor <motor>]
```

El comando recompila desde el Markdown congelado y el manifiesto de `publicados/<slug-libro>/`; no lee ni modifica workspaces.

## Flujo 4: corregir un relato publicado

Una corrección de contenido es una edición nueva, no una recompilación. Desde el hub:

```text
/nueva-edicion <workspace-publicado> <slug-edicion> [--titulo "Título"] [--motivo "..."]
```

Solo admite relatos en `publicado`. El original permanece intacto. El hub crea `workspaces/<slug-edicion>/`, conserva la versión de partida en `relato-edicion-anterior.md` y deja el derivado en estado `correccion`.

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

El scaffolder lee `config.json`, `BRIEF.md` y los actos elegidos; valida la semilla, presenta una nueva reflexión editorial y pide confirmación. Solo entonces crea el destino en `diseno` con `H_XXXX`, agentes, skills, comandos y transacciones vigentes. Nunca incorpora guion, draft, fichas, memoria ni manuscrito del origen, y tampoco modifica el origen.

El destino debe tener un slug nuevo. Si después quieres sustituir el workspace legado, archiva primero el origen y realiza el intercambio como una operación explícita separada.

## Flujo 6: importar fuentes narrativas libres

Usa este flujo para ideas dispersas, notas, escaletas, guiones parciales o borradores que no sean un workspace Forja:

```text
/importar-relato <slug-destino> --fuente "<ruta-1>" [--fuente "<ruta-2>" ...]
```

La primera versión admite archivos Markdown y texto plano, incluidos de forma recursiva dentro de las rutas autorizadas. El hub genera un paquete temporal con rutas, hashes y líneas para que el scaffolder extraiga evidencias, hipótesis, conflictos y candidatas. Las fuentes nunca se modifican ni se copian como prosa al destino.

Si hay varias historias o versiones incompatibles, el scaffolder pide elegir antes de generar un brief. Si hay una candidata clara, completa el briefing, recomienda la escala adecuada y solicita la reflexión editorial y confirmación habituales. Tras crear el workspace, elimina el paquete temporal salvo que se pida conservar el informe.

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
| Tengo notas, escaletas o guiones sin estructura Forja. | Usa `/importar-relato` con rutas autorizadas; primero valida la semilla recuperada. |
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
