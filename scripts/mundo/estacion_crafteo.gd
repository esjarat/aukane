extends StaticBody3D

# ═══════════════════════════════════════════════════════════════
# Estación de crafteo interactuable (Banco de Trabajo, Horno, Molino...)
# Al interactuar abre la UI de crafteo filtrada por su tipo de estación.
# Patrón: igual que NpcBase (StaticBody3D + AreaInteraccion hijo).
# ═══════════════════════════════════════════════════════════════

# Tipo de estación: &"banco_trabajo", &"horno", &"molino", ...
@export var tipo_estacion: StringName = &"banco_trabajo"

# Nombre visible que se muestra en el prompt
@export var nombre_visible: String = "Estación de crafteo"

# Escena de la UI de crafteo (se asigna en el Inspector cuando exista UICrafteo.tscn)
@export var escena_ui_crafteo: PackedScene = null

var _ui_instancia: Control = null

func _ready() -> void:
	# Por consistencia con el resto de objetos interactuables
	if not is_in_group("interactuables"):
		add_to_group("interactuables")

# ──────────────────────────────────────────────────────────────
# PATRÓN INTERACTUABLE (igual que pozo.gd / npc_base.gd)
# ──────────────────────────────────────────────────────────────
func puede_interactuar() -> bool:
	return true

func get_prompt() -> String:
	return "[F] Abrir " + nombre_visible

func interactuar(_jugador: Node) -> void:
	# Si la UI ya está abierta → cerrarla (toggle)
	if _ui_instancia != null and is_instance_valid(_ui_instancia):
		cerrar_ui()
		return

	# Abrir la UI real (cuando exista UICrafteo.tscn)
	if escena_ui_crafteo == null:
		push_warning("[Estacion] escena_ui_crafteo NO ASIGNADA en el Inspector (se creará en FASE 6.3)")
		return

	_ui_instancia = escena_ui_crafteo.instantiate()
	get_tree().root.add_child(_ui_instancia)
	GameState.modo_actual = GameState.MODO_UI

	if _ui_instancia.has_method("asignar_estacion"):
		_ui_instancia.asignar_estacion(tipo_estacion, self)

# ──────────────────────────────────────────────────────────────
# CERRAR UI
# ──────────────────────────────────────────────────────────────
func cerrar_ui() -> void:
	if _ui_instancia != null and is_instance_valid(_ui_instancia):
		_ui_instancia.queue_free()
	_ui_instancia = null
	GameState.modo_actual = GameState.MODO_MUNDO

# Si el jugador se aleja, cerramos la UI
func _on_area_interaccion_body_exited(body: Node3D) -> void:
	if body.is_in_group("jugador") and _ui_instancia != null:
		cerrar_ui()
