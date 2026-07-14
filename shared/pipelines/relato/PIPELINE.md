# Pipeline — Relato (4 fases)

Escala `relato`. Pipeline ligero, sin Qdrant ni Neo4j: todos los contratos y la memoria viven en archivos Markdown locales.

> Rutas: `MAPA.md` · contratos de agentes: `ORQUESTACION.md` · progreso: `config.json`, `guion.md` y `contexto_narrativo.md`.

## Contrato narrativo canónico

```text
_actos.md: H_XXXX (hechos del briefing)
       ↓
guion.md: B_XXXX (beats globales, en orden narrativo)
       ↓
guion.md: E_XXXX (escenas que agrupan beats contiguos)
       ↓
relato-draft.md: prosa por B_XXXX, agrupada por E_XXXX
       ↓
relato.md: manuscrito limpio
```

| ID | Función | Regla de identidad |
|---|---|---|
| `H_XXXX` | Hecho fijado por el briefing. Puede ser lineal o distribuido `[D]`. | No se renumera durante la generación. |
| `B_XXXX` | Unidad causal mínima del arco y de la prosa. | Global, único y durable. Un beat nuevo toma el siguiente número disponible; nunca se renumeran beats existentes. |
| `E_XXXX` | Contenedor dramático de beats contiguos. | Global y durable tras su creación. Puede cambiar su composición en una corrección estructural. |

El orden de los bloques en `guion.md` determina el orden narrativo; el número no se reutiliza ni se recalcula al insertar contenido. No existen `stable_id`, `parent_id` ni secuencias locales en relato.

Estados de beat: `⬜ pendiente` → `🔄 en_progreso` → `✅ aprobado`; `⛔ bloqueado` detiene el pipeline y requiere una resolución explícita.

---

## FASE 1 — Diseño (`estado: diseno`)

| Paso | Agente | Resultado |
|---|---|---|
| 1.1 Preparar | director | Verifica hechos `H_XXXX`, rangos `[D]` y restricciones del brief. |
| 1.2 Mapa de beats | guionista, modo `beats` | Genera todos los `B_XXXX` globales a partir de los hechos lineales. |
| 1.3 Inyectar `[D]` | director + guionista, modo `distribuidos` | Añade beats de hechos distribuidos junto a un beat ancla `B_XXXX`, sin crear escenas propias. |
| 1.4 Auditar arco | auditor-beats: `cobertura`, `atomizar`, `transiciones`, `limpieza` | Corrige causalidad, cobertura de `H_XXXX`, granularidad y transiciones. Máximo dos ciclos de reparación. |
| 1.5 Agrupar escenas | guionista, modo `escenas` | Crea `E_XXXX` agrupando beats contiguos por continuidad de espacio, tiempo, POV, objetivo y tensión. |
| 1.6 Auditar escenas | auditor-beats, modo `escenas` | Verifica función dramática, ritmo, entradas/salidas y transiciones entre escenas. |

**Gate de beats:** cada `H_XXXX` lineal está cubierto por uno o más beats; cada `[D]` está resuelto dentro de su rango; cada `B_XXXX` es atómico, único y tiene consecuencia.

**Gate de escenas:** cada beat pertenece a exactamente una `E_XXXX`; los beats de una escena son contiguos; toda escena tiene ubicación, tiempo, POV, objetivo, tensión, resultado y transición.

Si un gate no se resuelve en dos reparaciones, el director marca los beats implicados `⛔ bloqueado`, conserva el diagnóstico en `registro-pipeline.md` y no pasa a FASE 2.

**Transición:** `config.json.estado = "fichas"`.

---

## FASE 2 — Componentes (`estado: fichas`)

1. El director extrae entidades del guion y crea las fichas Markdown necesarias.
2. Reconcilia nombres, rasgos, ubicaciones y relaciones entre fichas.
3. Crea `contexto_narrativo.md`, `relato-draft.md` y `registro-pipeline.md` si aún no existen.

**Gate:** entidades relevantes con ficha y sin contradicciones; memoria local inicializada.

**Transición:** `config.json.estado = "escritura"`.

---

## FASE 3 — Escritura por escena y beat (`estado: escritura`)

Se recorren las escenas `E_XXXX` y, dentro de cada una, sus beats `B_XXXX` en el orden del guion.

1. El director marca el beat `🔄`.
2. El escritor devuelve solamente la prosa del beat. El director es el único que persiste el bloque con el formato `## B_XXXX — acción` y, al abrir una escena, `<!-- ESCENA E_XXXX: nombre -->`.
3. El validador evalúa las dimensiones que el director seleccionó para el beat.
4. Si falla, el integrador devuelve el bloque corregido. El director lo reemplaza de forma exacta y revalida con **las mismas dimensiones**.
5. Tras tres intentos fallidos, el beat queda `⛔ bloqueado`; no se continúa ni se publica.
6. Al aprobar, el director marca `✅`. Al cerrar una escena, actualiza `contexto_narrativo.md` con su resumen y el estado de entidades.

**Gate:** todos los `B_XXXX` están `✅`; el draft contiene cada beat del guion exactamente una vez, sin beats huérfanos, y el contexto está actualizado tras cada `E_XXXX`.

---

## FASE 4 — Finalizar

1. Comprueba de nuevo la correspondencia exacta entre `guion.md` y `relato-draft.md`.
2. Crea `relato.md` con `# <titulo de config.json>`, convierte cada marcador `E_XXXX` en `---` y elimina los headings `B_XXXX`.
3. Verifica que no queden IDs de control, separadores dobles ni contenido vacío.

**Transición:** `config.json.estado = "finalizado"`. El estado `publicado` solo lo asigna el hub tras compilar correctamente.

---

## Correcciones y ediciones

- En `diseno`, `/refinar-hechos`, `/validar-hechos` y `/revisar-guion` pueden modificar la estructura.
- En `fichas` o `escritura`, `/revisar-guion` es solo auditoría; cualquier cambio estructural exige una corrección transaccional de guion, draft y contexto.
- En `finalizado` o `publicado`, el contenido es inmutable. Una modificación requiere una edición derivada en `correccion`.
- En una edición derivada, una corrección estructural reagrupa escenas cuando sea necesario, reescribe los beats afectados y regenera el contexto desde la primera escena modificada.

## Infraestructura

Sin Qdrant ni Neo4j. Las fichas son Markdown local y `contexto_narrativo.md` es la única memoria acumulada.
