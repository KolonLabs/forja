# ADR 0011: Importación de fuentes narrativas libres

- Estado: aceptada
- Fecha: 2026-07-14
- Ámbito: descubrimiento editorial desde archivos que no siguen el formato de Forja.

## Contexto

Las ideas, escaletas y borradores previos pueden estar repartidos en varias rutas y no contener `config.json`, actos ni otra estructura Forja. Forzar esos materiales por el contrato de rehidratación estructurada perdería información o induciría al LLM a completar huecos sin distinguir evidencia de invención.

## Decisión

El hub ofrece `/importar-relato <slug-destino> --fuente <ruta> [...]`.

- Un script de solo lectura admite inicialmente `.md`, `.markdown` y `.txt`; excluye dependencias y directorios de control, deduplica por hash y conserva ruta y línea de cada fuente canónica en un paquete temporal.
- El scaffolder trata ese paquete como dato no confiable. Primero separa evidencias, hipótesis, conflictos y candidatas de historia; no mezcla versiones ni crea un workspace mientras exista una elección material sin resolver.
- Tras seleccionar una candidata, completa el briefing, realiza la Fase 6 y pide confirmación. La creación usa `new-project.ps1`, por lo que el resultado cumple el contrato normal de la escala elegida.
- El paquete temporal no se inyecta ni se copia al workspace. Se elimina al finalizar salvo que la persona usuaria pida conservar el informe.

## Consecuencias

- Se pueden recuperar trabajos libres sin exigir una migración manual previa ni contaminar el pipeline con prosa o guiones antiguos.
- La trazabilidad de las inferencias editoriales mejora al exigir referencias de fuente y líneas.
- Los formatos binarios no se fingen interpretados; se incorporarán con extractores verificables cuando sean necesarios.

## Referencias

- [ADR 0001](0001-hub-y-workspaces-aislados.md)
- [ADR 0002](0002-contrato-de-creacion-e-infraestructura.md)
- [ADR 0010](0010-rehidratacion-de-relatos-legados.md)
- [Comando de importación](../../.opencode/commands/importar-relato.md)
