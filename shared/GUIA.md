# Guía de uso del workspace

Esta guía responde **qué comando usar según tu objetivo**. Para el contrato detallado, consulta el archivo del comando en `.opencode/commands/`; para saber el punto exacto del proceso, consulta `config.json.estado` y `PIPELINE.md`.

## Decisión rápida

| Quiero… | Usa | Cuándo | No uses |
|---|---|---|---|
| Afinar hechos antes de desarrollar | `/refinar-hechos` | Un hecho es vago, demasiado amplio o un `[D]` no tiene rango/anotaciones claros. | Para revisar el ritmo del guion ya creado. |
| Comprobar que los hechos cuentan una historia coherente | `/validar-hechos` | Quieres detectar contradicciones, huecos, fugas de información o problemas de arco. | Para corregir prosa. |
| Crear o continuar la obra | `/generar` | El workspace está en el flujo normal de diseño, componentes o escritura. | En una edición derivada con estado `correccion`. |
| Revisar la estructura antes de escribir o cerrar | `/revisar-guion` | Hay dudas sobre beats, escenas operativas, ritmo, registros o salidas visibles. | Para cambiar solo la redacción de un beat. |
| Corregir un fragmento concreto | `/revisar B_XXXX <instrucción>` | Conoces el beat que contiene el cambio. | Para una pasada integral de toda la obra. |
| Añadir desarrollo a un fragmento sin cambiar su acción | `/expandir B_XXXX <enfoque>` | Falta detalle sensorial, emocional, físico o un monólogo. | Para alterar la estructura o el resultado del beat. |
| Corregir estructura o una pasada completa | `/corregir [alcance] <instrucción>` | En `escritura` o en una edición derivada con estado `correccion`. | En el workspace publicado original o en novelas por ahora. |
| Generar el manuscrito limpio | `/publicar` | Todos los beats están cerrados o has terminado una edición derivada. | Para corregir prosa: primero revisa o corrige el draft. |

## Camino habitual

```text
_actos.md
  ├─ /refinar-hechos          (opcional, recomendado)
  ├─ /validar-hechos          (opcional, recomendado)
  └─ /generar
       ├─ /revisar-guion      (audita beats, escenas operativas y salidas)
       ├─ /revisar o /expandir (si un beat concreto necesita cambios)
       └─ /publicar
```

No edites `relato.md` ni `novela.md` directamente: son la salida limpia. Las correcciones se hacen sobre el draft y los beats mediante los comandos anteriores.

### Cómo se construye un relato

`/generar` trabaja de forma autónoma a partir del arco ya acotado:

```text
H_XXXX (hechos) → B_XXXX (beats globales) → E_XXXX (escenas operativas) → prosa
```

- `H_XXXX` se asigna al crear `_actos.md` y no cambia durante la generación.
- `B_XXXX` es una acción causal, sin prosa ni cuota de longitud. El rango de diseño es provisional; una vez persistido el guion, su identificador nunca se renumera.
- `E_XXXX` agrupa beats contiguos en una unidad dramática que se escribe en una sola generación. Una situación amplia puede incluir varias escenas operativas.
- La escena define un arco tonal; un beat solo añade `[registro: ...]` cuando requiere un tratamiento distinto, por ejemplo explícito o visceral.
- `Salida: continua` mantiene la prosa sin corte visible; `Salida: separador` crea `---` en el manuscrito.

El `relato-draft.md` conserva prosa continua por escena. Sus comentarios `<!-- B_XXXX -->` son anclas invisibles para localizar una corrección; no son secciones narrativas y desaparecen al publicar.

El sistema valida el mapa de beats una vez, agrupa escenas y escribe una escena completa cada vez. Se detiene únicamente ante contradicción con hechos, restricciones o desenlace fijados; las preferencias editoriales se resuelven de forma autónoma.

Los cambios de hechos, diseño, guion, componentes, escritura, corrección y publicación se preparan internamente en `.forja-transaccion/`. No edites esa carpeta: el director la retoma si sigue siendo válida, la descarta si no lo es y restaura el último estado coherente si una aplicación se interrumpe.

## Estados

### Relato

```text
diseno → fichas → escritura → finalizado → publicado (hub)
```

- `diseno`: permite afinar hechos y recurrencias. Los cambios autorizados de hechos actualizan `_actos.md` y su contador juntos; `/revisar-guion` aquí diagnostica los insumos y `/generar` construye el primer guion.
- `fichas`: permite revisar y ajustar el guion antes de empezar prosa; `/revisar-guion` lo confirma de forma transaccional sin cambiar de estado.
- `escritura`: confirma una escena completa por vez. El draft es un prefijo de escenas ya cerradas; `/revisar`, `/expandir` y `/corregir` solo modifican prosa de ese prefijo.
- `finalizado`: el manuscrito está listo para compilar desde el hub.
- `publicado`: no reabras el original. Si cambia el contenido, crea una edición derivada desde el hub.

Una edición derivada de relato sigue este camino:

```text
publicado (origen) → correccion (edición derivada) → finalizado → publicado (hub)
```

En `correccion`, usa `/corregir`, `/revisar` o `/expandir`; conserva `relato-edicion-anterior.md` como referencia y termina con `/publicar`.

### Novelas

Usa siempre el estado y las fases de `PIPELINE.md` de tu workspace. La migración de novela simple y multi-hilo al contrato `finalizado` y a las ediciones derivadas está pendiente; por eso `/corregir` no está disponible aún para novelas.

## Comandos del hub: fuera de este workspace

Vuelve a la raíz de Forja para estas operaciones:

| Objetivo | Comando del hub |
|---|---|
| Abrir una edición corregible de un relato publicado | `/nueva-edicion <origen> <slug-edicion>` |
| Crear un libro desde una obra terminada | `/crear-libro <slug-libro> <workspace...>` |
| Añadir o regenerar EPUB/PDF sin cambiar el texto | `/recompilar-libro <slug-libro> --epub/--pdf` |

`/recompilar-libro` no cambia contenido. Una corrección textual requiere `/nueva-edicion` (solo relatos por ahora).

## Antes de actuar

1. Lee `config.json.estado`.
2. Consulta `MAPA.md` para localizar el archivo correcto.
3. Si dudas entre estructura y prosa, empieza por `/revisar-guion`; si el problema ya está localizado en un beat, usa `/revisar`.
4. Conserva los backups que crea el director y no modifiques archivos de salida limpia a mano.
