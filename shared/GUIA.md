# Guía de uso del workspace

Esta guía responde **qué comando usar según tu objetivo**. Para el contrato detallado, consulta el archivo del comando en `.opencode/commands/`; para saber el punto exacto del proceso, consulta `config.json.estado` y `PIPELINE.md`.

## Decisión rápida

| Quiero… | Usa | Cuándo | No uses |
|---|---|---|---|
| Afinar hechos antes de desarrollar | `/refinar-hechos` | Un hecho es vago, demasiado amplio o un `[D]` no tiene rango/anotaciones claros. | Para revisar el ritmo del guion ya creado. |
| Comprobar que los hechos cuentan una historia coherente | `/validar-hechos` | Quieres detectar contradicciones, huecos, fugas de información o problemas de arco. | Para corregir prosa. |
| Crear o continuar la obra | `/generar` | El workspace está en el flujo normal de diseño, componentes o escritura. | En una edición derivada con estado `correccion`. |
| Revisar la estructura antes de escribir o cerrar | `/revisar-guion` | Hay dudas sobre escenas, arcos, ritmo, transiciones o trenzado. | Para cambiar solo la redacción de un beat. |
| Corregir un fragmento concreto | `/revisar B_NNNN <instrucción>` | Conoces el beat o puedes describirlo con suficiente precisión. | Para una pasada integral de toda la obra. |
| Añadir desarrollo a un fragmento sin cambiar su acción | `/expandir B_NNNN <enfoque>` | Falta detalle sensorial, emocional, físico o un monólogo. | Para alterar la estructura o el resultado del beat. |
| Corregir una edición completa de un relato publicado | `/corregir [alcance] <instrucción>` | Solo en un relato derivado con estado `correccion`. | En el workspace publicado original o en novelas por ahora. |
| Generar el manuscrito limpio | `/publicar` | Todos los beats están cerrados o has terminado una edición derivada. | Para corregir prosa: primero revisa o corrige el draft. |

## Camino habitual

```text
_actos.md
  ├─ /refinar-hechos          (opcional, recomendado)
  ├─ /validar-hechos          (opcional, recomendado)
  └─ /generar
       ├─ /revisar-guion      (si la estructura necesita ajustes)
       ├─ /revisar o /expandir (si un beat concreto necesita cambios)
       └─ /publicar
```

No edites `relato.md` ni `novela.md` directamente: son la salida limpia. Las correcciones se hacen sobre el draft y los beats mediante los comandos anteriores.

## Estados

### Relato

```text
diseno → fichas → escritura → finalizado → publicado (hub)
```

- `diseno`, `fichas`, `escritura`: usa `/generar` para avanzar o los comandos de revisión cuando corresponda.
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
