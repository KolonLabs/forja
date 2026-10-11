# ADR 0029: Secretos del usuario fuera de los repositorios

- Estado: aceptada
- Fecha: 2026-10-11
- Ámbito: `shared/scripts/` (helpers inyectados en cada obra), hub y obras existentes.
- Relaciona: ADR 0026 (un git por obra).

## Contexto

Los scripts de Forja y de las obras pueden necesitar claves de servicios externos (por ejemplo, ElevenLabs). No había un sitio común: un `.env` por workspace duplica la clave en cada obra y, con un git por obra, multiplica el riesgo de commitearla. El Administrador de credenciales de Windows no es accesible desde una sesión de Cowork en Claude Desktop, que se ejecuta en un entorno aislado con acceso solo a las carpetas compartidas.

## Decisión

1. **Un único archivo de secretos por usuario**, fuera de cualquier repositorio: `~/.forja/secretos.env` (formato `NOMBRE=valor`). La carpeta y el archivo solo dan acceso al usuario y a SYSTEM. En otro entorno (Cowork), `FORJA_SECRETOS` indica la ruta del archivo.
2. **Lectura con un helper común** en `shared/scripts/`: `secretos.ps1` (`Get-ForjaSecreto`, `Test-ForjaSecreto`) y `secretos.py` (`obtener_secreto`, `--comprobar`). Orden: variable de entorno del proceso con el mismo nombre y, si no existe, el archivo. Ningún script lee el archivo por su cuenta.
3. **Los helpers nunca muestran valores.** La comprobación solo informa de si el secreto está definido y de su fuente; los errores dicen dónde definirlo.
4. **Guardas en git:** `.env`, `*.env` y `secretos.env` están en el `.gitignore` del hub, en el de cada obra nueva y en el de las obras existentes.
5. **Las claves de proveedores de opencode** (Venice, DeepSeek) siguen en su propio almacén (`opencode auth login`); no se duplican aquí.

## Consecuencias

- El archivo está en texto plano: cualquier proceso del usuario, incluido un agente con acceso a la terminal, puede leerlo. Se mitiga con claves distintas por entorno (una clave limitada y revocable para Cowork) y compartiendo la carpeta con Cowork solo cuando haga falta.
- No se usa el Administrador de credenciales: Cowork no lo ve y mantener dos almacenes exigiría sincronizarlos.
- La contraseña por defecto de Neo4j sigue escrita en `scripts/neo4j.py`; pasarla a este mecanismo queda pendiente (DT-018).

## Referencias

- [shared/scripts/secretos.ps1](../../shared/scripts/secretos.ps1), [shared/scripts/secretos.py](../../shared/scripts/secretos.py), [tests/secretos-regression.ps1](../../tests/secretos-regression.ps1)
