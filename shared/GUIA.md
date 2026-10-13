# Guía de uso del workspace

Esta guía responde **qué comando usar según tu objetivo**. Para el contrato detallado, consulta el archivo del comando en `.opencode/commands/` (opencode) o `.claude/commands/` (Claude Code); para saber el punto exacto del proceso, consulta `config.json.estado` y `PIPELINE.md`.

## Decisión rápida

| Quiero… | Usa | Cuándo | No uses |
|---|---|---|---|
| Afinar hechos antes de escribir | `/refinar-hechos` | Un hecho es vago, demasiado amplio o no deja claro qué evolución debe hacerse visible. En `fichas` también se puede: el director revisa después los beats de ese hecho. | Para revisar el ritmo del guion ya creado. |
| Comprobar que los hechos cuentan una historia coherente | `/validar-hechos` | Quieres detectar contradicciones, huecos, fugas de información o problemas de arco. | Para corregir prosa. |
| Crear o continuar la obra | `/generar` | El workspace está en el flujo normal de diseño, componentes o escritura. En escritura confirma una escena y se detiene. | En una edición derivada con estado `correccion`. |
| Revisar la estructura antes de escribir o cerrar | `/revisar-guion` | Hay dudas sobre beats, escenas operativas, ritmo, tonos o salidas visibles. | Para cambiar solo la redacción de un beat. |
| Escribir todas las escenas pendientes de una vez | `/generar completo` | Has revisado las primeras escenas y quieres que el resto se escriba sin parar. Cada escena se valida y confirma por separado. | Si quieres revisar escena a escena. |
| Corregir un fragmento concreto | `/revisar B_XXXX <instrucción>` | Conoces el beat que contiene el cambio. | Para una pasada integral de toda la obra. |
| Añadir desarrollo a un fragmento sin cambiar su acción | `/expandir B_XXXX <enfoque>` | Falta detalle sensorial, emocional, físico o un monólogo. | Para alterar la estructura o el resultado del beat. |
| Corregir estructura o una pasada completa | `/corregir [alcance] <instrucción>` | En `escritura` o en una edición derivada con estado `correccion`. | En el workspace publicado original o en novelas por ahora. |
| Generar el manuscrito limpio | `/publicar` | Todos los beats están cerrados o has terminado una edición derivada. | Para corregir prosa: primero revisa o corrige el draft. |
| Compilar el libro (EPUB/PDF) | `/compilar [--epub] [--pdf]` | El manuscrito está `finalizado`, o ya `publicado` y quieres regenerar formatos. | Para cambiar el texto: el manuscrito no se toca al compilar. |
| Leer o revisar lo escrito hasta ahora | `/borrador [--epub] [--pdf]` | Quieres una versión limpia de la prosa confirmada, sin anclas ni marcadores, para leerla o compartirla. No cambia el estado. | Para publicar: el borrador no es el libro. |

## Camino habitual

```text
_actos.md
  ├─ /refinar-hechos          (opcional, recomendado)
  ├─ /validar-hechos          (opcional, recomendado)
  └─ /generar
       ├─ /revisar-guion      (audita beats, escenas operativas y salidas)
       ├─ /revisar o /expandir (si un beat concreto necesita cambios)
       └─ /publicar
            └─ /compilar --epub   (libro en publicacion/)
```

No edites `relato.md` ni `novela.md` directamente: son la salida limpia. Las correcciones se hacen sobre el draft y los beats mediante los comandos anteriores.

### Cómo se construye un relato

`/generar` trabaja de forma autónoma a partir del arco ya acotado:

```text
H_XXXX (hechos) → B_XXXX (beats globales) → E_XXXX (escenas operativas) → prosa
```

- `H_XXXX` se asigna al crear `_actos.md` y no cambia durante la generación.
- Un `H_XXXX` puede fijar una secuencia causal o una pauta que deba hacerse visible. El guionista construye el mapa global e intercala sus beats representativos con rutina, relación y consecuencias ya respaldadas; no existen `[D]` ni `cola_d.md`.
- `B_XXXX` es una acción causal completa, sin prosa ni cuota de longitud; lleva `[Tono — EXTENSIÓN]` del catálogo `tonos-beat` (uno o dos tonos y `BREVE`, `MEDIA` o `EXTENSA` según el detenimiento que merece dentro de su escena). El guion indica qué ocurre; el escritor decide cómo, incluidas las palabras del diálogo. El rango de diseño es provisional; una vez persistido el guion, su identificador nunca se renumera.
- `E_XXXX` agrupa beats contiguos en una unidad dramática que se escribe en una sola generación. Una situación amplia puede incluir varias escenas operativas.
- La escena no declara arco tonal: su recorrido es la secuencia de tonos de sus beats. `[elipsis]` marca aparte un beat que salta deliberadamente un intervalo.
- `Salida: continua` mantiene la prosa sin corte visible; `Salida: separador` crea `---` en el manuscrito.

El `relato-draft.md` conserva prosa continua por escena. Sus comentarios `<!-- B_XXXX -->` son anclas invisibles para localizar una corrección; no son secciones narrativas y desaparecen al publicar.

El sistema valida el mapa de beats una vez, agrupa escenas y escribe una escena completa cada vez. Se detiene ante contradicción con hechos, restricciones o desenlace fijados, y consulta antes de escribir una escena si una duda pendiente puede cambiar canon o condicionar su prosa; las preferencias editoriales se resuelven de forma autónoma.

Los cambios de hechos, diseño, guion, componentes, escritura, corrección y publicación se preparan internamente en `.forja-transaccion/`. No edites esa carpeta: el director la retoma si sigue siendo válida, la descarta si no lo es y restaura el último estado coherente si una aplicación se interrumpe.

### Renumerar identificadores

Por defecto un `B_XXXX` o `E_XXXX` persistido no se renumera: lo insertado recibe el siguiente número libre (por eso aparecen `B_0101` entre `B_0014` y `B_0015`). Si decides dejar la numeración consecutiva, `scripts/renumerar.ps1` hace la parte mecánica:

```text
pwsh -File scripts/renumerar.ps1 guion.md -LineStart "⬜ B_,🔄 B_,✅ B_"            # simula y muestra la tabla viejo -> nuevo
pwsh -File scripts/renumerar.ps1 guion.md -LineStart "⬜ B_,🔄 B_,✅ B_" -InPlace   # aplica
pwsh -File scripts/renumerar.ps1 guion.md -LineStart "### E_" -InPlace
pwsh -File scripts/renumerar.ps1 _actos.md -LineStart "- H_" -InPlace
```

Solo cambia las líneas que **definen** un identificador: prefijo al inicio de línea, número y separador (` —`; `-Start` fija el primer número). Las menciones en mitad de línea, las notas y los demás ficheros (`relato-draft.md` con sus anclas `<!-- B_XXXX -->`, `correcciones.md`, `contexto_narrativo.md`, fichas, `config.json`) conservan los números viejos.

Lo más cómodo es pedírselo al director («renumera los beats del guion»): sigue la skill `renumeracion-ids`, que ejecuta el script dentro de una transacción, te enseña la simulación y revisa después las referencias con la tabla de cambios. Mejor antes de escribir escenas.

## Estados

### Relato

```text
diseno → fichas → escritura → finalizado → publicado (/compilar)
```

- `diseno`: permite afinar hechos y el contexto de sus patrones. Los cambios autorizados de hechos actualizan `_actos.md` y su contador juntos; `/revisar-guion` aquí diagnostica los insumos y `/generar` construye el primer guion.
- `fichas`: permite revisar y ajustar el guion antes de empezar prosa; `/revisar-guion` lo confirma de forma transaccional sin cambiar de estado. Un hecho todavía puede cambiar con `/refinar-hechos`: queda pendiente de revisión y la escritura no empieza hasta que el director revisa sus beats.
- `escritura`: confirma una escena completa por vez. El draft es un prefijo de escenas ya cerradas; `/revisar`, `/expandir` y `/corregir` solo modifican prosa de ese prefijo.
- `finalizado`: el manuscrito está listo para compilar con `/compilar`.
- `publicado`: el libro está en `publicacion/` y `/compilar` puede regenerar sus formatos. No reabras el original: si cambia el contenido, crea una edición derivada desde el hub.

Una edición derivada de relato sigue este camino:

```text
publicado (origen) → correccion (edición derivada) → finalizado → publicado (/compilar)
```

En `correccion`, usa `/corregir`, `/revisar` o `/expandir`; conserva `relato-edicion-anterior.md` como referencia y termina con `/publicar`.

### Novelas

Usa siempre el estado y las fases de `PIPELINE.md` de tu workspace. La migración de novela simple y multi-hilo al contrato `finalizado` y a las ediciones derivadas está pendiente; por eso `/corregir` no está disponible aún para novelas.

## Comandos del hub: fuera de este workspace

Vuelve a la raíz de Forja para estas operaciones:

| Objetivo | Comando del hub |
|---|---|
| Abrir una edición corregible de un relato publicado | `/nueva-edicion <origen> <slug-edicion>` |
| Reiniciar un relato legado desde su semilla editorial | `/rehidratar-relato <origen> <slug-destino>` |
| Recuperar una obra desde notas, guiones libres o una URL pública | `/importar-proyecto <slug-destino> --fuente "<ruta-o-url>"` |
| Reunir varios relatos terminados en una antología | `/crear-libro <slug-libro> <workspace1> <workspace2...>` |
| Añadir o regenerar EPUB/PDF de una antología | `/recompilar-libro <slug-libro> --epub/--pdf` |

El libro de esta obra se compila aquí con `/compilar`; el hub solo ensambla antologías. `/recompilar-libro` no cambia contenido. Una corrección textual requiere `/nueva-edicion` (solo relatos por ahora). `/rehidratar-relato` extrae la semilla de un relato legado como evidencia y propone una estructura nueva antes de crear el workspace; `/importar-proyecto` analiza notas o guiones libres como evidencia, propone un argumento reforzado y permite confirmar tanto la escala como las ampliaciones antes de crear el brief.

## Antes de actuar

1. Lee `config.json.estado`.
2. Consulta `MAPA.md` para localizar el archivo correcto.
3. Si dudas entre estructura y prosa, empieza por `/revisar-guion`; si el problema ya está localizado en un beat, usa `/revisar`.
4. No modifiques archivos de salida limpia a mano. El pipeline no crea copias de seguridad: el historial es el git de la obra; haz commit cuando quieras un punto de restauración.
