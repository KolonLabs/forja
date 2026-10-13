# Guía de uso del workspace — Novela

Esta guía responde **qué comando usar según tu objetivo**. Para el contrato detallado, consulta el archivo del comando en `.opencode/commands/` (opencode) o `.claude/commands/` (Claude Code); para saber el punto exacto del proceso, consulta `config.json.estado` y `PIPELINE.md`.

## Decisión rápida

| Quiero… | Usa | Cuándo | No uses |
|---|---|---|---|
| Afinar hechos antes de desarrollar | `/refinar-hechos` | Un hecho es vago, demasiado amplio o no deja claro qué evolución debe hacerse visible. | Para revisar el ritmo de un guion ya creado. |
| Comprobar que los hechos cuentan una historia coherente | `/validar-hechos` | Quieres detectar contradicciones, huecos o problemas de arco antes de estructurar. | Para corregir prosa. |
| Crear o continuar la novela | `/generar` | El workspace está en el flujo normal: diseño, componentes o escritura. | Para retocar un solo beat. |
| Revisar la estructura antes de escribir | `/revisar-guion` | Hay dudas sobre el reparto de hechos en capítulos, los arcos, el ritmo o las transiciones. | Para cambiar la redacción de un beat. |
| Corregir un fragmento concreto | `/revisar B_XXXX <instrucción>` | Conoces el beat que contiene el problema. | Para una pasada integral de toda la novela. |
| Añadir desarrollo sin cambiar la acción | `/expandir B_XXXX <enfoque>` | Falta detalle sensorial, emocional o físico en un beat. | Para alterar la estructura o el resultado del beat. |
| Generar el manuscrito limpio | `/publicar` | Todos los capítulos están cerrados. | Para corregir prosa: primero usa `/revisar` o `/expandir`. |
| Compilar el libro (EPUB/PDF) | `/compilar [--epub] [--pdf]` | El manuscrito está `finalizado`, o ya `publicado` y quieres regenerar formatos. | Para cambiar el texto: el manuscrito no se toca al compilar. |
| Leer o revisar un capítulo en curso | `/borrador [cap-NN] [--epub] [--pdf]` | Quieres una versión limpia de un capítulo, completo o a medias, con solo sus escenas completas. Sin capítulo, usa el capítulo en curso. No cambia el estado. | Para publicar o para la novela entera: el borrador es siempre de un solo capítulo. |
| Revisar el guion de un capítulo | `/borrador --guion [cap-NN] [--anotado] [--epub] [--pdf]` | Quieres leer los beats como texto, con su etiqueta `B_NNNN` para comentarlos con el director, sin estados, `stable_id` ni marcas; `--anotado` añade tono, extensión, personajes y zona. Sin capítulo, el primero con beats pendientes. No cambia el estado. | Para cambiar el guion: usa `/revisar-guion`. |

`/corregir` no está disponible en novela: es un comando de ediciones derivadas de relato.

## Camino habitual

```text
_actos.md  (actos → hechos)
  ├─ /refinar-hechos          (opcional, recomendado)
  ├─ /validar-hechos          (opcional, recomendado)
  └─ /generar
       ├─ estructura en capítulos     (guion-novela.md)
       ├─ /revisar-guion              (audita arcos, ritmo y cobertura)
       ├─ escritura por escena        (cada escena se presenta y espera tu aprobación)
       │    └─ /revisar o /expandir   (si un fragmento concreto necesita cambios)
       └─ /publicar
            └─ /compilar --epub   (libro en publicacion/)
```

No edites `novela.md` ni los `capitulo.md` directamente: son la salida limpia. Las correcciones se hacen sobre el draft mediante los comandos anteriores.

## Checkpoint de narrativa

Tras generar o corregir una escena, el director te presenta la escena completa con su hash y **se detiene**. Solo tu conformidad y la revisión editorial del mismo hash permiten aceptar y sincronizar. Aprobar una escena no autoriza la siguiente: el avance se pide aparte. Cualquier cambio textual invalida la aprobación anterior. Un fallo de red no regenera prosa: se reintenta la sincronización. `/revisar` y `/expandir` también pasan por este checkpoint.

## Cómo se construye la novela

```text
hechos → capítulos → escenas y beats → prosa
```

- **Hecho**: un evento que debe ocurrir. Vive en `guion-novela.md`, agrupado por actos y repartido en capítulos.
- **Beat**: una unidad dramática dentro de una escena. Se genera al preparar cada capítulo, no antes.
- **Escena**: agrupación de beats por coherencia de contexto; es la unidad de escritura, revisión y checkpoint.
- Un hecho marcado `[D]` es un patrón distribuido: no genera capítulo propio, sus beats se inyectan dentro de otros hechos del rango.

### Identificadores

Cada hecho y cada beat tiene un `stable_id` opaco que **nunca cambia**. El número de posición de un beat es local a su escena y puede cambiar al reordenar; el de los hechos conserva la secuencia de planificación. Cuando uses `/revisar B_0034`, el sistema traduce ese número al `stable_id` real. Si insertas material y los números se desplazan, las referencias internas siguen funcionando.

Para dejar consecutivos los números visibles de un Markdown (`H_XXXX` en `_actos.md`, `B_XXXX` en una tabla de guion), `scripts/renumerar.ps1` hace la parte mecánica:

```text
pwsh -File scripts/renumerar.ps1 _actos.md -LineStart "- H_"                     # simula y muestra la tabla viejo -> nuevo
pwsh -File scripts/renumerar.ps1 _actos.md -LineStart "- H_" -InPlace            # aplica
pwsh -File scripts/renumerar.ps1 capitulos/cap-05/guion.md -LineStart "| B_" -Start 120 -InPlace
```

Solo cambia las líneas que **definen** un identificador (prefijo al inicio de línea, número y separador: ` —`, `:`, ` [` o ` |`). No toca `stable_id`, Qdrant ni las menciones en mitad de línea, notas u otros ficheros.

Lo más cómodo es pedírselo al director: sigue la skill `renumeracion-ids`, que te enseña la simulación, revisa después las referencias con la tabla de cambios y alinea el `seq` en Qdrant si cambió el orden de los beats.

## Estados

```text
diseno → fichas → escritura → publicacion → finalizado
```

| Estado | Qué ocurre | Qué puedes hacer |
|---|---|---|
| `diseno` | Se estructura la novela en actos y capítulos | Afinar hechos, revisar la estructura |
| `fichas` | Se crean y completan las entidades | `/revisar-guion` antes de escribir |
| `escritura` | Se escribe capítulo a capítulo | `/revisar`, `/expandir` |
| `publicacion` | Todos los capítulos cerrados | `/publicar` |
| `finalizado` | Manuscrito listo | `/compilar` |
| `publicado` | Libro compilado en `publicacion/` | `/compilar` para regenerar formatos |

`finalizado` es el último estado que escribe el director. `publicado` lo asigna `/compilar` al generar el libro; no lo escribas a mano.

## Infraestructura

Esta escala **requiere Qdrant y Neo4j operativos**. La memoria de la novela no cabe en un archivo: los resúmenes por capítulo y arco viven en Qdrant, y las relaciones entre personajes en Neo4j.

Si alguno no responde, el director te avisa antes de escribir. No sigas en modo degradado en una novela larga: perderás coherencia sin darte cuenta.

```powershell
python scripts/qdrant.py check
python scripts/neo4j.py check
```

## Compilar el libro

El libro se compila dentro de este workspace con `/compilar [--epub] [--pdf]`: deja el resultado en `publicacion/` y no modifica el manuscrito. El hub solo ensambla antologías de relatos. Las ediciones derivadas (`/nueva-edicion`) todavía no están disponibles para novelas.

## Antes de actuar

1. Lee `config.json.estado`.
2. Consulta `MAPA.md` para localizar el archivo correcto.
3. Si dudas entre estructura y prosa, empieza por `/revisar-guion`; si el problema ya está en un beat, usa `/revisar`.
4. No modifiques archivos de salida limpia a mano. El pipeline no crea copias de seguridad: el historial es el git de la obra; haz commit cuando quieras un punto de restauración.
