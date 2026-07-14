# ADR 0012: Importación general de proyectos y extracción editorial guiada

- Estado: aceptada
- Fecha: 2026-07-14
- Sustituye parcialmente: ADR 0011
- Ámbito: importación de fuentes narrativas libres y selección de escala.

## Contexto

El mecanismo aprobado en ADR 0011 preserva correctamente la evidencia de fuentes libres, pero el nombre `/importar-relato` sugiere una escala que las fuentes todavía no han permitido confirmar. Además, la separación entre evidencia, hipótesis y decisiones de briefing dependía solo de instrucciones del comando y del agente.

## Decisión

El comando público pasa a ser `/importar-proyecto <slug-destino> --fuente <ruta> [...]` y su empaquetador se denomina `preparar-importacion-proyecto.ps1`.

- La importación es transversal: una fuente puede originar un `relato`, una `novela-simple` o una `novela-multi-hilo`.
- El `scaffolder` sigue siendo el único agente coordinador. Antes de interpretar el paquete, carga la skill del hub `importacion-fuentes`.
- La skill establece el contrato de extracción: candidatas independientes, evidencias trazables, hipótesis explícitas, conflictos/huecos y relevo acotado al briefing. No genera prosa, beats ni escenas.
- El scaffolder presenta una recomendación razonada de escala al cerrar la Fase 5. La persona usuaria la confirma o la modifica; la inferencia no crea ni fija automáticamente un workspace de una escala.
- Se mantiene el empaquetado de solo lectura, los límites de formatos y la eliminación del paquete temporal definidos en ADR 0011.

## Consecuencias

- El nombre público no condiciona la arquitectura narrativa antes de analizar las fuentes.
- La extracción se vuelve reutilizable y más consistente sin crear otro agente ni fragmentar el briefing editorial.
- La confirmación humana evita que una inferencia sobre extensión, número de POVs o estructura convierta equivocadamente una semilla en un proyecto de escala inadecuada.

## Referencias

- [ADR 0011](0011-importacion-de-fuentes-narrativas-libres.md)
- [Comando de importación](../../.opencode/commands/importar-proyecto.md)
- [Skill de extracción](../../.opencode/skills/importacion-fuentes/SKILL.md)
