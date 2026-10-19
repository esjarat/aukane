class_name Pozo
extends StaticBody3D

## ¿Cuántos segundos tarda llenar la regadera? (0 para instantáneo, 1 para un chasquido)
@export var segundos_llenado: float = 0.0


# ──────────────────────────────────────────────────────────────
# FASE 1.2: PATRÓN INTERACTUABLE
# ──────────────────────────────────────────────────────────────
func puede_interactuar() -> bool:
	return true


func get_prompt() -> String:
	# Si NO tienes regadera → lo decimos
	if not Inventario.tiene_item(ClavesDatos.HERR_REGADERA, 1):
		return "[F] (Craftea una REGADERA primero)"

	# Si NO la tienes equipada → prompt para equipar
	if Inventario.herramienta_equipada != ClavesDatos.HERR_REGADERA:
		return "[F] Equipa la REGADERA para llenarla"

	# Si la tienes equipada → mostrar agua actual / max
	var agua_actual: int = Inventario.get_item_extra(ClavesDatos.HERR_REGADERA, ClavesDatos.CLAVE_AGUA_ACTUAL, 0)
	var agua_max: int = Inventario.get_item_extra(ClavesDatos.HERR_REGADERA, ClavesDatos.CLAVE_AGUA_MAX, ClavesDatos.AGUA_MAX_POR_DEFECTO)
	if agua_actual >= agua_max:
		return "[F] 💧 Regadera LLENA (" + str(agua_max) + "/" + str(agua_max) + ")"
	else:
		return "[F] 💧 Llenar regadera (" + str(agua_actual) + "/" + str(agua_max) + ")"


func interactuar(jugador: CharacterBody3D) -> void:
	# 1) Validación previa
	if not Inventario.tiene_item(ClavesDatos.HERR_REGADERA, 1):
		print("[Pozo] ❌ No tienes regadera.")
		return
	if Inventario.herramienta_equipada != ClavesDatos.HERR_REGADERA:
		print("[Pozo] ❌ Equipa primero la regadera.")
		return

	var agua_max: int = Inventario.get_item_extra(ClavesDatos.HERR_REGADERA, ClavesDatos.CLAVE_AGUA_MAX, ClavesDatos.AGUA_MAX_POR_DEFECTO)
	var agua_actual: int = Inventario.get_item_extra(ClavesDatos.HERR_REGADERA, ClavesDatos.CLAVE_AGUA_ACTUAL, 0)

	# 2) ¿Ya está llena?
	if agua_actual >= agua_max:
		print("[Pozo] 💧 Regadera ya está llena.")
		return

	# 3) Llenar INSTANTÁNEO (en FASE 7 podemos hacer corutina await)
	var cantidad_a_llenar: int = agua_max - agua_actual
	Inventario.set_item_extra(ClavesDatos.HERR_REGADERA, ClavesDatos.CLAVE_AGUA_ACTUAL, agua_max)
	print(
		"[Pozo] ✅ Regadera rellenada: +",
		cantidad_a_llenar,
		" agua (ahora ",
		agua_max,
		"/",
		agua_max,
		")",
	)
