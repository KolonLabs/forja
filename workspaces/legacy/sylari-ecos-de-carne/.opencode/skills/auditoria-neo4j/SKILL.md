---
name: auditoria-neo4j
description: Protocolo de auditoría de consistencia entre la prosa de un capítulo (draft.md) y el grafo de relaciones en Neo4j. El cronista lo carga al final de cada capítulo para detectar discrepancias.
compatibility: opencode
---

# Skill: auditoria-neo4j

## Cuándo usar

El `cronista` carga este skill en el Paso 4 (auditar consistencia). El director nunca lo carga directamente.

## Objetivo

Comparar las relaciones que aparecen en la prosa del capítulo contra las relaciones existentes en Neo4j. Detectar discrepancias sin escribir en Neo4j. El grafo es territorio del `director` y `entidades`.

---

## Proceso

### Paso 1: Extraer relaciones del draft

Leer el `draft.md` del capítulo. Para cada interacción significativa entre entidades, extraer:

- **Entidad A y entidad B** — los IDs estables (`per-daniel`, `ser-naamah`, `lug-sotano`, etc.)
- **Dirección** — quién actúa sobre quién
- **Tipo de relación** — mapear la acción a un tipo del vocabulario Neo4j
- **Rol** — si aplica (para tipos person-person)

**Vocabulario de mapeo acción → tipo Neo4j:**

| Lo que dice el texto | Tipo Neo4j | Rol (si aplica) |
|---------------------|-----------|-----------------|
| "A penetra a B", "A folla a B" | ACCION_SOBRE | — (usar el que corresponda) |
| "A desea a B", "A teme a B", "A odia a B" | SENTIMIENTO_HACIA | deseo, miedo, odio... |
| "A y B son amantes" | PAREJA_DE | amante |
| "A es hijo de B" | FAMILIA_DE | hijo |
| "A trabaja en B" | TRABAJA_EN | — |
| "A vive en B" | VIVE_EN | — |
| "A posee B" | POSEE | — |
| "A está implicado en el hilo B" | IMPLICADO_EN | — |
| "A traiciona a B" | ACCION_SOBRE | traiciona |

Si un tipo o rol no existe en el vocabulario, no lo inventes. Márcalo como `tipo: no_vocabulario` en la discrepancia.

### Paso 2: Consultar Neo4j

Para cada entidad que aparece en el capítulo, ejecutar:

```powershell
python scripts/neo4j.py query-relationships --novela SLUG --entity per-<id>
```

Esto devuelve todas las relaciones actuales de esa entidad en el grafo.

### Paso 3: Comparar

Para cada relación detectada en el texto:

| Escenario | Discrepancia |
|-----------|-------------|
| Relación en el texto, **ausente** en Neo4j | `faltante` |
| Relación en Neo4j con tipo/rol distinto al del texto | `cambio` |
| Relación en Neo4j que el texto **contradice** (ej: Neo4j dice "alianza", texto dice "traición") | `contradiccion` |
| Relación en Neo4j que el texto **rompe** (ej: "A ya no trabaja en B") | `rota` |

**No marcar como discrepancia:**
- Relaciones que aparecen en Neo4j pero no se mencionan en este capítulo (son de capítulos anteriores y siguen vigentes)
- Entidades que no interactúan (no toda co-presencia es una relación)

### Paso 4: Formatear discrepancias

Cada discrepancia en el JSON de output:

```json
{
  "tipo": "faltante",
  "entidad_a": "per-daniel",
  "entidad_b": "ser-naamah",
  "tipo_relacion": "ACCION_SOBRE",
  "rol": "catalizador_de",
  "evidencia": "B_0012: 'Daniel sintió a Naamah activar su próstata'",
  "sugerencia": "Crear relación per-daniel → ser-naamah con ACCION_SOBRE / catalizador_de"
}
```

---

## Reglas

1. **Solo lectura en Neo4j.** No ejecutes `upsert-relationship` ni `delete-relationship`.
2. **No inventes tipos ni roles.** Si no encajan en el vocabulario, marca `no_vocabulario`.
3. **Evidencia concreta.** Cada discrepancia debe citar el beat y fragmento de texto que la justifica.
4. **Sugerencia accionable.** El director debe poder ejecutar la corrección sin interpretar.
5. **No inundes.** Si hay 20 discrepancias, es probable que el capítulo no esté sincronizado. Informa pero no satures — el director decidirá si vale la pena corregir todas o si el grafo necesita una revisión mayor.
