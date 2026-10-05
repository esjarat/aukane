extends StaticBody3D

@export var cantidad_piedra: int = 10
const PICKUP_PIEDRA = preload("res://escenes/mundo/PickupPiedra.tscn")

func recibir_golpe() -> void:
	var pickup := PICKUP_PIEDRA.instantiate()
	pickup.cantidad = cantidad_piedra
	
	pickup.position = global_position + Vector3(randf_range(-0.8, 0.8), 0.15, randf_range(-0.8, 0.8))
	pickup.scale = Vector3(0.25, 0.25, 0.25)  # 25cm
	
	get_parent().add_child(pickup, true)
	queue_free()
