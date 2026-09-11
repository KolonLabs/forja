# Riesgos operativos del workspace

Registro local; no modifica decisiones ni deuda tecnica del hub.

| ID | Riesgo abierto | Impacto | Cierre verificable |
|----|---------------|---------|--------------------|
| NAR-001 | Backend activo puede conservar configuracion anterior; 64K solo verificado con schema y adaptador simulado | No se puede afirmar que haya cambiado la latencia ni la peticion real | Reiniciar OpenCode y verificar presupuesto/finish/tokens en el primer uso real; comparar calidad y duracion antes de atribuir mejora |
| NAR-002 | No hay transaccion conjunta disco/Qdrant ni CAS remoto | Dos escritores concurrentes del mismo capitulo/puntos pueden competir; un fallo parcial deja sincronizacion pendiente | Operacion serial obligatoria y retry idempotente; si se requiere concurrencia, implementar bloqueo/CAS y probar conflictos antes de habilitarla |
| NAR-003 | Checks mecanicos no comprenden el significado de la prosa | Una escena completa por IDs puede incumplir cobertura semantica o canon | Mantener revision independiente por hash con incidencias concretas; nunca aprobar solo por estructura o promedio |
| NAR-005 | Contrato editorial de beats revisado, pendiente de verificar en agentes tras reinicio | Pruebas estaticas no demuestran naturalidad, separacion de inferencia/declaracion ni libertad de ejecucion | Reiniciar OpenCode y revisar con el usuario casos de la decision 0002; comprobar que no reaparecen microcoreografia, replicas forzadas o ejemplos tratados como canon; no cerrar por regex |
| NAR-007 | Checkpoint humano y autorizacion de avance regulados por el director, no por el helper | Una aprobacion del validador o una instruccion antigua podria confundirse con permiso humano y disparar la escena/capitulo siguiente | Tras reinicio verificar presentacion y parada real; aprobacion aislada permite aceptar el mismo hash, no avanzar; cambios vuelven a presentarse. Decision 0003 y pruebas estaticas no prueban cumplimiento real |
| NAR-006 | Persisten instrucciones heredadas contradictorias de identidad en guionista/plantilla (seq global o padre hecho frente a seq local y padre escena del contrato de Qdrant) | Riesgo de persistir identidades o posiciones equivocadas al reanudar generacion | Reconciliar contratos de identidad en tarea separada y probar recorrido beat-L1-L2 con los helpers, sin migracion implicita de datos; la decision 0002 no cambia persistencia |

## Cerradas

| ID | Resolucion | Evidencia |
|----|-----------|-----------|
| NAR-004 | Migracion controlada de los 5 L1 divergentes a las identidades canonicas del guion, con vectores y payloads preservados, borrado de puntos erroneos tras verificacion, y contrato de cronista fijado para conservar el stable_id de escena (upsert-summary --id). | 2026-09-09: 5 L1 con stable_id canonico y seq 1-5; `query-summary-by-position` devuelve el ID del guion; `query-chapters-by-beat` resuelve beat → L1 → L2 (smoke test con score 0.839 hacia d1a2b3c4); 30 beats sin padres sin L1; backups `renacer-qdrant-export-20260909-110638.json` y `l1-backup-20260909.json` en el temporal aprobado |
| NAR-004 (prevencion verificada) | La comprobacion anterior era solo posterior a la escritura. Helper endurecido: rechaza identidad/posicion divergentes, duplicados y colisiones de proyecto ANTES de escribir; L1 nuevo exige ID canonico. Contratos alineados y discrepancias Qdrant separadas de Neo4j. | 2026-09-09: 22 pruebas nuevas offline + 54 regresiones de persistencia aprobadas. Comparacion completa con backups: cinco L1 conservan payload salvo stable_id y vector exacto; 30 beats, otros 23 summaries y 20 entidades intactos. Concurrencia fuera del preflight sigue en NAR-002 |

Implementacion y pruebas: [decision narrativa por escena](decisiones/0001-narrativa-por-escena.md).

Contrato editorial: [compromiso narrativo y libertad de ejecucion](decisiones/0002-contrato-editorial-beats.md).
