# ADR 0018: Aislamiento multi-tenant de Qdrant y Neo4j y contrato del L4

- Estado: aceptada
- Fecha: 2026-08-13
- Complementa: ADR 0002
- Ámbito: infraestructura compartida de novelas (`novela-simple` y `novela-multi-hilo`).

## Contexto

Una auditoría de aislamiento multi-tenant detectó cuatro defectos en los helpers compartidos de memoria.

**Qdrant — puntos derivados solo de `stable_id`.** El ID físico del punto es `uuid5(stable_id)`, sin el proyecto. Dos proyectos que generen el mismo `stable_id` (8 hex aleatorios) colisionan en la colección compartida y se pisan. Las rutas de lectura por ID físico (`query-entity`, el fetch previo de `update-beat`) no verificaban el proyecto del punto devuelto, por lo que una colisión entregaba datos de otro proyecto.

**Qdrant — L4 con identidad literal `"global"`.** El nivel L4 se escribía con `stable_id="global"` y se leía con ese mismo literal. El punto físico resultante es idéntico para todos los proyectos: el L4 de una novela sobrescribía el de cualquier otra. Además convivían dos vías de escritura incompatibles: `upsert-summary --id global` (literal) y `upsert-summary-by-position --nivel L4` (stable_id aleatorio), que `query-l4-current` no encontraba por exigir el literal.

**Neo4j — `import` sin `proyecto` en las relaciones.** El bucle que armaba el `SET` de las relaciones importadas saltaba la clave `proyecto`. Las relaciones restauradas desde backup quedaban sin `r.proyecto` y un `export` posterior no las devolvía: el round-trip export → import → export perdía relaciones en silencio.

**Consola Windows.** Los mensajes de `export` usaban `→` (U+2192), que revienta con `UnicodeEncodeError` en la codificación cp1252 de la consola de Windows.

## Decisión

**1. El L4 es único por proyecto, con identidad opaca.**

- El L4 se localiza siempre por `(proyecto, nivel L4)`. Su `stable_id` es un UUID8 opaco generado en el primer upsert; nunca el literal `"global"`.
- `upsert-summary --nivel L4` delega en la vía posicional e ignora `--id`.
- `upsert-summary-by-position --nivel L4` es idempotente y no exige `--parent-id` (su `parent_id` queda vacío).
- `query-l4-current` devuelve el L4 del proyecto sin exigir un id concreto; un L4 legado con `stable_id="global"` sigue devolviéndose si es el único.
- Los L3 referencian al L4 por su `stable_id` opaco, obtenido con `query-l4-current`.

**2. Las lecturas por ID físico verifican el proyecto.**

- `query-entity` devuelve `{}` si el punto recuperado pertenece a otro proyecto.
- El fetch previo de `update-beat` (`get_existing_payload`) acepta `proyecto` y trata un punto ajeno como inexistente para la decisión de re-embedding.

**3. El import de Neo4j escribe `r.proyecto`.**

- El `SET` de import incluye `proyecto` en toda relación restaurada, garantizando el round-trip export → import → export.

**4. Los helpers no emiten caracteres no-ASCII en consola.**

- Los mensajes de `export` y los errores de vocabulario usan `->` en lugar de `→`. El docstring del módulo queda como documentación, no como salida de consola.

## Consecuencias

- Dos novelas pueden compartir `stable_id` sin pisarse en las rutas auditadas; el aislamiento por `proyecto` es ahora defensivo además de nominal.
- El L4 de cada novela es un punto independiente; ya no existe un punto físico compartido entre proyectos.
- Un backup de Neo4j restaurado es íntegro y re-exportable.
- Los scripts del hub y los reinyectados en workspaces existentes (canida-2 en esta auditoría) quedan alineados; los workspaces de novela no tocados conservan su copia antigua hasta su próxima reinyección.
- Los 82 nodos y relaciones sin `proyecto` presentes en el grafo pertenecen a otro sistema (tipos `SCRIBA_*`, `HAS_*`, `GENERATED`) y no se tocan; `query-relationships` sigue partiendo de un nodo filtrado por `proyecto`, por lo que no los expone.

## Referencias

- [ADR 0002](0002-contrato-de-creacion-e-infraestructura.md)
- `docs/deuda-tecnica.md`, DT-005 (reinyección de pipeline en workspaces de novela existentes)
