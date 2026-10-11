# ADR 0030: Producción de audiolibros con ElevenLabs y distribución por Author's Republic

- Estado: aceptada (implementación pendiente, por fases)
- Fecha: 2026-10-11
- Ámbito: herramienta de audio en el hub y en `shared/`, independiente del pipeline de escritura.
- Relaciona: ADR 0026 (compilación en la obra), ADR 0028 (borradores), ADR 0029 (secretos).

## Contexto

La primera obra a producir en audio es *Canida*: thriller sin contenido sexual, en español, fuera de Forja (`C:\Proyectos\Personal\Writting\canida`), con unos 1 176 000 caracteres (≈200 000 palabras, 44 capítulos) en `build/canida.md`. El objetivo es llegar a Audible.

Investigación del 2026-10-11 (fuentes en la conversación de diseño):

- **ACX** (vía directa a Audible) solo admite residentes en EE. UU., Reino Unido, Canadá e Irlanda y exige narración humana.
- **Voices by INaudio** solo acepta narración con IA como paquete LPF original de Google Play Books, ElevenLabs Studio o Spoken Press; no MP3 propios. Spotify indica que la narración digital no se comparte con sus socios de distribución.
- **KDP Virtual Voice** usa voces de Amazon, solo para la tienda de EE. UU. y por invitación.
- **Author's Republic** acepta MP3 propios por capítulo y tiene un programa de distribución de audiolibros con IA en pruebas, que «no se permite en todas las plataformas» sin decir cuáles. Es la única vía documentada que podría llevar audio propio de ElevenLabs a Audible. No exige exclusividad.
- **Kobo Writing Life** acepta audiolibros con IA declarados como «Synthesized Voice». **Spotify for Authors** acepta narración digital declarada.
- **API de ElevenLabs** (plan Creator, ≈127 700 créditos/mes): texto a voz disponible; la API de Studio (proyectos) requiere habilitación expresa de la cuenta. `eleven_v4` (10 000 caracteres por petición) y `eleven_v3` (5 000) admiten etiquetas de emoción (`[whispers]`, `[sighs]`…) y de efectos (`[gunshot]`, `[applause]`…); no admiten pausas SSML. La documentación no confirma el empalme entre peticiones (`previous_request_ids`) con estos modelos.

## Decisión

1. **Primer canal: Author's Republic.** Solo publicando se sabrá a qué tiendas llega el audio con IA; los demás canales (Kobo, Spotify, venta directa) se valoran después, sin enviar el mismo título a una tienda por dos vías.
2. **Voz: ElevenLabs por API, `eleven_v4` por defecto,** con narración declarada siempre como sintética. La calidad de voz ya está validada por la persona usuaria.
3. **Herramienta independiente del pipeline de escritura.** La entrada es un manuscrito limpio con un capítulo por encabezado `#` (sirve `canida/build/canida.md` y el libro de `publicacion/` de cualquier obra). La salida vive junto a ese manuscrito, en una carpeta de audio fuera de git.
4. **Fases, cada una determinista salvo la primera:**
   1. **Guion de audio:** un agente añade por capítulo etiquetas de emoción y efectos sobre el texto, sin cambiar la prosa. La persona usuaria lo revisa antes de gastar créditos. Un script valida que solo haya etiquetas de la lista admitida y que el texto, sin etiquetas, sea idéntico al manuscrito.
   2. **Estimación:** créditos necesarios frente a los disponibles (`/v1/user/subscription`); la generación exige confirmación explícita.
   3. **Generación:** fragmentos de hasta 10 000 caracteres sin cortar frases ni capítulos; caché por hash de texto, voz, modelo y ajustes, de modo que una corrección solo regenera sus fragmentos.
   4. **Masterizado para Author's Republic** con `ffmpeg`: un MP3 por capítulo (CBR ≥192 kbps, 44,1 kHz, ≤170 MB, ≤119 min), anuncio de capítulo al inicio, 1–5 s de silencio en los extremos, RMS entre −23 y −18 dB, picos ≤ −3 dB; pistas aparte de créditos iniciales y finales y una muestra de 1–5 min.
   5. **Validación** de esas especificaciones antes de entregar.
   6. **Registro** de qué versión del audio se ha entregado a cada canal y cuándo.
5. **La publicación es manual.** Ninguna plataforma documenta una API de publicación para autores independientes; la herramienta prepara el paquete y la ficha de metadatos, y la persona usuaria lo sube.
6. **La clave se lee con los helpers de ADR 0029** (`ELEVENLABS_API_KEY`).

## Pendiente antes de producir

- Confirmar cuál es el texto definitivo de *Canida* (`build/canida.md` es de diciembre de 2025; el EPUB, de junio de 2026).
- Plan de ElevenLabs o excedente: *Canida* equivale a unos 9 meses del plan Creator con un modelo de coste ×1, sin contar etiquetas ni repeticiones.
- Probar el empalme entre fragmentos con `eleven_v4` y la consistencia de las etiquetas con la voz elegida.
- Investigar metadatos y portada que exige Author's Republic.

## Consecuencias

- El coste dominante es generar el audio; cada corrección posterior a la entrega cuesta créditos y una nueva subida por canal.
- Audible no está asegurado: depende de los canales que Author's Republic acepte para audio con IA.
- Las etiquetas son experimentales en algunas voces; la revisión del guion de audio y una escucha de control por capítulo forman parte del proceso.
