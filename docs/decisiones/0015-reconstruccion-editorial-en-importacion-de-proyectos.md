# ADR 0015: Reconstrucción editorial durante la importación de proyectos

- Estado: aceptada
- Fecha: 2026-07-14
- Ámbito: `/importar-proyecto`, la skill `importacion-fuentes` y el scaffolder.

## Contexto

La importación ya distingue evidencia, hipótesis y conflictos, pero esa separación no impedía que una escaleta, unas notas o un guion parcial se convirtieran en un brief demasiado literal. Una fuente libre puede contener hechos comprimidos, orden provisional o una estructura insuficiente para que el guionista derive beats con variedad y ritmo.

La mejora no puede transformar inferencias en datos recuperados: a diferencia de una rehidratación, las fuentes pueden ser fragmentarias, contradictorias o no canónicas.

## Decisión

- El empaquetador continúa limitado a lectura y trazabilidad; no interpreta ni modifica las fuentes.
- Tras elegir una candidata, el scaffolder la trata como evidencia e idea, no como brief ni escaleta definitivos. Puede proponer añadir, fusionar, dividir, reordenar o descartar elementos para reforzar arco, causalidad y ritmo.
- Distingue los no negociables respaldados o confirmados de las hipótesis y propuestas editoriales. Toda ampliación sin respaldo declara su indicio y se valida de forma conjunta antes de persistir el brief.
- Una vez confirmada la escala, el scaffolder carga los skills de acto, hecho y escala. Los hechos finales pasan la prueba de derivación: detonante o situación, agencia bajo presión, cambio causal y consecuencia visible; las pautas añaden ámbito, variación y progresión o coste, sin convertirse en beats, escenas ni prosa.
- La Fase 6 confirma el argumento reconstruido y la escala, no solo la importación de las fuentes.

## Consecuencias

- El resultado puede ser más sólido y desarrollado que sus notas de partida sin falsear su procedencia.
- La persona usuaria conserva el control sobre decisiones creativas nuevas, mientras que el scaffolder puede proponerlas de modo autónomo y razonado.
- La trazabilidad se usa durante la conversación; los hechos del brief final no llevan referencias `F_XXX` ni copian la redacción fuente.

## Referencias

- [ADR 0012](0012-importacion-general-y-extraccion-editorial.md)
- [ADR 0014](0014-reconstruccion-editorial-en-rehidratacion-de-relatos.md)
- [Comando de importación](../../.opencode/commands/importar-proyecto.md)
- [Skill de extracción](../../.opencode/skills/importacion-fuentes/SKILL.md)
