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

El usuario puede forzar la escala con `--tipo relato` o `--tipo novela`.

## Comandos

| Comando | Descripción |
|---------|-------------|
| `/generar "premisa" [--estilo X] [--tipo relato|novela]` | Pipeline completo: diseño → escritura → validación → publicación |
| `/revisar B_NNN [instrucciones]` | Revisa/mejora un beat específico |
| `/expandir B_NNN [instrucciones]` | Expande un beat con más detalle |
| `/publicar [--epub]` | Genera salida limpia (+ EPUB si se solicita) |
