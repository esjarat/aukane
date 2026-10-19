class_name EstacionDefinicion
extends Resource

# ═══════════════════════════════════════════════════════════════
# EstacionDefinicion — Define UNA estación del año (FASE 11.3)
# Añadir/ajustar una estación = crear/editar un .tres. Cero hardcodeo.
# ═══════════════════════════════════════════════════════════════

@export var id: StringName = &""
@export var nombre_visible: String = ""
## Posición en el ciclo anual (1, 2, 3, 4...). IMPRESCINDIBLE: DirAccess
## devuelve los .tres en orden arbitrario, y el ciclo debe ser determinista.
@export var orden: int = 1

## Cuántos días de JUEGO dura esta estación.
@export var dias_duracion: int = 30

## Factor que MULTIPLICA el peso de cada clima durante esta estación.
## Clave = id del clima ("soleado", "lluvioso"...). Valor 1.0 = sin cambio.
## 0.0 = ese clima no puede salir. 2.0 = el doble de probable.
@export var multiplicadores_peso: Dictionary = {}
## Multiplicador de la velocidad de crecimiento de los cultivos durante
## esta estación. 1.0 = normal, 0.5 = la mitad de rápido (invierno).
@export var multiplicador_crecimiento_cultivos: float = 1.0
## Multiplicador de peso para un clima concreto. Devuelve 1.0 si no se define.
func multiplicador_para(p_clima: StringName) -> float:
	# El Inspector guarda las claves de un Dictionary como String (no StringName),
	# así que comprobamos ambas formas para no depender de cómo se escribió.
	if multiplicadores_peso.has(p_clima):
		return float(multiplicadores_peso[p_clima])
	var clave_texto: String = String(p_clima)
	if multiplicadores_peso.has(clave_texto):
		return float(multiplicadores_peso[clave_texto])
	return 1.0

@export var emoji_hud: String = ""
