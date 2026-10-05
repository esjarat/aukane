# scripts/mundo/pinchito_prueba.gd
extends Area3D

var _temporizador_anti_spam: float = 0.0

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
	print("[PinchitoPrueba] Listo. Cada 1.5s si el jugador está encima quita 10 HP. Prueba i-frames.")

func _process(delta: float) -> void:
	if _temporizador_anti_spam > 0.0:
		_temporizador_anti_spam = max(0.0, _temporizador_anti_spam - delta)

func _on_body_entered(body: Node3D) -> void:
	_procesar_jugador(body)

func _on_body_exited(body: Node3D) -> void:
	pass

func _physics_process(_delta: float) -> void:
	if _temporizador_anti_spam > 0.0:
		return

	var cuerpos: Array[Node3D] = get_overlapping_bodies()
	for c: Node3D in cuerpos:
		if c.is_in_group("jugador"):
			_procesar_jugador(c)
			_temporizador_anti_spam = 1.5
			return

func _procesar_jugador(body: Node3D) -> void:
	if not body.is_in_group("jugador"):
		return

	var dam: Node = body.get_node_or_null("Damageable")
	if dam == null:
		push_warning("[PinchitoPrueba] Jugador encontrado pero NO TIENE Damageable.")
		return

	dam.call("recibir_danio", 10, self)
