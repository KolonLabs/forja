---
name: beats-estructura
description: Use ONLY when the user is proponiendo, revisando o desarrollando beats, escenas, capítulos o trenzado de novela multi-hilo. Define el contrato de unidad dramática, formato, identidad, orden, personajes, zonas e hilos.
user-invocable: false
---

# Skill — Estructura de Beats (Novela Multi-Hilo)

## Reglas fundamentales

- Una unidad dramática por beat: acontecimiento, decisión, descubrimiento o inferencia atribuida que aporta un cambio narrativo. Una línea de guion no equivale a una microacción ni a un párrafo de prosa.
- Sin títulos de bloque en la propuesta.
- Sin número fijo de beats por bloque: la cantidad es criterio editorial del director, no una cuota (el exceso solo se juzga como dilución narrativa, no contra un número).
- Los beats crecen hasta que haya masa narrativa suficiente para empaquetar un capítulo.
- Los capítulos se empaquetan por material narrativo, no por una cuota predefinida.
- Cada beat pertenece al menos a un hilo narrativo; varios hilos pueden coexistir en el capítulo.
- Cada beat recibe un `stable_id` opaco e inmutable al crearse.
- `seq` expresa la posición y siempre es local al `parent_id` de la escena.
- El ID de presentación se deriva de `seq` y nunca se almacena.

## Contrato de interpretación

El beat fija un compromiso narrativo, no su ejecución literal. Puede contener varios gestos o intercambios si sirven al mismo acontecimiento. Divide por cambios independientes de objetivo, información, decisión o contexto; no por puntuación, número de verbos, mezcla de tonos o hilos. Tampoco agrupes todo un capítulo bajo una intención vaga: la cobertura debe poder comprobarse.

- **Obligatorio:** hechos, decisiones, consecuencias, restricciones y quién sabe, dice o infiere cada cosa. Una declaración no acredita su verdad; una inferencia no es una certeza ni debe convertirse en confesión de otro personaje.
- **Libre:** palabras, gestos, pausas, detalle, ritmo y enlaces ordinarios compatibles con el canon. No fijes silencios, miradas o reacciones para fabricar tensión si no tienen función necesaria.
- **Ejemplos opcionales:** ilustran posibilidades; no son canon ni una lista que deba aparecer completa. Un ejemplo solo pasa a obligatorio mediante una decisión explícita del director/usuario.

Estas distinciones viven en el objetivo y contexto editorial existente, no en campos nuevos del payload. El director las pasa inline a escritor e integrador, que no cargan skills.

### Acción sin ejecución

- La acción declara el acontecimiento y su consecuencia, sin gestos, miradas, posiciones, adverbios de modo, detalles de ambiente ni valoraciones («sin levantar la vista», «con afabilidad», «ausente, más en su cabeza que en la mesa», «cruza el tráfico de carretillas»).
- El espacio, la utilería y el cast viven en la anotación del beat (`Zona`, `Props`, `Personajes`) y en la cabecera de escena; **la ejecución es del escritor**. Prueba de libertad: dos ejecuciones distintas deben poder cumplir el mismo beat.
- Microcoreografía, pausas impuestas e inferencias redactadas como listas o preguntas son defectos de formulación, no contenido.

### Diálogo e interioridad

El guion establece qué se comunica y qué cambia, no un turno por beat. Revisa la conversación completa: cada réplica responde al intercambio anterior; saludos, despedidas y desplazamientos ordinarios caben en los beats existentes cuando son pertinentes. No exijas un beat por gesto ni omitas un enlace porque no está enumerado.

Una decisión o deducción interior puede ser el cambio narrativo. Define su contenido y grado de certeza sin escribir el pensamiento literal ni sustituirlo automáticamente por una mirada. El escritor construye su voz: inferir no obliga a enumerar datos en cursiva. El tono de la escena puede nacer de lo que comprende el POV mientras otro personaje habla con normalidad.

Reserva `⚡` para palabras exactas exigidas por el usuario o cuya literalidad tenga una función causal documentada (por ejemplo, una clave reconocida después). Sin esa necesidad, fija el contenido verbal, no la réplica literal. Una frase `⚡` vigente sigue siendo obligatoria: ante conflicto, el director resuelve y actualiza el guion antes de escribir; no se elimina ni se recoloca para salvarla a cualquier precio.

### Comprobación antes de entregar

1. ¿Se puede identificar el acontecimiento y su consecuencia sin inventar un hecho nuevo?
2. ¿Queda claro qué es dicho, sabido, inferido y confirmado, y por quién?
3. ¿Dos ejecuciones distintas cumplirían el beat sin cambiar el canon? Si no, revisa si el detalle fijado es realmente obligatorio.
4. ¿La interacción completa tiene una progresión causal, sin preguntas redundantes, confesiones forzadas ni puentes artificiales?
5. ¿La cobertura responde al hecho, sin cuotas de beats ni microcoreografía?
6. ¿La anotación de hilos coincide con la acción y el beat pertenece a los hilos declarados?

### Ejemplos neutrales

- Demasiado prescrito: `Eva responde dejando un silencio tras cada palabra y mirando la taza`.
- Compromiso: `Eva cuenta con normalidad su jornada; Luis relaciona el cambio de horario con una preocupación que ella no menciona`. La preocupación es inferencia de Luis, no reconocimiento de Eva.
- Una unidad: `Luis solicita el cambio de turno y obtiene la autorización`. Pregunta, respuesta y gestos no requieren beats separados.
- Dos cambios independientes: `Luis obtiene el cambio de turno; al salir descubre que han cancelado el tren`. La puntuación no decide: la autorización y el descubrimiento tienen consecuencias distintas.
- Con hilos: `Laura firma el contrato del taller [Obrero — MEDIA] [Laura, Diego] [Zona: taller] [Hilos: hilo-taller]`, aunque la firma materialice una conexión con `hilo-patrimonio`; la conexión se declara cuando cambia algo en ambos.

## Representación técnica

```text
⬜ stable_id [seq] — acción [Tono — EXTENSIÓN] [Personajes] [Zona: nombre] [Hilos: hilo-<slug>]
```

Ejemplo canónico:

```text
⬜ a1b2c3d4 [34] — Laura se arrodilla ante Diego [Opresivo — BREVE] [Laura, Diego] [Zona: salón] [Hilos: hilo-<slug>]
```

- `a1b2c3d4`: `stable_id` inmutable.
- `[34]`: `seq` local a la escena padre.
- `i9j0k1l2 [34]`: display derivado de `seq: 34` al presentar; nunca se persiste.
- Las referencias cruzadas, fichas, `parent_id` y `cola_d.md` usan `stable_id`.

## Componentes

| Componente | Formato | Descripción |
|------------|---------|-------------|
| Acción | Compromiso narrativo concreto | Sujeto + acontecimiento/decisión/inferencia + consecuencia |
| Tono y extensión | `[Tono — EXTENSIÓN]` | Tono narrativo y `BREVE`, `MEDIA` o `EXTENSA` |
| Personajes | `[Nombre, Nombre]` | Personajes presentes y activos |
| Zona | `[Zona: nombre]` | Ubicación espacial del beat |
| Hilos | `[Hilos: hilo-A, hilo-B]` | Hilos narrativos que el beat realiza |

## Ejemplos

```text
✅ a1b2c3d4 [1] — Ricardo desembarca en Villaverde arrastrando la mochila por el muelle [Contemplativo — EXTENSA] [Ricardo] [Zona: muelle de Villaverde] [Hilos: hilo-ricardo]
🔄 e5f6a7b8 [2] — Isabel recibe el informe sobre la desaparición de su hermano [Administrativo — BREVE] [Isabel, Funcionario] [Zona: Ministerio del Interior] [Hilos: hilo-isabel]
⬜ 11223344 [3] — Elena intercepta a Ricardo en el puerto y le ofrece alojamiento [Tenso — MEDIA] [Ricardo, Elena] [Zona: salida del puerto] [Hilos: hilo-ricardo, hilo-elena]
⬜ 55667788 [4] — Isabel soborna al celador para acceder a los expedientes sellados [Clandestino — MEDIA] [Isabel, Celador] [Zona: archivo provincial] [Hilos: hilo-isabel]
```

Estados: ✅ completo · 🔄 en progreso · ⬜ pendiente.

## Orden, inserción y renumeración

Al insertar, eliminar o reordenar hermanos:

1. Identifica el grupo por `parent_id` y, cuando corresponda, por `hilo`.
2. Usa `renumber-siblings` desde el primer `seq` afectado para abrir o cerrar el hueco.
3. Actualiza exclusivamente `seq`.
4. Conserva `stable_id`, `parent_id`, hilo, fichas y referencias externas.
5. Deriva de nuevo displays como `i9j0k1l2 [34]` solo al presentar.

No renumeres beats de otra escena o bloque de hilo por compartir el mismo `seq`. La secuencia siempre es local al padre.

## Reglas de hilos

- Todo beat anota al menos un hilo mediante `[Hilos: hilo-<slug>]`.
- Un beat puede pertenecer a varios hilos cuando estos interactúan.
- Los beats de hilos distintos se trenzan en el guion del capítulo.
- No se fuerza alternancia 1:1; manda la tensión narrativa.
- En capítulos puente, el padre o el filtro `hilo` delimitan los grupos de hermanos que se renumeran.
- La anotación de hilos es planificación y trazabilidad; no convierte la acción en coreografía ni autoriza a exigir en la prosa cada hilo anotado por separado.

## Extensiones y tonos

La extensión (`BREVE`, `MEDIA`, `EXTENSA`) indica peso narrativo relativo: no hay suelo ni techo numérico. El catálogo de tonos está en `tonos-beat`. El guionista asigna la etiqueta; el escritor la desarrolla. El beat del guion siempre ocupa una línea.

## Qué debe tener

- Sujeto claro que actúa, decide, descubre o infiere.
- Acontecimiento concreto y narrable, no solo una intención vaga.
- Consecuencia o cambio.
- Personajes presentes.
- Zona coherente.
- Hilo o hilos narrativos.

## Qué no debe tener

- Estados de ánimo estáticos sin función o cambio narrativo.
- Resumen de intenciones.
- Descripciones sin evento.
- Reflexiones abstractas o pensamientos ya redactados como prosa; si cambia la comprensión del personaje, indica el contenido de la inferencia y su certeza.
- Gestos, posiciones, adverbios de modo o valoraciones que invadan la ejecución del escritor.
- Beats sin hilo asignado.

## Evaluación

| # | Criterio | ¿Pasa? |
|---|----------|--------|
| 1 | ¿Hay un sujeto claro que actúa, decide, descubre o infiere? | |
| 2 | ¿El acontecimiento es narrable y tiene consecuencia? | |
| 3 | ¿Dos ejecuciones distintas podrían cumplir el beat? | |
| 4 | ¿No repite información anterior? | |
| 5 | ¿Progresa el arco? | |
| 6 | ¿Los personajes anotados coinciden con la acción? | |
| 7 | ¿La zona es coherente? | |
| 8 | ¿Tiene al menos un hilo? | |
| 9 | ¿Los hilos son coherentes con la acción? | |
| 10 | ¿`seq` es local al padre y `stable_id` permanece inmutable? | |
