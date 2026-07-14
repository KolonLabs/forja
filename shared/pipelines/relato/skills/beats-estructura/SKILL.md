---
name: beats-estructura
description: Contrato de beats globales para relatos. Úsalo al crear, insertar, revisar o escribir beats.
---

# Beats globales — Relato

## Identidad y orden

- Un beat se identifica exclusivamente como `B_XXXX`.
- El identificador es global, único y durable dentro del relato. Se toma de `config.json.ultimo_beat_seq` y nunca se reutiliza ni renumera.
- La posición narrativa es la posición de la línea en `guion.md`; no se deduce del número de ID.
- Al insertar un beat, se crea el siguiente `B_XXXX` y se coloca junto al beat ancla. Las referencias existentes siguen intactas.
- No uses `stable_id`, `parent_id`, `seq`, UUIDs ni displays derivados.

## Formato canónico

```text
⬜ B_0001 — Acción concreta y verificable [Tono — EXTENSIÓN] {H_0001}
```

Un beat distribuido añade la procedencia:

```text
⬜ B_0012 — Ana borra el aviso antes de que Luis lo lea [Tenso — BREVE] {D:H_0004}
```

Estados permitidos: `⬜`, `🔄`, `✅`, `⛔`.

## Un beat correcto

- Tiene sujeto, acción, consecuencia y un cambio comprobable.
- Es una unidad causal mínima, no un resumen ni una escena completa.
- Puede escribirse en prosa sin necesitar inventar una acción nuclear nueva.
- Conserva referencias a uno o más `H_XXXX`; los beats `[D]` conservan `D:H_XXXX`.
- Lleva uno o dos tonos y una extensión de `tonos-beat`.

No contiene ambientación, psicología abstracta ni prosa acabada: esos elementos corresponden al escritor.

## Inserción, eliminación y reparación

1. Localiza el beat ancla por `B_XXXX`.
2. Crea el siguiente `B_XXXX` solo si aparece una acción causal nueva.
3. Inserta, elimina o reordena las líneas necesarias sin cambiar los IDs supervivientes.
4. Revisa las transiciones inmediatas y la cobertura de hechos.
5. Si la modificación afecta a una escena ya agrupada, reevalúa esa `E_XXXX` y las adyacentes; no se renumeran escenas.

## Checklist

| Criterio | Debe cumplirse |
|---|---|
| Identidad | `B_XXXX` único, global y no reutilizado |
| Acción | sujeto + acción concreta + consecuencia |
| Cobertura | referencia a `H_XXXX` o `D:H_XXXX` |
| Atomicidad | no fusiona acontecimientos independientes |
| Causalidad | enlaza con el beat previo y prepara el siguiente |
| Escritura | extensión y tono son realizables en prosa |
