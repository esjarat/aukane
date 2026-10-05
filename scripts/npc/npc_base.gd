extends StaticBody3D
class_name NpcBase

@export var id_npc: StringName = &""
@export var nombre_visible: String = "NPC"
@export var dialogo_inicial_id: StringName = &""   # Para FASE 4
@export var rango_interaccion: float = 2.5

var jugador_cerca: bool = false

func _ready() -> void:
	# Si no tiene grupo "interactuables", lo agregamos
	if not is_in_group("interactuables"):
		add_to_group("interactuables")

# ──────────────────────────────────────────────────────────────
# MÉTODOS QUE LAS SUBCLASES SOBREESCRIBIRÁN (patrón Template Method)
# ──────────────────────────────────────────────────────────────
func interactuar(jugador: Node) -> void:
	print("[NpcBase] ", nombre_visible, " interactuado. Sobre-escribe esta función en el hijo.")

func get_prompt() -> String:
	return "[F] Hablar con " + nombre_visible

func puede_interactuar() -> bool:
	return true   # Las subclases pueden poner false (ej: tienda cerrada de noche)

# ──────────────────────────────────────────────────────────────
# Detectores COMUNES a todo NPC (mismo código siempre)
# ──────────────────────────────────────────────────────────────
func _on_area_interaccion_body_entered(body: Node3D) -> void:
	print ( "[DEBUG AREA] Entró body: " , body.name, " - grupo jugador?: " , body. is_in_group ( "jugador" ))
	if body.is_in_group("jugador"):
		jugador_cerca = true
		# (FASE 1.2: aquí avisaremos a Jugador.indicador_interaccion)
		print("👉 ", get_prompt())

func _on_area_interaccion_body_exited(body: Node3D) -> void:
	if body.is_in_group("jugador"):
		jugador_cerca = false
