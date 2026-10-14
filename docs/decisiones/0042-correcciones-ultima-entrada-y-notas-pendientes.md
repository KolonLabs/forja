# ADR 0042: `correcciones.md` guarda solo la última corrección y las notas para escenas pendientes van al contexto

- Estado: aceptada
- Fecha: 2026-10-14
- Ámbito: relato. Skill `contexto-narrativo` de relato, director, `/corregir`, `/revisar` y `/expandir` (ambos entornos), `/corregir` común, `PIPELINE.md` y `ORQUESTACION.md` de relato, `shared/GUIA.md`, `scripts/new-edicion-relato.ps1` (registro inicial y `MAPA.md` de la edición) y skill `scaffolding-mapa`.
- Modifica: ADR 0005 y ADR 0006 (las correcciones «se registran en `correcciones.md`», que funcionaba como registro acumulado).
- Relaciona: ADR 0026 (el historial es el git de la obra).

## Contexto

En *El tío Vicente II*, `correcciones.md` llegó a 406 líneas antes de escribir ninguna escena. Cada corrección añadía una entrada al final y nada lo compactaba. El director lo consultaba al preparar cada escena, y algunas notas viejas ya estaban sustituidas por entradas posteriores.

El registro mezclaba tres cosas que duran más que una corrección:

- reglas nuevas de la persona usuaria;
- indicaciones para escenas aún no escritas;
- decisiones pendientes.

Las indicaciones son lo más delicado. El flujo de escritura no las recogía de `correcciones.md` al encargar una escena, así que podían no llegar al escritor.

La persona usuaria decidió que el registro solo sirve mientras se aplica una corrección y reorganizó la obra así:

- las reglas pasan a `config.json.restricciones`;
- las indicaciones van a dos secciones nuevas de `contexto_narrativo.md`, que se borran al escribir cada escena;
- `correcciones.md` se queda con una sola entrada.

## Decisión

1. **`correcciones.md` solo contiene la última corrección.** Cada transacción `correccion` lo sobrescribe con su entrada (fecha, alcance, cambios con sus IDs y resultado), con una cabecera que explica su uso. Las decisiones pendientes se conservan hasta que se resuelven. El historial está en el git de la obra.
2. **Notas para escenas pendientes en `contexto_narrativo.md`.** Se añaden dos secciones opcionales:
   - «Notas transversales para el briefing», para indicaciones que valen para varias escenas;
   - «Notas por escena pendiente».

   Al encargar una escena, el director pasa al escritor y al validador, como notas del director, las suyas y las transversales que le afecten. En la transacción `escritura` que la persiste, borra sus notas.
3. **Cada cosa a su sitio.**
   - Una regla de la obra va a `config.json.restricciones`. Como `AGENTS.md` y `BRIEF.md` los edita la persona usuaria, el director le propone el texto y, mientras tanto, la recoge como nota transversal.
   - Una pregunta bloqueante abierta consta en «Decisiones pendientes» si surge en una corrección, o en las notas de la escena afectada si surge al escribir.
   - Al resolverse, la decisión va donde dure.
4. **Ediciones derivadas.** `/nueva-edicion` crea `correcciones.md` con la apertura de la edición como única entrada; la sustituye la primera corrección. El linaje y el motivo siguen en `EDICION.md`.
5. El helper de transacciones no cambia: ya exigía un registro no vacío al confirmar una corrección, y `escritura` ya podía modificar `contexto_narrativo.md`.

## Consecuencias

- El registro no crece y el contexto de cada escena solo lleva notas vigentes: el bloque de notas encoge a medida que avanza el relato.
- El detalle de una corrección solo sobrevive a la siguiente si la persona usuaria hace commit entre ambas. La guía lo indica.
- Los `correcciones.md` existentes no se reescriben: la regla se aplica desde la siguiente corrección de cada obra.
- Las novelas no tienen `correcciones.md` y no cambian.
