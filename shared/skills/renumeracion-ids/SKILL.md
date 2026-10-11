---
name: renumeracion-ids
description: Renumerar identificadores visibles H_XXXX, E_XXXX y B_XXXX para dejarlos consecutivos (por ejemplo, B_0101 intercalados entre B_0014 y B_0015) con scripts/renumerar.ps1 y revisar después sus referencias con la tabla viejo -> nuevo. Úsalo solo cuando la persona usuaria pida renumerar o dejar consecutiva la numeración.
user-invocable: false
---

# Renumeración de identificadores

Renumerar tiene dos partes: la mecánica, que hace `scripts/renumerar.ps1`, y la revisión de referencias, que haces tú con la tabla que imprime el script.

## Cuándo

- **Solo a petición expresa de la persona usuaria.** Por defecto no se renumera: lo insertado recibe el siguiente número libre y los identificadores persistidos son durables.
- Nunca para «ordenar» por iniciativa propia ni como efecto secundario de otra tarea.
- `stable_id` no se renumera nunca: este procedimiento solo cambia números visibles.

## 1. Simular y aplicar

```text
pwsh -NoProfile -File scripts/renumerar.ps1 <fichero> -LineStart "<prefijos>"            # simula: tabla viejo -> nuevo, no escribe
pwsh -NoProfile -File scripts/renumerar.ps1 <fichero> -LineStart "<prefijos>" -InPlace   # aplica
```

- Solo renumera líneas que **definen** un identificador: prefijo al inicio de línea, número y separador (` —`, `:`, ` [` o ` |`). Las menciones en mitad de línea y las notas como `- H_0001 se superpone…` no se tocan.
- Asigna números en orden de aparición desde `-Start` (por defecto 1), con 4 dígitos (`-Pad`).
- Varios prefijos van en una sola cadena separada por comas y comparten contador.
- Es idempotente: si ya está consecutivo, informa «Sin cambios» y no escribe.
- Si avisa de un identificador definido dos veces, para y consulta: la tabla de ese id es ambigua.

Presenta la simulación a la persona usuaria antes de aplicar.

| Escala | Fichero | `-LineStart` |
|---|---|---|
| relato | `guion.md`, beats | `"⬜ B_,🔄 B_,✅ B_"` (todos los estados; añade `- ` delante si las líneas lo llevan) |
| relato | `guion.md`, escenas | `"### E_"` |
| relato | `_actos.md`, hechos | `"- H_"` |
| novela | `_actos.md`, hechos (`- H_0003: …`, `- H_0004 [D · …]: …`) | `"- H_"` |

Tablas de beats con filas que empiezan por la barra vertical y `B_0001`: `-LineStart` es la barra, un espacio y `B_`; con `-Start` igual al primer número del capítulo si la secuencia es global.

Los guiones de capítulo de novela con beats `<stable_id> [seq]` no usan este formato: su `seq` lo gestiona el `guionista` y se alinea en Qdrant (sección 3).

## 2. Revisar referencias con la tabla

El script no cambia las referencias. Con la tabla `viejo -> nuevo`:

1. **Busca cada número viejo** en los ficheros que pueden citarlo:
   - relato: `_actos.md`, `guion.md` (notas y menciones), `relato-draft.md` (`<!-- ESCENA E_XXXX: … -->` y anclas `<!-- B_XXXX -->`), `correcciones.md`, `contexto_narrativo.md`, fichas, `config.json`, `BRIEF.md`;
   - novela: `_actos.md` (rangos `[D · H_XXXX–H_YYYY]`), `guion-novela.md`, guiones de hilo y de capítulo (`Rango de hechos`, `[D · …]`, `<stable_id> [seq]` de los hechos), `cola_d.md`, `contexto.md`, fichas, `config.json`.
2. **Aplica la tabla en una sola pasada.** Reemplazar uno a uno encadena errores: tras `B_0015 -> B_0019`, el siguiente `B_0019 -> B_0023` cambiaría también el que acabas de escribir. Hazlo en dos fases:
   - cada número viejo pasa a un marcador temporal con el nuevo (`B_0101` -> `B_#0015#`);
   - cuando no quede ninguno viejo, quita los marcadores (`B_#0015#` -> `B_0015`).
3. **No toques lo que no es de este proyecto.** Una nota como «la cabina de I (B_0116–B_0049)» cita otra obra: esos números no están en la tabla y se quedan.
4. **Comprueba al final**:
   - vuelve a ejecutar el script sin `-InPlace`: debe responder «Sin cambios»;
   - busca `#` de marcadores olvidados;
   - en relato, el contrato del draft compara escenas y beats con el guion: deben coincidir.
5. Informa a la persona usuaria de los ficheros tocados y de cualquier mención dudosa que hayas dejado sin cambiar.

## 3. Por escala

**Relato.** Los artefactos canónicos solo cambian dentro de una transacción (`scripts/relato-transaccion.ps1`). Ejecuta el script sobre las copias de `.forja-transaccion/siguiente/` y confirma al terminar la revisión:
- solo `_actos.md`: operación `hechos`;
- `guion.md` sin prosa escrita: operación `guion`;
- con prosa ya escrita: operación `correccion` (incluye `relato-draft.md`, `contexto_narrativo.md` y `correcciones.md`).

**Novela.** El script no toca Qdrant. Si cambió el orden de los beats de una escena, alinea el `seq`:
- desplazamiento simple tras insertar o quitar: `python -X utf8 scripts/qdrant.py renumber-siblings --proyecto <slug> --nivel L0 --parent-id <escena_stable_id> --from-seq N --direction up|down`;
- cualquier otro cambio de orden: `python -X utf8 scripts/qdrant.py update-beat --proyecto <slug> --beat <beat_stable_id> --seq N` por cada beat afectado.

Renumerar hechos no cambia `config.json.ultimo_hecho_seq` si no cambia su número total.
