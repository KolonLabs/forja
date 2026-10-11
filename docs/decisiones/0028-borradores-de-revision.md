# ADR 0028: Borradores de revisión con `/borrador`

- Estado: aceptada
- Fecha: 2026-10-11
- Ámbito: `shared/` (las tres escalas, ambos entornos) y obras existentes.
- Relaciona: ADR 0026 (compilación en la obra), ADR 0024 (dos entornos).

## Contexto

`/compilar` solo acepta un manuscrito `finalizado` y asigna `publicado`. Durante la escritura no había forma de obtener una versión limpia (sin anclas, encabezados de beat, marcadores ni notas) para leer o revisar lo escrito, ni en EPUB o PDF, sin cambiar el estado de la obra.

## Decisión

1. **Comando `/borrador [cap-NN] [--epub] [--pdf] …`** en las tres escalas y ambos entornos. Lo ejecuta `scripts/borrador.ps1`, determinista; el director solo pasa los argumentos. Nunca cambia el estado ni toca draft, guion, `config.json`, manuscrito ni el libro de `publicacion/`.
2. **Relato:** toda la prosa confirmada de `relato-draft.md`, limpia con las reglas de `/publicar`: se retiran las anclas `B_XXXX` y cada `salida: separador` produce `---` tras su escena salvo la última. Verificado contra el `relato.md` real de `el-tio-vicente-ii`: el borrador del mismo draft es idéntico byte a byte.
3. **Novela y multi-hilo: un único capítulo, nunca la novela entera.** El capítulo puede estar completo o a medias. Solo entran las escenas completas: presentes en el `draft.md` del capítulo y con todos sus beats `✅` en su `guion.md`. Las candidatas `escena-*.pendiente.md` y las escenas con beats `⬜` o `🔄` no entran. Un hueco entre escenas completas se señala con «*[Escena pendiente: <nombre>]*». Se retiran encabezados de beat, marcadores y notas del escritor, y se añade `# Capítulo N — Nombre`.
4. **Capítulo por defecto:** el capítulo en curso, es decir, el primero con beats pendientes y alguna escena completa; si todos los que tienen escenas completas están cerrados, el último de ellos. Un capítulo sin escenas completas se rechaza.
5. **Salida:** `publicacion/borrador/<slug>-borrador.*` o `<slug>-cap-NN-borrador.*`, con un `.manifest.json` (escenas incluidas y pendientes intermedias, hashes de las fuentes, commit). Cada ejecución sustituye el borrador del mismo alcance; no se acumulan copias. El título lleva «(borrador)» y la primera línea, la fecha y la cobertura.
6. **`/compilar` conserva `publicacion/borrador/`** al sustituir el libro.
7. **Código común:** `shared/scripts/publicacion-comun.ps1` reúne el hash, la lectura de `config.json` y el estado git que usan `compilar.ps1` y `borrador.ps1`.

## Consecuencias

- La limpieza de relato existe ahora en un script además de en las instrucciones de `/publicar`. Usar ese mismo script desde `/publicar` evitaría dos versiones de la misma regla; queda para otra decisión.
- La limpieza de notas del escritor en novela cubre las dos formas conocidas (bloque «Notas del escritor» y línea `*Nota del escritor: …*`); una nota con otro formato aparecería en el borrador, igual que lo haría ante `/publicar`.

## Referencias

- [shared/scripts/borrador.ps1](../../shared/scripts/borrador.ps1), [tests/borrador-regression.ps1](../../tests/borrador-regression.ps1)
- [ADR 0026](0026-obras-como-repositorios-independientes-fuera-del-hub.md)
