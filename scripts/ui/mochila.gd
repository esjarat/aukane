extends Control

# ═══════════════════════════════════════════════════════════════
# UI MOCHILA / INVENTARIO
# Muestra todos los slots del inventario con icono + cantidad.
# Se abre/cierra con la tecla I.
# FASE 10.8: los slots son SlotArrastrable → se puede arrastrar a la HOTBAR.
# ═══════════════════════════════════════════════════════════════

@onready var _grid: GridContainer = $Fondo/Centrador/HBoxContenedor/PanelMochila/VBoxPrincipal/ScrollSlots/GridSlots
@onready var _label_titulo: Label = $Fondo/Centrador/HBoxContenedor/PanelMochila/VBoxPrincipal/LabelTitulo
@onready var _btn_cerrar: Button = $Fondo/Centrador/HBoxContenedor/PanelMochila/VBoxPrincipal/BotonCerrar
@onready var _label_tooltip: Label = $Fondo/Centrador/HBoxContenedor/PanelMochila/VBoxPrincipal/LabelTooltip

var _generador_iconos: IconoItem = null
var _botones_slots: Array[SlotArrastrable] = []

func _ready() -> void:
	# Crear instancia del generador de iconos
	_generador_iconos = IconoItem.new()
	add_child(_generador_iconos)
	# Conectar señal de inventario para refrescar
	Inventario.inventario_cambiado.connect(_refrescar_slots)
	# Botón cerrar
	if not _btn_cerrar.pressed.is_connected(cerrar):
		_btn_cerrar.pressed.connect(cerrar)
	# Crear los botones UNA vez y refrescar su contenido
	_crear_slots()
	_refrescar_slots()

func abrir() -> void:
	visible = true
	GameState.modo_actual = GameState.MODO_UI
	_refrescar_slots()
	# Construir también el crafteo manual
	var crafteo_manual = $Fondo/Centrador/HBoxContenedor/PanelCrafteoManual
	if crafteo_manual != null and crafteo_manual.has_method("_construir_ui"):
		crafteo_manual._construir_ui()

func cerrar() -> void:
	visible = false
	GameState.modo_actual = GameState.MODO_MUNDO

func toggle() -> void:
	if visible:
		cerrar()
	else:
		abrir()

# Crea los botones vacíos (una sola vez)
func _crear_slots() -> void:
	_limpiar_slots()
	for i in range(Inventario.tamano_maximo_slots):
		var btn: SlotArrastrable = SlotArrastrable.new()
		btn.origen = &"mochila"
		btn.indice = i
		btn.custom_minimum_size = Vector2(64, 64)
		btn.toggle_mode = false
		btn.expand_icon = true
		btn.add_theme_font_size_override("font_size", 14)
		btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		_grid.add_child(btn)
		_botones_slots.append(btn)

func _limpiar_slots() -> void:
	for btn in _botones_slots:
		if is_instance_valid(btn):
			btn.queue_free()
	_botones_slots.clear()

# Refresca el CONTENIDO de los botones ya existentes (no los recrea)
func _refrescar_slots() -> void:
	for i in range(_botones_slots.size()):
		_pintar_slot(_botones_slots[i], Inventario.get_slot(i))

func _pintar_slot(btn: SlotArrastrable, p_slot: Dictionary) -> void:
	# Estilo: fondo
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.1, 0.18, 0.9)
	sb.border_color = Color(0.4, 0.35, 0.2, 0.8)
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	btn.add_theme_stylebox_override("normal", sb)
	var sb_hover: StyleBoxFlat = sb.duplicate()
	sb_hover.bg_color = Color(0.2, 0.16, 0.28, 0.95)
	btn.add_theme_stylebox_override("hover", sb_hover)

	# Si el slot NO está vacío → mostrar icono + cantidad
	if p_slot.is_empty() or not p_slot.has("id"):
		btn.icon = null
		btn.text = ""
		btn.tooltip_text = ""
		return

	var def: ItemDefinicion = ItemDatabase.get_item(p_slot.id)
	if def == null:
		return

	btn.icon = _generador_iconos.get_icono(def)
	btn.text = "x" + str(p_slot.cantidad)
	btn.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	btn.tooltip_text = "%s (x%d)\n%s" % [def.nombre_visible, p_slot.cantidad, def.descripcion]

# Cerrar con ESC
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey:
		var k: InputEventKey = event as InputEventKey
		if k.pressed and not k.echo and k.keycode == KEY_ESCAPE:
			cerrar()
			get_viewport().set_input_as_handled()
