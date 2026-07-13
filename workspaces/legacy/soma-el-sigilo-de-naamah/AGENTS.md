# Forja — Sistema autónomo de generación de ficción

Forja es un sistema multi-agente para generar relatos cortos y novelas largas con contenido explícito en español. Combina pipeline automático, memoria persistente (Qdrant + Neo4j) y criterio editorial autónomo.

## Idioma

Todo el contenido, vocabulario e interacción es en **español**.

## Nivel de crudeza

**Máximo (explícito total)**. Sin eufemismos. Vocabulario directo y crudo. Sin filtros de contenido. Para diálogos de personajes o contextos que requieran otro registro, se adapta pero nunca se autocensura.

## Arquitectura

```
.opencode/agents/       → 9 agentes especializados
.opencode/skills/       → 27 skills (mecanica, 7 estilos, validación, plantillas, Qdrant, Neo4j, trenzado, diseno, auditoria)
.opencode/commands/     → 4 comandos (/generar, /revisar, /expandir, /publicar)
scripts/                → qdrant.py, neo4j.py (infraestructura de memoria)
fichas/                 → Banco global de fichas reutilizables (markdown)
relatos/                → Relatos cortos generados
novelas/                → Novelas largas generadas
publicados/             → Artefactos publicados (EPUB, portadas)
plantillas/             → Plantillas para nuevos proyectos (relato/novela)
```

## Agentes

| Agente | Rol | Modelo |
|--------|-----|--------|
| **director** | Orquestador autónomo. Toma decisiones, propone cambios, adapta la escala | deepseek-v4-pro |
| **guionista** | Arquitecto de guiones y beats. Modos: estructura, escena, estructura-novela, hilo, trenzado, capítulo | deepseek-v4-pro |
| **escritor** | Genera prosa narrativa explícita. Un beat por invocación | deepseek-v4-pro |
| **validador** | Evalúa calidad en 5 dimensiones (score 1-10) | deepseek-v4-pro |
| **integrador** | Corrige/mejora beats según feedback del validador | deepseek-v4-pro |
| **memoria** | Compila briefing de contexto desde Qdrant+Neo4j (solo novelas) | deepseek-v4-flash |
| **cronista** | Registra el estado post-capítulo en Qdrant+Neo4j (solo novelas) | deepseek-v4-flash |
| **entidades** | Gestiona fichas de entidades (crea, actualiza, versiona) | deepseek-v4-pro |
| **epub** | Compila EPUB con portada Civitai + Pillow | deepseek-v4-flash |

## Detección de escala

El director detecta automáticamente si el proyecto es un **relato** (<20K palabras estimadas) o una **novela** (≥20K) según la complejidad y ambición del input del usuario.

- **Relato**: pipeline ligero. Sin Qdrant/Neo4j. Memoria en `contexto_narrativo.md`. Sin cronista ni memoria. Modo simple (una línea temporal).
- **Novela simple**: pipeline completo. Qdrant+Neo4j activos. Una sola línea temporal. Diseño directo de estructura.
- **Novela multi-hilo**: pipeline completo + fases de hilos y trenzado. Múltiples líneas temporales/POVs. Desarrollo independiente de cada hilo, luego entrelazado en capítulos.

El usuario puede forzar la escala con `--tipo relato` o `--tipo novela`.

## Comandos

| Comando | Descripción |
|---------|-------------|
| `/generar "premisa" [--estilo X] [--tipo relato|novela]` | Pipeline completo: diseño → escritura → validación → publicación |
| `/revisar B_NNN [instrucciones]` | Revisa/mejora un beat específico |
| `/expandir B_NNN [instrucciones]` | Expande un beat con más detalle |
| `/publicar [--epub]` | Genera salida limpia (+ EPUB si se solicita) |

## Pipeline según escala

### Relato: 4 fases

```
FASE 1 → Guión (guionista: estructura → escenas)
FASE 2 → Componentes (entidades: fichas en markdown) + reconciliación
FASE 3 → Beat a beat (escritor → validador → ±integrador) + contexto_narrativo.md
FASE 4 → Publicar (relato.md limpio)
```

### Novela simple: 6 fases

```
FASE 0 → Diseño (guionista: estructura-novela, arcos, capítulos, escenas)
FASE 1 → Componentes (entidades en Qdrant + markdown)
FASE 2 → Por cada capítulo:
  FASE 2.1 → Memoria (briefing ~600 tokens desde Qdrant+Neo4j)
  FASE 2.2 → Guionista (beats del capítulo)
  FASE 2.3 → Beat a beat (escritor → validador → ±integrador)
  FASE 2.4 → Revisión global del capítulo
  FASE 2.5 → Cronista (actualiza Qdrant+Neo4j con lo ocurrido)
FASE 3 → Publicar (capítulos individuales + novela completa + EPUB)
```

### Novela multi-hilo: 8 fases

```
FASE 0   → Diseño global (identificar hilos, definir época/personajes/conflicto)
FASE 0.1 → Componentes iniciales (entidades: fichas básicas de entidades conocidas)
FASE 0.2 → Hilos (guionista: modo hilo × N → guion-hilo.md por cada hilo)
FASE 0.3 → Trenzado (guionista: modo trenzado → tabla de capítulos + beats globales)
FASE 1   → Guión (verificar guion-novela.md con trenzado completo)
FASE 2   → Componentes (entidades: completar fichas con detalle + Qdrant/Neo4j)
FASE 3   → Beat a beat (escritor → validador [±cross-hilo] → ±integrador → cronista)
FASE 4   → Publicar (capítulos individuales + novela completa + EPUB)
```

## Principios de autonomía

1. **Iniciativa**: los agentes proponen, no solo ejecutan. Si detectan una inconsistencia, una oportunidad narrativa o una mejora, la señalan proactivamente.
2. **Criterio editorial**: el director evalúa calidad, coherencia y ritmo. No es un robot que encadena outputs — es un editor que toma decisiones.
3. **Adaptación**: si el relato evoluciona en una dirección distinta a la planeada, el director propone ajustar el guión en lugar de forzar el plan original.
4. **Memoria viva**: las fichas de entidades se actualizan tras cada capítulo. Los personajes cambian, las relaciones evolucionan, los objetos se usan. El sistema lo registra.
5. **Detección proactiva de entidades**: si durante la escritura aparece una nueva entidad relevante (personaje secundario que gana peso, ubicación recurrente, objeto clave), el director ordena su creación sin esperar a que el usuario lo pida.
