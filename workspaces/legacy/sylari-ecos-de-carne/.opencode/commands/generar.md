---
description: Genera un relato corto o novela larga. El director detecta la escala automáticamente.
agent: director
---

# /generar

Genera un relato corto o una novela larga con contenido explícito en español. El pipeline se adapta automáticamente a la escala del proyecto.

## Sintaxis

```
/generar "premisa o descripción" [--estilo X] [--tipo relato|novela] [--revision completa|media|ligera]
```

## Parámetros

| Parámetro | Valores | Default | Descripción |
|-----------|---------|---------|-------------|
| `premisa` | texto libre | (requerido) | Descripción de la historia: idea, personajes, mundo, tono deseado |
| `--estilo` | noir, romantico, erotico, thriller, fantasia, contemporaneo | contemporaneo | Estilo narrativo |
| `--tipo` | relato, novela | auto | Fuerza la escala. Por defecto, el director la detecta |
| `--revision` | completa, media, ligera | completa | Nivel de validación: completa (5 dims), media (3 dims), ligera (sin validador) |

## Ejemplos

```
/generar "Un diseñador junior descubre un sigilo sumerio en el sótano de su oficina y lo convierte en el logo de una app"
/generar "Cinco androides infiltran Madrid para colonizar la Tierra mediante compuestos psicoactivos" --estilo thriller --tipo novela
/generar "Una mujer casada descubre el deseo en un club clandestino" --estilo erotico --revision media
```

## Detección automática de escala

El director analiza la premisa y decide:
- **Relato**: historia autoconclusiva, ≤20K palabras estimadas, pocos personajes, 1-2 arcos
- **Novela**: historia con múltiples arcos, ≥20K palabras estimadas, elenco amplio, worldbuilding complejo

Si no está seguro, pregunta al usuario.

## Pipeline

### Relato (4 fases)
1. **Guión** — el guionista diseña escenas y beats (interactivo con el usuario)
2. **Componentes** — el entidades crea fichas de personajes, lugares y objetos + reconciliación
3. **Beat a beat** — escritor → validador → ±integrador. Contexto narrativo automático
4. **Publicar** — `relato.md` limpio

### Novela (6 fases)
0. **Diseño** — estructura completa: arcos, capítulos, escenas, fichas iniciales
1. **Componentes** — entidades en Qdrant + Neo4j
2. **Por capítulo**: memoria → guionista → beat a beat → revisión global → cronista
3. **Publicar** — capítulos individuales + novela completa + EPUB

## Output

- **Relato**: `relatos/[nombre]/relato.md`
- **Novela**: `novelas/[slug]/novela.md` + `novelas/[slug]/capitulos/cap-XX/capitulo.md`
- Con `--epub` en `/publicar`: EPUB con portada generada por IA

## Notas

- El director tiene iniciativa editorial: propone cambios, detecta problemas, sugiere mejoras
- Las fichas de entidades se versionan automáticamente (timestamp + hash)
- En novelas, la memoria persistente (Qdrant + Neo4j) mantiene coherencia entre capítulos
- El usuario puede interrumpir en cualquier fase para ajustar dirección
