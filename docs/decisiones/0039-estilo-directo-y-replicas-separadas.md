# ADR 0039: Lo dicho en estilo directo y réplicas separadas, en todas las escalas

- Estado: aceptada
- Fecha: 2026-10-14
- Ámbito: `mecanica-prosa` (relato y común de novela), `plantilla-draft` (relato), `escritor` y `validador` de las tres escalas, en ambos entornos.
- Relaciona: ADR 0020 (el beat fija el qué; el cómo es del escritor), ADR 0035 (`[elipsis]` como corte).

## Contexto

En el tío Vicente I, la prosa resumía en la narración lo que los personajes decían («le pregunta si…», «me cuenta que…»). Ocurría sobre todo con el habla que no viene en el beat: saludos, preguntas de mesa, comentarios de fondo. También había réplicas en raya pegadas a la línea anterior con un salto simple, que al compilar se funden en el mismo párrafo. La `mecanica-prosa` de relato solo decía «usa raya cuando haya diálogo». La común de novela ya exigía un párrafo propio por réplica, pero tampoco pedía estilo directo. El validador de ninguna escala lo comprobaba, y su regla de no corregir el **cómo** lo dejaba fuera.

## Decisión

1. **Lo dicho, en boca de quien lo dice.** Si la escena recoge el contenido de lo que alguien dice (también el narrador), va en estilo directo con raya. No se resume en la narración ni se cita entre comillas dentro de un párrafo narrativo. Quedan fuera lo que el POV no llega a oír, el ruido sin contenido, los mensajes escritos (entre comillas latinas) y el pensamiento. Un beat con `[elipsis]` sigue resolviéndose con un corte, sin narrar lo omitido.
2. **Cada réplica es un párrafo propio**, separado del anterior y del siguiente por una línea en blanco. En el draft de relato, también después de cada ancla `<!-- B_XXXX -->` (`plantilla-draft`).
3. **El escritor** aplica la regla también al habla que el beat no enumera; las palabras siguen siendo suyas.
4. **El validador lo señala siempre**, con su beat, como corrección: en relato, en su lista de comprobaciones; en novela, con gravedad `corregir`. Es un requisito de forma, no una elección del cómo, así que la regla de no corregir el cómo no lo excluye.

## Consecuencias

- Las tres escalas comparten la misma regla de diálogo. La escribe cada `mecanica-prosa`, que el director pasa inline a escritor e integrador en novela.
- Los workspaces existentes la reciben solo si se reinyectan sus agentes y skills desde `shared/`.
