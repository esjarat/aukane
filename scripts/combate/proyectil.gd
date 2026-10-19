class_name Proyectil
extends Area3D

# ═══════════════════════════════════════════════════════════════
# Proyectil — Flechas y otros (FASE 10.2)
# NO conoce a su tirador ni al arma: recibe dirección, daño y
# tirador por parámetro. Reutilizable por jugador, enemigos o trampas.
# ═══════════════════════════════════════════════════════════════

@export var velocidad: float = 18.0        # m/s (18 @ 60fps = 0.30 m/frame, sin tunneling)
@export var daño: int = 15
@export var tiempo_vida_max: float = 2.0   # Segundos antes de autodestruirse
@export_group("Volumen de impacto")
## Ancho en X/Z (m): cuánto "barre" la flecha al cruzar su trayectoria.
@export var ancho_impacto: float = 0.5
## Banda vertical (Y de mundo) que cubre el impacto. En isométrico no se apunta
## en vertical, así que la flecha debe alcanzar cualquier objetivo de su
## trayectoria: conejo (0.6 m) ... puma (2.0 m). Debe quedar por encima del
## suelo (y=0) para no autodestruirse al nacer.
@export var altura_min_impacto: float = 0.15
@export var altura_max_impacto: float = 2.1

var _direccion: Vector3 = Vector3.FORWARD
var _daño_efectivo: int = 0
var _tirador: Node = null
var _vida_restante: float = 0.0
var _activo: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

# Lo llama quien dispara (jugador en 10.3). Después de add_child().
func disparar(p_direccion: Vector3, p_daño: int, p_tirador: Node) -> void:
	_direccion = p_direccion.normalized()
	_daño_efectivo = p_daño
	_tirador = p_tirador
	_vida_restante = tiempo_vida_max
	_activo = true
	# Orientar el mesh hacia la dirección de vuelo (eje -Z = frente)
	if _direccion.length_squared() > 0.001:
		look_at(global_position + _direccion, Vector3.UP)
	_ajustar_volumen_impacto()

func _physics_process(delta: float) -> void:
	if not _activo:
		return
	# Movimiento rectilíneo uniforme (Area3D no tiene gravedad)
	global_position += _direccion * velocidad * delta
	_vida_restante -= delta
	if _vida_restante <= 0.0:
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	if not _activo:
		return

	# Filtro anti-autogolpe (mismo patrón que el hitbox del jugador)
	if body == self or body == _tirador:
		return
	if body.is_in_group("jugador"):
		return
	if body.is_in_group("terreno") or body.name == "LimitesMapa":
		queue_free()   # Chocó con el escenario → se destruye
		return

	# Buscar Damageable (patrón componente: nodo hijo directo)
	var dam: Node = _buscar_damageable(body)
	if dam == null:
		queue_free()   # Chocó con algo sin vida (árbol, roca, muro)
		return

	dam.call("recibir_danio", _daño_efectivo, _tirador)
	queue_free()

func _buscar_damageable(n: Node) -> Node:
	if n == null:
		return null
	var dam: Node = n.get_node_or_null("Damageable")
	if dam != null and dam.has_method("recibir_danio"):
		return dam
	return null
## Reconstruye el volumen de impacto como una caja alta y fina, ANCLADA a
## alturas de mundo (no a la posición de la flecha). Requiere que la posición
## global ya esté fijada por quien dispara.
func _ajustar_volumen_impacto() -> void:
	var cs: CollisionShape3D = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if cs == null:
		push_warning("[Proyectil] Falta el nodo 'CollisionShape3D'.")
		return
	var alto: float = maxf(0.1, altura_max_impacto - altura_min_impacto)
	var centro_y: float = (altura_max_impacto + altura_min_impacto) * 0.5
	var caja: BoxShape3D = BoxShape3D.new()
	caja.size = Vector3(ancho_impacto, alto, ancho_impacto)
	cs.shape = caja
	# El proyectil solo gira en YAW (vuelo horizontal), así que su eje Y local
	# coincide con el Y del mundo → basta desplazar el volumen en Y local.
	cs.position = Vector3(0.0, centro_y - global_position.y, 0.0)
