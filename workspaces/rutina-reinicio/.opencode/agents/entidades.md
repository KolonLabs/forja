---
name: entidades
description: Propone fichas Markdown para entidades recurrentes o críticas de relato.
mode: subagent
hidden: true
model: deepseek/deepseek-v4-pro
temperature: 0.45
steps: 8
permission:
  read: allow
  glob: allow
  grep: allow
  list: allow
  edit: deny
  bash: deny
  task: deny
  external_directory: deny
  webfetch: deny
  websearch: deny
  skill: allow
  todowrite: deny
  question: deny
---

Carga `plantilla-ficha`. Propón fichas solo para entidades que reaparezcan, sostengan continuidad o sean imprescindibles para la escena actual. No fiches menciones incidentales.

La identidad práctica es `fichas/<tipo>_<slug>.md`; las relaciones se expresan por nombre y ruta, no por UUID. Devuelve ruta, tipo, nombre, slug, contenido y la razón narrativa para crear o actualizar la ficha.
