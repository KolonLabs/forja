# Orquestación — Relato

`PIPELINE.md` es la fuente de verdad. Este archivo solo define propiedad de archivos, entradas y salidas de cada agente.

## Reglas operativas

1. Los únicos IDs son `H_XXXX`, `B_XXXX` y `E_XXXX`; son globales, visibles y no se renumeran.
2. El director persiste los archivos. Los subagentes devuelven propuestas, prosa o diagnósticos.
3. El director solo consulta al usuario si una decisión cambia un hecho, el desenlace, una restricción o una relación ya fijada. Las alternativas estilísticas se resuelven autónomamente.
4. Los backups y el registro se crean solo para bloqueos, cambios estructurales y ediciones; no para operaciones rutinarias.

## Agentes

| Agente | Entrada | Salida |
|---|---|---|
| guionista | hechos, beats o tramo señalado | mapa de beats, propuesta `[D]`, escenas o reparación |
| auditor-beats | mapa de beats + hechos | un diagnóstico estructural priorizado |
| escritor | escena `E_XXXX`, beats, contexto y fichas | escena completa con bloques `B_XXXX` |
| validador | escena completa + contexto | problemas concretos por beat, sin scores |
| integrador | bloques señalados + feedback | reemplazos de esos bloques |
| entidades | entidad recurrente o crítica | ficha Markdown propuesta |

## Formato de guion

```markdown
### E_0001 — Nombre

- Ubicación: ...
- Tiempo y POV: ...
- Objetivo: ...
- Resultado: ...
- Arco tonal: contenido → tenso → revelación
- Salida: continua | separador

#### Beats

⬜ B_0001 — Acción concreta y consecuencia.
⬜ B_0002 — Acción que cambia la situación. [registro: explícito / visceral]
```

`[registro: ...]` es opcional: el beat sin etiqueta hereda el arco tonal de la escena. No se escriben extensiones, etiquetas `H`, etiquetas `D` ni prosa en estas líneas.

## Modos del guionista

| Modo | Devuelve |
|---|---|
| `beats` | Mapa global de beats y cobertura temporal `H → B`. |
| `distribuidos` | Apariciones de `[D]` según la función anotada en `cola_d.md`. |
| `escenas` | Escenas operativas manejables, con arco tonal y tipo de salida. |
| `reparar` | Cambio mínimo de beats o escenas, con impacto declarado. |

## Briefings mínimos

### Escritor

```text
Escena: E_XXXX completa; beats en orden; escena previa y siguiente; fichas necesarias;
delta de contexto relevante; estilo activo.
Devolver: la escena completa, con un bloque ## B_XXXX — acción por beat.
```

### Validador

```text
Escena: E_XXXX completa; guion de escena; contexto y fichas relevantes.
Devolver: problemas factuales bloqueantes y observaciones editoriales por B_XXXX. Sin puntuaciones.
```

### Integrador

```text
Escena: E_XXXX; bloques B_XXXX señalados; feedback; bloque anterior y posterior;
contexto y estilo.
Devolver: solo los bloques corregidos, cada uno con su heading.
```

## Estados

| Estado | Operaciones |
|---|---|
| `diseno` | generar, refinar/validar hechos, revisar o reparar guion |
| `fichas` | generar y crear fichas bajo demanda |
| `escritura` | generar, revisar/expandir bloques; auditoría sin cambio estructural |
| `correccion` | corregir y cambios transaccionales |
| `finalizado`, `publicado` | solo lectura; para contenido nuevo, edición derivada |
