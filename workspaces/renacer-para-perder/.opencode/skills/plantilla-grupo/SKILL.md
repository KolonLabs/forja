---
name: plantilla-grupo
description: Estructura y campos obligatorios para crear una ficha de grupo con composición, dinámica interna, función colectiva y rol narrativo. Secciones FIJO (inmutable) y DINÁMICO (actualizable por el cronista).
---

<!-- FIJO — No modificar tras la creación inicial -->

# [NOMBRE DEL GRUPO]

## Composición
- **Tipo**: (pareja, trío, cuadrilla, pandilla, equipo, familia, clan, multitud, etc.)
- **Número de miembros**: (fijo, variable, estimado)
- **Perfil de los miembros**: (edad, género, origen, ocupación común)

## Miembros
- **Núcleo**: (per-id de los personajes que forman el núcleo duro)
- **Periferia**: (per-id de miembros secundarios o rotativos)
- **Líder o figura central**: (per-id, si hay jerarquía)
- **Roles dentro del grupo**: (quién hace qué, dinámicas de poder)

## Dinámica interna
- **Tipo de vínculo**: (amistad, interés, supervivencia, tradición, obligación, sangre)
- **Cohesión**: (muy unido, fracturado, en tensión, estable, cambiante)
- **Conflictos internos**: (qué los divide, rencores, secretos entre miembros)
- **Rituales o costumbres**: (lo que hacen juntos, códigos compartidos)
- **Lenguaje o señas**: (jerga, gestos, apodos internos)

## Relación con otros
- **Aliados**: (org-id, per-id, otros grupos)
- **Enemigos o rivales**: (quiénes los enfrentan)
- **Percepción externa**: (cómo los ven desde fuera)

## Rol narrativo
- **Función en la trama**: (apoyo, obstáculo, testigo, catalizador, contraste, coro)
- **Arco colectivo**: (evolución del grupo como entidad: se une, se rompe, se transforma)
- **Información que poseen**: (qué saben que otros no, rumores, verdades compartidas)

## Reglas del grupo
- [Restricciones narrativas: "siempre actúan juntos", "nunca hablan con extraños"]
- [Consistencia: "los miembros respetan la jerarquía interna salvo excepciones"]

## Tags
[tipo] [tamaño] [cohesión] [rol-narrativo] [líder-id] [tag]

---

<!-- DINÁMICO — Actualizado por el agente cronista tras cada capítulo -->

## Estado actual
- **Miembros activos**: (quién sigue, quién se fue, quién murió)
- **Estado del grupo**: (unido, fracturado, disuelto, en formación, en crisis)
- **Ubicación o dispersión**: (dónde están, si están juntos o separados)
- **Última actualización**: (cap-XX)

## Historial
- **Cap-XX**: [evento significativo: unión, ruptura, traición, victoria, pérdida colectiva]
- **Cap-YY**: [otro evento]

## Cambios recientes
- [Altas, bajas, cambios de liderazgo, alianzas rotas o nuevas]
