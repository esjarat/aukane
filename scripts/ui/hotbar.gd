extends Control

# ═══════════════════════════════════════════════════════════════
# UI HOTBAR (FASE 10.8) — 9 casillas abajo en pantalla
# · Arrastra items desde la mochila hasta estas casillas.
# · Click (o teclas 1-9) selecciona la casilla → equipa su herramienta.
# ═══════════════════════════════════════════════════════════════

@onready var _hbox: HBoxContainer = $Centrador/HBoxSlots

var _generador_iconos: IconoItem = null
var _botones: Array[SlotArrastrable] = []

func _ready() -> void:
	_generador_iconos = IconoItem.new()
	add_child(_generador_iconos)
	# La hotbar se redibuja cuando cambian las casillas o el inventario
	Inventario.hotbar_cambiada.connect(_refrescar)
	Inventario.inventario_cambiado.connect(_refrescar)
	_crear_botones()
	_refrescar()

# Los botones se crean UNA vez y luego solo se refresca su contenido.
# (Recrearlos en cada señal rompería el arrastre en curso.)
func _crear_botones() -> void:
	for i in range(Inventario.slots_hotbar.size()):
		var btn: SlotArrastrable = SlotArrastrable.new()
		btn.origen = &"hotbar"
		btn.indice = i
		btn.custom_minimum_size = Vector2(64, 64)
		btn.toggle_mode = false
		btn.expand_icon = true
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(_on_slot_presionado.bind(i))
		_hbox.add_child(btn)
		_botones.append(btn)

func _refrescar() -> void:
	for i in range(_botones.size()):
		var seleccionado: bool = (i == Inventario.slot_hotbar_seleccionado)
		_pintar_slot(_botones[i], Inventario.get_slot_hotbar(i), seleccionado)

func _pintar_slot(btn: SlotArrastrable, p_slot: Dictionary, p_seleccionado: bool) -> void:
	# ── Estilo de la casilla (borde dorado si está seleccionada) ──
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.1, 0.18, 0.9)
	sb.border_color = Color(1.0, 0.9, 0.35, 1.0) if p_seleccionado else Color(0.4, 0.35, 0.2, 0.8)
	var grosor: int = 3 if p_seleccionado else 1
	sb.border_width_left = grosor
	sb.border_width_right = grosor
	sb.border_width_top = grosor
	sb.border_width_bottom = grosor
	btn.add_theme_stylebox_override("normal", sb)

	var sb_hover: StyleBoxFlat = sb.duplicate()
	sb_hover.bg_color = Color(0.2, 0.16, 0.28, 0.95)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_hover)

	# ── Contenido ──
	if p_slot.is_empty() or not p_slot.has("id"):
		btn.icon = null
		btn.text = str(btn.indice + 1)  # Número de la casilla como pista
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.25))
		btn.tooltip_text = ""
		return

	var def: ItemDefinicion = ItemDatabase.get_item(p_slot.id)
	if def == null:
		return

	btn.icon = _generador_iconos.get_icono(def)
	btn.text = ("x" + str(p_slot.cantidad)) if p_slot.cantidad > 1 else ""
	btn.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_BOTTOM
	btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	btn.tooltip_text = def.nombre_visible

func _on_slot_presionado(indice: int) -> void:
	Inventario.seleccionar_hotbar(indice)
