# ADR 0031: Sin ficheros de trabajo en las obras (intermedios de escena y borradores)

- Estado: aceptada
- Fecha: 2026-10-13
- Ámbito: `persistir-escena.py` de novela simple y multi-hilo, directores, `/revisar`, `/expandir` y guías de esas escalas; `borrador.ps1` y `/borrador` en las tres escalas.
- Relaciona: ADR 0026 (git por obra, sin copias de seguridad); modifica el punto 5 del ADR 0028 (salida del borrador).

## Contexto

`persistir-escena.py preparar` lee la salida del escritor desde un archivo de entrada (por convención `escena-<SID>*.entrada.md` dentro del capítulo) y la copia como candidato `escena-<SID>.pendiente.md`; `aceptar` la inserta en `draft.md` y `sincronizar` la lleva a Qdrant. Nada retiraba después la entrada ni el candidato. En `renacer-para-perder` se acumularon 59 entradas (incluidas versiones descartadas de revisiones) y 40 candidatos, 39 de ellos ya idénticos a su escena del draft: copias que el ADR 0026 excluye, porque el historial de la obra es su git. Las entradas, además, no están en `.gitignore`.

La limpieza no puede depender de que el director (un LLM) se acuerde de ejecutarla, y tampoco puede romper los reintentos idempotentes de `aceptar` y `sincronizar`, que cubren las pruebas (repetir tras un fallo de red no regenera prosa).

## Decisión

1. **Limpieza automática en el script.** `aceptar` y `sincronizar`, al terminar bien, eliminan del capítulo los candidatos cuyo contenido ya está en el draft y las entradas `escena-<SID>*.entrada.md` de escenas presentes en el draft y anteriores a su última escritura. Conservan el candidato y las entradas de una escena en curso y cualquier entrada posterior al draft, que puede ser trabajo aún sin preparar. No crean copias. Un fallo al limpiar no invalida el comando: se informa en `limpieza_error`.
2. **Reintentos sin candidato.** Si el candidato ya no existe, `aceptar` y `sincronizar` usan la escena del draft siempre que coincida con el hash revisado; repetir cualquiera de los dos sigue siendo seguro. Un `preparar` posterior recrea el candidato y el siguiente `aceptar` lo vuelve a retirar.
3. **`limpiar --capitulo <cap> [--simular]` solo para contingencias:** intermedios anteriores a este cambio o una limpieza fallida. Aplica las mismas reglas; `--simular` lista sin borrar. El director no lo ejecuta en el flujo normal.
4. Los candidatos siguen en `.gitignore` como estado transitorio; las entradas no se ignoran: si alguna queda, debe verse.
5. **Borradores sin ficheros de trabajo.** `borrador.ps1` con `-Epub` o `-Pdf` deja en `publicacion/borrador/` solo los formatos pedidos; el `.md` y el `.manifest.json` se generan en la carpeta temporal y se eliminan con ella. Sin formatos, el borrador es el `.md` y conserva su manifest. El alcance no cambia: el relato completo, o un capítulo en novela y multi-hilo. La prosa se escribe en `publicacion/borrador/prosa/` (el guion tendrá su carpeta hermana); una versión suelta del mismo alcance en `publicacion/borrador/` se retira al regenerarlo.

## Consecuencias

- Una escena aceptada y sincronizada no deja más rastro que su texto en `draft.md`.
- Un borrador en EPUB o PDF no registra de qué versión de las fuentes salió; para esa trazabilidad se genera sin formatos.
- La limpieza es de capítulo: aceptar o sincronizar una escena también retira los restos ya incorporados de las demás escenas de ese capítulo.
- Las obras existentes necesitan el script nuevo; los intermedios acumulados en capítulos que ya no se tocan se retiran con `limpiar`.
