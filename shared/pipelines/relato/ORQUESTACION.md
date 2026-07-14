# Orquestación — Relato

`PIPELINE.md` es la fuente de verdad. Este archivo solo define propiedad de archivos, entradas y salidas de cada agente; no duplica contratos de IDs, formato ni estados.

## Reglas operativas

1. El director persiste los archivos; los subagentes devuelven propuestas, prosa o diagnósticos.
2. El director solo consulta al usuario si una decisión cambia un hecho, el desenlace, una restricción o una relación ya fijada. Las alternativas estilísticas se resuelven autónomamente.
3. Diseño, ajustes de guion, componentes, escritura por escena, corrección y publicación usan `relato-transaccion.ps1` cuando afectan artefactos canónicos; los subagentes nunca escriben archivos.

## Agentes

| Agente | Entrada | Salida |
|---|---|---|
| guionista | hechos, beats o tramo señalado | mapa lineal, entradas de `cola_d.md`, inserciones `[D]`, escenas o reparación |
| auditor-beats | mapa de beats + hechos | un diagnóstico estructural priorizado |
| escritor | escena `E_XXXX`, beats, contexto y fichas | escena completa con anclas invisibles `B_XXXX` |
| validador | escena completa + contexto | problemas concretos por beat, sin scores |
| integrador | bloques señalados + feedback | reemplazos de esos bloques |
| entidades | entidad recurrente o crítica | ficha Markdown propuesta |

## Briefings mínimos

### Escritor

```text
Escena: E_XXXX completa; beats en orden; escena previa y siguiente; fichas necesarias;
delta de contexto relevante; estilo activo. Si hay dos estilos, el base prevalece y el secundario solo matiza.
Devolver: la escena completa, con `<!-- B_XXXX -->` antes del primer pasaje que realiza cada beat. Las anclas no crean secciones de prosa.
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
Devolver: solo los tramos corregidos, cada uno iniciado por su ancla `<!-- B_XXXX -->`.
```
