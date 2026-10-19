extends CharacterBody3D

# ──────────────────────────────────────────────────────────────
# COMBATE
# ──────────────────────────────────────────────────────────────
const ANGULO_CONO_GOLPE_DEG: float = 55.0
## Semiangulo del cono frontal para elegir interactuable. 60° = el candidato
## debe estar dentro de ±60° de la mirada. Comparado con ANGULO_CONO_GOLPE_DEG
## (55°), que es el cono del arma: criterios parecidos, sin copiarse.
const ANGULO_CONO_INTERACCION_DEG: float = 60.0
const DISTANCIA_OVERLAP_FISICO_MIN: float = 0.35
const VELOCIDAD_ANDAR: float = 3.5
const VELOCIDAD_CORRER: float = 6.5

@export var cooldown_ataque: float = 0.0 # >0 = no puede atacar
@export var _duracion_activar_hitbox_ms: float = 0.25  # 250ms
@export var _daño_ataque: int = 15 # Daño base del golpe
@export var rango_golpe_recurso: float = 2.5  # FASE 10.6: radio SIMÉTRICO de tala/minado (m)

var _temporizador_hitbox_activo: float = 0.0  # Cuenta atrás apagar hitbox
var _objetos_golpeados_en_este_golpe: Array[NodePath] = []  # Evita pegar 2 veces al mismo en 1 swing
var _esta_atacando: bool = false # Control de estado
# ──────────────────────────────────────────────────────────────
# MODO COLOCACIÓN DE ESTACIONES
# ──────────────────────────────────────────────────────────────
const ESCENA_ESTACION: PackedScene = preload("res://escenes/mundo/EstacionCrafteo.tscn")
const ESCENA_UI_CRAFTEO: PackedScene = preload("res://escenes/ui/UICrafteo.tscn") 
const ESCENA_PROYECTIL: PackedScene = preload("res://escenes/combate/Proyectil.tscn")
const DISTANCIA_MAX_COLOCACION: float = 2.0
var _en_modo_colocacion: bool = false
var _estacion_a_colocar: StringName = &""
var _preview_colocacion: MeshInstance3D = null
# ── PALA (crear/retirar parcela en la rejilla) ──
var _en_modo_pala: bool = false
var _pala_a_usar: StringName = &""
var _preview_pala: MeshInstance3D = null
# El GestorTerreno NO está en el grupo "terreno" (ese grupo lo tiene su hijo
# 'Colision'), así que se busca por tipo y se cachea.
var _terreno_cache: GestorTerreno = null
# ──────────────────────────────────────────────────────────────
# VARIABLES GLOBALES JUGADOR
# ──────────────────────────────────────────────────────────────
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _recurso_cercano: Node3D = null
var interactuable_mas_cercano: Node = null # para INTERACTUAR con F (mercado, puertas, parcelas...)
var _distancia_interactuable_cercano: float = INF
# Variables globales movimiento / debug:
# 👉 input_dir SE INICIALIZA EN CERO. NUNCA poner Input.get_vector() AQUÍ (solo se lee 1 vez).
var input_dir: Vector2 = Vector2.ZERO
# 👉 Vectores ISO = CONSTANTES (nunca cambian en runtime). Combinación #3 (resuelve FrenteMesh
# punta derecha):
var ISO_ARRIBA: Vector3 = Vector3(-0.70710678, 0.0, -0.70710678 )
var ISO_DERECHA: Vector3 = Vector3( 0.70710678, 0.0, -0.70710678 )
var ultimo_input_dir: Vector2 = Vector2.ZERO
var _ultima_dir_mov_normalizada: Vector3 = Vector3.ZERO# 🆕 AÑADE ESTA LÍNEA
var _ultima_herramienta_aplicada: StringName = &""

# FASE 11.4: multiplicador de velocidad del clima actual (nieve ralentiza).
var _mult_velocidad_clima: float = 1.0
# ──────────────────────────────────────────────────────────────
# SISTEMA DE ARMAS (FASE 3.5)
# ──────────────────────────────────────────────────────────────
# 1) Diccionario MAPEO de "nombre herramienta equipada" a SU Resource ArmaDefinicion.
#    (lo cargamos en _ready() para no tener rutas hardcodeadas en runtime)
var _mapa_armas: Dictionary = {}                     # key: StringName, value: ArmaDefinicion
var _arma_actual: ArmaDefinicion = null              # Resource del arma activa en este instante
# Cache BoxShape3D asignado (creamos 1 único shape LOAD TIME y lo modificamos su tamaño N veces)
var _hitbox_shape: BoxShape3D = BoxShape3D.new()

# ──────────────────────────────────────────────────────────────
# ONREADY NODOS
# ──────────────────────────────────────────────────────────────
@onready var visual_holder: Node3D = $VisualHolder
@onready var modelo_arma: MeshInstance3D = $VisualHolder/ModeloArmaActual
@onready var hitbox_ataque: Area3D = $VisualHolder/HitboxAtaque
@onready var rango_interaccion: Area3D = $RangoInteraccion # PASO 1.1
@onready var prompt_interaccion: Label3D = $PromptInteraccion  # PASO 1.2
@onready var damageable: Node = $Damageable
@onready var camara: Camera3D = $Camera
# Cache CollisionShape3D hijo del HitboxAtaque (accesible en 1 lookup, no get_node cada frame)
@onready var _hitbox_collision: CollisionShape3D = $VisualHolder/HitboxAtaque/CollisionShape3D
@onready var stats: Node = $Stats
@onready var estadisticas: Node = $Estadisticas
# ──────────────────────────────────────────────────────────────
# READY (conectar señales AREAS)
# ──────────────────────────────────────────────────────────────
func _ready() -> void:
	add_to_group("jugador")

	if camara != null:
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
	# FASE 12.2: la vida máxima la dicta la Constitución. Se aplica AQUÍ
	# porque en Godot los hijos corren su _ready() ANTES que el padre, así
	# que el Damageable ya inicializó su vida actual desde vida_maxima.
	if estadisticas != null:
		if estadisticas.has_signal("estadisticas_cambiadas"):
			if not estadisticas.estadisticas_cambiadas.is_connected(_aplicar_vida_max_a_damageable):
				estadisticas.estadisticas_cambiadas.connect(_aplicar_vida_max_a_damageable)
		_aplicar_vida_max_a_damageable()
	# ──────────────────────────────────────────────────────────
	# PREVIEW DE COLOCACIÓN
	# ──────────────────────────────────────────────────────────
	_preview_colocacion = MeshInstance3D.new()
	_preview_colocacion.name = "PreviewColocacion"
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(1.5, 1.0, 1.5)
	_preview_colocacion.mesh = box
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.2, 1.0, 0.2, 0.45)
	_preview_colocacion.material_override = mat
	_preview_colocacion.visible = false
	add_child(_preview_colocacion)
	
	# FASE 10.8b: el MODO COLOCACIÓN sigue a la casilla seleccionada de la hotbar
	Inventario.hotbar_cambiada.connect(_sincronizar_modo_colocacion)
	_sincronizar_modo_colocacion()
	# FASE 11.4: escuchar el clima y sincronizar con el estado actual.
	GestorClima.clima_cambio.connect(_on_clima_cambio)
	_on_clima_cambio(GestorClima.clima_actual)
# ──────────────────────────────────────────────────────────────
# PROCESS VISUAL (herramienta en mano + PROMPT flotante)
# ──────────────────────────────────────────────────────────────
func _process(_delta: float) -> void:
	_recurso_cercano = _buscar_recurso_cercano ()
	# 2. ⭐ ELECCIÓN DEL INTERACTUABLE OBJETIVO.
	# Va en _process (y NO solo en los eventos entrar/salir) porque la elección
	# depende de hacia dónde MIRA el jugador, y eso cambia al girar sin moverse.
	# El coste es despreciable: el Area3D tiene 2-3 solapamientos como máximo.
	_recalcular_interactuable_mas_cercano()
	# 3. ⭐ Actualizar el PROMPT flotante encima del jugador
	_actualizar_prompt_interaccion()

	if Inventario.herramienta_equipada != _ultima_herramienta_aplicada:
		_ultima_herramienta_aplicada = Inventario.herramienta_equipada
		_aplicar_arma_por_herramienta_equipada()
	# ──────────────────────────────────────────────────────────
	# PREVIEW COLOCACIÓN
	# ──────────────────────────────────────────────────────────
	if _en_modo_colocacion:
		_actualizar_preview_colocacion()
	if _en_modo_pala:
		_actualizar_preview_pala()
	# ── PREVIEW DE LA PALA: un cubo del tamaño de UN TILE ──
	# El tamaño real se ajusta en caliente desde terreno.tamano_celda, así que
	# aquí NO se hardcodea el 2.0 (cambiar el tile no rompe el preview).
	_preview_pala = MeshInstance3D.new()
	_preview_pala.name = "PreviewPala"
	var box_pala: BoxMesh = BoxMesh.new()
	box_pala.size = Vector3(1.0, 0.3, 1.0)
	_preview_pala.mesh = box_pala
	var mat_pala: StandardMaterial3D = StandardMaterial3D.new()
	mat_pala.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_pala.albedo_color = Color(0.2, 1.0, 0.2, 0.35)
	_preview_pala.material_override = mat_pala
	_preview_pala.visible = false
	add_child(_preview_pala)
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
## ──────────────────────────────────────────────────────────────
# INPUTS GLOBALES DEL JUGADOR (UNICO PUNTO DE ENTRADA)
# ──────────────────────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if not GameState.esta_en_modo_mundo():
		return
	# ═══════════════════════════════════════════════════════════
	# MODO PALA (crear/retirar parcela) — mismo patrón que colocación
	# ═══════════════════════════════════════════════════════════
	if _en_modo_pala:
		if event is InputEventKey:
			var kb_pal: InputEventKey = event as InputEventKey
			if kb_pal.pressed and not kb_pal.echo:
				if kb_pal.keycode >= KEY_1 and kb_pal.keycode <= KEY_9:
					Inventario.seleccionar_hotbar(kb_pal.keycode - KEY_1)
			return
		elif event is InputEventMouseButton:
			var mb_pal: InputEventMouseButton = event as InputEventMouseButton
			if mb_pal.pressed and mb_pal.button_index == MOUSE_BUTTON_LEFT:
				_usar_pala()
			return
	# ═══════════════════════════════════════════════════════════
	# MODO COLOCACIÓN (prioridad sobre ataque/interacción)
	# ═══════════════════════════════════════════════════════════
	if _en_modo_colocacion:
		if event is InputEventKey:
			var kb: InputEventKey = event as InputEventKey
			if kb.pressed and not kb.echo:
				if kb.keycode == KEY_ESCAPE:
					_salir_modo_colocacion()
					return
				# Las teclas 1-9 cambian de casilla también en colocación:
				# seleccionar otra casilla dispara _sincronizar_modo_colocacion(),
				# que sale del modo si la nueva casilla no es una estación.
				if kb.keycode >= KEY_1 and kb.keycode <= KEY_9:
					Inventario.seleccionar_hotbar(kb.keycode - KEY_1)
			return
		elif event is InputEventMouseButton:
			var mb: InputEventMouseButton = event as InputEventMouseButton
			if mb.pressed:
				if mb.button_index == MOUSE_BUTTON_LEFT:
					_colocar_estacion()
				elif mb.button_index == MOUSE_BUTTON_RIGHT:
					_salir_modo_colocacion()
			return
	# ⭐ 1) TECLA F = INTERACTUAR (con objeto MÁS CERCANO)
	if event.is_action_pressed("interactuar_mundo"):
		_interactuar_con_cercano()

	# 🔹 3) ATAQUE CUERPO A CUERPO (ROBUSTO: 3 métodos)
	var quiere_atacar: bool = false

	# --- Método A: InputMap click_izquierdo (si lo tienes configurado) ---
	if InputMap.has_action("click_izquierdo") and event.is_action_pressed("click_izquierdo"):
		quiere_atacar = true

	# --- Método B: InputEventMouseButton DIRECTO (MOUSE BUTTON 1 / click izquierdo) 🔹 PRINCIPAL
	# 🔹 ---
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
		
	# ── USAR ITEM EN MANO (comer/beber) — FASE 10.10 ──────────────
	# Clic derecho: solo con el ítem de la casilla SELECCIONADA de la
	# hotbar. El modo colocación ya retornó arriba (usa su propio clic
	# derecho para cancelar), así que aquí no hay conflicto.
	if event is InputEventMouseButton:
		var mb_usar: InputEventMouseButton = event as InputEventMouseButton
		if mb_usar.button_index == MOUSE_BUTTON_RIGHT and mb_usar.pressed:
			Inventario.usar_item_en_mano()
			
	# ── Atajos de la HOTBAR (FASE 10.8) ───────────────────────────
	# Cero hardcodeo: un BUCLE sobre las 9 casillas en vez de un match por
	# tecla. Añadir una casilla = cambiar CANTIDAD_SLOTS_HOTBAR, nada más.
	if event is InputEventKey:
		var kb: InputEventKey = event as InputEventKey
		if kb.pressed and not kb.echo:
			if kb.keycode >= KEY_1 and kb.keycode <= KEY_9:
				Inventario.seleccionar_hotbar(kb.keycode - KEY_1)
		
# ═══════════════════════════════════════════════════════════════
# FASE 10.2: dispara un proyectil desde el frente del jugador.
# 10.3 (arco) llamará a esto pasando velocidad/daño del ArmaDefinicion.
# ═══════════════════════════════════════════════════════════════
func disparar_proyectil(p_velocidad: float, p_daño: int) -> void:
	if ESCENA_PROYECTIL == null:
		return
	var proy: Node3D = ESCENA_PROYECTIL.instantiate()
	# Frente del jugador = -Z del VisualHolder (el único que rota)
	var dir: Vector3 = -visual_holder.global_transform.basis.z
	var origen: Vector3 = visual_holder.global_position + dir * 0.8 + Vector3.UP * 0.5
	# Al nodo raíz de la escena (NO como hijo del jugador, o heredaría su rotación)
	get_tree().current_scene.add_child(proy)
	proy.global_position = origen
	if proy.has_method("disparar"):
		proy.call("disparar", dir, p_daño, self)
		# ═══════════════════════════════════════════════════════════════
# FASE 10.3: dispara el arma a distancia, consumiendo 1 de munición.
# ═══════════════════════════════════════════════════════════════
func _intentar_disparar() -> void:
	var id_mun: StringName = _arma_actual.id_municion
	# Sin munición configurada (&"") el arma dispara infinito
	if id_mun != &"" and not Inventario.tiene_item(id_mun, 1):
		print("[Jugador] 🏹 Sin munición: ", str(id_mun))
		return

	cooldown_ataque = _arma_actual.cooldown_segundos

	if id_mun != &"":
		Inventario.gastar_item(id_mun, 1)

	disparar_proyectil(_arma_actual.velocidad_proyectil, _daño_efectivo())
	print("[Jugador] 🏹 Disparo con ", str(_arma_actual.nombre))
# FASE 8.5 — Decide si este frame el jugador corre y le cobra la energía.
# Devuelve true solo si: pulsa Shift + se está moviendo + Stats permite correr.
func _intentar_correr(delta: float) -> bool:
	if not Input.is_key_pressed(KEY_SHIFT):
		return false
	if input_dir.length() < 0.001:
		return false
	if stats == null:
		return true
	if not bool(stats.call("puede_correr")):
		return false  # Agotado o sin energía → se fuerza andar
	stats.call("gastar_energia_correr", delta)
	return true
	
func _procesar_movimiento(delta: float) -> void:
	# 1) Leer input vector (Godot 4: Input.get_vector devuelve Vector2 ya normalizado)
	input_dir = Input.get_vector("mover_izquierda", "mover_derecha", "mover_arriba", "mover_abajo")
	# 2) Velocidad actual según Shift correr / andar	# 2) Velocidad actual según Shift correr / andar
	#    FASE 8.5: correr requiere energía y la consume (ver _intentar_correr)
	#    FASE 8.5b: si está agotado, se aplica un multiplicador de velocidad reducido
	var corriendo: bool = _intentar_correr(delta)
	var multiplicador: float = 1.0
	if stats != null:
		multiplicador = float(stats.call("get_multiplicador_velocidad"))
	var vel_actual: float = (VELOCIDAD_CORRER if corriendo else VELOCIDAD_ANDAR) * multiplicador * _mult_velocidad_clima
	
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
		var q_slerped: Quaternion = q_actual.slerp(
			q_objetivo_puro,
			clamp(factor_rotacion, 0.0, 1.0),
		)
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
		print(
			"[Jugador] El objeto ",
			interactuable_mas_cercano.name,
			" NO tiene método interactuar().",
		)
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
	print(
		"[Jugador] Interactuando con: ",
		interactuable_mas_cercano.name if interactuable_mas_cercano.has_method("get_name") else interactuable_mas_cercano,
	)
	interactuable_mas_cercano.interactuar(self)  # self = el jugador, se lo pasamos al objeto


# ──────────────────────────────────────────────────────────────
# PROMPT FLOTANTE (encima del jugador)
# ──────────────────────────────────────────────────────────────
func _actualizar_prompt_interaccion() -> void:
	# MODO PRUEBA TEMPORAL (luego borrar):
	if interactuable_mas_cercano == null and _recurso_cercano == null:
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
	elif _recurso_cercano != null:
		var res: RecursoRespawneable = _recurso_cercano as RecursoRespawneable
		if res != null:
			var ok: bool = _herramienta_tipo_equipada() == res.herramienta_requerida
			if ok:
				prompt_interaccion.text = "[Click] Golpear con " + str(res.herramienta_requerida)
			else:
				prompt_interaccion.text = "Necesitas: " + str(res.herramienta_requerida)
			prompt_interaccion.visible = true
			prompt_interaccion.global_position = res.global_position + Vector3(0, 2.5, 0)
		else:
			prompt_interaccion.visible = false
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


# ⭐ ELIGE EL INTERACTUABLE OBJETIVO.
# Criterio: PRIMERO lo que el jugador tiene AL FRENTE (cono frontal), y
# entre esos, el más cercano. Si no hay NADIE en el cono, cae al más
# cercano de todos → no se pierde la interacción con lo que está detrás.
func _recalcular_interactuable_mas_cercano() -> void:
	# "Frente" = -Z del VisualHolder. Es el ÚNICO nodo que rota (el raíz está
	# siempre en identidad) y es la MISMA dirección que usan el arma (L257) y
	# el proyectil (L257) → una sola definición de "frente" en todo el jugador.
	var frente: Vector3 = -visual_holder.global_transform.basis.z
	frente.y = 0.0
	if frente.length_squared() < 0.000001:
		frente = Vector3.BACK  # -Z canónico de reserva
	else:
		frente = frente.normalized()

	var cos_cono: float = cos(deg_to_rad(ANGULO_CONO_INTERACCION_DEG))

	var mejor_frente: Node = null
	var dist_frente: float = INF
	var mejor_cualquiera: Node = null
	var dist_cualquiera: float = INF

	# Cuerpos (Parcela, Mercado...) y Áreas (estaciones...) en una sola lista:
	# antes eran 2 bucles idénticos duplicados.
	var candidatos: Array[Node] = []
	candidatos.append_array(rango_interaccion.get_overlapping_bodies())
	candidatos.append_array(rango_interaccion.get_overlapping_areas())

	for candidato: Node in candidatos:
		if candidato == null or not candidato.has_method("interactuar"):
			continue
		var n3: Node3D = candidato as Node3D
		if n3 == null:
			continue

		var d: float = global_position.distance_to(n3.global_position)
		if d < dist_cualquiera:
			dist_cualquiera = d
			mejor_cualquiera = candidato

		var hacia: Vector3 = n3.global_position - global_position
		hacia.y = 0.0
		# Si estamos ENCIMA del objeto (hacia ≈ 0) cuenta como "al frente".
		var al_frente: bool = true
		if hacia.length_squared() > 0.000001:
			al_frente = frente.dot(hacia.normalized()) >= cos_cono

		if al_frente and d < dist_frente:
			dist_frente = d
			mejor_frente = candidato

	# Prioridad: lo que tengo al frente. Si no hay nada, el más cercano.
	if mejor_frente != null:
		interactuable_mas_cercano = mejor_frente
		_distancia_interactuable_mas_cercano = dist_frente
	else:
		interactuable_mas_cercano = mejor_cualquiera
		_distancia_interactuable_mas_cercano = dist_cualquiera
# ──────────────────────────────────────────────────────────────
# TALA / MINADO (FASE 10.6) — rango SIMÉTRICO, sin Area3D desplazado
# ──────────────────────────────────────────────────────────────
## Devuelve el recurso (árbol/roca) MÁS CERCANO dentro de rango_golpe_recurso.
## Distancia euclídea → el mismo alcance en TODOS los ángulos.
func _buscar_recurso_cercano() -> Node3D:
	var mejor: Node3D = null
	var mejor_dist: float = rango_golpe_recurso
	var yo: Vector3 = global_position
	for grupo: StringName in RecursoRespawneable.GRUPOS_RECURSO:
		for nodo: Node in get_tree().get_nodes_in_group(grupo):
			if not (nodo is RecursoRespawneable):
				continue
			var n3: Node3D = nodo as Node3D
			var d: float = yo.distance_to(n3.global_position)
			if d <= mejor_dist:
				mejor_dist = d
				mejor = n3
	return mejor

## 'herramienta_tipo' del item equipado (ej. "hacha"), o &"" si no aplica.
## Zero hardcodeo: el dato vive en el ItemDefinicion del item.
func _herramienta_tipo_equipada() -> StringName:
	var id_h: StringName = Inventario.herramienta_equipada
	if id_h == &"" or not ItemDatabase.items.has(id_h):
		return &""
	var def: ItemDefinicion = ItemDatabase.items[id_h]
	if def == null:
		return &""
	return def.herramienta_tipo

## Intenta talar/minar el recurso cercano. Devuelve true si golpeó.
func _intentar_golpear_recurso() -> bool:
	var res: RecursoRespawneable = _recurso_cercano as RecursoRespawneable
	if res == null:
		return false
	# La herramienta equipada debe COINCIDIR con la requerida por el recurso
	if _herramienta_tipo_equipada() != res.herramienta_requerida:
		return false
	res.recibir_golpe()
	cooldown_ataque = _cooldown_de_arma()
	print("[Jugador] 🪓 %s golpeado con %s" % [res.name, str(res.herramienta_requerida)])
	return true
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
	query.collision_mask = 0x7fffffff   # TODAS las capas menos la 32 (0b01111...1111) — busca TODO
	query.transform = Transform3D(Basis.IDENTITY, origen_golpe)
	query.collide_with_bodies = true
	query.collide_with_areas = false    # Damageable es Nodo (componente), no Area
	var espacio: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var resultados: Array = espacio.intersect_shape(
		query,
		32,
	)   # max 32 cuerpos (más que suficiente)

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
		dam.call("recibir_danio", _daño_efectivo(), self)
		print("[GolpeManual] ⚔️  DAÑO x%d aplicado a %s!" % [_daño_efectivo(), nodo_colision.name])


func _intentar_atacar() -> void:
	if cooldown_ataque > 0.0:
		return
	if _esta_atacando:
		return
	# FASE 10.3: si el arma equipada es a DISTANCIA, dispara en vez de golpear.
	# El dato manda: no se pregunta por el id del arma (cero hardcodeo).
	if _arma_actual != null and _arma_actual.es_a_distancia:
		_intentar_disparar()
		return
	if _intentar_golpear_recurso(): 
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

	# 🔹 Procesar SOLAPAMIENTOS EXISTENTES
	await get_tree().process_frame
	var cuerpos_solapados: Array[Node3D] = hitbox_ataque.get_overlapping_bodies()
	var nombres: Array[String] = []
	for c: Node3D in cuerpos_solapados:
		nombres.append(c.name)
	#print(
		#"[Jugador] Cuerpos solapados en hitbox al activar: ",
		#cuerpos_solapados.size(),
		#". Nombres: ",
		#nombres,
	#)
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


# ═══════════════════════════════════════════════════════════════
# COMBATE: Hitbox golpeó algo con cuerpo físico
func _on_hitbox_ataque_body_entered(body: Node3D) -> void:
	if not _esta_atacando:
		return
	#print(
		#"[Jugador DEBUG] _on_hitbox_ataque_body_entered llamado con: ",
		#body.name,
		#"(tipo: ",
		#body.get_class(),
		#")",
	#)

		# 0) 🛡️ FILTRO ANTI-AUTOGOLPE: 3 CAPAS DE SEGURIDAD
	if body == null:
		return
	# CAPA 1: Nombre exacto
	if body.name == "Jugador" or body.name == "LimitesMapa" or body.is_in_group("terreno"):
		return
	# CAPA 2: Jerarquía (es el propio jugador o alguno de sus nodos internos)
	if body == self or body.is_ancestor_of(self) or self.is_ancestor_of(body):
		return
	# CAPA 3: Grupo "jugador"
	if body.is_in_group("jugador"):
		return

	# 1) Evitar golpear 2 veces al MISMO nodo en el mismo swing
	var path_body: NodePath = body.get_path()
	if _objetos_golpeados_en_este_golpe.has(path_body):
		return
	_objetos_golpeados_en_este_golpe.append(path_body)

	# 2) Buscar Damageable
	var dam: Node = _buscar_damageable_en_nodo(body)

	if dam == null:
		#print("[Jugador DEBUG]→ ", body.name, " NO tiene Damageable. No hay daño.")
		return

	# Otra comprobación extra: dañar Damageable del jugador nunca
	if dam == damageable or dam.is_ancestor_of(self) or self.is_ancestor_of(dam):
		return

	# 3) Aplicar daño
	dam.call("recibir_danio", _daño_efectivo(), self)
	print(
		"[Jugador] ⚔️ Golpeaste a: ",
		body.name,
		" con ",
		_daño_efectivo(),
		" de daño.",
	)# ═══════════════════════════════════════════════════════════════


# Busca Damageable en: el propio body O como nodo hijo directo (patrón componente)
func _buscar_damageable_en_nodo(n: Node) -> Node:
	if n == null:
		return null
	var dam_directo: Node = n.get_node_or_null("Damageable")
	if dam_directo != null and dam_directo.has_method("recibir_danio"):
		return dam_directo
	return null
const DIRECTORIO_ARMAS: String = "res://recursos/armas/"

# ═══════════════════════════════════════════════════════════════
# FASE 12.2 — Estadísticas: daño y cooldown derivados de los atributos
# ═══════════════════════════════════════════════════════════════
## Daño REAL del golpe = daño del arma + bono por Fuerza.
func _daño_efectivo() -> int:
	var base: int = _arma_actual.daño if _arma_actual != null else _daño_ataque
	if estadisticas == null:
		return base
	return base + int(estadisticas.call("get_bono_daño"))

## Cooldown REAL del arma = cooldown base × multiplicador por Destreza.
func _cooldown_de_arma() -> float:
	if _arma_actual == null:
		return 0.66
	var mult: float = 1.0
	if estadisticas != null:
		mult = float(estadisticas.call("get_multiplicador_cooldown"))
	return _arma_actual.cooldown_segundos * mult

## Contrato con Damageable: la vida máxima la manda la Constitución.
func _aplicar_vida_max_a_damageable() -> void:
	if damageable == null or estadisticas == null:
		return
	if not damageable.has_method("set_vida_maxima"):
		push_warning("[Jugador] El Damageable no tiene 'set_vida_maxima'.")
		return
	damageable.call("set_vida_maxima", int(estadisticas.call("get_vida_max")))
	
func _cargar_mapa_armas_desde_recursos() -> void:
	# FASE 10.1: carga DATA-DRIVEN por carpeta (antes: 5 rutas hardcodeadas).
	# Cualquier .tres de tipo ArmaDefinicion en recursos/armas/ se carga solo,
	# usando su campo 'nombre' como clave. Añadir un arma = crear el .tres.
	_mapa_armas = {}
	var dir: DirAccess = DirAccess.open(DIRECTORIO_ARMAS)
	if dir == null:
		push_warning("[Armas] ⚠️ NO EXISTE el directorio: " + DIRECTORIO_ARMAS)
	else:
		dir.list_dir_begin()
		var nombre_archivo: String = dir.get_next()
		while nombre_archivo != "":
			if not nombre_archivo.begins_with(".") and nombre_archivo.ends_with(".tres"):
				var ruta: String = DIRECTORIO_ARMAS + nombre_archivo
				var recurso: Resource = load(ruta)
				if recurso != null and recurso is ArmaDefinicion:
					var arma: ArmaDefinicion = recurso as ArmaDefinicion
					if arma.nombre == &"":
						push_warning("[Armas] ⚠️ Arma sin campo 'nombre': " + ruta)
					else:
						_mapa_armas[arma.nombre] = arma
						print("[Armas] ⚔️ Cargada '%s' desde %s" % [str(arma.nombre), ruta])
				else:
					push_warning("[Armas] ⚠️ .tres no es ArmaDefinicion: " + ruta)
			nombre_archivo = dir.get_next()
		dir.list_dir_end()

	# Fallback crítico (sin cambios): si no hay ningún arma, puños in-memory
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
		push_warning("[Armas] 🚨 MODO FALLBACK: sin recursos .tres, usando puños in-memory.")
		
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
	_aplicar_visual_arma()
	# Actualizar variables de COMBATE heredadas de la FASE 3.2:
	_daño_ataque = _daño_efectivo()
	_duracion_activar_hitbox_ms = float(_arma_actual.duracion_activa_ms) / 1000.0
	cooldown_ataque = _arma_actual.cooldown_segundos   

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

	_hitbox_shape.size = Vector3(
		_arma_actual.ancho_metros,
		_arma_actual.alto_metros,
		largo_total_shape,
	)
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
		# Verificación: punta = centro_z - mitad_largo_shape = -(OFFSET + mitad) - mitad = -(OFFSET
		# + largo_total)
		#   pero largo_total = alcance - OFFSET → punta = -(OFFSET + alcance - OFFSET) = -alcance ✅
		pos_local.z = -(OFFSET_SALIDA_CUERPO + mitad_largo_shape)
		pos_local.y = _arma_actual.alto_metros * 0.5
		hitbox_ataque.position = pos_local

	print("[Armas 3.5] Arma equipada: '%s' | daño=%d | alcance=%.1fm | ancho=%.1fm | cooldown=%.2fs" %
		[
			_arma_actual.nombre_mostrar,
			_daño_efectivo(),
			_arma_actual.alcance_metros,
			_arma_actual.ancho_metros,
			cooldown_ataque,
		])
		
## Aplica el VISUAL del arma actual. El modelo ya no se elige por un
## diccionario hardcodeado: lo declara el propio recurso (.tres).
func _aplicar_visual_arma() -> void:
	if modelo_arma == null:
		return
	if _arma_actual == null or _arma_actual.malla == null:
		modelo_arma.mesh = null
		modelo_arma.visible = false
		return
	modelo_arma.mesh = _arma_actual.malla
	modelo_arma.transform = _arma_actual.transform_modelo
	modelo_arma.visible = true
## FASE 10.8b + PALA: el modo de colocación va ligado a la casilla SELECCIONADA.
## - Item con es_estacion  = true → colocar estación (posición LIBRE)
## - Item con crea_parcela = true → MODO PALA (crear/retirar parcela en la REJILLA)
func _sincronizar_modo_colocacion() -> void:
	# ── PALA ──
	var id_pala: StringName = _pala_de_hotbar_seleccionada()
	if id_pala != &"":
		if _en_modo_colocacion:
			_salir_modo_colocacion()
		if not _en_modo_pala:
			var def_pala: ItemDefinicion = ItemDatabase.get_item(id_pala)
			print("[Jugador] Modo pala: ", def_pala.nombre_visible if def_pala != null else str(id_pala))
		_en_modo_pala = true
		_pala_a_usar = id_pala
		return
	if _en_modo_pala:
		_salir_modo_pala()

	# ── ESTACIÓN (comportamiento original, sin cambios) ──
	var id_estacion: StringName = _estacion_de_hotbar_seleccionada()
	if id_estacion == &"":
		if _en_modo_colocacion:
			_salir_modo_colocacion()
		return
	if _en_modo_colocacion and _estacion_a_colocar == id_estacion:
		return  # Ya estamos colocando justo esta estación
	_estacion_a_colocar = id_estacion
	_en_modo_colocacion = true
	_preview_colocacion.visible = true
	print("[Jugador] Modo colocación: ", ItemDatabase.get_item(id_estacion).nombre_visible)
	
func _estacion_de_hotbar_seleccionada() -> StringName:
	var slot: Dictionary = Inventario.get_slot_hotbar(Inventario.slot_hotbar_seleccionado)
	if slot.is_empty() or not slot.has("id"):
		return &""
	var def: ItemDefinicion = ItemDatabase.get_item(slot.id)
	if def != null and def.es_estacion:
		return def.id
	return &""

func _salir_modo_colocacion() -> void:
	_en_modo_colocacion = false
	_estacion_a_colocar = &""
	_preview_colocacion.visible = false

## Devuelve el id de la PRIMERA estación que haya en el inventario.
## FASE 10.8: revisa MOCHILA + HOTBAR (el inventario es unificado; sin esto,
## una estación guardada en la barra rápida no se podía colocar).
func _buscar_primera_estacion_en_inventario() -> StringName:
	var colecciones: Array = [Inventario.slots, Inventario.slots_hotbar]
	for coleccion: Array in colecciones:
		for slot: Dictionary in coleccion:
			if slot.is_empty():
				continue
			var item_def: ItemDefinicion = ItemDatabase.get_item(slot.id)
			if item_def != null and item_def.es_estacion:
				return slot.id
	return &""

## Punto del suelo donde apunta el ratón (intersección rayo ∩ plano, FASE 10.7)
## Determinista: NO depende de qué objetos haya en la trayectoria, así que el
## preview aparece en TODO el contorno del jugador, no solo donde el rayo
## encuentra hueco entre colisiones.
func _obtener_punto_suelo_bajo_raton() -> Vector3:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = camara.project_ray_origin(mouse_pos)
	var ray_dir: Vector3 = camara.project_ray_normal(mouse_pos)

	# Altura del suelo leída del propio terreno (grupo "terreno", cero
	# hardcodeo). Si no existe (p. ej. escena de test sin terreno), asumimos 0.
	var y_suelo: float = 0.0
	var nodo_terreno: Node3D = get_tree().get_first_node_in_group("terreno") as Node3D
	if nodo_terreno != null:
		y_suelo = nodo_terreno.global_position.y

	# Plano horizontal y = y_suelo  →  normal · p + d = 0  con d = -y_suelo
	var plano_suelo: Plane = Plane(Vector3.UP, -y_suelo)
	var punto: Variant = plano_suelo.intersects_ray(ray_origin, ray_dir)
	if punto == null:
		return Vector3.INF
	return punto as Vector3

## ¿Se puede colocar en ese punto? (distancia HORIZONTAL al jugador)
func _es_posicion_valida_para_colocar(punto: Vector3) -> bool:
	# FASE 10.7: medimos solo en XZ → el radio es un círculo perfecto sobre el
	# suelo. Medido en 3D, la altura del jugador (y=1) deformaba el área.
	var yo_xz: Vector2 = Vector2(global_position.x, global_position.z)
	var punto_xz: Vector2 = Vector2(punto.x, punto.z)
	return yo_xz.distance_to(punto_xz) <= DISTANCIA_MAX_COLOCACION

## Mueve el preview fantasma y cambia de color según validez
func _actualizar_preview_colocacion() -> void:
	var punto: Vector3 = _obtener_punto_suelo_bajo_raton()
	if punto == Vector3.INF:
		_preview_colocacion.visible = false
		return
	_preview_colocacion.visible = true
	# Subir la mitad de la altura para que no se hunda en el suelo
	_preview_colocacion.global_position = Vector3(punto.x, punto.y + 0.5, punto.z)
	var valido: bool = _es_posicion_valida_para_colocar(punto)
	var mat: StandardMaterial3D = _preview_colocacion.material_override as StandardMaterial3D
	mat.albedo_color = Color(0.2, 1.0, 0.2, 0.45) if valido else Color(1.0, 0.2, 0.2, 0.45)

## Instancia la estación en el mundo y gasta el item
func _colocar_estacion() -> void:
	if not _en_modo_colocacion or _estacion_a_colocar == &"":
		return
	var punto: Vector3 = _obtener_punto_suelo_bajo_raton()
	if punto == Vector3.INF or not _es_posicion_valida_para_colocar(punto):
		push_warning("[Jugador] No se puede colocar aquí.")
		return

	var item_def: ItemDefinicion = ItemDatabase.get_item(_estacion_a_colocar)
	if item_def == null or not item_def.es_estacion:
		push_error("[Jugador] El item no es una estación válida.")
		return

	var estacion: Node3D = ESCENA_ESTACION.instantiate()
	estacion.global_position = Vector3(punto.x, punto.y + 0.5, punto.z)
	estacion.tipo_estacion = item_def.tipo_estacion
	estacion.nombre_visible = item_def.nombre_visible
	estacion.escena_ui_crafteo = ESCENA_UI_CRAFTEO  
	get_tree().current_scene.add_child(estacion)

	Inventario.gastar_item(_estacion_a_colocar, 1)
	print("[Jugador] Colocada estación: ", item_def.nombre_visible)

	# Si no quedan más unidades de esta estación, salir del modo
	if not Inventario.tiene_item(_estacion_a_colocar, 1):
		_salir_modo_colocacion()
# ════════════════════════════════════════════════════════════════════
# FASE 11.4: EL CLIMA AFECTA A LA VELOCIDAD DEL JUGADOR
# ════════════════════════════════════════════════════════════════════
func _on_clima_cambio(_id: StringName) -> void:
	var clima: ClimaDefinicion = GestorClima.get_clima_actual()
	if clima != null:
		# clamp por seguridad: el clima nunca debe acelerar al jugador
		# más allá de lo normal ni detenerlo por completo.
		_mult_velocidad_clima = clampf(clima.multiplicador_velocidad_jugador, 0.2, 1.0)
	else:
		_mult_velocidad_clima = 1.0

## id del item de la casilla SELECCIONADA que crea parcelas (pala), o &"".
## Cero hardcodeo: lo decide el campo 'crea_parcela' del ItemDefinicion.
## Simétrico a _estacion_de_hotbar_seleccionada().
func _pala_de_hotbar_seleccionada() -> StringName:
	var slot: Dictionary = Inventario.get_slot_hotbar(Inventario.slot_hotbar_seleccionado)
	if slot.is_empty() or not slot.has("id"):
		return &""
	var def: ItemDefinicion = ItemDatabase.get_item(slot.id)
	if def != null and def.crea_parcela:
		return def.id
	return &""

func _salir_modo_pala() -> void:
	_en_modo_pala = false
	_pala_a_usar = &""
	if _preview_pala != null:
		_preview_pala.visible = false

## GestorTerreno de la escena. Se busca por TIPO y se CACHEA: el grupo
## "terreno" está en el StaticBody3D hijo 'Colision', no en el gestor.
func _terreno() -> GestorTerreno:
	if is_instance_valid(_terreno_cache):
		return _terreno_cache
	_terreno_cache = null
	var raiz: Node = get_tree().current_scene
	if raiz != null:
		for nodo: Node in raiz.find_children("*", "GestorTerreno", true, false):
			if nodo is GestorTerreno:
				_terreno_cache = nodo as GestorTerreno
				break
	return _terreno_cache

## GestorHuerto de la escena (se registra en el grupo "huerto" en su _ready).
func _huerto() -> GestorHuerto:
	return get_tree().get_first_node_in_group("huerto") as GestorHuerto

## ¿La pala puede actuar en esta celda? Crear si está libre y es cultivable;
## retirar solo si la parcela existente está VACÍA (sin planta viva).
func _puedo_usar_pala_en(p_celda: Vector2i) -> bool:
	if p_celda.x < 0:
		return false
	var terreno: GestorTerreno = _terreno()
	var huerto: GestorHuerto = _huerto()
	if terreno == null or huerto == null:
		return false
	var parcela: Parcela = huerto.parcela_en(p_celda.x, p_celda.y)
	if parcela == null:
		return terreno.es_cultivable_en(p_celda.x, p_celda.y)
	return parcela.estado == Parcela.ESTADO_VACIO

## Preview de 1 TILE completo, encajado a la rejilla (verde = acción válida)
func _actualizar_preview_pala() -> void:
	if _preview_pala == null:
		return
	var terreno: GestorTerreno = _terreno()
	if terreno == null:
		_preview_pala.visible = false
		return
	var celda: Vector2i = terreno.celda_desde_punto(_obtener_punto_suelo_bajo_raton())
	if celda.x < 0:
		_preview_pala.visible = false
		return
	# El cubo mide EXACTAMENTE un tile: el tamaño lo manda el terreno.
	var box: BoxMesh = _preview_pala.mesh as BoxMesh
	if box != null and not is_equal_approx(box.size.x, terreno.tamano_celda):
		box.size = Vector3(terreno.tamano_celda, 0.3, terreno.tamano_celda)
	_preview_pala.global_position = terreno.centro_mundo_de_celda(celda.x, celda.y) + Vector3(0.0, 0.15, 0.0)
	_preview_pala.visible = true
	var mat: StandardMaterial3D = _preview_pala.material_override as StandardMaterial3D
	mat.albedo_color = (
		Color(0.2, 1.0, 0.2, 0.35) if _puedo_usar_pala_en(celda) else Color(1.0, 0.2, 0.2, 0.35)
	)

## Clic izquierdo con la pala: crea la parcela del tile apuntado, o la retira
## si ya hay una VACÍA. La posición NO la decide el clic: la decide la rejilla.
func _usar_pala() -> void:
	var terreno: GestorTerreno = _terreno()
	var huerto: GestorHuerto = _huerto()
	if terreno == null or huerto == null:
		push_warning("[Jugador] Falta el GestorTerreno o el Huerto en la escena.")
		return
	var celda: Vector2i = terreno.celda_desde_punto(_obtener_punto_suelo_bajo_raton())
	if celda.x < 0:
		print("[Jugador] La pala apunta fuera del terreno.")
		return
	# Misma distancia que las estaciones (círculo en XZ)
	var centro: Vector3 = terreno.centro_mundo_de_celda(celda.x, celda.y)
	if not _es_posicion_valida_para_colocar(centro):
		print("[Jugador] Esa celda está demasiado lejos.")
		return

	var parcela: Parcela = huerto.parcela_en(celda.x, celda.y)
	if parcela != null:
		if parcela.estado != Parcela.ESTADO_VACIO:
			print("[Jugador] Solo puedes retirar una parcela VACÍA (estado: ", parcela._get_nombre_estado(parcela.estado), ").")
			return
		huerto.eliminar_parcela_en(celda.x, celda.y)
		return

	if huerto.crear_parcela_en(celda.x, celda.y) != null:
		print("[Jugador] Parcela creada en (col %d, fila %d)." % [celda.x, celda.y])
