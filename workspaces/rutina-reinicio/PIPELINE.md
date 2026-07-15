# Pipeline — Relato (4 fases)

Relato trabaja solo con archivos Markdown locales. No usa Qdrant, Neo4j ni identidad opaca.

## Contrato canónico

```text
H_XXXX (hechos de briefing)
  → B_XXXX (beats globales: acción, no prosa)
  → E_XXXX (escenas operativas, manejables para una generación)
  → relato-draft.md (prosa continua por E, con anclas invisibles de B)
  → relato.md (manuscrito limpio)
```

| ID | Función |
|---|---|
| `H_XXXX` | Hecho del briefing. Se congela al iniciar la escritura. |
| `B_XXXX` | Acción causal mínima. Es global, único y no se renumera tras persistirse. |
| `E_XXXX` | Unidad dramática y de generación. Agrupa beats contiguos y no se renumera tras persistirse. |

El orden en `guion.md` es el orden narrativo. Los IDs solo identifican: no existen `stable_id`, `parent_id`, `seq` ni UUID. `config.json.ultimo_hecho_seq`, `ultimo_beat_seq` y `ultimo_escena_seq` son los contadores canónicos: el director asigna desde contador + 1 y los actualiza al persistir, sin recalcularlos ni reutilizar IDs retirados.

Un beat contiene únicamente acción, consecuencia y, cuando difiere del arco tonal de su escena, un registro opcional: `[registro: explícito / visceral]`. No contiene hecho de origen, prosa, extensión, sensorialidad ni psicología.

## FASE 1 — Diseño (`diseno`)

1. **Preparar.** El director verifica `H_XXXX` y restricciones. Un hecho puede contener una secuencia causal o un patrón que deba hacerse perceptible, pero relato no usa marcas `[D]` ni artefactos de recurrencia separados.
2. **Mapa global provisional.** El director lee `ultimo_beat_seq`, fija el primer `B_XXXX` disponible y se lo comunica al guionista. El guionista lee el arco completo y genera un único mapa de beats con cobertura temporal `H → B`. Materializa los patrones explícitos de hechos y brief mediante beats ordinarios, escogiendo instancias representativas e intercalándolas con beats de rutina, relación o consecuencia ya respaldados por el arco. Mientras no se persista el guion, los IDs son provisionales y no sobreviven a una interrupción.
3. **Diagnóstico único.** `auditor-beats` revisa cobertura, causalidad, atomicidad, fugas de información, ausencia de prosa y que una pauta explícita no quede como una sucesión plana o invisible. Solo los problemas bloqueantes se reparan, en una única pasada.
4. **Escenas.** El guionista agrupa beats en `E_XXXX`. Una situación amplia puede contener varias escenas operativas si existe un giro de objetivo, información, poder, foco o resultado. Cada escena declara arco tonal y `Salida: continua | separador`.
5. **Persistencia recuperable.** El director completa en el staging `guion.md` y `config.json`. Confirma solo si el helper valida estructura, transición y contadores.
6. **Gate mecánico.** El director comprueba pertenencia única de beats, orden narrativo y salidas coherentes. No hay una segunda auditoría estética por defecto.

Si un gate falla antes de confirmar, el director ejecuta `-Accion Descartar`; los artefactos vivos quedan intactos. Tras una interrupción, `-Accion Recuperar` restaura un commit interrumpido o conserva un staging preparado para reanudarlo. Solo se descarta ese staging si ya no es válido.

Si para hacer perceptible un patrón el guionista necesitara un giro irreversible, una relación, una revelación o un desenlace no contenidos en el arco, el director presenta ese bloqueo: no inventa ni altera `H_XXXX` sin autorización.

**Transición:** `estado = fichas`, confirmada por `diseno`.

## FASE 2 — Componentes (`fichas`)

1. El director crea las fichas necesarias para la primera escena y las entidades recurrentes o críticas para continuidad.
2. Las fichas restantes se crean bajo demanda cuando una escena las necesita.
3. Prepara una transacción `componentes`, inicializa en staging `contexto_narrativo.md` y `relato-draft.md` mediante `plantilla-draft`, deja `config.json.estado = "escritura"` y confirma el conjunto.

**Gate:** la próxima escena puede escribirse con información consistente. No se ficha toda mención incidental del guion.

**Transición:** `estado = escritura`, confirmada por `componentes`.

## FASE 3 — Escritura por escena (`escritura`)

En una misma invocación de `/generar`, el director recorre todas las `E_XXXX` pendientes en orden. Cada escena sigue siendo una unidad de generación y una transacción independiente; una confirmación correcta continúa automáticamente con la siguiente. El bucle solo se detiene ante un bloqueo factual, una restricción imposible, un fallo de herramienta o una interrupción externa.

Por cada `E_XXXX`, en orden:

1. El director prepara fichas, contexto y la escena siguiente. Los estados `🔄` son efímeros: no se persisten por separado.
2. El escritor genera la **escena completa** en una respuesta. El director la valida y, si procede, obtiene los reemplazos del integrador antes de abrir persistencia.
3. El director prepara una transacción `escritura` y persiste solo en staging la escena bajo `<!-- ESCENA E_XXXX: nombre | salida: continua|separador -->`, con una ancla `<!-- B_XXXX -->` antes del primer pasaje que realiza cada beat.
4. Verifica la misma `Salida`, anclas únicas y ordenadas, y prosa no vacía tras cada ancla. También comprueba que la escena realiza cada acción nuclear. Las anclas no dividen la escena en prosas independientes.
5. El validador evalúa la escena completa: continuidad, arco tonal, ritmo y crudeza cuando aplique. Devuelve problemas concretos por `B_XXXX`, no puntuaciones. Si hay correcciones, el integrador reescribe solo los bloques señalados y el director vuelve a comprobar las invariantes afectadas.
6. En el mismo staging marca los beats `✅`, actualiza el delta de contexto y confirma. Solo una contradicción factual o una restricción imposible bloquea el avance.

**Gate final de fase:** cada `B_XXXX` del guion tiene exactamente una ancla en el draft y todas las escenas están cerradas sin contradicciones factuales. Durante la fase, el draft es un prefijo ordenado y completo por escena: solo contiene las `E_XXXX` ya confirmadas.

## FASE 4 — Finalizar

1. Verifica que cada `E_XXXX` del guion tenga un único marcador de draft, en el mismo orden y con la misma `Salida`; cada marcador debe contener exactamente sus `B_XXXX`, una vez y en orden. Rechaza escenas, anclas o beats huérfanos.
2. Prepara una transacción `publicar`, genera en su staging `relato.md` con el título de `config.json` y deja `config.json.estado = "finalizado"`.
3. Elimina anclas `B_XXXX` y marcadores de escena. Convierte en `---` solo los marcadores con `salida: separador`; los de `continua` se eliminan sin corte visible. Confirma la transacción; el helper rechaza IDs de control, separadores duplicados, título sin prosa y manuscrito vacío.

**Transición:** `estado = finalizado`. El hub asigna `publicado` tras compilar.

## Correcciones y memoria

- En `fichas`, `/revisar-guion` puede ajustar el guion con la transacción `guion`, sin iniciar prosa. En `escritura` o `correccion`, una corrección actualiza mediante staging transaccional el guion, el prefijo de escenas del draft afectado, el contexto desde la primera `E_XXXX` modificada y el registro. `/revisar` y `/expandir` solo actúan sobre escenas ya presentes en ese prefijo.
- Al dividir una escena, la primera conserva su `E_XXXX` y la siguiente toma un ID nuevo. Al fusionarlas, sobrevive la primera y la otra queda retirada; ningún ID se reutiliza.
- Si un draft heredado usa headings `## B_XXXX — ...`, el director los sustituye dentro del staging de corrección por `<!-- B_XXXX -->`, sin reescribir su prosa, antes de revisar, expandir o corregir.
- Cada escena añade al contexto solo un delta breve. Tras una salida `separador`, el director compacta los deltas de la secuencia cerrada.
- Los beats recurrentes no conservan una etiqueta o cola propia: son beats ordinarios del mapa global y se validan junto con él.
