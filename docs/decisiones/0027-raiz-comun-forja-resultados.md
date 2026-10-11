# ADR 0027: Raíz común `Forja-resultados` para obras y publicados

- Estado: aceptada
- Fecha: 2026-10-11
- Ámbito: resolución de rutas del hub (`scripts/lib/common.ps1`) y documentación.
- Sustituye parcialmente: ADR 0026, punto 2 (rutas por defecto de las raíces).

## Contexto

ADR 0026 sacó las obras y los libros del hub a dos carpetas hermanas, `..\Obras` y `..\Publicados`. Junto al hub hay otros proyectos ajenos a Forja, y dos carpetas sueltas con nombres genéricos no dejan ver que ambas son producto de Forja ni que van juntas.

## Decisión

1. **Una carpeta común de resultados.** Todo lo que produce Forja vive en `Forja-resultados/`, hermana del hub: `Forja-resultados/Obras` y `Forja-resultados/Publicados`. Hoy: `C:\Proyectos\Personal\Writting\Forja-resultados`.
2. **Variables.** `FORJA_RESULTADOS` sitúa la carpeta común. `FORJA_OBRAS` y `FORJA_PUBLICADOS` siguen sobrescribiendo cada raíz por separado y prevalecen sobre la común; los tests las usan para trabajar en carpetas temporales.
3. **Sin cambios de contrato.** Lo demás de ADR 0026 se mantiene: un git por obra, sin copias de seguridad ni commits automáticos, `/compilar` en la obra y antologías en el hub. `scripts/ruta-obra.ps1` sigue siendo la forma de conocer las rutas.

## Migración (aplicada el 2026-10-11)

`C:\Proyectos\Personal\Writting\Obras` y `C:\Proyectos\Personal\Writting\Publicados` se movieron, sin cambios de contenido, a `C:\Proyectos\Personal\Writting\Forja-resultados\`. Mover la carpeta no afecta al git de cada obra.

## Consecuencias

- Una sesión abierta en la ruta anterior de una obra debe reabrirse en la nueva.
- Las obras no guardan rutas absolutas al hub ni a su raíz, así que no requieren cambios.

## Referencias

- [ADR 0026](0026-obras-como-repositorios-independientes-fuera-del-hub.md)
- [scripts/lib/common.ps1](../../scripts/lib/common.ps1), [scripts/ruta-obra.ps1](../../scripts/ruta-obra.ps1)
