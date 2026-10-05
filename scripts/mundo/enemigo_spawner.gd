extends Node3D
# FASE 3.4: Spawner genérico y configurable de enemigos.
# Desacoplado (no sabe qué enemigo spawnea: @export PackedScene).
# Eficiente (sin polling de grupos; usa conexión por señales Damageable.murio).

# ──────────────────────────────────────────────────────────────
# EXPORTS (ajustables por Inspector en mundo.tscn, por cada spawner)
# ──────────────────────────────────────────────────────────────
@export var escena_enemigo: PackedScene          # Cualquier PackedScene de enemigo (EnemigoSlime.tscn, etc.)
@export var radio_min_spawn: float = 8.0         # Distancia MÍNIMA al jugador (NUNCA spawnea más cerca que esto → anillo seguridad)
@export var radio_max_spawn: float = 18.0        # Distancia MÁXIMA al jugador (spawnea dentro de este radio)
@export var max_enemigos_simultaneos: int = 5    # Pico máximo de enemigos vivos de este spawner
@export var cooldown_entre_spawns: float = 4.5   # Segundos entre cada intento de spawn

# ──────────────────────────────────────────────────────────────
# VARIABLES INTERNAS (estado)
# ──────────────────────────────────────────────────────────────
var _temporizador_spawn: float = 0.0             # Cuenta atrás para el próximo spawn
var _cantidad_activos: int = 0                   # Cuántos enemigos vivos creado POR ESTE spawner (cuenta por spawner, no global)

# Cache del jugador (buscamos 1 vez, no cada frame)
var _jugador_cache: Node3D = null

# ──────────────────────────────────────────────────────────────
# READY: buscar jugador y prender temporizador
# ──────────────────────────────────────────────────────────────
func _ready() -> void:
	# 1) Validación fuerte: si alguien olvidó meter la escena_enemigo en el Inspector, paramos todo con warning claro
	if escena_enemigo == null:
		push_warning("[Spawner %s] ⚠️ NO hay PackedScene 'escena_enemigo' asignada en el Inspector. Apagando spawner." % name)
		set_process(false)
		return

	# 2) Validación de radios (no permitir min > max → anillo imposible)
	if radio_min_spawn >= radio_max_spawn:
		push_warning("[Spawner %s] ⚠️ radio_min_spawn >= radio_max_spawn (anillo imposible). Forzando min = max*0.5" % name)
		radio_min_spawn = radio_max_spawn * 0.5

	# 3) Buscar jugador (una sola vez, al ser singleton/group no se mueve de índice)
	_buscar_jugador_cache()

	# 4) Prender temporizador (empieza YA: primer spawn a los 0.5s del arranque para probar rápido)
	_temporizador_spawn = 0.5
	print("[Spawner %s] ✅ Encendido. Max activos %d, cooldown %.1fs, anillo %.1f-%.1fm" %
		[name, max_enemigos_simultaneos, cooldown_entre_spawns, radio_min_spawn, radio_max_spawn])

# ──────────────────────────────────────────────────────────────
# HELPERS
# ──────────────────────────────────────────────────────────────
func _buscar_jugador_cache() -> void:
	# Buscamos 1 vez al jugador por su grupo (registrado en jugador.gd _ready())
	if _jugador_cache == null and get_tree().has_group("jugador"):
		var lista_jugadores := get_tree().get_nodes_in_group("jugador")
		if lista_jugadores.size() > 0:
			_jugador_cache = lista_jugadores[0] as Node3D

func _posicion_aleatoria_en_anillo_jugador() -> Vector3:
	# Devuelve un punto aleatorio DENTRO del anillo [radio_min, radio_max] alrededor del jugador
	# Técnica: ángulo aleatorio [0, 2PI] + radio aleatorio [min, max], proyectado en plano XZ.
	var angulo: float = randf() * TAU
	var radio:  float = randf_range(radio_min_spawn, radio_max_spawn)

	# Posición base = posición del jugador
	var pos_jug: Vector3 = Vector3.ZERO
	if _jugador_cache != null:
		pos_jug = _jugador_cache.global_position

	# Calculamos punto en XZ:
	var x_offset: float = cos(angulo) * radio
	var z_offset: float = sin(angulo) * radio
	# Devolvemos: pos jugador + offset plano XZ. ¡NO CAMBIAMOS LA Y! (respetar la altura del terreno)
	return Vector3(pos_jug.x + x_offset, global_position.y, pos_jug.z + z_offset)
	# En vez de fijar Y = spawner.global_position.y, hacemos un RAYCAST hacia abajo desde 5m arriba para ajustar al suelo.
	var punto_alto: Vector3 = Vector3(pos_jug.x + x_offset, global_position.y + 5.0, pos_jug.z + z_offset)
	var query := PhysicsRayQueryParameters3D.create(punto_alto, punto_alto + Vector3.DOWN * 10.0)
	var resultado: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if resultado.has("position"):
		return resultado.position + Vector3(0.0, 0.5, 0.0)  # posiciona justo sobre el suelo, medio metro arriba por el collider del enemigo
	else:
		return Vector3(pos_jug.x + x_offset, global_position.y, pos_jug.z + z_offset)
# ──────────────────────────────────────────────────────────────
# SPAWNEAR 1 ENEMIGO
# ──────────────────────────────────────────────────────────────
func _intentar_spawnear_1() -> void:
	# Regla: si ya estamos llenos, no spawneamos (población máxima)
	if _cantidad_activos >= max_enemigos_simultaneos:
		return

	# Regla: si no hay cache del jugador, reintentar buscar (raro pero por si se cargó orden raro)
	if _jugador_cache == null:
		_buscar_jugador_cache()
		if _jugador_cache == null:
			return   # jugador no spawneó todavía; reintento en el próximo cooldown

	# 1) Instanciar la escena del enemigo (el PackedScene que exportamos):
	var instancia: Node3D = escena_enemigo.instantiate()
	if instancia == null:
		push_warning("[Spawner %s] ❌ No se pudo instanciar escena_enemigo" % name)
		return

	# 2) Posición = aleatoria en anillo (función helper):
	instancia.global_position = _posicion_aleatoria_en_anillo_jugador()

	# 3) PADRE: lo añadimos como hijo del MISMO NODO QUE NOSOTROS (en mundo.tscn el padre es el raíz)
	#    Así el enemigo NO es hijo del spawner (si movemos el spawner no arrastramos todos los slimes)
	get_parent().add_child(instancia)

	# 4) +1 a la cuenta de activos de ESTE spawner
	_cantidad_activos += 1

	# 5) 🔑 CONEXIÓN A SEÑAL MURIO: descontar cuando el jugador lo mate (NO polling)
	#    5.1) Buscamos el Damageable DENTRO del enemigo instanciado (hijo, según EnemigoSlime.tscn):
	var damageable_nodo: Node = instancia.get_node_or_null("Damageable")
	if damageable_nodo != null and damageable_nodo.has_signal("murio"):
		damageable_nodo.murio.connect(_on_enemigo_murio.bind(instancia))
		# 5.2 Bind(instancia): guardamos una referencia para luego comprobar si es el que murió
		print("[Spawner %s] 🟢 Spawneado: %s → pos=%s | Activos ahora %d/%d" %
			[name, instancia.name, instancia.global_position, _cantidad_activos, max_enemigos_simultaneos])
	else:
		# El enemigo no tiene Damageable con señal murio → fallback: descontar al cabo de N segundos para no bloquear la cuenta
		# (enemigos que mueren por otros medios). Mejor que nada si se rompe la señal.
		_temporizador_spawn += 3.0
		print("[Spawner %s] 🟡 Spawneado sin Damageable.murio conectado (fallback: +3s cooldown)" % name)

# ──────────────────────────────────────────────────────────────
# CALLBACK SEÑAL: 1 enemigo matado
# ──────────────────────────────────────────────────────────────
func _on_enemigo_murio(_param1 = null , _param2 = null , _param3 = null , enemigo_instancia: Node = null ) -> void:
	# _datos es lo que envía Damageable (hp_restante etc); no lo usamos.
	# enemigo_instancia es el bind(instancia) del paso 5 anterior.

	# 1) Seguridad: solo descontar si el enemigo sigue existiendo (no fue liberado antes)
	if enemigo_instancia == null or not is_instance_valid(enemigo_instancia):
		if _cantidad_activos > 0:
			_cantidad_activos -= 1
		return

	# 2) Descontar 1 de la cuenta activa:
	if _cantidad_activos > 0:
		_cantidad_activos -= 1

	print("[Spawner %s] 💀 Enemigo matado: %s | Quedan activos %d/%d" %
		[name, enemigo_instancia.name, _cantidad_activos, max_enemigos_simultaneos])

# ──────────────────────────────────────────────────────────────
# BUCLE SPAWN (process o physics_process es indiferente aquí)
# ──────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	# Contar hacia atrás el cooldown:
	if _temporizador_spawn > 0.0:
		_temporizador_spawn -= delta
		return   # no es momento de spawnear → salir ya

	# 1) Intentar spawnear 1:
	_intentar_spawnear_1()

	# 2) Resetear el cooldown (independientemente de si hubo spawn o no; 
	#    así si está lleno no lo reintenta hasta el próximo ciclo)
	_temporizador_spawn = cooldown_entre_spawns
