# Pipeline — Relato (4 fases)

Relato trabaja solo con archivos Markdown locales. No usa Qdrant, Neo4j ni identidad opaca.

## Contrato canónico

```text
H_XXXX (hechos de briefing)
  → B_XXXX (beats globales: acción, no prosa)
  → E_XXXX (escenas operativas, manejables para una generación)
  → relato-draft.md (prosa de cada E, dividida internamente por B)
  → relato.md (manuscrito limpio)
```

| ID | Función |
|---|---|
| `H_XXXX` | Hecho del briefing. Se congela al iniciar la escritura. |
| `B_XXXX` | Acción causal mínima. Es global, único y no se renumera. |
| `E_XXXX` | Unidad dramática y de generación. Agrupa beats contiguos y no se renumera. |

El orden en `guion.md` es el orden narrativo. Los IDs solo identifican: no existen `stable_id`, `parent_id`, `seq` ni UUID.

Un beat contiene únicamente acción, consecuencia y, cuando difiere del arco tonal de su escena, un registro opcional: `[registro: explícito / visceral]`. No contiene hecho de origen, prosa, extensión, sensorialidad ni psicología.

## FASE 1 — Diseño (`diseno`)

1. **Preparar.** El director verifica `H_XXXX`, restricciones y rangos `[D]`.
2. **Mapa de beats.** El guionista genera todos los `B_XXXX` de hechos lineales. Devuelve al director una cobertura temporal `H → B`; no se persiste en el guion.
3. **Recurrencias.** El director procesa `cola_d.md`: resuelve eventos, patrones y progresiones; los motivos pasan como directrices de escena y no generan beats. Las apariciones se insertan por función, no por cuota.
4. **Diagnóstico único.** El auditor revisa cobertura, causalidad, atomicidad, fugas de información y ausencia de prosa en los beats. Solo los problemas bloqueantes se reparan, en una única pasada.
5. **Escenas.** El guionista agrupa beats en `E_XXXX`. Una situación amplia puede contener varias escenas operativas si existe un giro de objetivo, información, poder, foco o resultado. Cada escena declara arco tonal y `Salida: continua | separador`.
6. **Gate mecánico.** El director comprueba que todos los beats pertenecen a una escena, son contiguos y que las salidas son coherentes. No hay una segunda auditoría estética por defecto.

Si falta un hecho lineal para culminar un `[D]`, el director presenta ese bloqueo: no inventa ni altera `H_XXXX` sin autorización.

**Transición:** `estado = fichas`.

## FASE 2 — Componentes (`fichas`)

1. El director crea las fichas necesarias para la primera escena y las entidades recurrentes o críticas para continuidad.
2. Las fichas restantes se crean bajo demanda cuando una escena las necesita.
3. Inicializa `contexto_narrativo.md` y `relato-draft.md`.

**Gate:** la próxima escena puede escribirse con información consistente. No se ficha toda mención incidental del guion.

**Transición:** `estado = escritura`.

## FASE 3 — Escritura por escena (`escritura`)

Por cada `E_XXXX`, en orden:

1. El director marca sus beats `🔄` y prepara fichas, contexto y la escena siguiente.
2. El escritor genera la **escena completa** en una respuesta, con un bloque `## B_XXXX — acción` por cada beat. El director persiste el resultado bajo `<!-- ESCENA E_XXXX: nombre | salida: continua|separador -->`.
3. El director verifica mecánicamente que todos los beats están presentes una vez y realizan su acción nuclear.
4. El validador evalúa la escena completa: continuidad, arco tonal, ritmo y crudeza cuando aplique. Devuelve problemas concretos por `B_XXXX`, no puntuaciones.
5. Si hay correcciones, el integrador reescribe solo los bloques señalados. El director comprueba las invariantes afectadas y cierra la escena. Solo una contradicción factual o una restricción imposible bloquea el avance.
6. El director marca los beats `✅` y actualiza el contexto con el delta de la escena.

**Gate:** cada `B_XXXX` del guion aparece exactamente una vez en el draft y todas las escenas están cerradas sin contradicciones factuales.

## FASE 4 — Finalizar

1. Verifica la correspondencia guion/draft y que no existan beats huérfanos.
2. Genera `relato.md` con el título de `config.json`.
3. Elimina headings `B_XXXX`. Convierte en `---` solo los marcadores de escena con `salida: separador`; los de `continua` se eliminan sin corte visible.

**Transición:** `estado = finalizado`. El hub asigna `publicado` tras compilar.

## Correcciones y memoria

- Una corrección estructural actualiza en una transacción el guion, las escenas del draft afectadas y el contexto desde la primera `E_XXXX` modificada.
- Al dividir una escena, la primera conserva su `E_XXXX` y la siguiente toma un ID nuevo. Al fusionarlas, sobrevive la primera y la otra queda retirada; ningún ID se reutiliza.
- Cada escena añade al contexto solo un delta breve. Tras una salida `separador`, el director compacta los deltas de la secuencia cerrada.
- `cola_d.md` se cierra al terminar diseño y no se carga durante la escritura.
