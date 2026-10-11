---
name: validacion-crudeza
description: Criterios de evaluación de explicitud según el nivel fijado en el proyecto y checklist de eufemismos. Úsalo cuando necesites validar o corregir el nivel de crudeza de un texto.
user-invocable: false
---

# Validación de Crudeza

## Primero: el nivel del proyecto

El criterio depende de la explicitud fijada para el proyecto: `config.json.explicitud`, repetida en `AGENTS.md` y `BRIEF.md`. Las restricciones de `AGENTS.md` prevalecen sobre este skill. Si el nivel falta o es ambiguo, no supongas `maximo`: señálalo al director como incidencia `bloqueante`.

| Nivel | Qué se exige | Qué se corrige |
|---|---|---|
| `maximo` | Escenas explícitas mostradas con precisión física y vocabulario directo (secciones 1-4) | Eufemismos, resúmenes, actos fuera de cámara |
| `alto` | Igual que `maximo` en las escenas fuertes; no todas lo son ni se fuerzan | Eufemismos y resúmenes en escenas fuertes; escenas fuertes gratuitas |
| `medio` | Lenguaje directo y sin eufemismos; el sexo y lo gráfico están presentes pero no se recrean: lo más gráfico se elide | Eufemismos en el lenguaje general; detalle gráfico sostenido que supere el nivel; una escena fuerte puntual convertida en el centro del capítulo |
| `bajo` | El contenido adulto se menciona, no se describe | Cualquier descripción del acto o de lo gráfico |
| `minimo` | Sin contenido explícito | Cualquier contenido explícito |

En `medio`, `bajo` y `minimo`, la elipsis no es un defecto: no la corrijas como «acto fuera de cámara». Las secciones 2-4 y la checklist sexual solo se aplican en `maximo` y `alto`. La sección 1 (sin eufemismos de pudor) vale en `maximo`, `alto` y `medio`.

## Criterios editoriales (`maximo` y `alto`)

### 1. Ausencia de eufemismos
Sin "miembro", "senos", "entrepierna", "hacer el amor", "mantener relaciones", "clímax" donde corresponda el término directo. El nivel del proyecto no se rebaja salvo excepcion aprobada (dialogo del personaje, contexto medico, ironia, estilo declarado menor).

### 2. Vocabulario explícito
Polla, coño, tetas, follar, correrse, mamar, lamer, dedear — directos y sin variantes decorativas. La repeticion del termino correcto es valida; la variedad no se consigue a costa de eufemismos.

### 3. Mostrar, no contar
En escenas explicitas, el acto se muestra con precision fisica: quien, donde, como y con que resultado inmediato en el cuerpo. No se resume ni se sustituye el detalle por valoraciones ("la comió despacio, con pasion", "sin prisa") que dejan la accion fuera de camara. La lengua, los circulos sobre el clitoris, el dedo que entra, la humedad, la presion, los fluidos y los sonidos se describen cuando la escena los contiene; no como inventario mecanico, sino con sensacion y geometria coherente.

### 4. Sin rodeos
Sin insinuar en lugar de describir ni saltarse partes: la camara sigue la accion sin cortes. El cierre del acto (orgasmos, donde cae el semen, el cuerpo despues) es tan explicito como el desarrollo.

## Checklist de eufemismos y resumenes (`maximo` y `alto`)

Reporta cada caso con incidencia concreta (fragmento, problema, correccion), sin gate por score:

- ¿Usa "miembro" en vez de "polla"?
- ¿Usa "senos" en vez de "tetas"?
- ¿Usa "entrepierna" en vez de "coño"?
- ¿Usa "hacer el amor" en vez de "follar"?
- ¿Usa "mantener relaciones"?
- ¿Describe orgasmos como "clímax"?
- ¿Evita describir fluidos?
- ¿Evita describir sonidos explícitos?
- ¿Usa metáforas donde debería ser directo?
- ¿Insinúa en vez de describir?

## Checklist por debajo de `alto`

- `medio`: ¿hay eufemismos de pudor en el lenguaje ordinario? ¿Se sostiene el detalle gráfico más allá de lo que el nivel permite? ¿Una escena fuerte desplaza al conflicto del capítulo?
- `bajo` y `minimo`: ¿se describe algo que solo debía mencionarse, o se incluye algo que el nivel excluye?

## Formato de respuesta

Respeta el contrato del consumidor: el agente `validador` de prosa usa su informe vigente (candidato/hash, estado e incidencias con fragmento, problema, gravedad y correccion). Para director o comandos de revision de guion, diagnostico sin exigir hash de candidata inexistente. Este skill no crea otro formato ni exige puntuaciones por dimension.

En `maximo` y `alto`, una escena explicita con resumenes o acciones fuera de camara es `corregir` aunque el vocabulario sea crudo; un termino directo no compensa un acto no mostrado. Un error factual no se salva por media.

## Excepciones permitidas

Solo en estos casos se permite un término menos crudo que el que pide el nivel:
1. **Diálogo de personaje**: Si el personaje habla así por educación/estatus
2. **Contexto médico**: Si un personaje es médico y habla técnicamente
3. **Ironía**: Si el narrador usa un eufemismo de forma irónica
4. **Estilo específico**: Si el estilo pide un nivel menor (ej: romántico)

En `maximo` y `alto`, en cualquier otro caso: **SIEMPRE el término más crudo**.
