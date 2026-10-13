---
name: plantilla-ficha
description: Plantilla ligera de fichas Markdown para entidades relevantes de un relato sin infraestructura ni cronista.
user-invocable: false
---

# Ficha — [NOMBRE]

- **Tipo:** persona | lugar | objeto | animal | ser-sobrenatural | organización | grupo | evento
- **Función narrativa:** por qué esta entidad importa en el relato.
- **Ruta:** `fichas/<tipo>_<slug>.md`

## Rasgos de continuidad

- Lo que debe mantenerse consistente en prosa: apariencia, capacidades, límites, relaciones, ubicación o reglas del lugar.
- Solo los detalles que la escena actual o las futuras necesiten.

## Estado narrativo actual

- Situación confirmada al cierre de la última escena pertinente.
- Cambios relevantes y su `E_XXXX` de origen.

## Canon heredado *(solo si el personaje viene de otra obra; skill `referencias`)*
- Origen: (obra y dossier `referencias/<dossier>.md`)
- Tiempo transcurrido: (desde el final de la obra previa)
- Estado al final de la obra previa: (con cita [cap. N: «…»])
- No contradecir: (hechos con cita [cap. N: «…»])
- Evolución permitida: (qué puede haber cambiado y por qué)

## Uso

- No crees una ficha para una mención incidental.
- No uses UUID, versiones, capítulos, hilos ni campos de cronista.
- Añade un cambio solo cuando el texto o el guion lo confirmen.
