# Compromiso narrativo y libertad de ejecucion

- Estado: aceptada por el usuario; implementacion local.
- Fecha: 2026-09-09.
- Alcance: solo `renacer-para-perder`. No modifica hub, shared/ ni otros workspaces.
- No cambia manuscrito, guiones existentes, identidades, payloads, modelos, presupuestos, permisos ni operaciones de persistencia.

## Motivo

Las revisiones del capitulo 02 mostraron beats que fijaban pausas y reacciones, frases sugeridas convertidas en literales obligatorias e inferencias transformadas en listas o preguntas directas. Hubo tambien errores de ejecucion y validaciones que comprobaron elementos del guion sin detectar conversaciones inconexas. No todo fallo procede del beat: "cuelga" no prohibe una despedida y "conversacion habitual" no exige telegramas.

## Decision

1. El beat es una unidad dramatica con compromiso verificable: acontecimiento, decision, descubrimiento o inferencia atribuida y sus consecuencias. Puede incluir gestos e intercambios subordinados. No se divide por puntuacion, verbos, mezcla tonal ni cuotas de beats.
2. En objetivos y contexto existentes se distinguen **Obligatorio**, **Libre** y **Ejemplos opcionales**. No son campos nuevos del payload. El director pasa estas distinciones inline a escritor e integrador, sin herramientas ni lecturas adicionales.
3. Obligatorio fija hechos, decisiones, consecuencias, restricciones, POV y literalidad justificada. Libre abarca ejecucion compatible. Los ejemplos no son canon ni una lista a realizar; solo se convierten en obligaciones mediante decision explicita.
4. Separar lo dicho, sabido, inferido y confirmado, indicando sujeto y certeza. Saber no obliga a preguntar; inferir no exige confesion ajena ni acredita la verdad de una declaracion. La interioridad puede ser el cambio narrativo sin escribirse literalmente en el guion ni sustituirse por una mirada.
5. `⚡` sigue significando literalidad real. Su uso nuevo exige palabras exactas solicitadas por el usuario o funcion causal documentada y aprobada. Una frase vigente en conflicto requiere resolucion del director antes de generar; no se omite ni se recoloca a la fuerza. No hay migracion automatica de marcas existentes.
6. El escritor desarrolla la escena continua. Los encabezados son trazabilidad, no cortes de conversacion ni parrafos obligatorios. Saludos, despedidas y enlaces ordinarios caben en los beats existentes cuando proceden; no son una cuota. Conserva IDs, orden y cuerpos no vacios.
7. El integrador repara el mecanismo del defecto en el intercambio minimo autorizado y sus transiciones, conservando el resto. Recibe y devuelve completas las secciones solicitadas. Si falta contexto/alcance o el guion impide el arreglo, devuelve `BLOQUEO:` al director, sin modificar el guion ni reconstruir texto ausente.
8. Los tonos orientan expresion, no conducta o conocimiento. Una conversacion normal puede resultar opresiva por lo que comprende el POV. No imponer voces quebradas, silencios, confesiones o listas interiores por etiqueta.
9. La validacion comprueba cobertura semantica y naturalidad con evidencia. IDs correctos no bastan; una friccion concreta de dialogo puede exigir correccion. La revision focalizada no ignora un error factual descubierto fuera del fragmento, pero tampoco repuntua toda la escena por rutina.

## Propagacion

Contrato comun en `beats-estructura` y `contexto-subagente`; instrucciones operativas en guionista (capitulo/revision), auditor (mismos nombres de modo), director, escritor, integrador y validador. Se alinean plantilla, hechos, estructura, mecanica, tonos, consistencia y validacion de geometria, tono y coherencia, junto con los resumenes de `PIPELINE.md` y plantillas de `ORQUESTACION.md`. La revision independiente detecto y se corrigieron dos residuos: conducta impuesta por tono e inventario obligatorio de todo objeto de ejecucion.

El flujo tecnico y sus hashes se conservan, ampliados por la [decision 0003](0003-checkpoint-narrativa-usuario.md): `preparar -> presentar y detenerse para el usuario -> revisar -> aceptar -> sincronizar`. El checkpoint de narrativa es siempre obligatorio; cualquier cambio textual exige nueva conformidad y avanzar a otra escena/capitulo requiere autorizacion expresa. No se consulta ni modifica Qdrant/Neo4j para aplicar estas decisiones de contratos.

## Casos de regresion editorial

Estos casos neutrales son criterios de revision humana, no salidas de una inferencia ya ejecutada:

| Caso | Resultado esperado |
|------|--------------------|
| Solicitar permiso, explicar el motivo y obtener autorizacion | Una unidad si los intercambios sirven al mismo resultado; no dividir por verbos o puntuacion |
| Obtener permiso y descubrir despues un sabotaje independiente | Dos cambios distinguibles aunque esten escritos en una sola frase |
| Eva dice que todo sigue igual; Luis sospecha un cambio por el horario | No convertir la sospecha en pregunta, confesion ni hecho confirmado |
| El briefing ofrece dos ejemplos de saludo | No insertar ambos ni hacer literal ninguno sin necesidad aprobada |
| Una frase `⚡` vigente contradice una revision solicitada | Conflicto al director antes de generar, no frase forzada ni omision silenciosa |
| Un beat termina una llamada | Despedida natural si procede, sin exigir beat adicional ni prohibir elipsis |
| Un beat pide deducir una causa | Interioridad con voz propia; no copiar la etiqueta "deduce" ni enumerar datos por obligacion |
| Cambiar una pregunta deja inconexa la respuesta siguiente | Integrador repara el intercambio minimo autorizado, o pide alcance si no lo tiene |

## Verificacion y limites

`tests/test_beat_contracts.py` comprueba presencia de salvaguardas y ausencia de reglas regresivas concretas en los contratos. Son comprobaciones estaticas de texto, no pruebas de comprension de los agentes ni de calidad literaria.

Las suites existentes de contratos y persistencia verifican que siguen vigentes los presupuestos, permisos, IDs/cuerpos y el flujo de candidato/revision/sincronizacion. Se ejecutan offline, sin inferencia ni BD reales.

Resultado local (2026-09-09): 11 comprobaciones nuevas de prompts, 12 de configuracion local, 54 de persistencia y 22 de identidad aprobadas. Las cuatro comprobaciones opcionales de esquema oficial no se ejecutaron (sin `--schema`); los campos de modelo, presupuesto y permisos no se modificaron. Revision independiente y `diff --check` sin incidencias pendientes en el alcance editorial. Las skills de validacion respetan el formato del consumidor: hash para candidatas de prosa, diagnostico sin hash para guion.

Reiniciar OpenCode antes de evaluar estos contratos en agentes reales. La sesion activa puede conservar instrucciones antiguas. Validar el primer caso real con el usuario; no atribuir mejora de naturalidad a las comprobaciones estaticas. Riesgo abierto NAR-005 en `docs/deuda-tecnica.md`.

Backup previo: `C:/Users/migue/AppData/Local/Temp/opencode/renacer-beats-antes-20260909.tar`.
