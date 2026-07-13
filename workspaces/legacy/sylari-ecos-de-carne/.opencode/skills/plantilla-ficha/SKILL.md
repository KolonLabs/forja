---
name: plantilla-ficha
description: Estructura unificada para fichas de entidad narrativa. Soporta 10 tipos con versionado y estado operativo.
---

# Ficha: [NOMBRE]

**Tipo:** persona | lugar | objeto | animal | ser_sobrenatural | organizacion | hilo | arco | evento | grupo
**Proyecto:** [título del relato/novela o "banco" si es genérica]
**Versión:** `[YYYYMMDD_HHmm]-[hash8]`
**Tags:** [tag1] [tag2] [tag3]

---

## Descripción general

[1-2 frases que definan la entidad. Lo esencial.]

---

## Estado operativo *(campos dinámicos — se actualizan tras cada capítulo)*

**Acto actual:** [I-VII]
**Ubicación actual:** [dónde está ahora]
**Estado:** [vivo | muerto | transformado | desaparecido | etc.]
**Función narrativa activa:** [qué rol juega AHORA en la trama]

---

## Registro de desarrollo *(log acumulativo — una entrada por capítulo)*

| Fecha | Capítulo | Cambio |
|-------|----------|--------|
| YYYY-MM-DD | CAP_XX | [qué le ocurrió] |

---

## Secciones por tipo

Rellena solo las secciones de tu tipo. Omite las que no apliquen.

### Tipo: persona

**Físico general:** edad, altura, complexión, piel, cabello, ojos, rasgos faciales, vestimenta, marcas.
**Cuerpo - tren superior:** hombros, pecho, abdomen, espalda, brazos, manos, cuello.
**Cuerpo - tren inferior:** caderas, culo, muslos, piernas, genitales, ano.
**Sexualidad:** orientación, experiencia, fetiches, zonas erógenas, dominancia, ruido, límites.
**Personalidad:** rasgo principal, secundario, manías, miedos, deseos, vicios, virtudes.
**Historia:** origen, situación actual, motivación, secreto.
**Relaciones:** con otros personajes (nombre + tipo de vínculo).
**Sensorial:** olor, voz, tacto, sonidos que produce, manierismos (mínimo 3 sentidos).

### Tipo: lugar

**Físico:** dimensiones, materiales, iluminación, elementos destacados.
**Zonas específicas:** sub-áreas con nombre y descripción breve.
**Sensorial:** olores dominantes, sonidos ambientales, temperatura, texturas (mínimo 3).
**Ambiente:** atmósfera general, sensación al entrar.
**Posibilidades narrativas:** ¿qué tipo de escenas permite este espacio?

### Tipo: objeto

**Físico:** tamaño, material, color, peso, textura.
**Función narrativa:** para qué sirve en la trama.
**Historia:** origen, dueños anteriores, eventos ligados.
**Poderes/Mecánica:** si es un objeto especial, cómo funciona.

### Tipo: animal

**Especie/Raza:** nombre común y científico si aplica.
**Físico:** tamaño, pelaje/plumas/escamas, color, rasgos distintivos.
**Comportamiento:** temperamento, instintos, hábitos.
**Sentidos destacados:** qué percibe mejor que un humano.
**Dueño/Vínculo:** a quién pertenece o con quién tiene lazo.
**Rol narrativo:** mascota, guardián, amenaza, símbolo.

### Tipo: ser_sobrenatural

**Físico:** forma base, transformaciones, rasgos no humanos.
**Poderes/Mecánica:** qué puede hacer, reglas, limitaciones.
**Sexualidad:** si aplica, misma estructura que persona.
**Función narrativa:** rol en la trama, objetivo.
**Sensorial:** olor, voz, tacto (mínimo 3, suelen incluir temperatura anómala).

### Tipo: organizacion

**Descripción:** qué es, propósito, fachada pública vs realidad.
**Miembros clave:** nombres y roles.
**Estructura:** jerarquía, sede, alcance geográfico.
**Métodos:** cómo opera, herramientas, alcance.
**Rol narrativo:** antagonista, aliada, contexto.

### Tipo: hilo *(subtrama)*

**Descripción:** qué conflicto/situación sigue este hilo.
**Personajes implicados:** quiénes participan.
**Estado:** activo | latente | cerrado.
**Tensión actual:** baja | media | alta | crítica.
**Capítulos donde avanza:** lista de IDs.

### Tipo: arco

**Premisa:** de qué va este arco (Acto I-VII).
**Capítulos:** qué capítulos lo componen.
**Personajes clave:** quiénes llevan el peso.
**Hilos que contiene:** qué hilos narrativos lo cruzan.
**Estado:** planificado | en_progreso | completado.

### Tipo: evento

**Cuándo ocurre:** capítulo y momento específico.
**Quiénes participan:** lista de personajes.
**Qué ocurre:** descripción del suceso.
**Consecuencias:** qué cambia en la trama a partir de aquí.

### Tipo: grupo

**Miembros:** lista de personajes que lo componen.
**Dinámica interna:** relaciones de poder, roles.
**Función narrativa:** propósito del grupo en la trama.
**Historia:** origen del grupo, evolución.

---

## Reglas generales

1. **Sin eufemismos** en campos sexuales o anatómicos.
2. **Sin campos vacíos ni "N/A"** — omite lo que no aplique.
3. **Tags obligatorios** — tipo, rasgo dominante, función narrativa.
4. **Versión automática** — timestamp + hash MD5 de 8 caracteres al guardar.
5. **Detalle sensorial** — mínimo 3 sentidos en la sección Sensorial.
6. **Estado operativo** — se actualiza tras cada capítulo en el que participa la entidad.
7. **Registro de desarrollo** — entrada por capítulo con cambio concreto (no genérico).
8. **Nombre del archivo** — `[tipo]_[nombre].md` en minúsculas, sin espacios ni acentos.
