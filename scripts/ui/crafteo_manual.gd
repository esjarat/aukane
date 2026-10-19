extends PanelContainer

# ═══════════════════════════════════════════════════════════════
# CRAFTEO MANUAL (dentro de la mochila)
# Lista las recetas de estacion_requerida = &"ninguna"
# (ej: banco_trabajo). Se cierra junto a la mochila.
# ═══════════════════════════════════════════════════════════════

@onready var _label_titulo: Label = $VBoxPrincipal/LabelTitulo
@onready var _vbox_recetas: VBoxContainer = $VBoxPrincipal/ScrollRecetas/VBoxRecetas

var _generador_iconos: IconoItem = null

func _ready() -> void:
	_generador_iconos = IconoItem.new()
	add_child(_generador_iconos)
	# Refrescar cuando cambia el inventario
	Inventario.inventario_cambiado.connect(_construir_ui)

# ──────────────────────────────────────────────────────────────
# Construir la lista de recetas "ninguna"
# ──────────────────────────────────────────────────────────────
func _construir_ui() -> void:
	_limpiar_recetas()
	var recetas: Array[RecetaCrafteo] = CrafteoManager.get_recetas_por_estacion(&"ninguna")
	for receta in recetas:
		var fila: PanelContainer = _crear_fila_receta(receta)
		_vbox_recetas.add_child(fila)

func _limpiar_recetas() -> void:
	for hijo in _vbox_recetas.get_children():
		hijo.queue_free()

# ──────────────────────────────────────────────────────────────
# Crear una fila de receta (icono + nombre + ingredientes + botón)
# ──────────────────────────────────────────────────────────────
func _crear_fila_receta(p_receta: RecetaCrafteo) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 64)
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.1, 0.18, 0.85)
	sb.border_color = Color(0.4, 0.35, 0.2, 0.7)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_right = 4
	sb.corner_radius_bottom_left = 4
	panel.add_theme_stylebox_override("panel", sb)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.add_child(hbox)

	# 1) Icono
	var def_resultado: ItemDefinicion = ItemDatabase.get_item(p_receta.id_resultado)
	if def_resultado != null:
		var btn_icono: Button = Button.new()
		btn_icono.custom_minimum_size = Vector2(40, 40)
		btn_icono.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn_icono.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn_icono.flat = true
		btn_icono.disabled = true
		btn_icono.focus_mode = Control.FOCUS_NONE
		btn_icono.icon = _generador_iconos.get_icono(def_resultado)
		btn_icono.expand_icon = true
		btn_icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(btn_icono)

	# 2) Columna info (nombre + ingredientes) — TAMAÑOS EXPLÍCITOS
	var vbox_info: VBoxContainer = VBoxContainer.new()
	vbox_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_info.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	vbox_info.custom_minimum_size = Vector2(0, 50)
	vbox_info.add_theme_constant_override("separation", 2)
	hbox.add_child(vbox_info)

	var nombre_resultado: String = str(p_receta.id_resultado)
	if def_resultado != null:
		nombre_resultado = def_resultado.nombre_visible
	var lbl_nombre: Label = Label.new()
	lbl_nombre.text = "%s  x%d" % [nombre_resultado, p_receta.cantidad_resultado]
	lbl_nombre.add_theme_color_override("font_color", Color(1, 0.926, 0.584, 1))
	lbl_nombre.add_theme_font_size_override("font_size", 16)
	lbl_nombre.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	lbl_nombre.custom_minimum_size = Vector2(0, 20)
	lbl_nombre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox_info.add_child(lbl_nombre)

	var hbox_ing: HBoxContainer = HBoxContainer.new()
	hbox_ing.add_theme_constant_override("separation", 6)
	hbox_ing.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	hbox_ing.custom_minimum_size = Vector2(0, 18)
	vbox_info.add_child(hbox_ing)

	for ing in p_receta.ingredientes:
		var lbl_ing: Label = Label.new()
		var nombre_ing: String = str(ing.item_id)
		var def_ing: ItemDefinicion = ItemDatabase.get_item(ing.item_id)
		if def_ing != null:
			nombre_ing = def_ing.nombre_visible
		var disponible: int = CrafteoManager.get_disponible_ingrediente(ing)
		var color: Color = Color(0.4, 0.9, 0.4, 1) if disponible >= ing.cantidad else Color(0.9, 0.4, 0.4, 1)
		lbl_ing.text = "%s %d/%d" % [nombre_ing, disponible, ing.cantidad]
		lbl_ing.add_theme_color_override("font_color", color)
		lbl_ing.add_theme_font_size_override("font_size", 12)
		lbl_ing.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		lbl_ing.custom_minimum_size = Vector2(0, 18)
		lbl_ing.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox_ing.add_child(lbl_ing)

	# 3) Botón
	var btn_craftear: Button = Button.new()
	btn_craftear.text = "Craftear"
	btn_craftear.custom_minimum_size = Vector2(90, 44)
	btn_craftear.add_theme_font_size_override("font_size", 14)
	btn_craftear.disabled = not CrafteoManager.puede_craftear(p_receta)
	btn_craftear.pressed.connect(_on_craftear_pressed.bind(p_receta))
	hbox.add_child(btn_craftear)

	return panel

func _on_craftear_pressed(p_receta: RecetaCrafteo) -> void:
	CrafteoManager.craftear(p_receta)
	_construir_ui()
