# scripts/mundo/muneco_practica.gd
extends StaticBody3D

@onready var damageable: Node = $Damageable


func _ready() -> void:
	add_to_group("enemigo")
	if damageable != null:
		if damageable.has_signal("danio_recibido"):
			damageable.danio_recibido.connect(_on_danio)
		if damageable.has_signal("murio"):
			damageable.murio.connect(_on_murio)
	print(
		"[MuñecoPractica] Listo. HP = ",
		damageable.call("get_vida_actual") if damageable != null else "?",
	)


func _on_danio(cantidad: int, _atacante_path: NodePath) -> void:
	var vida: int = int(damageable.call("get_vida_actual"))
	print(
		"[MuñecoPractica] 💥 Recibí ",
		cantidad,
		" de daño → HP ",
		vida,
		"/",
		damageable.call("get_vida_maxima"),
	)


func _on_murio(_atacante_path: NodePath) -> void:
	print("[MuñecoPractica] 💀 MUERTO. Desaparezco en 0.3s.")
	# Desaparecer suavemente
	var tween: Tween = create_tween()
	tween.tween_interval(0.3)
	tween.tween_callback(queue_free)
