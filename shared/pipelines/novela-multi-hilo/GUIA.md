# Guía de uso del workspace — Novela multi-hilo

Esta guía responde **qué comando usar según tu objetivo**. Para el contrato detallado, consulta el archivo del comando en `.opencode/commands/`; para saber el punto exacto del proceso, consulta `config.json.estado` y `PIPELINE.md`.

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

`/corregir` no está disponible en novela: es un comando de ediciones derivadas de relato.

## Camino habitual

```text
_actos.md  (hilos → actos → hechos)
  ├─ /refinar-hechos          (opcional, recomendado)
  ├─ /validar-hechos          (opcional, recomendado)
  └─ /generar
       ├─ diseño de cada hilo         (conversación contigo)
       ├─ trenzado en capítulos       (conversación contigo)
       ├─ /revisar-guion              (audita trenzado, ritmo y cobertura)
       ├─ escritura capítulo a capítulo
       │    └─ /revisar o /expandir   (si un beat concreto necesita cambios)
       └─ /publicar
```

No edites `novela.md` ni los `capitulo.md` directamente: son la salida limpia. Las correcciones se hacen sobre el draft mediante los comandos anteriores.

## Cómo se construye la novela

```text
hilos → hechos por hilo → tabla de Trenzado → capítulos → beats → prosa
```

- **Hilo**: una línea narrativa con época, ubicación, elenco, conflicto y tono propios. Un hilo se diseña y se guioniza **aislado**, como si fuera una novela corta independiente.
- **Hecho**: un evento que debe ocurrir. Vive en `hilos/hilo-<slug>/guion-hilo.md`. Sin beats todavía.
- **Trenzado**: la tabla de `guion-novela.md` que decide en qué capítulo global entra cada hecho y de qué hilo. Es donde la novela deja de ser varios relatos y pasa a ser una sola obra.
- **Beat**: una acción concreta dentro de un capítulo. Se genera al preparar cada capítulo, no antes.

### Tipos de capítulo

| Tipo | Qué es | Cómo se lee |
|---|---|---|
| **Exclusivo** | Un solo hilo ocupa el capítulo | Inmersión continua en una época |
| **Puente** | Dos hilos en bloques separados por `---` | El lector salta de época dentro del mismo capítulo |
| **Espejo** | Dos hilos alternados mostrando paralelismos | Dos épocas rimando gesto a gesto |

Reglas que el sistema respeta y audita solo: máximo 2 hilos por capítulo, ningún hilo desaparece más de 3 capítulos seguidos, y el clímax de cada hilo cae en capítulo exclusivo.

### Identificadores

Cada hecho y cada beat tiene un `stable_id` opaco que **nunca cambia** y un número de posición que sí puede cambiar al reordenar. Cuando uses `/revisar B_0034`, el sistema traduce ese número al `stable_id` real. Si insertas material y los números se desplazan, las referencias internas siguen funcionando.

## Estados

```text
diseno → diseno_hilos → trenzado → fichas → escritura → publicacion → finalizado
```

| Estado | Qué ocurre | Qué puedes hacer |
|---|---|---|
| `diseno` | Se identifican hilos, conexiones y entidades semilla | Afinar hechos, definir hilos |
| `diseno_hilos` | Se diseña y guioniza cada hilo por separado | Iterar el arco de cada hilo |
| `trenzado` | Se entrelazan los hilos en capítulos globales | Revisar y ajustar la tabla |
| `fichas` | Se completan entidades y conexiones cross-hilo | `/revisar-guion` antes de escribir |
| `escritura` | Se escribe capítulo a capítulo | `/revisar`, `/expandir` |
| `publicacion` | Todos los capítulos cerrados | `/publicar` |
| `finalizado` | Manuscrito listo | Compilar desde el hub |

`finalizado` es el estado terminal de este workspace. `publicado` lo asigna el hub al compilar el libro; no lo escribas a mano.

## Infraestructura

Esta escala **requiere Qdrant y Neo4j operativos**. La memoria de la novela no cabe en un archivo: los resúmenes por capítulo y arco viven en Qdrant, y las relaciones entre personajes —incluidas las que cruzan épocas— en Neo4j.

Si alguno no responde, el director te avisa antes de escribir. No sigas en modo degradado en una novela larga: perderás coherencia cross-hilo sin darte cuenta.

```powershell
python scripts/qdrant.py check
python scripts/neo4j.py check
```

## Comandos del hub: fuera de este workspace

Vuelve a la raíz de Forja para estas operaciones:

| Objetivo | Comando del hub |
|---|---|
| Crear un libro desde la novela terminada | `/crear-libro <slug-libro> <workspace>` |
| Añadir o regenerar EPUB/PDF sin cambiar el texto | `/recompilar-libro <slug-libro> --epub/--pdf` |

`/recompilar-libro` no cambia contenido. Las ediciones derivadas (`/nueva-edicion`) todavía no están disponibles para novelas.

## Antes de actuar

1. Lee `config.json.estado` y `config.json.hilos[].estado`.
2. Consulta `MAPA.md` para localizar el archivo correcto.
3. Si dudas entre estructura y prosa, empieza por `/revisar-guion`; si el problema ya está en un beat, usa `/revisar`.
4. Conserva los backups que crea el director y no modifiques archivos de salida limpia a mano.
