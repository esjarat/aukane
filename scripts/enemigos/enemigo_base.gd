class_name EnemigoBase
# scripts/npc/enemigo_base.gd
extends CharacterBody3D

# ═══════════════════════════════════════════════════════════════
# 1) ESTADOS (State Machine - 3 estados)
# ═══════════════════════════════════════════════════════════════
enum Estado {
	PATRULLA,
	PERSEGUIR,
	ATACAR,
}

# ═══════════════════════════════════════════════════════════════
# 2) EXPORTS CONFIGURABLES POR CADA ENEMIGO EN INSPECTOR
# ═══════════════════════════════════════════════════════════════
@export var velocidad_patrulla: float = 0.4
@export var velocidad_perseguir: float = 1.6
@export var rango_deteccion: float = 6.0      # Radio para pasar PATRULLA → PERSEGUIR
@export var rango_ataque: float = 2.2         # Distancia para pasar PERSEGUIR → ATACAR
@export var distancia_perdida: float = 9.0    # Si jugador > dist → vuelve PATRULLA
@export var daño_ataque: int = 12             # Daño por golpe al jugador
@export var cooldown_entre_ataques: float = 1.35      # Segundos entre golpes
@export var tiempo_cambio_patrulla: float = 3.0  # Cada X seg cambia dirección random
@export var id_enemigo: StringName = &""
@export var drops: Array[Dictionary] = []
@export var xp_al_morir: int = 0
# ── FASE 12.3: ESCALADO POR NIVEL ──
## Nivel del enemigo. El spawner lo sobreescribe al instanciar.
@export var nivel: int = 1
## Cuánto SUMA cada nivel extra (nivel 2 = base + 1×incremento). 0 = no escala.
@export var vida_por_nivel: int = 0
@export var daño_por_nivel: int = 0
@export var xp_por_nivel: int = 0
# ═══════════════════════════════════════════════════════════════
# 4) VARIABLES INTERNAS FSM
# ═══════════════════════════════════════════════════════════════
var estado_actual: int = Estado.PATRULLA
var _jugador_ref: CharacterBody3D = null
var _cooldown_ataque_actual: float = 0.0
var _temporizador_patrulla: float = 0.0
var _direccion_patrulla: Vector3 = Vector3.FORWARD
var _esta_muerto: bool = false
var _vida_base: int = 0   # Vida del .tscn, antes de escalar (FASE 12.3)
# ═══════════════════════════════════════════════════════════════
# 3) NODOS HIJO (referencias por @onready)
# ═══════════════════════════════════════════════════════════════
@onready var damageable: Node = $Damageable


# ═══════════════════════════════════════════════════════════════
# 5) READY
# ═══════════════════════════════════════════════════════════════
func _ready() -> void:
	add_to_group("enemigo")
	# Conectar muerte
	if damageable != null:
		if damageable.has_signal("murio"):
			damageable.murio.connect(_on_murio)
	# Inicializar dirección de patrulla random
	_asignar_direccion_patrulla_random()
	print("[EnemigoBase] ", name, " listo | Estado inicial: PATRULLA")
	# FASE 12.3: guardamos la vida base del .tscn y aplicamos el escalado.
	# Los hijos corren _ready() antes que el padre, así que aquí el Damageable
	# YA inicializó su vida → leer vida_maxima es fiable como base.
	_vida_base = int(damageable.get("vida_maxima")) if damageable != null else 0
	_aplicar_nivel()

# ═══════════════════════════════════════════════════════════════
# 6) _PROCESS: Actualizar cada frame (cooldowns + transiciones FSM)
# ═══════════════════════════════════════════════════════════════
func _process(delta: float) -> void:
	if _esta_muerto:
		return

	# a) Actualizar jugador referencia (solo si no la tenemos)
	if _jugador_ref == null:
		_buscar_jugador()

	# b) Cooldown ataque (siempre hacia atrás)
	if _cooldown_ataque_actual > 0.0:
		_cooldown_ataque_actual = max(0.0, _cooldown_ataque_actual - delta)

	# c) Temporizador patrulla (cambio dirección random cada N segundos)
	if estado_actual == Estado.PATRULLA:
		_temporizador_patrulla += delta
		if _temporizador_patrulla >= tiempo_cambio_patrulla:
			_temporizador_patrulla = 0.0
			_asignar_direccion_patrulla_random()

	# d) TRANSICIONES FSM (reglas)
	_ejecutar_transiciones_estado()


# ═══════════════════════════════════════════════════════════════
# 7) _PHYSICS_PROCESS: Movimiento (CharacterBody3D necesita physics)
# ═══════════════════════════════════════════════════════════════
func _physics_process(delta: float) -> void:
	if _esta_muerto:
		return

	var dir_movimiento: Vector3 = Vector3.ZERO
	var vel_mov: float = 0.0

	match estado_actual:
		Estado.PATRULLA:
			dir_movimiento = _direccion_patrulla
			vel_mov = velocidad_patrulla

		Estado.PERSEGUIR:
			if _jugador_ref != null:
				var vec_a_jugador: Vector3 = _jugador_ref.global_position - global_position
				vec_a_jugador.y = 0.0   # ignorar altura (plano XZ)
				dir_movimiento = vec_a_jugador.normalized()
				vel_mov = velocidad_perseguir

		Estado.ATACAR:
			# Quieto mientras ataca (no se mueve pegado)
			# Pero ROSTRA hacia el jugador para que el golpe sea justo
			if _jugador_ref != null:
				var vec_a_jugador: Vector3 = _jugador_ref.global_position - global_position
				vec_a_jugador.y = 0.0
				if vec_a_jugador.length() > 0.01:
					look_at(global_position + vec_a_jugador, Vector3.UP)

			dir_movimiento = Vector3.ZERO
			vel_mov = 0.0
			_intentar_atacar_jugador()

	# Aplicar movimiento
	if dir_movimiento.length() > 0.01:
		velocity.x = dir_movimiento.x * vel_mov
		velocity.z = dir_movimiento.z * vel_mov
		# Mirar hacia dónde camina (rotación suave)
		if estado_actual != Estado.ATACAR:
			look_at(global_position + dir_movimiento, Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x, 0.0, velocidad_perseguir)
		velocity.z = move_toward(velocity.z, 0.0, velocidad_perseguir)

	# Gravedad simple (por si hubiera desniveles)
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	else:
		velocity.y = -0.1

	move_and_slide()


# ═══════════════════════════════════════════════════════════════
# 8) FSM: REGLAS DE TRANSICIÓN ENTRE ESTADOS
# ═══════════════════════════════════════════════════════════════
func _ejecutar_transiciones_estado() -> void:
	if _jugador_ref == null:
		# Sin jugador → siempre patrulla
		if estado_actual != Estado.PATRULLA:
			_cambiar_estado(Estado.PATRULLA)
		return

	var dist: float = global_position.distance_to(_jugador_ref.global_position)

	match estado_actual:
		Estado.PATRULLA:
			if dist <= rango_deteccion:
				_cambiar_estado(Estado.PERSEGUIR)

		Estado.PERSEGUIR:
			if dist > distancia_perdida:
				_cambiar_estado(Estado.PATRULLA)
			elif dist <= rango_ataque:
				_cambiar_estado(Estado.ATACAR)

		Estado.ATACAR:
			# Si jugador se aleja del rango ataque → volvemos a PERSEGUIR
			if dist > rango_ataque:
				_cambiar_estado(Estado.PERSEGUIR)


# ═══════════════════════════════════════════════════════════════
# 9) FSM: CAMBIAR ESTADO (helper centralizado, no cambio directo)
# ═══════════════════════════════════════════════════════════════
func _cambiar_estado(nuevo: int) -> void:
	if estado_actual == nuevo:
		return
	var nombre_anterior: String = _nombre_estado(estado_actual)
	estado_actual = nuevo
	print("[EnemigoBase] ", name, " | ", nombre_anterior, " → ", _nombre_estado(nuevo))


# ═══════════════════════════════════════════════════════════════
# 10) ATAQUE AL JUGADOR (solo en estado ATACAR + cooldown == 0)
# ═══════════════════════════════════════════════════════════════
func _intentar_atacar_jugador() -> void:

	if _cooldown_ataque_actual > 0.0:
		return
	if _jugador_ref == null:
		return
	var dam_jugador: Node = _jugador_ref.get_node_or_null("Damageable")
	if dam_jugador == null:
		return
	# ✅ Golpe válido
	_cooldown_ataque_actual = cooldown_entre_ataques
	dam_jugador.call("recibir_danio", daño_ataque, self)
	print("[EnemigoBase] ", name, " ⚔️ ATACA al jugador! Daño ", daño_ataque)

# ═══════════════════════════════════════════════════════════════
# 11.b) ESCALADO POR NIVEL (FASE 12.3)
# ═══════════════════════════════════════════════════════════════
## Aplica el nivel sobre los valores base. Con nivel 1 no cambia nada.
func _aplicar_nivel() -> void:
	var extra: int = maxi(0, nivel - 1)
	if extra == 0:
		return
	# Vida: el dueño es el Damageable (mismo contrato que usa el jugador).
	if damageable != null and damageable.has_method("set_vida_maxima"):
		damageable.call("set_vida_maxima", _vida_base + extra * vida_por_nivel)
	# Daño y XP viven en este nodo.
	daño_ataque += extra * daño_por_nivel
	xp_al_morir += extra * xp_por_nivel
	print("[EnemigoBase] ", name, " nv", nivel, " | vida ", _vida_base + extra * vida_por_nivel,
		" | daño ", daño_ataque, " | xp ", xp_al_morir)
# ═══════════════════════════════════════════════════════════════
# 11) HANDLER MUERTE (conectado desde Damageable)
# ═══════════════════════════════════════════════════════════════
func _on_murio(atacante_path: NodePath) -> void:
	_esta_muerto = true
	velocity = Vector3.ZERO
	# FASE 12.1: la XP va a quien mató (si fue el jugador).
	Nivel.otorgar_xp_a_atacante(get_node_or_null(atacante_path), xp_al_morir)
	# FASE 9.1: soltar drops unificados en el punto de muerte (self = excluir del raycast)
	DropManager.soltar(drops, global_position, null, self)
	print("[EnemigoBase] 💀 ", name, " MUERE. Desaparezco en 0.4s.")
	# Tween desvanecer visual + eliminar
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_interval(0.4)
	# (Opcional): buscar MeshInstance para escalar/desvanecer (solo si existe)
	var mesh: MeshInstance3D = get_node_or_null("MeshInstance3D")
	if mesh != null:
		tween.parallel().tween_property(mesh, "scale", Vector3.ZERO, 0.4)
	tween.tween_callback(queue_free)
	# Si el enemigo tiene un id (lo pondrás en cada .tscn), notifica al MisionManager
	if id_enemigo != &"":
		MisionManager.actualizar_progreso(&"matar", id_enemigo, 1)


# ═══════════════════════════════════════════════════════════════
# 12) HELPERS PRIVADOS
# ═══════════════════════════════════════════════════════════════
func _buscar_jugador() -> void:
	var nodo_jug = get_tree().get_first_node_in_group("jugador")
	if nodo_jug != null and nodo_jug is CharacterBody3D:
		_jugador_ref = nodo_jug as CharacterBody3D


func _asignar_direccion_patrulla_random() -> void:
	# Vector aleatorio en plano XZ (-1 a 1) normalizado, sin eje Y
	var angulo_rad: float = randf() * TAU
	_direccion_patrulla = Vector3(cos(angulo_rad), 0.0, sin(angulo_rad)).normalized()


func _nombre_estado(e: int) -> String:
	match e:
		Estado.PATRULLA: return "PATRULLA"
		Estado.PERSEGUIR: return "PERSEGUIR"
		Estado.ATACAR: return "ATACAR"
	return "DESCONOCIDO"
