class_name Mision
extends Resource


# ═══════════════════════════════════════════════════════════════
# RESOURCE DATA-DRIVEN: Define UNA misión del juego.
# Cada .tres de esta clase = una misión única.
# ═══════════════════════════════════════════════════════════════

# Identificador único global (ej: &"mision_madera_1")
@export var id_mision: StringName = &""
# Nombre visible para el jugador (ej: "Leña para el invierno")
@export var nombre: String = "Misión sin nombre"
# Descripción larga que se muestra en el diario de misiones
@export var descripcion: String = ""
# ──────────────────────────────────────────────────────────────
# OBJETIVO de la misión
# ──────────────────────────────────────────────────────────────
# Tipo de objetivo: &"recolectar", &"matar", &"hablar"
@export var tipo_objetivo: StringName = &"recolectar"
# Item / enemigo / NPC objetivo (según tipo_objetivo):
#   - recolectar → id del item que hay que juntar (ej &"madera")
#   - matar       → id del enemigo que hay que derrotar (ej &"slime")
#   - hablar      → id del NPC con el que hay que hablar (ej &"mercader")
@export var id_objetivo: StringName = &""
# Cantidad necesaria para completar
@export var cantidad_objetivo: int = 1
# ──────────────────────────────────────────────────────────────
# RECOMPENSAS
# ──────────────────────────────────────────────────────────────
@export var recompensa_oro: int = 0
# Array de items: [{id: StringName, cantidad: int}]
@export var recompensas_items: Array[Dictionary] = []

# ──────────────────────────────────────────────────────────────
# PROGRESO (NO export — se gestiona en runtime por MisionManager)
# ──────────────────────────────────────────────────────────────
var progreso_actual: int = 0
var completada: bool = false


# ──────────────────────────────────────────────────────────────
# HELPERS
# ──────────────────────────────────────────────────────────────
func esta_completada() -> bool:
	return completada


func get_progreso_0_1() -> float:
	if cantidad_objetivo <= 0:
		return 0.0
	return clampf(float(progreso_actual) / float(cantidad_objetivo), 0.0, 1.0)
