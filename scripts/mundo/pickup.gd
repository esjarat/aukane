extends Area3D
class_name Pickup

@export var item_id: StringName = &"madera"
@export var cantidad: int = 1

func _ready() -> void:
	add_to_group("pickups")
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("jugador"):
		return
	if Inventario.agregar_item(item_id, cantidad):
		print("[Pickup] +", cantidad, " ", str(item_id))
		queue_free()
