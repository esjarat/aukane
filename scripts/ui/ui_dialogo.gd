class_name UIDialogo
# scripts/ui/ui_dialogo.gd
extends ColorRect


# ═══════════════════════════════════════════════════════════════
# UI GENÉRICA: Renderiza UN DialogoDefinicion en pantalla.
# 100% DESACOPLADO. No sabe nada de NpcTienda.
# Pública API: abrir_dialogo_por_id(StringName)
# Señales externas que EMITE:
#   - dialogo_cerrado(StringName ultimo_id_dialogo)
#   - accion_especial_solicitada(StringName accion, StringName id_dialogo_actual)
#     ("abrir_tienda", "mercader_menu_comprar")
# ═══════════════════════════════════════════════════════════════

# Señales
signal dialogo_cerrado(ultimo_id_dialogo: StringName)
signal accion_especial_solicitada(
	accion: StringName,
	id_dialogo_actual: StringName,
	parametro: int,
)
# Estado actual
var _dialogo_actual: DialogoDefinicion = null
var _index_linea_actual: int = 0
var _botones_opciones_creados: Array[Button] = []
var _npc_owner: Node = null   # (opcional: referencia al NPC que abrió el diálogo. SIN usarla para nada, solo la dejamos por si se necesita en FASE 4.3)

# ── Nodos UI
@onready var _label_nombre: Label = $MarginExterior/PanelFondo/VBoxPrincipal/LabelNombreNPC
@onready var _texto: RichTextLabel = $MarginExterior/PanelFondo/VBoxPrincipal/RichTextoDialogo
@onready var _vbox_opciones: VBoxContainer = $MarginExterior/PanelFondo/VBoxPrincipal/CentradorOpciones/VBoxOpciones
@onready var _label_hint: Label = $LabelHintAvance


# ──────────────────────────────────────────────────────────────
# INPUT: Teclado via _unhandled_input, Mouse via _gui_input
# Patrón GODOT 4 estándar:
#   - El teclado NO lo consume ningún Control (a menos que tenga focus)
#     → llega por _unhandled_input
#   - El mouse SÍ lo consumen los Controls
#     → llega por _gui_input
# ──────────────────────────────────────────────────────────────


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _dialogo_actual == null:
		return
	if GameState.modo_actual != GameState.MODO_UI:
		return
	# Si hay opciones visibles → el usuario debe clickear botones, no avanzar
	if _vbox_opciones.visible and _botones_opciones_creados.size() > 0:
		return
	# TECLADO: Enter / Espacio = avanzar
	if event is InputEventKey:
		var tecla: InputEventKey = event as InputEventKey
		if (tecla.pressed
				and not tecla.echo
				and (tecla.keycode == KEY_ENTER or tecla.keycode == KEY_SPACE)):
			_avanzar()


# ──────────────────────────────────────────────────────────────
# MOUSE: Los Control reciben clicks vía _gui_input (NO _unhandled_input)
# ──────────────────────────────────────────────────────────────
func _gui_input(event: InputEvent) -> void:
	if not visible or _dialogo_actual == null:
		return
	if GameState.modo_actual != GameState.MODO_UI:
		return
	# Si hay opciones visibles → los botones manejan sus propios clicks
	if _vbox_opciones.visible and _botones_opciones_creados.size() > 0:
		return
	# Click izquierdo en el área del diálogo = avanzar
	if event is InputEventMouseButton:
		var raton: InputEventMouseButton = event as InputEventMouseButton
		if raton.pressed and raton.button_index == MOUSE_BUTTON_LEFT:
			_avanzar()
			accept_event()


# ──────────────────────────────────────────────────────────────
# API PÚBLICA PRINCIPAL (llamar esta desde cualquier lugar)
# ──────────────────────────────────────────────────────────────
func abrir_dialogo_por_id(p_id_dialogo: StringName, p_npc_owner_opcional: Node = null) -> void:
	print(
		"[UIDialogo] 📨 abro diálogo ID=",
		p_id_dialogo,
		" | NPC=",
		p_npc_owner_opcional.name if p_npc_owner_opcional != null else "nil",
	)
	var d: DialogoDefinicion = DialogoDatabase.get_dialogo(p_id_dialogo)
	if d == null:
		print("[UIDialogo] 🚨 DialogoDatabase.get_dialogo devolvió NULL. ID=", p_id_dialogo)
		push_warning("[UIDialogo] ❌ No puedo abrir diálogo. ID no encontrado en DB: " + String(p_id_dialogo))
		return
	print(
		"[UIDialogo] ✅ Diálogo cargado OK. Líneas=",
		d.get_cantidad_lineas(),
		" Opciones=",
		d.get_cantidad_opciones(),
	)
	_cargar_y_mostrar_dialogo(d, p_npc_owner_opcional)


# ──────────────────────────────────────────────────────────────
# API PÚBLICA SECUNDARIA (cierre forzado si el jugador se aleja)
# ──────────────────────────────────────────────────────────────
func cerrar_forzado() -> void:
	if _dialogo_actual != null:
		var id_anterior: StringName = _dialogo_actual.id_dialogo
		_limpiar()
		emit_signal("dialogo_cerrado", id_anterior)
	visible = false
	GameState.modo_actual = GameState.MODO_MUNDO


# ──────────────────────────────────────────────────────────────
# FUNCIONES INTERNAS
# ──────────────────────────────────────────────────────────────
func _cargar_y_mostrar_dialogo(p_dialogo: DialogoDefinicion, p_npc: Node) -> void:
	if p_dialogo == null:
		return
	_limpiar()
	_dialogo_actual = p_dialogo
	_npc_owner = p_npc
	_index_linea_actual = 0
	# Mostrar UI
	visible = true
	GameState.modo_actual = GameState.MODO_UI
	print("[UIDialogo] 👁️ VISIBLE=true. Size actual: ", size, " | pos=", position)
	# Nombre NPC
	if _label_nombre != null:
		_label_nombre.text = p_dialogo.nombre_mostrar_npc
	else:
		push_warning("[UIDialogo] No se pudo mostrar el nombre NPC: _label_nombre es null.")
	# Ocultar opciones POR DEFECTO hasta llegar a la última línea
	if _vbox_opciones != null:
		_vbox_opciones.visible = false
	if _label_hint != null:
		_label_hint.visible = true
	# Primera línea
	_mostrar_linea_actual()


func _limpiar() -> void:
	_dialogo_actual = null
	_index_linea_actual = 0
	# Destruir botones opciones creados anteriormente
	for btn: Button in _botones_opciones_creados:
		if is_instance_valid(btn):
			btn.queue_free()
	_botones_opciones_creados.clear()
	_vbox_opciones.visible = false
	_texto.text = ""
	_label_nombre.text = ""


# Muestra la línea con índice _index_linea_actual en el RichText (con \n como salto real)
func _mostrar_linea_actual() -> void:
	if _dialogo_actual == null:
		return
	if _texto == null:
		push_warning("[UIDialogo] RichTextLabel = null, no puedo mostrar línea.")
		return
	var dl: DialogoLinea = _dialogo_actual.get_linea(_index_linea_actual)
	if dl == null:
		_finalizar_lineas_y_mostrar_opciones_si_procede()
		return
	var html: String = "[center]%s[/center]" % [dl.texto]
	_texto.parse_bbcode(html)


func _avanzar() -> void:
	if _dialogo_actual == null:
		return
	# Quedan líneas por delante?
	var total_lineas: int = _dialogo_actual.get_cantidad_lineas()
	if _index_linea_actual < total_lineas - 1:
		_index_linea_actual += 1
		_mostrar_linea_actual()
		return
	# Estamos en ÚLTIMA línea. Mostrar opciones (si hay) y/o avanzar dialogo
	_finalizar_lineas_y_mostrar_opciones_si_procede()


func _finalizar_lineas_y_mostrar_opciones_si_procede() -> void:
	if _dialogo_actual == null:
		return
	var tiene_opciones: bool = _dialogo_actual.tiene_opciones()
	if tiene_opciones:
		_crear_botones_opciones()
		_vbox_opciones.visible = true
		_label_hint.visible = false  # No hay enter, debe elegir botón
		return
	# NO hay opciones → mirar siguiente_dialogo automático o acción final
	if _dialogo_actual.tiene_siguiente_automatico():
		var id_sig: StringName = _dialogo_actual.id_dialogo_siguiente_automatico
		var id_original: StringName = _dialogo_actual.id_dialogo
		# Antes de saltar emitimos acción especial (si procede), PERO después se ejecuta el salto
		_emitir_accion_si_procede()
		abrir_dialogo_por_id(id_sig)
		return
	# NO opciones, NO siguiente automático → emitir acción si procede y cerrar
	_emitir_accion_si_procede()
	_cerrar_normal()


func _crear_botones_opciones() -> void:
	if _dialogo_actual == null:
		return
	var n: int = _dialogo_actual.get_cantidad_opciones()
	var i: int = 0
	while i < n:
		var op: DialogoOpcion = _dialogo_actual.get_opcion(i)
		if op == null:
			i += 1
			continue
		# ── Opción OK, comprobar requisitos si aplica
		var se_debe_mostrar: bool = true
		# Requisito 1: item requerido
		if op.id_item_requerido != &"" and op.cantidad_item_requerido > 0:
			var cantidad_jug: int = Inventario.get_cantidad(op.id_item_requerido)
			se_debe_mostrar = (cantidad_jug >= op.cantidad_item_requerido)
		# Requisito 2: misión activa (FASE 4.3)
		if se_debe_mostrar and op.requiere_mision_activa != &"":
			se_debe_mostrar = MisionManager.tiene_mision_activa(op.requiere_mision_activa)
		# Requisito 3: misión NO activa y NO completada (para ofrecerla)
		if se_debe_mostrar and op.requiere_mision_no_activa != &"" : 
			var id: StringName = op.requiere_mision_no_activa
			se_debe_mostrar = ( not MisionManager.tiene_mision_activa(id)) and ( not MisionManager.mision_ya_completada(id)) 
		if not se_debe_mostrar:
			i += 1 
			continue
		# ── Crear Button
		var btn: Button = Button.new()
		btn.text = op.texto_opcion
		btn.custom_minimum_size = Vector2(460, 34)
		# Estilo botón: StyleBoxFlat inline
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		sb.bg_color = Color(0.15, 0.12, 0.22, 0.95)
		sb.border_color = Color(1, 0.8, 0.3, 0.6)
		sb.border_width_left = 2
		sb.border_width_right = 2
		sb.border_width_top = 2
		sb.border_width_bottom = 2
		sb.corner_radius_top_left = 6
		sb.corner_radius_top_right = 6
		sb.corner_radius_bottom_left = 6
		sb.corner_radius_bottom_right = 6
		btn.add_theme_stylebox_override("normal", sb)
		# Hover
		var sbh: StyleBoxFlat = sb.duplicate()
		sbh.bg_color = Color(0.25, 0.18, 0.35, 0.98)
		sbh.border_color = Color(1, 0.88, 0.3, 1.0)
		btn.add_theme_stylebox_override("hover", sbh)
		# Pressed
		var sbp: StyleBoxFlat = sb.duplicate()
		sbp.bg_color = Color(0.35, 0.22, 0.45, 1.0)
		btn.add_theme_stylebox_override("pressed", sbp)
		# Font color + outline
		btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		btn.add_theme_font_size_override("font_size", 14)
		# Conectar click con CALLABLE y bind(op)
		if not btn.pressed.is_connected(_on_boton_opcion_presionado.bind(op)):
			btn.pressed.connect(_on_boton_opcion_presionado.bind(op))
		_vbox_opciones.add_child(btn)
		_botones_opciones_creados.append(btn)
		i += 1


# ──────────────────────────────────────────────────────────────
# CALLBACK botón opción clickeado
# ──────────────────────────────────────────────────────────────
func _on_boton_opcion_presionado(p_opcion: DialogoOpcion, _extra1 = null, _extra2 = null) -> void:
	if _dialogo_actual == null:
		return
	# 1) Si esta OPCIÓN tiene una acción especial → ejecutarla ANTES de saltar/cerrar
	if p_opcion.accion_especial != &"":
		var accion_limpia: String = String(p_opcion.accion_especial).strip_edges()
		print(
			"[UIDialogo] 📤 ACCIÓN por OPCIÓN: '",
			accion_limpia,
			"' | diálogo: ",
			String(_dialogo_actual.id_dialogo),
		)
		emit_signal(
			"accion_especial_solicitada",
			StringName(accion_limpia),
			_dialogo_actual.id_dialogo,
			p_opcion.parametro_accion,
		)
	# 2) Si la opción lleva a OTRO diálogo → saltar
	if p_opcion.id_siguiente_dialogo != &"":
		abrir_dialogo_por_id(p_opcion.id_siguiente_dialogo)
		return
	# 3) Si no hay siguiente diálogo → cerrar
	_cerrar_normal()

# ──────────────────────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────────────────────
func _emitir_accion_si_procede() -> void:
	if _dialogo_actual == null:
		return
	if _dialogo_actual.tiene_accion_especial():
		var accion_bruta: StringName = _dialogo_actual.accion_al_terminar
		var id_actual: StringName = _dialogo_actual.id_dialogo
		# 🔑 HIGIENIZAR: String() + strip_edges() + volver a StringName
		# Elimina ESPACIOS, TABS, SALTOS DE LÍNEA que el usuario pudo meter al editar el .tres en
		# el Inspector
		var accion_limpia: String = String(accion_bruta).strip_edges()
		var accion_final: StringName = StringName(accion_limpia)
		print(
			"[UIDialogo] 📤 EMITO ACCIÓN ESPECIAL (limpia): '",
			accion_limpia,
			"' | original: '",
			String(accion_bruta),
			"' | Diálogo origen: '",
			String(id_actual),
			"'. Conexiones: ",
			accion_especial_solicitada.get_connections().size(),
		)
		emit_signal(
			"accion_especial_solicitada",
			accion_final,
			id_actual,
			_dialogo_actual.parametro_accion,
		)
	else:
		print("[UIDialogo] ℹ️ El diálogo actual NO tiene acción especial. Se cierra sin más.")


func _cerrar_normal() -> void:
	if _dialogo_actual == null:
		return
	var id_ultimo: StringName = _dialogo_actual.id_dialogo
	_limpiar()
	visible = false
	GameState.modo_actual = GameState.MODO_MUNDO
	emit_signal("dialogo_cerrado", id_ultimo)
