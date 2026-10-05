extends "res://scripts/npc/npc_base.gd"
class_name NpcTienda

@export var escena_ui_tienda: PackedScene = preload("res://escenes/ui/UITienda.tscn")
@export var catalogo_asignado: Resource = null  # FASE 5
@export var horario_apertura: int = 8
@export var horario_cierre: int = 20
@export var id_dialogo_inicial: StringName = &"mercader_saludo_inicial"
var ui_tienda_instancia: Control = null
var _ui_dialogo_abierto_ahora: UIDialogo = null

# ──────────────────────────────────────────────────────────────
# SOBRE-ESCRIBIMOS métodos de NpcBase (Override / Template Method)
# ──────────────────────────────────────────────────────────────
func _ready() -> void:
	# Llamar al _ready de la CLASE PADRE (importante!)
	super()
	nombre_visible = "Don Mercader"
	print("[NPC Tienda Listo] ", nombre_visible, " espera clientes.")

func get_prompt() -> String:
	if not puede_interactuar():
		return "🛑 Tienda cerrada (horario " + str(horario_apertura) + "-" + str(horario_cierre) + ")"
	return "[F] Abrir tienda de " + nombre_visible

func puede_interactuar() -> bool:
	# TEMPORAL: FASE 7 lo conectaremos a GestorTiempo.hora
	return true

func interactuar(_jugador: Node) -> void:
	if not puede_interactuar():
		print("[NPC] Estamos cerrados.")
		return
	# Caso A: Si la TIENDA ya está abierta → la cierro (igual que antes)
	if ui_tienda_instancia != null:
		cerrar_tienda()
		return
	# Caso B: Si el DIÁLOGO ya está abierto → lo cierro por segunda pulsación F
	if _ui_dialogo_abierto_ahora != null and _ui_dialogo_abierto_ahora.visible:
		_ui_dialogo_abierto_ahora.cerrar_forzado()
		_ui_dialogo_abierto_ahora = null
		return
	# Caso C: Petición normal → ABRIR DIÁLOGO (NO ABRIR TIENDA TODAVÍA)
	var ui_root: CanvasLayer = get_tree().get_first_node_in_group("ui_principal")
	if ui_root == null:
		# Fallback si no tiene grupo
		ui_root = get_tree().root.get_node_or_null("UI")
	if ui_root == null or not ui_root.has_method("abrir_dialogo_desde_npc"):
		push_warning("[NpcTienda] No puedo abrir diálogo: nodo UI HUD no tiene método abrir_dialogo_desde_npc")
		return
	var dialogo: UIDialogo = ui_root.abrir_dialogo_desde_npc(id_dialogo_inicial, self)
	if dialogo != null:
		_ui_dialogo_abierto_ahora = dialogo
		# CONEXIÓN A SEÑALES — solo si no lo está ya
		if not dialogo.accion_especial_solicitada.is_connected(_on_ui_dialogo_pide_accion_especial):
			dialogo.accion_especial_solicitada.connect(_on_ui_dialogo_pide_accion_especial)
		if not dialogo.dialogo_cerrado.is_connected(_on_ui_dialogo_cerrado):
			dialogo.dialogo_cerrado.connect(_on_ui_dialogo_cerrado)

# ──────────────────────────────────────────────────────────────
# CALLBACKS Diálogo
# ──────────────────────────────────────────────────────────────
func _on_ui_dialogo_pide_accion_especial(p_accion: StringName, _id_diag: StringName, _p1 = null, _p2 = null) -> void:
	# 🔑 HIGIENIZAR: por si las moscas, aunque el emisor ya lo hizo.
	var accion_limpia: String = String(p_accion).strip_edges()
	print("[NpcTienda] 📥 RECIBO acción especial (limpia): '", accion_limpia, "' | desde diálogo: '", String(_id_diag), "'")
	match accion_limpia:
		"abrir_tienda":
			print("[NpcTienda] 🛒 Llamo a abrir_tienda() ahora!")
			abrir_tienda()
			if _ui_dialogo_abierto_ahora != null and is_instance_valid(_ui_dialogo_abierto_ahora):
				_ui_dialogo_abierto_ahora.cerrar_forzado()
				_ui_dialogo_abierto_ahora = null
		"cerrar":
			if _ui_dialogo_abierto_ahora != null:
				_ui_dialogo_abierto_ahora.cerrar_forzado()
		_:
			print("[NpcTienda] ⚠️ Acción especial DESCONOCIDA (tras limpieza): '", accion_limpia, "'")

func _on_ui_dialogo_cerrado(_ultimo_id: StringName, _p1 = null, _p2 = null) -> void:
	_ui_dialogo_abierto_ahora = null

# ──────────────────────────────────────────────────────────────
# Lógica Tienda ABRIR / CERRAR
# ──────────────────────────────────────────────────────────────
func abrir_tienda() -> void:
	if escena_ui_tienda == null:
		push_error("[NpcTienda] escena_ui_tienda NO ASIGNADA en inspector.")
		return
	
	ui_tienda_instancia = escena_ui_tienda.instantiate()
	get_tree().root.add_child(ui_tienda_instancia)
	GameState.modo_actual = GameState.MODO_UI
	
	if ui_tienda_instancia.has_method("asignar_npc_owner"):
		ui_tienda_instancia.asignar_npc_owner(self)
	
	print("[OK ✅] Tienda abierta: ", nombre_visible)

func cerrar_tienda() -> void:
	if ui_tienda_instancia != null:
		ui_tienda_instancia.queue_free()
		ui_tienda_instancia = null
	GameState.modo_actual = GameState.MODO_MUNDO
	print("[OK 🔒] Tienda cerrada: ", nombre_visible)

# Cuando el jugador se aleja de la zona, cerramos tienda
func _on_area_interaccion_body_exited(body: Node3D) -> void:
	super(body)
	if body.is_in_group("jugador"):
		if ui_tienda_instancia != null:
			cerrar_tienda()
		# Cerrar diálogo también si estaba abierto
		if _ui_dialogo_abierto_ahora != null and is_instance_valid(_ui_dialogo_abierto_ahora):
			_ui_dialogo_abierto_ahora.cerrar_forzado()
			_ui_dialogo_abierto_ahora = null
