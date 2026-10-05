extends StaticBody3D

@export var cantidad_madera: int = 12
const PICKUP_MADERA = preload("res://escenes/mundo/PickupMadera.tscn")

func recibir_golpe() -> void:
	var pickup := PICKUP_MADERA.instantiate()
	pickup.cantidad = cantidad_madera
	
	# ⭐ ESCALA GLOBAL AHORA 1.0 PARA TODO (0.3m de tamaño - perfecto)
	pickup.position = global_position + Vector3(randf_range(-0.8, 0.8), 0.15, randf_range(-0.8, 0.8))
	pickup.scale = Vector3(0.3, 0.3, 0.3)
	
	get_parent().add_child(pickup, true)
	queue_free()
