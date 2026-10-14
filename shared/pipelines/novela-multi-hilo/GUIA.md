# Guía de uso del workspace — Novela multi-hilo

Esta guía responde **qué comando usar según tu objetivo**. Para el contrato detallado, consulta el archivo del comando en `.opencode/commands/` (opencode) o `.claude/commands/` (Claude Code); para saber el punto exacto del proceso, consulta `config.json.estado` y `PIPELINE.md`.

## Decisión rápida

| Quiero… | Usa | Cuándo | No uses |
|---|---|---|---|
| Afinar hechos antes de desarrollar | `/refinar-hechos` | Un hecho es vago, demasiado amplio o no deja claro qué evolución debe hacerse visible. | Para revisar el ritmo de un guion ya creado. |
| Comprobar que los hechos cuentan una historia coherente | `/validar-hechos` | Quieres detectar contradicciones, huecos o problemas de arco antes de diseñar los hilos. | Para corregir prosa. |
| Crear o continuar la novela | `/generar` | El workspace está en el flujo normal: diseño, hilos, trenzado, componentes o escritura. | Para retocar un solo beat. |
| Revisar la estructura antes de escribir | `/revisar-guion` | Hay dudas sobre el trenzado, el reparto de hechos entre hilos, el ritmo o las transiciones. | Para cambiar la redacción de un beat. |
| Corregir un fragmento concreto | `/revisar B_XXXX <instrucción>` | Conoces el beat que contiene el problema. | Para una pasada integral de toda la novela. |
| Añadir desarrollo sin cambiar la acción | `/expandir B_XXXX <enfoque>` | Falta detalle sensorial, emocional o físico en un beat. | Para alterar la estructura o el resultado del beat. |
| Generar el manuscrito limpio | `/publicar` | Todos los capítulos de la tabla de Trenzado están cerrados. | Para corregir prosa: primero usa `/revisar` o `/expandir`. |
| Compilar el libro (EPUB/PDF) | `/compilar [--epub] [--pdf]` | El manuscrito está `finalizado`, o ya `publicado` y quieres regenerar formatos. La cubierta del EPUB es `imagenes/portada.jpg` (requisitos en `imagenes/LEEME.md`). | Para cambiar el texto: el manuscrito no se toca al compilar. |
| Leer o revisar un capítulo en curso | `/borrador [cap-NN] [--epub] [--pdf]` | Quieres una versión limpia de un capítulo, completo o a medias, con solo sus escenas completas. Sin capítulo, usa el capítulo en curso. No cambia el estado. | Para publicar o para la novela entera: el borrador es siempre de un solo capítulo. |
| Revisar el guion de un capítulo | `/borrador --guion [cap-NN] [--hilo <hilo>] [--anotado] [--epub] [--pdf]` | Quieres leer los beats como texto, con su etiqueta `B_NNNN` para comentarlos con el director, sin estados, `stable_id` ni marcas; `--anotado` añade tono, extensión, personajes y zona. Sin capítulo, el primero con beats pendientes. En multi-hilo, antes de ensamblar, indica el hilo. No cambia el estado. | Para cambiar el guion: usa `/revisar-guion`. |

`/corregir` no está disponible en novela: es un comando de ediciones derivadas de relato.

## Camino habitual

```text
_actos.md  (hilos → actos → hechos)
  ├─ /refinar-hechos          (opcional, recomendado)
  ├─ /validar-hechos          (opcional, recomendado)
  └─ /generar
       ├─ diseño de cada hilo         (conversación contigo)
       ├─ beats y escenas por hilo    (checkpoints por capítulo-borrador)
       ├─ trenzado de escenas         (conversación contigo)
       ├─ /revisar-guion              (audita trenzado, ritmo y cobertura)
       ├─ escritura por escena        (tras el trenzado; cada escena se presenta y espera tu aprobación)
       │    └─ /revisar o /expandir   (si un fragmento concreto necesita cambios)
       └─ /publicar
            └─ /compilar --epub   (libro en publicacion/)
```

No edites `novela.md` ni los `capitulo.md` directamente: son la salida limpia. Las correcciones se hacen sobre el draft mediante los comandos anteriores.

## Checkpoint de narrativa

Tras el trenzado, la novela se escribe **escena a escena**. Tras generar o corregir una escena, el director te presenta la escena completa con su hash y **se detiene**. Solo tu conformidad y la revisión editorial del mismo hash permiten aceptar y sincronizar. Aprobar una escena no autoriza la siguiente: el avance se pide aparte. Cualquier cambio textual invalida la aprobación anterior. Los checkpoints de estructura de los hilos (capítulos-borrador) y de costuras del guion siguen existiendo y son otra capa, no sustitutos.

## Cómo se construye la novela

```text
hilos → hechos por hilo → beats y escenas por hilo → trenzado de escenas → capítulos → prosa
```

- **Hilo**: una línea narrativa con época, ubicación, elenco, conflicto y tono propios. Un hilo se diseña, se guioniza y se desarrolla en beats **aislado**, como si fuera una novela corta independiente — hasta que se trenza con los demás.
- **Hecho**: un evento que debe ocurrir. Vive en `hilos/hilo-<slug>/guion-hilo.md`. Sin beats todavía.
- **Beat**: una unidad dramática con compromiso verificable. Se genera **dentro de cada hilo**, antes de que exista ningún capítulo global — no al preparar el capítulo.
- **Escena**: agrupación de beats por coherencia de contexto (mismo espacio/tiempo/cast). Nace dentro del hilo y es la unidad real que se trenza.
- **Trenzado**: mueve las escenas ya escritas de cada hilo a los capítulos globales de `guion-novela.md`, decidiendo en qué capítulo entra cada una. Es donde la novela deja de ser varios relatos y pasa a ser una sola obra.

### Tipos de capítulo

| Tipo | Qué es | Cómo se lee |
|---|---|---|
| **Exclusivo** | Un solo hilo ocupa el capítulo | Inmersión continua en una época |
| **Puente** | Dos hilos en bloques separados por `---` | El lector salta de época dentro del mismo capítulo |
| **Espejo** | Dos hilos alternados mostrando paralelismos | Dos épocas rimando gesto a gesto |

Reglas que el sistema respeta y audita solo: máximo 2 hilos por capítulo, ningún hilo desaparece más de 3 capítulos seguidos, y el clímax de cada hilo cae en capítulo exclusivo.

### Identificadores

Cada hecho y cada beat tiene un `stable_id` opaco que **nunca cambia**. El número de posición de un beat es local a su escena; el de los hechos conserva la secuencia de planificación. Cuando uses `/revisar B_0034`, el sistema traduce ese número al `stable_id` real. Si insertas material y los números se desplazan, las referencias internas siguen funcionando.

Para dejar consecutivos los `H_XXXX` visibles de un Markdown (`_actos.md`, `guion-hilo.md`), `scripts/renumerar.ps1` hace la parte mecánica:

```text
pwsh -File scripts/renumerar.ps1 _actos.md -LineStart "- H_"            # simula y muestra la tabla viejo -> nuevo
pwsh -File scripts/renumerar.ps1 _actos.md -LineStart "- H_" -InPlace   # aplica
```

Solo cambia las líneas que **definen** un identificador (prefijo al inicio de línea, número y separador: ` —`, `:`, ` [` o ` |`; primer número con `-Start`). No toca `stable_id`, Qdrant ni las menciones en mitad de línea, notas u otros ficheros (rangos `[D · H_0091–H_0096]`, `guion-hilo.md`, `cola_d.md`). Los beats de los guiones de capítulo (`stable_id [seq]`) no usan este formato.

Lo más cómodo es pedírselo al director: sigue la skill `renumeracion-ids`, que te enseña la simulación y revisa después las referencias con la tabla de cambios.

## Estados

```text
diseno → diseno_hilos → hilos_beats → trenzado → fichas → escritura → publicacion → finalizado
```

| Estado | Qué ocurre | Qué puedes hacer |
|---|---|---|
| `diseno` | Se identifican hilos, conexiones y entidades semilla | Afinar hechos, definir hilos |
| `diseno_hilos` | Se diseña y guioniza cada hilo por separado (solo hechos) | Iterar el arco de cada hilo |
| `hilos_beats` | Se generan beats y escenas dentro de cada hilo, aislado | Revisar checkpoints de escenas por hilo |
| `trenzado` | Se entrelazan las escenas de los hilos en capítulos globales | Revisar y ajustar la tabla |
| `fichas` | Se completan entidades y conexiones cross-hilo | `/revisar-guion` antes de escribir |
| `escritura` | Se escribe por escena, con checkpoint humano; costuras cross-hilo auditadas | `/revisar`, `/expandir` |
| `publicacion` | Todos los capítulos cerrados | `/publicar` |
| `finalizado` | Manuscrito listo | `/compilar` |
| `publicado` | Libro compilado en `publicacion/` | `/compilar` para regenerar formatos |

`finalizado` es el último estado que escribe el director. `publicado` lo asigna `/compilar` al generar el libro; no lo escribas a mano.

## Infraestructura

Esta escala **requiere Qdrant y Neo4j operativos**. La memoria de la novela no cabe en un archivo: los resúmenes por capítulo y arco viven en Qdrant, y las relaciones entre personajes —incluidas las que cruzan épocas— en Neo4j.

Si alguno no responde, el director te avisa antes de escribir. No sigas en modo degradado en una novela larga: perderás coherencia cross-hilo sin darte cuenta.

```powershell
python scripts/qdrant.py check
python scripts/neo4j.py check
```

## Compilar el libro

El libro se compila dentro de este workspace con `/compilar [--epub] [--pdf]`: deja el resultado en `publicacion/` y no modifica el manuscrito. La cubierta del EPUB es `imagenes/portada.jpg` (o `.png`; requisitos en `imagenes/LEEME.md`) y el subtítulo del libro, si lo tiene, `config.json.subtitulo`. El hub solo ensambla antologías de relatos. Las ediciones derivadas (`/nueva-edicion`) todavía no están disponibles para novelas.

## Antes de actuar

1. Lee `config.json.estado` y `config.json.hilos[].estado`.
2. Consulta `MAPA.md` para localizar el archivo correcto.
3. Si dudas entre estructura y prosa, empieza por `/revisar-guion`; si el problema ya está en un beat, usa `/revisar`.
4. No modifiques archivos de salida limpia a mano. El pipeline no crea copias de seguridad: el historial es el git de la obra; haz commit cuando quieras un punto de restauración.
