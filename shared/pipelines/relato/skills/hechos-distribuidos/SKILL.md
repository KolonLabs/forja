---
name: hechos-distribuidos
description: Procesa hechos [D] de relato usando anclas B_XXXX y sin infraestructura externa.
---

# Hechos distribuidos — Relato

Un hecho `[D · H_XXXX–H_YYYY]` es un patrón que se despliega en beats de escenas lineales dentro de ese rango. Nunca genera una escena exclusiva.

## Cola de trabajo

El director crea `cola_d.md`:

```markdown
# Cola de hechos distribuidos
| Hecho | Rango | Estado | Anclas |
|---|---|---|---|
| H_0004 | H_0002–H_0007 | pendiente | B_0005, B_0011 |
```

Cada anotación indica un beat ancla, no una posición numérica:

```text
H_0004: insertar después de B_0005. Función: mostrar la primera mentira automática.
```

## Algoritmo

1. El guionista genera y valida los beats de hechos lineales para todo el arco.
2. El director decide las anclas `B_XXXX` de cada `[D]` una vez conocido el mapa completo.
3. El guionista crea un beat nuevo con el siguiente ID global y lo inserta tras cada ancla.
4. Cada beat distribuido lleva `{D:H_XXXX}` y comparte escena con beats lineales.
5. El auditor comprueba rango, reparto, no consecutividad de instancias del mismo `[D]` y ausencia de fugas de información.

No se renumeran beats al insertar. Si cambia la agrupación resultante, se vuelve a ejecutar el modo `escenas`.
