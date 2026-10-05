extends CharacterBody3D

# ──────────────────────────────────────────────────────────────
# ONREADY NODOS
# ──────────────────────────────────────────────────────────────
@onready var visual_holder: Node3D = $VisualHolder
@onready var modelo_hacha: MeshInstance3D = $VisualHolder/ModeloHacha
@onready var modelo_pico: MeshInstance3D = $VisualHolder/ModeloPico
@onready var modelo_azada: MeshInstance3D = $VisualHolder/ModeloAzada
@onready var modelo_regadera: MeshInstance3D = $VisualHolder/ModeloRegadera
@onready var hitbox_ataque: Area3D = $VisualHolder/HitboxAtaque
@onready var rango_interaccion: Area3D = $RangoInteraccion # PASO 1.1
@onready var prompt_interaccion: Label3D = $PromptInteraccion  # PASO 1.2
@onready var damageable: Node = $Damageable
@onready var camara: Camera3D = $Camera
# ──────────────────────────────────────────────────────────────
# COMBATE
# ──────────────────────────────────────────────────────────────
const ANGULO_CONO_GOLPE_DEG : float = 55.0
const DISTANCIA_OVERLAP_FISICO_MIN : float = 0.35
@export var cooldown_ataque: float = 0.0 # >0 = no puede atacar
@export var _duracion_activar_hitbox_ms: float = 0.25  # 250ms
@export var _daño_ataque: int = 15 # Daño base del golpe
var _temporizador_hitbox_activo: float = 0.0  # Cuenta atrás apagar hitbox
var _objetos_golpeados_en_este_golpe: Array[NodePath] = []  # Evita pegar 2 veces al mismo en 1 swing
var _esta_atacando: bool = false # Control de estado

# ──────────────────────────────────────────────────────────────
# VARIABLES GLOBALES JUGADOR
# ──────────────────────────────────────────────────────────────
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var recurso_en_rango: Node3D = null  # para GOLPEAR con E (árboles/rocas)
var interactuable_mas_cercano: Node = null # para INTERACTUAR con F (mercado, puertas, parcelas...)
var _distancia_interactuable_cercano: float = INF
const VELOCIDAD_ANDAR: float = 3.5
const VELOCIDAD_CORRER: float = 6.5
# Variables globales movimiento / debug:
# 👉 input_dir SE INICIALIZA EN CERO. NUNCA poner Input.get_vector() AQUÍ (solo se lee 1 vez).
var input_dir: Vector2 = Vector2.ZERO

# 👉 Vectores ISO = CONSTANTES (nunca cambian en runtime). Combinación #3 (resuelve FrenteMesh punta derecha):
var ISO_ARRIBA: Vector3 = Vector3(-0.70710678, 0.0 , -0.70710678 )
var ISO_DERECHA: Vector3 = Vector3( 0.70710678 , 0.0 , -0.70710678 )
var ultimo_input_dir: Vector2 = Vector2.ZERO
var _ultima_dir_mov_normalizada: Vector3 = Vector3.ZERO# 🆕 AÑADE ESTA LÍNEA
var _ultima_herramienta_aplicada: StringName = &""

# ──────────────────────────────────────────────────────────────
# SISTEMA DE ARMAS (FASE 3.5)
# ──────────────────────────────────────────────────────────────
# 1) Diccionario MAPEO de "nombre herramienta equipada" a SU Resource ArmaDefinicion.
#    (lo cargamos en _ready() para no tener rutas hardcodeadas en runtime)
var _mapa_armas: Dictionary = {}                     # key: StringName, value: ArmaDefinicion
var _arma_actual: ArmaDefinicion = null              # Resource del arma activa en este instante

# Cache CollisionShape3D hijo del HitboxAtaque (accesible en 1 lookup, no get_node cada frame)
@onready var _hitbox_collision: CollisionShape3D = $VisualHolder/HitboxAtaque/CollisionShape3D
# Cache BoxShape3D asignado (creamos 1 único shape LOAD TIME y lo modificamos su tamaño N veces)
var _hitbox_shape: BoxShape3D = BoxShape3D.new()

# ──────────────────────────────────────────────────────────────
# READY (conectar señales AREAS)
# ──────────────────────────────────────────────────────────────
func _ready() -> void:
	add_to_group("jugador")
	
	if camara != null :
		camara.look_at(global_position, Vector3.UP)
	rango_interaccion.body_entered.connect(_on_rango_interaccion_body_entered)
	rango_interaccion.body_exited.connect(_on_rango_interaccion_body_exited)
	rango_interaccion.area_entered.connect(_on_rango_interaccion_area_entered)
	rango_interaccion.area_exited.connect(_on_rango_interaccion_area_exited)
	
	_recalcular_interactuable_mas_cercano()
	
	if prompt_interaccion != null:
		# Todo en unidades mundiales REALES. Sin multiplicar por nada.
		prompt_interaccion.visible = true
		prompt_interaccion.show()
	
	# Validación extra: HitboxAtaque debe existir (FASE 3.2)
	if hitbox_ataque == null:
		push_warning("[Jugador] ⚠️ NO EXISTE nodo hijo 'HitboxAtaque'(Area3D). Añádelo en la escena Jugador.tscn, hijo directo del raíz.")

	# 🔒 FIX UNICA VEZ: Rotación INICIAL VisualHolder mirar a cámara (1 sola vez, sin repeticiones)
	if camara != null:
		var vh: Node3D = $VisualHolder
		if vh != null:
			var dir_a_camara: Vector3 = camara.global_position - vh.global_position
			dir_a_camara.y = 0.0
			if dir_a_camara.length() > 0.001:
				dir_a_camara = dir_a_camara.normalized()
				var target: Vector3 = vh.global_position + dir_a_camara
				vh.look_at(target, Vector3.UP)
				print("[Jugador] VH inicial mirando a cámara (dir=", dir_a_camara, ")" )
	
	# ═══════════════════════════════════════════════════════════ 
	# FASE 3.5 (DESPUÉS de la rotación inicial): 
	_cargar_mapa_armas_desde_recursos()
	if _hitbox_collision != null:
		_hitbox_collision.shape = _hitbox_shape
	_aplicar_arma_por_herramienta_equipada()
# ──────────────────────────────────────────────────────────────
# PROCESS VISUAL (herramienta en mano + PROMPT flotante)
# ──────────────────────────────────────────────────────────────
func _process(_delta: float) -> void:
	# 1. Mostrar/ocultar modelos herramienta
	modelo_hacha.visible = (Inventario.herramienta_equipada == &"hacha")
	modelo_pico.visible = (Inventario.herramienta_equipada == &"pico")
	modelo_azada.visible = (Inventario.herramienta_equipada == &"azada" )
	modelo_regadera.visible = (Inventario.herramienta_equipada == &"regadera" )
	# 2. ⭐ Actualizar el PROMPT flotante encima del jugador
	_actualizar_prompt_interaccion()
	_actualizar_temporizadores_combate(_delta)
	
	if Inventario.herramienta_equipada != _ultima_herramienta_aplicada:
		_ultima_herramienta_aplicada = Inventario.herramienta_equipada
		_aplicar_arma_por_herramienta_equipada ()


# ═══════════════════════════════════════════════════════════════
# PHYSICS PROCESS + MOVIMIENTO ISOMÉTRICO FIJO (sin dependencia de cámara)
# - No usamos $Camera porque es HIJA del jugador y rota con él
# - No usamos look_at() por lo mismo (rotaría la cámara)
# - Usamos vectores MUNDIALES FIJOS calculados para vista isométrica 45°
# ═══════════════════════════════════════════════════════════════
func _physics_process(delta: float) -> void:
	if GameState.modo_actual == GameState.MODO_UI:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	_procesar_movimiento(delta)

func _procesar_movimiento(delta: float) -> void:
	# 1) Leer input vector (Godot 4: Input.get_vector devuelve Vector2 ya normalizado)
	input_dir = Input.get_vector("mover_izquierda", "mover_derecha", "mover_arriba", "mover_abajo")
	# 2) Velocidad actual según Shift correr / andar
	var vel_actual: float = VELOCIDAD_ANDAR
	if Input.is_key_pressed(KEY_SHIFT):
		vel_actual = VELOCIDAD_CORRER

	var movimiento: Vector3 = (ISO_ARRIBA * (-input_dir.y)) + (ISO_DERECHA * input_dir.x)
		# 5) ── ROTACIÓN VISUAL HOLDER (solo este nodo, siempre)
	if movimiento.length() > 0.001:
		_ultima_dir_mov_normalizada = movimiento

		# ═══════════════════════════════════════════════════════════
		# FIX INCLINACIÓN: Construimos rotación OBJETIVO PURAMENTE
		# alrededor del EJE Y (ninguna rotación X/Z = cero inclinación)
		# NO usamos .looking_at() porque arrastra basura de la base
		# ═══════════════════════════════════════════════════════════

		# 1) Vector dirección normalizado en XZ plano (y = 0 SIEMPRE)
		var mov_normalizado: Vector3 = movimiento.normalized()
		mov_normalizado.y = 0.0
		if mov_normalizado.length() < 0.001:
			mov_normalizado = Vector3.BACK  # -Z canónico fallback

		# 2) Ángulo directo en radianes entre eje -Z y dirección movimiento
		#    Vector3.BACK = (0,0,-1) es la dirección de FRENTE CANÓNICA
		var angulo_y: float = atan2(mov_normalizado.x, mov_normalizado.z) + PI
		
		# 3) Construimos cuaternio OBJETIVO SÓLO con rotación Y (sin X ni Z)
		var q_objetivo_puro: Quaternion = Quaternion(Vector3.UP, angulo_y)

		# 4) Slerp SOLO desde la rotación ACTUAL → objetivo PURO
		var q_actual: Quaternion = visual_holder.transform.basis.get_rotation_quaternion()

		# 🔑 Sign flip siempre antes de slerp
		if q_actual.dot(q_objetivo_puro) < 0.0:
			q_objetivo_puro = -q_objetivo_puro

		# 🔑 FIX VELOCIDAD ROTACIÓN: 18.0 en vez de 12.0 (1.5x más rápido)
		var factor_rotacion: float = delta * 18.0
		var q_slerped: Quaternion = q_actual.slerp(q_objetivo_puro, clamp(factor_rotacion, 0.0, 1.0))
		var nueva_base: Basis = Basis(q_slerped)

		# 5) ✅ Asignar base pura al VisualHolder (origin NO se toca)
		var t_vh_nuevo: Transform3D = visual_holder.transform
		t_vh_nuevo.basis = nueva_base
		visual_holder.transform = t_vh_nuevo

		# Debug (opcional, puedes borrarlo después)
		var debug_forward: Vector3 = visual_holder.transform.basis.z * (-1.0)
		var dot_paralelo: float = mov_normalizado.dot(debug_forward)

	# 6) Asignar velocidad para CharacterBody3D
	velocity.x = movimiento.x * vel_actual
	velocity.z = movimiento.z * vel_actual

	# 7) Gravedad (igual que antes — no tocar)
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	else:
		velocity.y = -0.1

	# 8) Aplicar movimiento (Godot CharacterBody3D)
	move_and_slide()
	ultimo_input_dir = input_dir
## ──────────────────────────────────────────────────────────────
# INPUTS GLOBALES DEL JUGADOR (UNICO PUNTO DE ENTRADA)
# ──────────────────────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if not GameState.esta_en_modo_mundo():
		return
	
	# ⭐ 1) TECLA F = INTERACTUAR (con objeto MÁS CERCANO)
	if event.is_action_pressed("interactuar_mundo"):
		_interactuar_con_cercano()
	
	# 2) TECLA E = GOLPEAR (herramienta) - mantenemos la tuya
	if event.is_action_pressed("golpear"):
		ejecutar_accion_herramienta()
	
	# 🔹 3) ATAQUE CUERPO A CUERPO (ROBUSTO: 3 métodos)
	var quiere_atacar: bool = false
	
	# --- Método A: InputMap click_izquierdo (si lo tienes configurado) ---
	if InputMap.has_action("click_izquierdo") and event.is_action_pressed("click_izquierdo"):
		quiere_atacar = true
	
	# --- Método B: InputEventMouseButton DIRECTO (MOUSE BUTTON 1 / click izquierdo) 🔹 PRINCIPAL 🔹 ---
	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			quiere_atacar = true
	
	# --- Método C: InputEventKey DIRECTO (Space / Enter) FALLBACK ---
	elif event is InputEventKey:
		var kb: InputEventKey = event as InputEventKey
		if kb.pressed and (kb.keycode == KEY_SPACE or kb.keycode == KEY_ENTER):
			quiere_atacar = true

	if quiere_atacar:
		_intentar_atacar()
		
		# 🔹 4) CAMBIO RÁPIDO DE HERRAMIENTAS CON TECLADO (FASE 3.5)
	#    1 = Hacha, 2 = Pico, 3 = Azada, 4 = Regadera, 5 = Puños / Desequipar
	if event is InputEventKey:
		var kb: InputEventKey = event as InputEventKey
		if kb.pressed and not kb.echo:
			match kb.keycode:
				KEY_1:
					Inventario.equipar_herramienta(&"hacha")
				KEY_2:
					Inventario.equipar_herramienta(&"pico")
				KEY_3:
					Inventario.equipar_herramienta(&"azada")
				KEY_4:
					Inventario.equipar_herramienta(&"regadera")
				KEY_5:
					if Inventario.herramienta_equipada == &"puños":
						Inventario.equipar_herramienta(&"puños")
					else:
						Inventario.herramienta_equipada = &"puños"
						Inventario.herramienta_equipada_cambiada.emit(Inventario.herramienta_equipada, &"puños")
						Inventario.inventario_cambiado.emit()
				KEY_Q:
					# Tecla Q = Toggle desequipar (volver a puños)
					if Inventario.herramienta_equipada == &"puños" or Inventario.herramienta_equipada == &"":
						Inventario.equipar_herramienta(&"hacha")
					else:
						Inventario.herramienta_equipada = &"puños"
						Inventario.herramienta_equipada_cambiada.emit(Inventario.herramienta_equipada, &"puños")
						Inventario.inventario_cambiado.emit()

# ──────────────────────────────────────────────────────────────
# LOGICA INTERACCION F (UNIFICADA)
# ──────────────────────────────────────────────────────────────
func _interactuar_con_cercano() -> void:
	# 1. Verificar que haya alguno
	if interactuable_mas_cercano == null:
		print("👉 Nada cerca para interactuar.")
		return
	
	# 2. Verificar que implemente el método (Duck Typing check)
	if not interactuable_mas_cercano.has_method("interactuar"):
		print("[Jugador] El objeto ", interactuable_mas_cercano.name, " NO tiene método interactuar().")
		return
	
	# 3. Si tiene "puede_interactuar", comprobar (sino asumimos true)
	if interactuable_mas_cercano.has_method("puede_interactuar"):
		if not interactuable_mas_cercano.puede_interactuar():
			var msg := "(no disponible ahora)"
			if interactuable_mas_cercano.has_method("get_prompt"):
				msg = interactuable_mas_cercano.get_prompt()
			print("[Jugador] No se puede interactuar: ", msg)
			return
	
	# 4. ✅ TODO OK → LLAMAR AL MÉTODO DEL OBJETO
	print("[Jugador] Interactuando con: ", interactuable_mas_cercano.name if interactuable_mas_cercano.has_method("get_name") else interactuable_mas_cercano)
	interactuable_mas_cercano.interactuar(self)  # self = el jugador, se lo pasamos al objeto

# ──────────────────────────────────────────────────────────────
# PROMPT FLOTANTE (encima del jugador)
# ──────────────────────────────────────────────────────────────
func _actualizar_prompt_interaccion() -> void:
	# MODO PRUEBA TEMPORAL (luego borrar):
	if interactuable_mas_cercano == null and recurso_en_rango == null:
		prompt_interaccion.text = "🧪 Acercate a algo"
		prompt_interaccion.visible = true
		prompt_interaccion.position = Vector3(0, 2.3, 0)  # 2.3m, no 25
		return
	
	if interactuable_mas_cercano != null and interactuable_mas_cercano.has_method("get_prompt"):
		prompt_interaccion.text = interactuable_mas_cercano.get_prompt()
		prompt_interaccion.visible = true
		if interactuable_mas_cercano is Node3D:
			var obj: Node3D = interactuable_mas_cercano as Node3D
			# AHORA +2.8 metros GLOBALES (no 2.8 * 0.1)
			prompt_interaccion.global_position = obj.global_position + Vector3(0, 2.8, 0)
	
	elif recurso_en_rango != null:
		var herramienta: String = ""
		if recurso_en_rango.is_in_group("arboles"):
			herramienta = "hacha"
		elif recurso_en_rango.is_in_group("rocas"):
			herramienta = "pico"
		if herramienta != "":
			prompt_interaccion.text = "[E] Golpear con " + herramienta
			prompt_interaccion.visible = true
			# 2.5m GLOBALES
			prompt_interaccion.global_position = recurso_en_rango.global_position + Vector3(0, 2.5, 0)
	else:
		prompt_interaccion.visible = false
		
# ──────────────────────────────────────────────────────────────
# DETECTORES RANGO INTERACCION (entra/sale un cuerpo interactuable)
# ──────────────────────────────────────────────────────────────
func _on_rango_interaccion_body_entered(body: Node3D) -> void:
	# Solo nos interesan objetos que TENGAN método interactuar
	if body.has_method("interactuar"):
		print("[Rango F] Entró interactuable: ", body.name)
		_recalcular_interactuable_mas_cercano()

func _on_rango_interaccion_body_exited(body: Node3D) -> void:
	if body.has_method("interactuar"):
		print("[Rango F] Salió interactuable: ", body.name)
		_recalcular_interactuable_mas_cercano()

# (Opcional: Algunos objetos como estaciones son Area3D, por eso estos 2)
func _on_rango_interaccion_area_entered(area: Area3D) -> void:
	if area.has_method("interactuar"):
		_recalcular_interactuable_mas_cercano()
func _on_rango_interaccion_area_exited(area: Area3D) -> void:
	if area.has_method("interactuar"):
		_recalcular_interactuable_mas_cercano()

# ⭐ CALCULAR CUÁL ES EL MÁS CERCANO (prioriza los que están a MENOR distancia)
func _recalcular_interactuable_mas_cercano() -> void:
	var candidato_cercano: Node = null
	var candidato_dist: float = INF
	
	# 1) Cuerpos dentro del área (StaticBody3D de Mercado)
	for body in rango_interaccion.get_overlapping_bodies():
		if body.has_method("interactuar"):
			var d := global_position.distance_to(body.global_position)
			if d < candidato_dist:
				candidato_dist = d
				candidato_cercano = body
	
	# 2) Áreas dentro (por si interactuables son Area3D)
	for area in rango_interaccion.get_overlapping_areas():
		if area.has_method("interactuar"):
			var d := global_position.distance_to(area.global_position)
			if d < candidato_dist:
				candidato_dist = d
				candidato_cercano = area
	
	# Actualizamos variables globales
	interactuable_mas_cercano = candidato_cercano
	_distancia_interactuable_cercano = candidato_dist

# ──────────────────────────────────────────────────────────────
# RANGO GOLPE (E = Tal árbol / Minar roca) - Tu código + mejora
# ──────────────────────────────────────────────────────────────
func ejecutar_accion_herramienta() -> void:
	if recurso_en_rango != null:
		if recurso_en_rango.is_in_group("arboles") and Inventario.herramienta_equipada == &"hacha":
			recurso_en_rango.recibir_golpe()
		elif recurso_en_rango.is_in_group("rocas") and Inventario.herramienta_equipada == &"pico":
			recurso_en_rango.recibir_golpe()
		else:
			var hint: String = ""
			if recurso_en_rango.is_in_group("arboles"):
				hint = "Equipa el HACHA primero."
			elif recurso_en_rango.is_in_group("rocas"):
				hint = "Equipa el PICO primero."
			print("❌ No puedes golpear esto. ", hint)
	else:
		print("👉 No hay nada cerca para golpear. Acercate más.")

func _on_rango_golpe_body_entered(body: Node3D) -> void:
	if body.is_in_group("arboles") or body.is_in_group("rocas"):
		recurso_en_rango = body

func _on_rango_golpe_body_exited(body: Node3D) -> void:
	if body == recurso_en_rango:
		recurso_en_rango = null
		
# ═══════════════════════════════════════════════════════════════

# COMBATE: Intentar atacar (input click izq / space)

# ═══════════════════════════════════════════════════════════════
# ═══════════════════════════════════════════════════════════════
# GOLPE INFALIBLE: Búsqueda manual por cono frontal + distancia
# NO depende de collision layers ni de solapamientos físicos.
# Úsalo JUNTO al Area3D normal (ambos sistemas trabajan juntos).
# ═══════════════════════════════════════════════════════════════
func _procesar_golpe_manual_cono_frontal() -> void:
	if _arma_actual == null:
		return

	# 1) Vector FRENTE CANÓNICO actual del VisualHolder (-Z en local → global)
	var frente_global: Vector3 = -visual_holder.global_transform.basis.z
	frente_global.y = 0.0
	frente_global = frente_global.normalized()

	# 2) Origen del golpe: un poco elevado (altura pecho/armas del jugador)
	var origen_golpe: Vector3 = visual_holder.global_position + Vector3(0.0, 0.7, 0.0)

	# 3) Rango efectivo TOTAL: alcance arma + margen por separación física cápsulas
	var rango_total: float = _arma_actual.alcance_metros + DISTANCIA_OVERLAP_FISICO_MIN

	# 4) Coseno del ángulo umbral (más barato que hacer acos a cada objetivo)
	var coseno_umbral: float = cos(deg_to_rad(ANGULO_CONO_GOLPE_DEG))

	# 5) Buscar TODO lo que esté en el radio esférico
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	var esfera: SphereShape3D = SphereShape3D.new()
	esfera.radius = rango_total
	query.shape = esfera
	query.collision_mask = 0x7FFFFFFF   # TODAS las capas menos la 32 (0b01111...1111) — busca TODO
	query.transform = Transform3D(Basis.IDENTITY, origen_golpe)
	query.collide_with_bodies = true
	query.collide_with_areas = false    # Damageable es Nodo (componente), no Area
	var espacio: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var resultados: Array = espacio.intersect_shape(query, 32)   # max 32 cuerpos (más que suficiente)

	# 6) Filtrar cada resultado (DISTANCIA + ÁNGULO CONO + NO JUGADOR)
	for r in resultados:
		var collider: Object = r.collider
		if collider == null or not (collider is Node):
			continue
		var nodo_colision: Node = collider as Node

		# FILTRO 1: Nunca es el propio jugador ni sus hijos
		if nodo_colision == self or self.is_ancestor_of(nodo_colision):
			continue
		if nodo_colision.name == "Jugador" or nodo_colision.is_in_group("jugador"):
			continue

		# FILTRO 2: Posición XZ del objetivo (ignoramos altura Y — isométrico)
		var pos_objetivo_xz: Vector3 = (nodo_colision as Node3D).global_position if nodo_colision is Node3D else Vector3.ZERO
		var vector_hacia_objetivo_xz: Vector3 = pos_objetivo_xz - origen_golpe
		vector_hacia_objetivo_xz.y = 0.0
		var distancia_objetivo: float = vector_hacia_objetivo_xz.length()

		if distancia_objetivo > rango_total:
			continue   # Fuera de rango esférico

		# FILTRO 3: Ángulo DENTRO del cono frontal
		var coseno_actual: float = 0.0
		if distancia_objetivo > 0.001:
			coseno_actual = vector_hacia_objetivo_xz.normalized().dot(frente_global)
		else:
			coseno_actual = 1.0   # Objetivo encima nuestro, siempre válido

		var dentro_del_cono: bool = (coseno_actual >= coseno_umbral)

		if not dentro_del_cono:
			continue

		# 🎯 FILTRO 4: Buscar Damageable (componente) en este nodo
		var dam: Node = _buscar_damageable_en_nodo(nodo_colision)
		if dam == null:
			# Intento B: tal vez es un hijo del collider (ej: Slime es nodo padre)
			if nodo_colision.get_parent() != null:
				dam = _buscar_damageable_en_nodo(nodo_colision.get_parent())
		if dam == null:
			continue

		# 🔴 Evitar mismo objetivo 2 veces en el mismo golpe (por Capa1 + Capa2)
		var path_nodo: NodePath = dam.get_parent().get_path() if dam.get_parent() != null else dam.get_path()
		if _objetos_golpeados_en_este_golpe.has(path_nodo):
			continue
		_objetos_golpeados_en_este_golpe.append(path_nodo)

		# ✅ APLICAR DAÑO
		dam.call("recibir_danio", _arma_actual.daño, self)
		print("[GolpeManual] ⚔️  DAÑO x%d aplicado a %s!" % [_arma_actual.daño, nodo_colision.name])
		
func _intentar_atacar() -> void:
	if cooldown_ataque > 0.0:
		return
	if _esta_atacando:
		return

	_esta_atacando = true
	
	if _arma_actual != null:
		cooldown_ataque = _arma_actual.cooldown_segundos
	else:
		cooldown_ataque = 0.66
		
	_temporizador_hitbox_activo = _duracion_activar_hitbox_ms
	_objetos_golpeados_en_este_golpe.clear()
	hitbox_ataque.monitoring = true
	if not hitbox_ataque.body_entered.is_connected(_on_hitbox_ataque_body_entered):
		hitbox_ataque.body_entered.connect(_on_hitbox_ataque_body_entered)

	print("[Jugador] ⚔️ ATAQUE iniciado!")

	# 🔹 Procesar SOLAPAMIENTOS EXISTENTES
	await get_tree().process_frame
	var cuerpos_solapados: Array[Node3D] = hitbox_ataque.get_overlapping_bodies()
	var nombres: Array[String] = []
	for c: Node3D in cuerpos_solapados:
		nombres.append(c.name)
	print("[Jugador] Cuerpos solapados en hitbox al activar: ", cuerpos_solapados.size(), ". Nombres: ", nombres)
	for c: Node3D in cuerpos_solapados:
		# 🔴 Filtrar lo que NUNCA puede ser un objetivo:
		# - El propio jugador
		# - Límites del mapa (no tienen Damageable)
		if c == self or c.name == "LimitesMapa":
			continue
		_on_hitbox_ataque_body_entered(c)
		
	
	_procesar_golpe_manual_cono_frontal()

# ═══════════════════════════════════════════════════════════════

# COMBATE: Cada frame, apagar hitbox / reset cooldown

# ═══════════════════════════════════════════════════════════════
func _actualizar_temporizadores_combate(delta: float) -> void:
	if cooldown_ataque > 0.0:
		cooldown_ataque = max(0.0, cooldown_ataque - delta)

	if _esta_atacando and _temporizador_hitbox_activo > 0.0:
		_temporizador_hitbox_activo = max(0.0, _temporizador_hitbox_activo - delta)
		if _temporizador_hitbox_activo <= 0.0:
			_finalizar_ataque()

# ═══════════════════════════════════════════════════════════════

# COMBATE: Terminar swing, apagar hitbox, desconectar señal

# ═══════════════════════════════════════════════════════════════
func _finalizar_ataque() -> void:
	_esta_atacando = false
	_temporizador_hitbox_activo = 0.0
	hitbox_ataque.monitoring = false
	if hitbox_ataque.body_entered.is_connected(_on_hitbox_ataque_body_entered):
		hitbox_ataque.body_entered.disconnect(_on_hitbox_ataque_body_entered)
	_objetos_golpeados_en_este_golpe.clear()
	print("[Jugador] Ataque finalizado.")

# ═══════════════════════════════════════════════════════════════
# COMBATE: Hitbox golpeó algo con cuerpo físico
func _on_hitbox_ataque_body_entered(body: Node3D) -> void:
	if not _esta_atacando:
		return
	print("[Jugador DEBUG] _on_hitbox_ataque_body_entered llamado con: ", body.name, "(tipo: ", body.get_class(), ")")

		# 0) 🛡️ FILTRO ANTI-AUTOGOLPE: 3 CAPAS DE SEGURIDAD
	if body == null:
		return
	# CAPA 1: Nombre exacto
	if body.name == "Jugador" or body.name == "LimitesMapa" or body.name == "Suelo":
		print("[Hitbox DEBUG] ❌ Bloqueado por nombre: ", body.name)
		return
	# CAPA 2: Jerarquía (es el propio jugador o alguno de sus nodos internos)
	if body == self or body.is_ancestor_of(self) or self.is_ancestor_of(body):
		print("[Hitbox DEBUG] ❌ Bloqueado por jerarquía: ", body.name)
		return
	# CAPA 3: Grupo "jugador"
	if body.is_in_group("jugador"):
		print("[Hitbox DEBUG] ❌ Bloqueado por grupo 'jugador': ", body.name)
		return

	# 1) Evitar golpear 2 veces al MISMO nodo en el mismo swing
	var path_body: NodePath = body.get_path()
	if _objetos_golpeados_en_este_golpe.has(path_body):
		return
	_objetos_golpeados_en_este_golpe.append(path_body)

	# 2) Buscar Damageable
	var dam: Node = _buscar_damageable_en_nodo(body)

	if dam == null:
		print("[Jugador DEBUG]→ ", body.name, " NO tiene Damageable. No hay daño.")
		return

	# Otra comprobación extra: dañar Damageable del jugador nunca
	if dam == damageable or dam.is_ancestor_of(self) or self.is_ancestor_of(dam):
		return

	# 3) Aplicar daño
	dam.call("recibir_danio", _daño_ataque, self)
	print("[Jugador] ⚔️ Golpeaste a: ", body.name, " con ", _daño_ataque, " de daño.")# ═══════════════════════════════════════════════════════════════


# Busca Damageable en: el propio body O como nodo hijo directo (patrón componente)
func _buscar_damageable_en_nodo(n: Node) -> Node:
	if n == null:
		return null
	var dam_directo: Node = n.get_node_or_null("Damageable")
	if dam_directo != null and dam_directo.has_method("recibir_danio"):
		return dam_directo
	return null

# ──────────────────────────────────────────────────────────────
# HELPERS SISTEMA ARMAS FASE 3.5
# ──────────────────────────────────────────────────────────────
func _cargar_mapa_armas_desde_recursos() -> void:
	# 1) Cargar los 5 Resources ArmaDefinicion. Usamos load() con rutas absolutas res://
	#    Si no encuentra un recurso, skip + warning claro, no peta.
	_mapa_armas = {}
	var rutas: Dictionary = {
		&"puños":     "res://recursos/armas/ArmaPunos.tres",
		&"hacha":     "res://recursos/armas/ArmaHacha.tres",
		&"pico":      "res://recursos/armas/ArmaPico.tres",
		&"azada":     "res://recursos/armas/ArmaAzada.tres",
		&"regadera":  "res://recursos/armas/ArmaRegadera.tres",
	}
	for nombre_id in rutas.keys():
		var ruta: String = str(rutas[nombre_id])
		var recurso = load(ruta)
		if recurso != null and recurso is ArmaDefinicion:
			_mapa_armas[nombre_id] = recurso
			print("[Armas 3.5] Cargada arma '%s' desde %s" % [recurso.nombre_mostrar, ruta])
		else:
			push_warning("[Armas 3.5] ⚠️ No se pudo cargar %s (falta el recurso %s?)" % [nombre_id, ruta])
	# Fallback crítico: si no hay ningún arma (error de paths), creamos puños IN-MEMORY para no romper el juego
	if _mapa_armas.size() == 0:
		var fallback: ArmaDefinicion = ArmaDefinicion.new()
		fallback.nombre = &"puños"
		fallback.nombre_mostrar = "Puños (fallback sin recursos)"
		fallback.daño = 5
		fallback.alcance_metros = 1.2
		fallback.ancho_metros = 0.8
		fallback.alto_metros = 1.2
		fallback.cooldown_segundos = 0.55
		fallback.duracion_activa_ms = 180
		_mapa_armas[&"puños"] = fallback
		push_warning("[Armas 3.5] 🚨 MODO FALLBACK: sin recursos .tres, usando ArmaPunos in-memory.")

func _aplicar_arma_por_herramienta_equipada() -> void:
	var id_buscado: StringName = Inventario.herramienta_equipada

	if _mapa_armas.has(id_buscado):
		_arma_actual = _mapa_armas[id_buscado]
	else:
		# ID no encontrado (ej: herramienta_equipada = &"martillo" que aún no hemos definido):
		# FALLBACK SEGURO = puños
		_arma_actual = _mapa_armas.get(&"puños", null)

	if _arma_actual == null:
		return  # nada que hacer, seguridad

	# Actualizar variables de COMBATE heredadas de la FASE 3.2:
	_daño_ataque = _arma_actual.daño
	_duracion_activar_hitbox_ms = float(_arma_actual.duracion_activa_ms) / 1000.0
	cooldown_ataque = _arma_actual.cooldown_segundos   # (nota: si tu variable se llama diferente, cambia el nombre)

		# ══════════════════════════════════════════════════════════════
	# FIX RANGO ISOMÉTRICO:
	# 1) Offset = distancia desde el CENTRO del jugador hasta el INICIO del hitbox.
	#    El CollisionShape3D del jugador (cápsula) tiene radio ~0.3-0.4m.
	#    Empezamos el hitbox FUERA del cuerpo, no dentro.
	# 2) El "alcance" del arma debe ser = DISTANCIA TOTAL que llega la punta.
	#    Ej: alcance_metros = 1.8m → la punta del hitbox está a -1.8m
	# ══════════════════════════════════════════════════════════════
	const OFFSET_SALIDA_CUERPO: float = 0.45   # 45cm = distancia desde centro jugador hasta EMPEZAR el hitbox (FUERA del cuerpo)
	var largo_total_shape: float = _arma_actual.alcance_metros - OFFSET_SALIDA_CUERPO
	var mitad_largo_shape: float = largo_total_shape * 0.5

	_hitbox_shape.size = Vector3(_arma_actual.ancho_metros, _arma_actual.alto_metros, largo_total_shape)
	# 🔒 ASIGNACIÓN FORZADA (por si el editor rompió la referencia)
	if _hitbox_collision != null:
		_hitbox_collision.shape = _hitbox_shape
		_hitbox_collision.disabled = false

	# Posición LOCAL del Area3D HitboxAtaque:
	# -Z es el FRENTE.
	# Queremos que LA PUNTA DEL HITBOX esté a -(alcance_metros) exactamente.
	# El centro del BoxShape3D está a mitad del largo.
	if hitbox_ataque != null:
		var pos_local: Vector3 = hitbox_ataque.position
		# Centro Z = - [OFFSET_SALIDA_CUERPO + mitad del shape]
		# Verificación: punta = centro_z - mitad_largo_shape = -(OFFSET + mitad) - mitad = -(OFFSET + largo_total)
		#   pero largo_total = alcance - OFFSET → punta = -(OFFSET + alcance - OFFSET) = -alcance ✅
		pos_local.z = -(OFFSET_SALIDA_CUERPO + mitad_largo_shape)
		pos_local.y = _arma_actual.alto_metros * 0.5
		hitbox_ataque.position = pos_local

	print("[Armas 3.5] Arma equipada: '%s' | daño=%d | alcance=%.1fm | ancho=%.1fm | cooldown=%.2fs" %
		[_arma_actual.nombre_mostrar, _daño_ataque, _arma_actual.alcance_metros, _arma_actual.ancho_metros, cooldown_ataque])
