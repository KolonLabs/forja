# ADR 0016: URL públicas como fuentes de importación

- Estado: aceptada
- Fecha: 2026-07-14
- Ámbito: `/importar-proyecto` y `preparar-importacion-proyecto.ps1`.

## Contexto

Las notas narrativas pueden residir en una ruta local o estar publicadas en una página web. Limitar la importación a disco obliga a copiar el material antes de analizarlo y pierde la referencia original.

Una URL también introduce riesgos ausentes en el sistema de archivos: redirecciones a recursos internos, hosts privados, contenido no textual y falta de trazabilidad de la versión leída.

## Decisión

- `--fuente` admite rutas locales y URL HTTPS públicas.
- El empaquetador descarga únicamente a memoria y al paquete temporal; nunca copia la fuente al workspace.
- Comprueba cada URL y cada redirección: solo HTTPS, sin credenciales, sin hosts o IP privadas, locales, reservadas o de enlace. Limita redirecciones, tiempo, número de fuentes y caracteres.
- Admite inicialmente `text/plain`, Markdown y `text/html`; HTML se convierte a texto para conservar referencias de línea. PDF y formatos ofimáticos remotos quedan fuera de alcance.
- El manifiesto v2 registra tipo de fuente, URL solicitada y final, tipo de contenido y SHA-256. El contenido sigue siendo dato no confiable y se analiza una sola vez desde el paquete.

## Consecuencias

- Se puede mezclar una ruta local y una referencia web pública en la misma importación con el mismo contrato editorial.
- La trazabilidad permite saber qué versión web fundamentó una evidencia, incluso si el sitio cambia después.
- El importador no se convierte en un navegador general: no sigue enlaces del contenido, no acepta redes privadas ni formatos arbitrarios.

## Referencias

- [ADR 0012](0012-importacion-general-y-extraccion-editorial.md)
- [ADR 0015](0015-reconstruccion-editorial-en-importacion-de-proyectos.md)
- [Comando de importación](../../.opencode/commands/importar-proyecto.md)
