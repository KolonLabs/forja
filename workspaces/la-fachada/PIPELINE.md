# Pipeline — Relato (4 fases)

Escala `relato`. Pipeline ligero sin Qdrant/Neo4j. Una línea temporal, sin hilos.

> Rutas: ver `MAPA.md` · Spawn y contratos: `ORQUESTACION.md` · Estado: `config.json` + `guion.md` statuses

## Jerarquía narrativa

```
_actos.md (estructura: actos con objetivo, tensión y hechos)
  └── guion.md (escenas + hechos H_NNNN + beats B_NNNN — generado por el guionista)
        └── relato-draft.md (prosa desarrollada desde beats, secciones ## B_NNNN)
```

## Hechos y beats

| ID | Qué es | Dónde |
|----|--------|-------|
| `H_NNNN` | Hecho narrativo definido en `_actos.md`. Puede ser lineal o distribuido `[D]`. | `_actos.md` → `guion.md` |
| `B_NNNN` | Acción concreta que el escritor desarrolla en prosa | `guion.md` (bajo un hecho) |

- IDs locales de 4 dígitos por relato. Sin hechos globales.
- Estados: ✅ completo · 🔄 en progreso · ⬜ pendiente.
- Un hecho `[D · H_XX–H_YY]` no genera escenas propias — sus beats se inyectan en las escenas de los hechos lineales dentro del rango.
- Skills: `beats-estructura`, `tonos-beat`, `estructura-narrativa`, `hechos-distribuidos`.

---

## Fases

### FASE 1 — Diseño (`estado: diseno`)

| Paso | Agente | Skill | Entrada | Salida |
|------|--------|-------|---------|--------|
| 1.1 Identificar [D] | `director` | `scaffolding-hecho`, `hechos-distribuidos` | `_actos.md` | Anotaciones `🎬 Director:` bajo hechos `[D]` en `_actos.md` |
| 1.2 Estructura | `guionista` modo `estructura` | `estructura-narrativa`, `plantilla-guion` [+ `hechos-distribuidos` si hay `[D]`] | `BRIEF.md`, `_actos.md` (con anotaciones) | Estructura de actos con escenas (agrupando hechos) + inyección incremental de `[D]` |
| 1.3 Escenas | `guionista` modo `escena` | `beats-estructura`, `tonos-beat`, `plantilla-guion` | Estructura confirmada + fichas existentes | `guion.md` (escenas + hechos + beats) |
| 1.4 Auditoría atomizar | `auditor-beats` modo `atomizar` | `beats-estructura` | `guion.md`, `_actos.md` | Diagnóstico: beats inconclusos, sobrecargados. Director → guionista corrige |
| 1.5 Auditoría transiciones | `auditor-beats` modo `transiciones` | `validacion-coherencia`, `beats-estructura` [+ `hechos-distribuidos` si `[D]`] | `guion.md`, `_actos.md` | Diagnóstico: huecos narrativos. Director → guionista inserta beats puente |
| 1.6 Auditoría limpieza | `auditor-beats` modo `limpieza` | `beats-estructura`, `mecanica-prosa` | `guion.md` | Diagnóstico: prosa sobrante en beats. Director → guionista limpia |

**Gate:** `guion.md` completo con ≥1 escena y beats definidos.

**Transición:** `config.json.estado = "fichas"`.

---

### FASE 2 — Componentes (`estado: fichas`)

| Paso | Agente | Acción |
|------|--------|--------|
| 2.1 Extraer entidades | director | Lee `guion.md`, identifica todas las entidades |
| 2.2 Crear fichas | `entidades` (×N) | Crea `fichas/<tipo>_<slug>.md` para cada entidad |
| 2.3 Reconciliación | director | Verifica sin contradicciones entre fichas |
| 2.4 Inicializar | director | Crea `contexto_narrativo.md` (vacío) + `relato-draft.md` (vacío) |

**Gate:** Todas las entidades del guion tienen ficha. Sin contradicciones.

**Transición:** `config.json.estado = "escritura"`.

---

### FASE 3 — Beat a beat (`estado: escritura`)

Por cada beat `⬜` en `guion.md`, en orden secuencial:

| Paso | Agente | Acción |
|------|--------|--------|
| 3.1 Marcar | director | `🔄` en guion |
| 3.2 Escribir | `escritor` | Genera prosa → `relato-draft.md` (append `## B_NNNN`) |
| 3.3 Validar | `validador` (read-only) | Scope `completa` por defecto. 5 dimensiones |
| 3.4 Corregir | `integrador` (condicional) | Si score < 7 o dimensión < 5. Reescribe beat |
| 3.5 Confirmar | director | ✅ en guion. Actualiza `config.json.ultimo_beat_global` |
| 3.6 Actualizar | director | Si último beat de escena: actualiza `contexto_narrativo.md` (2-3 frases) |

**Umbral validador:** `score_global ≥ 8` y todas dimensiones ≥ 7 para aprobación directa sin integrador.

**Gate:** Todos los beats ✅. `contexto_narrativo.md` actualizado por escena.

**Transición:** `config.json.estado = "publicado"`.

---

### FASE 4 — Publicar (`estado: publicacion`)

| Paso | Acción |
|------|--------|
| 4.1 Limpiar | `relato-draft.md` → `relato.md`: conserva título, convierte marcadores de escena en `---`, elimina headings `## B_XX` |
| 4.2 Verificar | Sin headings residuales, sin dobles separadores, archivo > 0 bytes |

**Gate:** `relato.md` existe y es válido.

---

## Transiciones de estado

```
diseno → fichas → escritura → publicacion → publicado
```

## Agentes activos

`director`, `guionista`, `escritor`, `validador`, `integrador`, `entidades`

**No aplican:** `memoria`, `cronista`

## Skills activos (30 skills)

`mecanica-prosa`, `beats-estructura`, `estructura-narrativa`, `tonos-beat`, `plantilla-guion`, `plantilla-ficha`, `plantilla-personaje`, `plantilla-lugar`, `plantilla-objeto`, `plantilla-animal`, `plantilla-arco`, `plantilla-evento`, `plantilla-organizacion`, `validacion-crudeza`, `validacion-coherencia`, `validacion-geometria`, `validacion-sensorial`, `validacion-tono`, `consistencia-narrativa`, `contexto-subagente`, `desarrollo-narrativa`, `fichas-personajes`, `estilo-explicito`, `estilo-contemporaneo`, `estilo-erotico`, `estilo-fantasia`, `estilo-noir`, `estilo-romantico`, `estilo-thriller`, `estilo-prosa`

**No aplican (7 skills):** `qdrant`, `neo4j`, `auditoria-neo4j`, `diseno-hilo`, `trenzado-narrativo`, `validacion-cross-hilo`, `plantilla-hilo`

## Comandos

- `/refinar-hechos` — revisa y afina los hechos de _actos.md antes de generar
- `/validar-hechos` — valida coherencia narrativa entre hechos, detecta problemas de interpretación y propone mejoras
- `/generar` — inicia o continúa desde `config.json.estado`
- `/revisar-guion` — revisa la coherencia de guion.md (escenas, arcos, ritmo, transiciones)
- `/revisar B_NNNN [instrucciones]` — revisión puntual de un beat
- `/expandir B_NNNN [instrucciones]` — expansión de un beat
- `/publicar` — salida limpia

## Infraestructura

**Sin Qdrant. Sin Neo4j.** Memoria en `contexto_narrativo.md`. Fichas en markdown local.

## Política de reintentos

Máximo 3 reintentos por beat. Tipos: formato, contenido, timeout. Ver `ORQUESTACION.md` para detalle.

