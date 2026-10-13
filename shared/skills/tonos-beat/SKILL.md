---
name: tonos-beat
description: Define cómo escribir cada beat según su tono específico. Úsalo cuando el escritor necesite desarrollar un beat con un tono concreto asignado en el guión.
user-invocable: false
---

# Tonos de Beat

## Propósito

Este skill define las características de escritura para cada tono individual de beat. Los tonos son independientes entre sí: el guión los asigna en combinaciones (`Hipnótico / Explícito`, `Explícito / Dominante`) y el escritor combina las características de cada uno al desarrollar el beat. El catálogo y el formato son los mismos en relato, novela simple y novela multi-hilo (ADR 0035).

**Regla fundamental**: el tono orienta la expresión local dentro del estilo y las restricciones aprobadas. Puede modular ritmo, registro y foco, pero no altera hechos, conducta, conocimiento, consentimiento ni intensidad o explicitud fijados. No confirma sospechas, impone obediencia ni añade acciones para representar una etiqueta.

El catálogo ofrece recursos de ejecución, no listas de elementos obligatorios. Sus focos sensoriales, gestos, silencios y metáforas son opciones con función, nunca cuotas. Los ejemplos son opcionales y ajenos al canon: no se trasladan sus personajes, frases ni acciones al guion. La literalidad ⚡ se rige por `mecanica-prosa`, no por el tono o la importancia de una réplica. Una frase ⚡ vigente incompatible se remite al director antes de generar; no se degrada a sugerencia.

## Formato

- **Todo beat** lleva al final de su acción `[Tono — EXTENSIÓN]`, con uno o dos tonos del catálogo separados por `/` y una extensión (`BREVE`, `MEDIA`, `EXTENSA`). Relato: `⬜ B_0007 — Ana abre el sobre. [Revelación — BREVE]`. Novela: `⬜ B_0007 · a1b2c3d4 [3] — Ana abre el sobre [Revelación — BREVE] [Ana] [Zona: despacho]`.
- **Una sola instrucción tonal por tramo:** las escenas no declaran arco tonal; su recorrido es la secuencia de tonos de sus beats. El escritor recibe solo el tono de cada beat, dentro del marco de tono de la obra (`BRIEF.md`). El tono que una estructura de novela anota por capítulo o bloque orienta al guionista al planificar y no se pasa al escritor como instrucción.
- **`[elipsis]`** no es un tono: marca un beat que salta deliberadamente un intervalo. Se añade a su etiqueta de tono (`[Clínico — BREVE] [elipsis]`) y el escritor lo resuelve con un corte, sin desarrollar lo omitido.
- Un tono que el catálogo no tiene se propone a la persona usuaria y se añade aquí con su ficha; nunca se inventa en el guion.

---

## Catálogo de tonos individuales

---

### Clínico

| Atributo | Valor |
|----------|-------|
| **Ritmo** | Tendencia a frases cortas y secas, con la amplitud necesaria para expresar el compromiso |
| **Registro** | Técnico, distante, neutro en la expresión; puede transmitir emociones o valoraciones atribuidas cuando el beat las requiere |
| **Foco sensorial** | Detalles observables pertinentes a la precisión del pasaje, sin exigir gestos, sonidos o silencios concretos |
| **Vocabulario** | Precisión y sobriedad; terminología técnica solo si corresponde al contexto y al conocimiento del POV |
| **Diálogos** | Concisión y precisión; conservar el contenido y efecto del intercambio, incluida su carga emocional aprobada |
| **Atmósfera** | Distancia y normalidad aparente; no ocultar información que el beat deba comunicar ni añadir peligro por la etiqueta |

**Ejemplo:**
```
El recibo registraba una entrega a las nueve. La firma no era legible.

—Necesito el original para comprobarla —dijo Ana.
```

---

### Hipnótico

| Atributo | Valor |
|----------|-------|
| **Ritmo** | Cadencia envolvente, que puede apoyarse en frases largas y repetición deliberada con función |
| **Registro** | Sugestivo, lento, casi monótono. Las palabras se colocan como pesos |
| **Foco sensorial** | Recurrencias perceptivas pertinentes, como sonidos o movimiento; no exige una voz, objeto u olor específico |
| **Vocabulario** | Palabras sencillas y recurrencias con función; las instrucciones solo aparecen si corresponden al intercambio aprobado |
| **Diálogos** | Cadencia sostenida y repeticiones pertinentes, sin imponer un hablante, órdenes o respuestas |
| **Atmósfera** | Efecto envolvente mediante cadencia; no establece que un personaje esté en trance ni que pierda agencia |

**Ejemplo:**
```
El tren seguía junto al río, junto a las mismas orillas que aparecían
y se perdían en el cristal, y Ana repasaba la dirección, una vez más,
la dirección que tendría que encontrar al llegar.
```

---

### Opresivo

| Atributo | Valor |
|----------|-------|
| **Ritmo** | Presión sostenida; aceleraciones y pausas al servicio del conflicto aprobado |
| **Registro** | Frío, controlado en la expresión de la presión, sin convertir una pretensión de poder en dominio absoluto |
| **Foco sensorial** | Posiciones, distancias y sonidos pertinentes a la presión; el silencio no implica obediencia |
| **Vocabulario** | Directo, contenido; la presión puede expresarse también en un intercambio abierto |
| **Diálogos** | Órdenes, preguntas, explicaciones o negativas según el beat; formular la presión sin predeterminar la respuesta |
| **Atmósfera** | Sensación de opciones estrechas, no prueba de que no haya salida ni de que los personajes lo sepan |

**Ejemplo:**
```
—Sin su firma, el expediente no sale de aquí.

—¿Dónde consta ese requisito? —preguntó Ana.

Faltaban diez minutos para el cierre del registro.
```

---

### Revelación

| Atributo | Valor |
|----------|-------|
| **Ritmo** | Contraste y énfasis en el cambio de comprensión; admite preparación, desarrollo y reacción en un mismo movimiento |
| **Registro** | Impacto de lo descubierto o inferido según el beat, sin imponer colapso emocional o físico |
| **Foco sensorial** | Detalles que sostienen el hallazgo y su recepción, sin obligación de cubrir todos los sentidos |
| **Vocabulario** | Precisión sobre qué cambia en la comprensión, con el registro y la crudeza aprobados |
| **Diálogos** | El hallazgo puede emerger en conversación continua, con preguntas y contexto; no exige frase aislada ni literalidad automática |
| **Atmósfera** | Contraste entre antes y después; distinguir revelación de un hecho, afirmación ajena e inferencia atribuida, sin convertirlas en certezas equivalentes |

**Ejemplo:**
```
—¿La copia se selló el lunes?

—El martes —dijo Carlos—. El lunes estaba cerrado el registro.

Ana sospechó que el recibo podía estar mal fechado. Tendría que ver el original.
```

---

### Brutal

| Atributo | Valor |
|----------|-------|
| **Ritmo** | Directo y contundente; la introspección o las pausas caben cuando realizan el compromiso del beat |
| **Registro** | Atención a hechos y consecuencias sin suavizarlos; no elimina la respuesta emocional o el juicio atribuible al POV |
| **Foco sensorial** | Fuerza, peso o sonidos de la acción cuando contribuyen a expresar sus consecuencias |
| **Vocabulario** | Directo y concreto sobre fuerza y consecuencias, sin onomatopeyas ni cosificación obligatorias |
| **Diálogos** | Concisos y contundentes, con las réplicas necesarias para conservar el intercambio aprobado |
| **Atmósfera** | Dureza de consecuencias; no borrar decisiones, resistencia o interpretación por favorecer la acción física |

**Ejemplo:**
```
La máquina trituró el original. Ana pulsó la parada, demasiado tarde.
Había perdido la única prueba que no dependía de una copia.
```

---

### Explícito

| Atributo | Valor |
|----------|-------|
| **Ritmo** | Variable según la intensidad del acto. Se acelera con la acción |
| **Registro** | Descripción directa de lo que el beat establece; no añade actos sexuales ni excluye subtexto, interioridad o metáforas que no oculten lo ocurrido |
| **Foco sensorial** | Máximo detalle pertinente a la explicitud fijada, sin igualdad obligatoria de sentidos ni elementos añadidos para completar una lista |
| **Vocabulario** | Crudeza fijada por el proyecto, sin rebajar su máximo mediante eufemismos. Consultar `validacion-crudeza`; la etiqueta no cambia las restricciones |
| **Diálogos** | Directos en formulación cuando corresponda, sin equiparar lo dicho con deseo, intención, verdad o consentimiento |
| **Atmósfera** | Lo ocurrido queda inequívoco en el grado aprobado; conservar sus consecuencias, ambigüedades intencionales y función dramática |

**Ejemplo:**
```
El agua atravesó la tapa de cartón. La tinta azul se disolvió en
manchas y el número de expediente dejó de ser legible.
```

---

### Visceral

| Atributo | Valor |
|----------|-------|
| **Ritmo** | Lento en los detalles físicos, se acelera en los picos de sensación |
| **Registro** | Experiencia corporal en primer plano, compatible con decisiones e interioridad sin reemplazarlas |
| **Foco sensorial** | Tacto en primer plano: dolor, presión, temperatura, humedad, peso. Los otros sentidos apoyan |
| **Vocabulario** | Sensaciones físicas concretas y pertinentes, con el vocabulario e intensidad fijados por el proyecto |
| **Diálogos** | La sensación puede afectar la voz; no sustituir réplicas comprometidas por sonidos ni añadir reacciones involuntarias obligatorias |
| **Atmósfera** | Lo ocurrido se experimenta desde el cuerpo del POV; una reacción física no demuestra deseo, verdad ni consentimiento |

**Ejemplo:**
```
El asa le cortaba los dedos. Ana cambió la caja de mano, pero el peso
siguió tirándole del hombro durante el último tramo de escalera.
```

---

### Íntimo

| Atributo | Valor |
|----------|-------|
| **Ritmo** | Cercano y pausado; el tiempo se dilata en lo que se comparte, sin detener el compromiso del beat |
| **Registro** | Cercanía emocional o corporal desde el POV: ternura, complicidad, vulnerabilidad o deseo contenido, sin énfasis gráfico |
| **Foco sensorial** | Proximidad: voz baja, piel, respiración, gestos pequeños, objetos compartidos; solo lo pertinente a la acción |
| **Vocabulario** | Cálido y preciso, sin cursilería ni eufemismos que oculten lo que el beat establece |
| **Diálogos** | Confidencias, frases a media voz o pausas con función; el intercambio comprometido se conserva completo |
| **Atmósfera** | Resguardo y exposición a la vez; no añade actos ni los vuelve gráficos: si el beat exige detalle explícito, su tono es Explícito |

**Ejemplo:**
```
Carlos le apartó el pelo de la cara antes de contestar. Ana no se movió;
dejó que la mano se quedara un momento más en su mejilla.
```

---

### Dominante

| Atributo | Valor |
|----------|-------|
| **Ritmo** | Énfasis en la iniciativa o el intento de control establecido por el beat; su resultado no lo decide el tono |
| **Registro** | Asimetría de poder o pretensión de mando según el contexto, sin imponer sumisión |
| **Foco sensorial** | Posiciones, distancias o contacto si están justificados por la acción; no añadir control físico para ilustrar la etiqueta |
| **Vocabulario** | Control y dirección cuando describan la conducta aprobada, sin intensificarla ni rebajarla |
| **Diálogos** | Autoridad en la formulación; una instrucción puede cumplirse, cuestionarse o rechazarse según el compromiso narrativo |
| **Atmósfera** | Peso de la iniciativa y sus consecuencias; preservar resistencia, negociación y consentimiento tal como estén establecidos |

**Ejemplo:**
```
—Primero revisaremos el original —dijo Ana—. Después hablaremos de cerrarlo.

—No sin la autorización —respondió Carlos.
```

---

### Sumiso

| Atributo | Valor |
|----------|-------|
| **Ritmo** | Atento a la espera y a la respuesta; la cadencia sigue la iniciativa ajena que el beat establece, sin apresurar ni aplazar su resultado |
| **Registro** | Cesión del control vivida desde el POV que la acepta o la busca —entrega, expectativa, alivio o inquietud según el beat—, sin presentarla como anulación de la persona |
| **Foco sensorial** | El propio cuerpo y su posición respecto al otro: exposición, quietud, contacto recibido, la voz que indica; solo lo pertinente a la acción |
| **Vocabulario** | Obediencia, espera y entrega cuando describan la conducta aprobada, sin intensificarla ni rebajarla |
| **Diálogos** | Respuestas, peticiones o silencios según el compromiso narrativo; ceder puede incluir pedir, negociar o poner límites |
| **Atmósfera** | Peso de renunciar a decidir y de sus consecuencias; el tono no establece consentimiento ni su falta (se conserva tal como esté fijado) ni añade actos de sumisión para representar la etiqueta |

Dominante y Sumiso orientan desde lados opuestos de la misma asimetría: el beat lleva el que corresponde a su POV, no ambos.

**Ejemplo:**
```
—Firma aquí —dijo Carlos, y le acercó el expediente.

Ana dejó que él marcara cada página con el dedo. Era más fácil no decidir
el orden; bastaba con seguir su mano.
```

---

### Frenético

| Atributo | Valor |
|----------|-------|
| **Ritmo** | Muy rápido; frases ágiles y encadenamiento que sostengan la urgencia, sin prohibir pausas necesarias |
| **Registro** | Urgente; integrar reflexión y ambiente necesarios sin perder el impulso del pasaje |
| **Foco sensorial** | Movimiento, sonido, impacto. Los detalles sensoriales son rápidos y concretos |
| **Vocabulario** | Verbos precisos y economía descriptiva; la sintaxis sirve a la urgencia, no a una prohibición de subordinadas |
| **Diálogos** | Réplicas ágiles, con contenido y efecto completos; no impone gritos ni elimina preguntas o decisiones |
| **Atmósfera** | Sensación de urgencia; no implica pérdida de control o agencia salvo que el beat la establezca |

**Ejemplo:**
```
El agua llegaba a las cajas. Ana levantó la del original y buscó la salida.

—¿Por la escalera?

—Está libre. Vamos.
```

---

### Tenso

| Atributo | Valor |
|----------|-------|
| **Ritmo** | Expectativa sostenida; silencios o pausas solo si tienen función, no entre cada réplica |
| **Registro** | Incertidumbre o anticipación durante la acción o antes de ella, sin aplazar resultados comprometidos |
| **Foco sensorial** | Señales perceptibles de riesgo o incertidumbre según el contexto, sin exigir miradas, silencios ni proximidad física |
| **Vocabulario** | Precisión en riesgos y opciones percibidas; contención cuando corresponde al pasaje |
| **Diálogos** | Subtexto cuando exista, compatible con preguntas y declaraciones directas; no exige ocultar intención en toda réplica |
| **Atmósfera** | Expectativa ante un resultado incierto; no atribuir al lector o a los personajes conocimiento de lo que va a pasar |

**Ejemplo:**
```
—Si el original no aparece hoy, cerrarán el expediente.

Ana miró la fecha del recibo. No sabía cuánto tardaría Carlos en volver.
```

---

### Contemplativo

| Atributo | Valor |
|----------|-------|
| **Ritmo** | Pausado, de respiración larga; la acción avanza sin prisa y admite demorarse en lo observado cuando tiene función |
| **Registro** | Observación serena o melancólica desde el POV; la interioridad aflora en lo que se mira, sin explicar su sentido ni convertirla en reflexión abstracta |
| **Foco sensorial** | Paisaje, luz, objetos y rutinas pertinentes al momento; un detalle concreto antes que una enumeración |
| **Vocabulario** | Sencillo y preciso, con imágenes contenidas; sin lirismo decorativo ni sentencias que cuenten lo que el pasaje muestra |
| **Diálogos** | Escasos o pausados cuando los hay, sin forzar silencios; el intercambio comprometido por el beat se conserva completo |
| **Atmósfera** | Quietud aparente; no anula la tensión subyacente ni aplaza los resultados que el beat compromete |

**Ejemplo:**
```
Ana dejó el expediente sobre la mesa y se quedó mirando el patio. La luz
de la tarde subía por la pared de enfrente, ventana a ventana, como cada
día a esa hora.
```

---

---

## Extensiones de beat

Cada beat lleva una extension que indica su peso narrativo relativo. El guionista asigna la etiqueta; el escritor decide la longitud que necesita la unidad dramatica dentro de la escena, sea accion, interaccion, decision, descubrimiento o inferencia atribuida.

| Extension | Aliento orientativo | Cuando usarla |
|-----------|---------------------|---------------|
| `BREVE` | Concentrado | Un cambio narrativo que admite tratamiento concentrado: se resuelve y sigue; no convierte cada gesto o replica en beat |
| `MEDIA` | Desarrollo moderado | Un evento con contexto y reaccion |
| `EXTENSA` | Desarrollo amplio | Una accion que merece demorarse: larga o con fases (por ejemplo, un acto explicito), un punto de giro o un desarrollo emocional denso |

La extensión mide cuánto se detiene la prosa en la acción del beat, no cuántas acciones contiene: `EXTENSA` se demora dentro de esa misma acción (tiempo, cuerpo, reacción) sin añadir acciones ni repetir las ya hechas, y `BREVE` no se infla. Significa lo mismo en relato, novela simple y novela multi-hilo (ADR 0035).

**Regla de extension (ADR 0020):** no hay suelo ni techo literario numerico obligatorio. No recortes, fusiones frases ni anadas relleno para satisfacer conteos. Valora ritmo, cadencia, cobertura y proporcion dentro de la escena; senala dilucion narrativa con evidencia, no contra una cuota. No exige justificar cada desviacion. El presupuesto tecnico de completion del agente es independiente y comparte razonamiento y respuesta.

La extensión es para el escritor. El guionista solo asigna la etiqueta. El beat en el guion siempre es una línea.

---

## Reglas de combinación

Cuando un beat tiene tono compuesto (`Hipnótico / Explícito`, `Explícito / Dominante`):

1. **El primer tono orienta ritmo y atmósfera**: no asigna una emoción o un estado mental al personaje por sí solo
2. **El segundo tono matiza el registro**: orienta vocabulario y foco sin desplazar el compromiso narrativo ni las restricciones
3. **Como máximo dos etiquetas por beat**: elegir las dominantes dentro del catálogo. Más matices en la ejecución no obligan a dividir; solo compromisos dramáticos distintos justifican beats separados, nunca la mezcla tonal, los verbos o la puntuación
4. **La extensión indica peso, no una coreografía tonal**: desarrollar el cambio con la cadencia que necesita la escena. Una revelación BREVE puede integrarse en una conversación sin aislar una frase ni cortarla artificialmente

---

## Integración con agentes

- El director incorpora al contexto preparado las reglas pertinentes de este skill; escritor e integrador no lo cargan mediante herramientas
- El agente `validador` puede usar este skill para verificar si el tono del texto desarrollado coincide con el tono asignado al beat
- El agente `guionista` carga este skill para consultar el catálogo de tonos disponibles y asignar el correcto a cada beat — no necesita saber cómo ejecutarlos, solo elegirlos
