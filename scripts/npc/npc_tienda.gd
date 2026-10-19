class_name NpcTienda
extends "res://scripts/npc/npc_base.gd"

@export var escena_ui_tienda: PackedScene = preload("res://escenes/ui/UITienda.tscn")
@export var catalogo_asignado: CatalogoTienda = null  # FASE 5
@export var horario_apertura: int = 8
@export var horario_cierre: int = 20
@export var id_dialogo_inicial: StringName = &"mercader_saludo_inicial"
@export var mision_ofrecida: Mision = null

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
	# FASE 7: la tienda abre/cierra según el tiempo del juego
	var hora: int = GestorTiempo.get_hora()
	return hora >= horario_apertura and hora < horario_cierre


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
func _on_ui_dialogo_pide_accion_especial(
	p_accion: StringName,
	_id_diag: StringName,
	_p1 = null,
	_p2 = null,
) -> void:
	# 🔑 HIGIENIZAR: por si las moscas, aunque el emisor ya lo hizo.
	var accion_limpia: String = String(p_accion).strip_edges()
	print(
		"[NpcTienda] 📥 RECIBO acción especial (limpia): '",
		accion_limpia,
		"' | desde diálogo: '",
		String(_id_diag),
		"'",
	)
	match StringName(accion_limpia):
		ClavesDatos.ACCION_ABRIR_TIENDA:
			# La pestaña la declara el DIÁLOGO en su .tres (parametro_accion),
			# NO el código. Renombrar el diálogo ya no rompe esta lógica.
			var tab_inicial: int = 0
			if _p1 != null:
				tab_inicial = int(_p1)
			# ⚠️ ORDEN IMPORTANTE: cerrar el diálogo PRIMERO.
			# cerrar_forzado() deja GameState en MODO_MUNDO. Si abriéramos la
			# tienda antes, ese cierre posterior dejaría el modo en MUNDO con
			# la tienda aún abierta y la hotbar volvería a mostrarse encima.
			# Cerrando primero, abrir_tienda() vuelve a poner MODO_UI después
			# y la hotbar permanece oculta. Ambos cambios son síncronos (mismo
			# frame), así que no hay parpadeo.
			if _ui_dialogo_abierto_ahora != null and is_instance_valid(_ui_dialogo_abierto_ahora):
				_ui_dialogo_abierto_ahora.cerrar_forzado()
				_ui_dialogo_abierto_ahora = null
			print("[NpcTienda] 🛒 Llamo a abrir_tienda() en pestaña ", tab_inicial)
			abrir_tienda(tab_inicial)
		ClavesDatos.ACCION_CERRAR:
			if _ui_dialogo_abierto_ahora != null:
				_ui_dialogo_abierto_ahora.cerrar_forzado()
		ClavesDatos.ACCION_ACEPTAR_MISION:
			_aceptar_mision_ofrecida()
		ClavesDatos.ACCION_ENTREGAR_MISION:
			_entregar_mision_al_npc()

func _on_ui_dialogo_cerrado(_ultimo_id: StringName, _p1 = null, _p2 = null) -> void:
	_ui_dialogo_abierto_ahora = null


# ──────────────────────────────────────────────────────────────
# Lógica Tienda ABRIR / CERRAR
# ──────────────────────────────────────────────────────────────
func abrir_tienda(p_tab_inicial: int = 0) -> void:
	if escena_ui_tienda == null:
		push_error("[NpcTienda] escena_ui_tienda NO ASIGNADA en inspector.")
		return
	ui_tienda_instancia = escena_ui_tienda.instantiate()
	get_tree().root.add_child(ui_tienda_instancia)
	GameState.modo_actual = GameState.MODO_UI
	if ui_tienda_instancia.has_method("asignar_npc_owner"):
		ui_tienda_instancia.asignar_npc_owner(self, p_tab_inicial)
	print("[OK ✅] Tienda abierta en pestaña ", p_tab_inicial, ": ", nombre_visible)


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
			
# ──────────────────────────────────────────────────────────────
# SISTEMA DE MISIONES: Aceptar la misión que ofrece este NPC
# ──────────────────────────────────────────────────────────────
func _aceptar_mision_ofrecida() -> void:
	if mision_ofrecida == null:
		print("[NpcTienda] ⚠️ Este NPC no tiene ninguna misión asignada en el Inspector.")
		return
	var ok: bool = MisionManager.aceptar_mision(mision_ofrecida)
	if ok:
		print("[NpcTienda] ✅ Misión aceptada: ", mision_ofrecida.nombre)
	else:
		print("[NpcTienda] ℹ️ No se pudo aceptar la misión (¿ya activa o completada?).")
# ──────────────────────────────────────────────────────────────
# ENTREGA de misión: el jugador entrega los items al NPC
# ──────────────────────────────────────────────────────────────
func _entregar_mision_al_npc() -> void:
	if mision_ofrecida == null:
		print("[NpcTienda] ⚠️ No hay misión asignada.")
		return
	var id_mision: StringName = mision_ofrecida.id_mision
	if not MisionManager.tiene_mision_activa(id_mision):
		print("[NpcTienda] ℹ️ No tienes activa la misión: ", String(id_mision))
		return
	var ok: bool = MisionManager.entregar_mision(id_mision)
	if ok:
		print("[NpcTienda] ✅ Entrega completada. Recompensa entregada.")
	else:
		print("[NpcTienda] ❌ No pudiste entregar (¿te faltan items?).")
# Devuelve el catálogo asignado a este NPC
func get_catalogo() -> CatalogoTienda:
	return catalogo_asignado
