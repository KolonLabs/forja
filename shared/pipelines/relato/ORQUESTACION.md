# Orquestación — Relato

Referencia operativa para el director. El contrato narrativo es `H_XXXX → B_XXXX → E_XXXX → prosa`; `PIPELINE.md` define gates y estados.

## Reglas globales

1. Relato no usa `stable_id`, `parent_id`, `seq`, Qdrant ni Neo4j.
2. `H_`, `B_` y `E_` son IDs visibles, globales y únicos dentro del workspace. Al crear un beat o una escena se toma el siguiente contador de `config.json`; nunca se renumera un ID existente.
3. El director es el único escritor persistente de `config.json`, `guion.md`, `relato-draft.md`, `contexto_narrativo.md` y `registro-pipeline.md`. Los subagentes devuelven contenido o diagnósticos.
4. Antes de sobrescribir, el director crea backup; cada transición, reparación o bloqueo se anota en `registro-pipeline.md`.
5. El director decide autónomamente dentro de `BRIEF.md`. Solo detiene el flujo si una reparación contradice una restricción explícita, hay dos direcciones editoriales equivalentes o se agotan los reintentos.

## Matriz de agentes

| Agente | Invocado por | Devuelve | No hace |
|---|---|---|---|
| director | comandos del usuario | decisiones, archivos y estados | Prosa o guion de autoría propia |
| guionista | director | mapa de beats, inserciones `[D]`, agrupación de escenas o tramos corregidos | Persistir archivos |
| auditor-beats | director | diagnóstico por `H_`/`B_`/`E_` | Modificar archivos |
| escritor | director | prosa de un `B_XXXX` | Encabezados, estados o archivos |
| validador | director | JSON de evaluación | Modificar archivos |
| integrador | director | bloque `B_XXXX` corregido | Persistir archivos |
| entidades | director | ficha Markdown propuesta | Persistir archivos |

## Modos del guionista

| Modo | Entrada | Salida |
|---|---|---|
| `beats` | `BRIEF.md`, `_actos.md`, contadores | Mapa global de `B_XXXX` para todos los hechos lineales. |
| `distribuidos` | `guion.md`, `cola_d.md`, beats ancla `B_XXXX` | Beats `[D]` insertados tras el ancla, dentro de su rango. |
| `escenas` | Mapa completo de beats | Escenas `E_XXXX` que agrupan beats contiguos. |
| `reparar` | Tramo señalado por auditor | Sustitución mínima de beats o agrupaciones, sin renumerar IDs existentes. |

## Formato de guion

```markdown
### E_0001 — Nombre de escena

- Ubicación: ...
- Tiempo: ...
- POV: ...
- Objetivo: ...
- Tensión: ...
- Resultado: ...
- Transición: ...
- Hechos cubiertos: H_0001, H_0002

#### Beats

⬜ B_0001 — acción concreta [Tenso — BREVE] {H_0001}
⬜ B_0002 — consecuencia concreta [Revelación — MEDIA] {H_0002}
```

Un beat puede mencionar varios hechos con `{H_..., H_...}`. Un beat `[D]` añade `{D:H_0004}` y siempre comparte escena con beats lineales.

## Briefings mínimos

### Escritor

```text
Beat: B_XXXX; escena: E_XXXX; posición: N de M.
Leer: bloque de escena, contexto_narrativo.md, fichas relevantes, prosa previa de la escena y últimos tres beats previos.
Devolver: solo prosa para B_XXXX, sin heading.
```

### Validador

```text
Beat: B_XXXX; texto y acción del guion; bloque E_XXXX; fichas y contexto relevantes.
Dimensiones: [lista exacta].
Devolver: JSON con beat_id, dimensiones_evaluadas, umbral_aplicado y aprobado.
```

### Integrador

```text
Beat: B_XXXX; bloque actual; feedback; mismas dimensiones de validación; bloque E_XXXX y ventanas anterior/posterior.
Devolver: bloque corregido con heading ## B_XXXX — acción.
```

## Estados y mutabilidad

| Estado | Operaciones permitidas |
|---|---|
| `diseno` | generar, refinar/validar hechos, revisar o reparar guion |
| `fichas` | generar; auditoría de guion sin cambios estructurales |
| `escritura` | generar, revisar/expandir beats; auditoría sin cambios estructurales |
| `correccion` | corregir, revisar/expandir; cambios estructurales transaccionales |
| `finalizado`, `publicado` | solo lectura/verificación; para cambiar contenido, edición derivada |

## Contadores de `config.json`

| Campo | Uso |
|---|---|
| `ultimo_hecho_seq` | Último hecho asignado por el scaffolder; no se modifica al generar. |
| `ultimo_beat_seq` | Último número de `B_XXXX` asignado. |
| `ultimo_escena_seq` | Último número de `E_XXXX` asignado. |
