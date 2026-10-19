class_name AnimalBase

# scripts/animales/animal_base.gd
extends CharacterBody3D

# ═══════════════════════════════════════════════════════════════

# 1) ESTADOS (FSM de animal PASIVO: solo 2 estados)

# ═══════════════════════════════════════════════════════════════
enum Estado {
	PASTAR,   # Deambula despacio, con pausas, sin rumbo fijo
	HUIDA,    # Corre alejándose del jugador
}

# ═══════════════════════════════════════════════════════════════

# 2) EXPORTS (ajustables por cada animal desde el Inspector)

# ═══════════════════════════════════════════════════════════════
@export var velocidad_pastar: float = 0.9          # Velocidad al deambular
@export var velocidad_huida: float = 4.5           # Velocidad al huir (más rápida que el jugador andando)
@export var rango_alerta: float = 6.0              # Distancia a la que detecta al jugador y empieza a huir
@export var distancia_seguridad: float = 13.0      # Si el jugador se aleja más que esto → vuelve a pastar
@export var tiempo_cambio_pastar: float = 4.0      # Cada X segundos elige una dirección nueva de pastoreo
@export var tiempo_pausa_pastar: float = 1.5       # Segundos quieto entre tramos de pastoreo
@export var id_animal: StringName = &""            # id para misiones (reutiliza el tipo "matar")
@export var drops: Array[Dictionary] = []          # Mismo formato que EnemigoBase (DropManager)
## XP que otorga al morir. 0 = no da XP. Configúralo por animal en el Inspector.
@export var xp_al_morir: int = 0
# ── FASE 12.3: ESCALADO POR NIVEL ──
@export var nivel: int = 1
@export var vida_por_nivel: int = 0
@export var daño_por_nivel: int = 0
@export var xp_por_nivel: int = 0
# ═══════════════════════════════════════════════════════════════
# 3) NODOS HIJO (referencias por @onready)
# ═══════════════════════════════════════════════════════════════
@onready var damageable: Node = $Damageable
@onready var visual_holder: Node3D = $VisualHolder

# ═══════════════════════════════════════════════════════════════
# 4) VARIABLES INTERNAS
# ═══════════════════════════════════════════════════════════════
var estado_actual: int = Estado.PASTAR
var _jugador_ref: Node3D = null
var _direccion: Vector3 = Vector3.FORWARD
var _temporizador_estado: float = 0.0
var _pausa_actual: float = 0.0
var _esta_muerto: bool = false
var _vida_base: int = 0
# ═══════════════════════════════════════════════════════════════
# 5) READY
# ═══════════════════════════════════════════════════════════════
func _ready() -> void:
	add_to_group("animal")
	if damageable != null and damageable.has_signal("murio"):
		damageable.murio.connect(_on_murio)
	_elegir_direccion_random()
	print("[AnimalBase] ", name, " listo | Estado: PASTAR")
	_vida_base = int(damageable.get("vida_maxima")) if damageable != null else 0
	_aplicar_nivel()
# ═══════════════════════════════════════════════════════════════
# 6) _PROCESS (FSM: temporizadores + transiciones)
# ═══════════════════════════════════════════════════════════════
func _process(delta: float) -> void:
	if _esta_muerto:
		return
	if _jugador_ref == null:
		_buscar_jugador()
	if _pausa_actual > 0.0:
		_pausa_actual = max(0.0, _pausa_actual - delta)
	_temporizador_estado += delta
	_ejecutar_transiciones()

# ═══════════════════════════════════════════════════════════════
# 7) _PHYSICS_PROCESS (movimiento)
# ═══════════════════════════════════════════════════════════════
func _physics_process(delta: float) -> void:
	if _esta_muerto:
		return

	var vel_mov: float = 0.0

	match estado_actual:
		Estado.PASTAR:
			# Solo se mueve si NO está en pausa
			if _pausa_actual <= 0.0:
				if _temporizador_estado >= tiempo_cambio_pastar:
					_temporizador_estado = 0.0
					_elegir_direccion_random()
					_pausa_actual = tiempo_pausa_pastar
				else:
					vel_mov = velocidad_pastar

		Estado.HUIDA:
			vel_mov = velocidad_huida
			_actualizar_direccion_huida()

	if vel_mov > 0.0 and _direccion.length() > 0.001:
		velocity.x = _direccion.x * vel_mov
		velocity.z = _direccion.z * vel_mov
		_girar_hacia(_direccion)
	else:
		velocity.x = move_toward(velocity.x, 0.0, velocidad_huida * 2.0)
		velocity.z = move_toward(velocity.z, 0.0, velocidad_huida * 2.0)

	# Gravedad (mismo patrón que EnemigoBase)
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	else:
		velocity.y = -0.1

	move_and_slide()

# ═══════════════════════════════════════════════════════════════
# 8) FSM: TRANSICIONES ENTRE ESTADOS
# ═══════════════════════════════════════════════════════════════
func _ejecutar_transiciones() -> void:
	if _jugador_ref == null:
		return
	var dist: float = global_position.distance_to(_jugador_ref.global_position)
	match estado_actual:
		Estado.PASTAR:
			if dist <= rango_alerta:
				_cambiar_estado(Estado.HUIDA)
		Estado.HUIDA:
			if dist > distancia_seguridad:
				_cambiar_estado(Estado.PASTAR)

func _cambiar_estado(nuevo: int) -> void:
	if estado_actual == nuevo:
		return
	print("[AnimalBase] ", name, " | ", _nombre_estado(estado_actual), " → ", _nombre_estado(nuevo))
	estado_actual = nuevo
	_temporizador_estado = 0.0
	if nuevo == Estado.HUIDA:
		_pausa_actual = 0.0   # huye ya, sin esperar

# ══════════════════════════════════════════════════════════════
# 9) MOVIMIENTO: HELPERS
# ═══════════════════════════════════════════════════════════════
func _actualizar_direccion_huida() -> void:
	if _jugador_ref == null:
		return
	# Dirección = alejarse del jugador (plano XZ)
	var alejarse: Vector3 = global_position - _jugador_ref.global_position
	alejarse.y = 0.0
	if alejarse.length() < 0.001:
		alejarse = Vector3.FORWARD
	_direccion = alejarse.normalized()

func _elegir_direccion_random() -> void:
	var angulo: float = randf() * TAU
	_direccion = Vector3(cos(angulo), 0.0, sin(angulo)).normalized()

# Gira SOLO el VisualHolder (la raíz queda SIEMPRE en identidad, regla canónica)
func _girar_hacia(dir: Vector3) -> void:
	if visual_holder == null:
		return
	var d: Vector3 = Vector3(dir.x, 0.0, dir.z)
	if d.length() < 0.001:
		return
	visual_holder.look_at(visual_holder.global_position + d, Vector3.UP)
# ═══════════════════════════════════════════════════════════════
# 10.b) ESCALADO POR NIVEL (FASE 12.3)
# ═══════════════════════════════════════════════════════════════
func _aplicar_nivel() -> void:
	var extra: int = maxi(0, nivel - 1)
	if extra == 0:
		return
	if damageable != null and damageable.has_method("set_vida_maxima"):
		damageable.call("set_vida_maxima", _vida_base + extra * vida_por_nivel)
	xp_al_morir += extra * xp_por_nivel
	print("[AnimalBase] ", name, " nv", nivel, " | vida ", _vida_base + extra * vida_por_nivel,
		" | xp ", xp_al_morir)
# ═══════════════════════════════════════════════════════════════
# 10) MUERTE (drops unificados + desvanecer)
# ═══════════════════════════════════════════════════════════════
func _on_murio(atacante_path: NodePath) -> void:
	_esta_muerto = true
	velocity = Vector3.ZERO
	# FASE 12.1: la XP va a quien mató (si fue el jugador).
	Nivel.otorgar_xp_a_atacante(get_node_or_null(atacante_path), xp_al_morir)
	# FASE 9.1: soltar drops en el punto de muerte (self = excluir del raycast)
	DropManager.soltar(drops, global_position, null, self)
	print("[AnimalBase] 💀 ", name, " MUERE. Desaparezco en 0.4s.")
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_interval(0.4)
	var mesh: MeshInstance3D = get_node_or_null("VisualHolder/Mesh")
	if mesh != null:
		tween.tween_property(mesh, "scale", Vector3.ZERO, 0.4)
	tween.tween_callback(queue_free)
	if id_animal != &"":
		MisionManager.actualizar_progreso(&"matar", id_animal, 1)

# ═══════════════════════════════════════════════════════════════
# 11) HELPERS PRIVADOS
# ═══════════════════════════════════════════════════════════════
func _buscar_jugador() -> void:
	var nodo: Node = get_tree().get_first_node_in_group("jugador")
	if nodo != null and nodo is Node3D:
		_jugador_ref = nodo as Node3D

func _nombre_estado(e: int) -> String:
	match e:
		Estado.PASTAR: return "PASTAR"
		Estado.HUIDA: return "HUIDA"
	return "DESCONOCIDO"
