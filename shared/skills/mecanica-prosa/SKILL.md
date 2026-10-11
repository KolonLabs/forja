---
name: mecanica-prosa
description: Mecanica de dialogo, parrafos, literalidad e interioridad. El director prepara las reglas inline para escritor e integrador sin herramientas.
user-invocable: false
---

# Skill: mecanica-prosa

## Qué es

Define la mecánica invariable de formato para cualquier prosa narrativa. No contiene vocabulario, estilo ni reglas de crudeza — solo formato. Es agnóstico al contenido.

Los ejemplos ilustran opciones de ejecución, no canon ni obligaciones de frase, gesto, silencio o metáfora. El escritor realiza el compromiso narrativo del beat con libertad de expresión, sin cambiar hechos, conducta, conocimiento, consentimiento, restricciones ni intensidad fijada.

---

## Formato de diálogo

### Párrafo independiente

Cada intervención de diálogo va en su propio párrafo, separado de la narración por una línea en blanco. Con guion largo (—).

```
Fernando se puso en pie con los hombros tensos.

—Cállate —dijo, y la miró fijo.
```

También las réplicas breves (`—Sí.`, `—Espera.`) tienen párrafo propio. Pueden llevar atribución o acotación pertinente, sin límite por longitud; no añadas gestos o silencios solo para separarlas. La conversación puede continuar entre beats y contener saludos, despedidas y transiciones ordinarias sin un beat por cada réplica o movimiento. Los encabezados técnicos no obligan a introducir una pausa en la escena.

### Líneas críticas (⚡)

**Criterio de entrada estricto:** solo se admite una nueva línea ⚡ si el usuario exige expresamente esas palabras exactas o si su literalidad tiene una función causal documentada y aprobada por el director, como un código que debe repetirse. Ser una frase importante, una revelación, una decisión o un ejemplo sugerente no basta. Sin ese requisito, el beat declara contenido y efecto del intercambio y el escritor formula las palabras.

**Literalidad real:** si el beat vigente contiene una línea ⚡, esa frase exacta DEBE aparecer en el texto. Puede acompañarse de acotación o reacción pertinente, pero la frase en sí no se altera. No se reclasifica silenciosamente como ejemplo ni se elimina el marcador para eludir el compromiso.

**Conflicto antes de generar:** si una frase ⚡ vigente resulta incompatible con una revisión, el POV, los hechos o las restricciones, o no consta ninguno de los dos criterios de entrada, pide resolución al director. No generes el tramo afectado hasta que resuelva el compromiso; el escritor no decide omitirlo, parafrasearlo ni imponerlo pese al conflicto. Una exigencia expresa del usuario no necesita además una función causal.

### Pensamiento e interioridad

El pensamiento directo reproduce la voz del personaje y puede marcarse en cursiva. Usa su persona verbal natural, incluida la primera persona cuando corresponda; la narración en tercera limitada no obliga al personaje a pensarse en tercera persona. El indirecto libre se integra sin cursiva en la persona y los tiempos compatibles con el POV, con su valoración y vocabulario. También cabe narrar de forma indirecta una decisión o inferencia.

No toda interioridad va en cursiva ni necesita párrafo propio. Elige la forma y el corte por claridad, voz y cadencia, sin listas obligatorias de pensamientos ni transcripción literal del guion. Una decisión o inferencia atribuida en el beat compromete ese cambio, no su redacción interior. Conserva quién dice, sabe o infiere algo y si está confirmado; una interpretación del personaje no se convierte en verdad del narrador.

Opciones alternativas de ejemplo, no fragmentos que deban acumularse:

```
Pensamiento directo: *No puedo entregar el informe sin comprobar la fecha.*

Indirecto libre: No podía entregar el informe así. ¿Y si la fecha estaba mal?

Narración indirecta: Daniel decidió comprobar la fecha antes de entregar el informe.
```

---

## División de párrafos narrativos

Dividir por claridad, cadencia y organización del pasaje. Acción, sensación y reacción interna pueden compartir párrafo si forman un movimiento legible; un cambio de foco, sujeto o recuerdo no exige corte automático. Cortar cuando el cambio dificulte seguir el referente o cuando el ritmo requiera una separación con función.

No hay umbral de líneas, frases, acciones ni sensaciones. El ancho de pantalla no determina la estructura. Tampoco se divide un beat por puntuación o por cada verbo: la unidad dramática y la división tipográfica son decisiones distintas.

---

## Uso del nombre del personaje en 3ª persona limitada

Cuando el relato se narra en 3ª persona limitada anclada a un solo personaje, **no repitas su nombre en cada frase**. El lector ya sabe quién es el sujeto.

### Cuándo SÍ usar el nombre
- Primera mención en una escena nueva o tras un cambio de escenario
- Cuando hay otro personaje del mismo género en escena y hay ambigüedad
- Cuando se ha perdido el referente y recuperarlo evita ambigüedad, con independencia de la longitud del párrafo

### Cuándo NO usar el nombre
- Verbos consecutivos sin cambio de sujeto: «Se giró. Buscó la sombra. La encontró.»
- Sensaciones físicas inequívocamente suyas: «El latido en las sienes. En el pecho.»
- Gestos automáticos ya establecidos como suyos: «Se recolocó la corbata.»

### Ejemplo

Con el referente ya claro, estas variantes ilustran solo el uso del nombre, sin añadir acciones:

```text
Repetición innecesaria: Miguel consultó el recibo. Miguel comparó la fecha con la del expediente.
Variante: Consultó el recibo. Comparó la fecha con la del expediente.
```

---

## Salida sin metatexto

La salida normal contiene solo prosa y la estructura técnica de escena y beats exigida por el contrato vigente. No añadas notas del escritor, justificaciones de extensión, listas de cobertura ni comentarios editoriales al cuerpo narrativo. La libertad de ejecución no exige justificar cada elección de ritmo o longitud.

Si realizar el beat exige cambiar un compromiso aprobado o resolver un conflicto de canon o literalidad, devuelve el bloqueo previsto por el contrato al director en lugar de prosa candidata; no lo encubras con una nota al final del texto.

---

## Estructura del beat generado

Conserva los encabezados Markdown, IDs, orden y cuerpo no vacío de cada beat recibidos en el contrato de salida. La continuidad dramática no autoriza a fundir secciones técnicas, dejar cuerpos vacíos ni duplicar prosa entre ellos. Los rótulos siguientes son esquemáticos, no instrucciones para sustituir las identidades recibidas.

### Beat normal
```
## B_XX — Acción breve

...texto del beat...
```

### Primer beat de escena nueva
```
<!-- ESCENA N: Nombre -->

## B_XX — Acción breve

...texto del beat...
```
