extends Control

# ═══════════════════════════════════════════════════════════════
# UI TIENDA DATA-DRIVEN
# Lee los items del CatalogoTienda asignado al NPC y genera
# botones dinámicamente. 2 pestañas: Comprar / Vender.
# ═══════════════════════════════════════════════════════════════

var _npc_owner: Node = null
var _catalogo: CatalogoTienda = null

# Nodos UI
@onready var _label_titulo: Label = $Fondo/Centrador/PanelTienda/VBoxPrincipal/LabelTitulo
@onready var _label_oro: Label = $Fondo/Centrador/PanelTienda/VBoxPrincipal/LabelOro
@onready var _vbox_comprar: VBoxContainer = $Fondo/Centrador/PanelTienda/VBoxPrincipal/TabContenedor/TabComprar/VBoxComprar
@onready var _vbox_vender: VBoxContainer = $Fondo/Centrador/PanelTienda/VBoxPrincipal/TabContenedor/TabVender/VBoxVender
@onready var _btn_cerrar: Button = $Fondo/Centrador/PanelTienda/VBoxPrincipal/BotonCerrar
@onready var _tab_contenedor: TabContainer = $Fondo/Centrador/PanelTienda/VBoxPrincipal/TabContenedor

func _ready() -> void:
	if not _btn_cerrar.pressed.is_connected(_on_btn_cerrar_pressed):
		_btn_cerrar.pressed.connect(_on_btn_cerrar_pressed)
	# Actualizar oro al abrir
	_actualizar_oro()

# ──────────────────────────────────────────────────────────────
# API: Asignar NPC y catálogo
# ──────────────────────────────────────────────────────────────
func asignar_npc_owner(npc: Node, p_tab_inicial: int = 0) -> void:
	_npc_owner = npc
	if _npc_owner != null and _npc_owner.has_method("get_catalogo"):
		_catalogo = _npc_owner.get_catalogo()
	elif _npc_owner != null and "catalogo_asignado" in _npc_owner:
		_catalogo = _npc_owner.catalogo_asignado
	_construir_ui()
	# Establecer pestaña inicial (0 = Comprar, 1 = Vender)
	if _tab_contenedor != null:
		_tab_contenedor.current_tab = p_tab_inicial

# ──────────────────────────────────────────────────────────────
# Construir botones desde el catálogo
# ──────────────────────────────────────────────────────────────
func _construir_ui() -> void:
	_limpiar_botones()
	if _catalogo == null:
		push_warning("[Tienda] ❌ Sin catálogo asignado.")
		return
	# Título
	_label_titulo.text = _catalogo.nombre_tienda
	# Pestaña COMPRAR
	for i in range(_catalogo.get_cantidad_items()):
		var it: ItemTienda = _catalogo.get_item(i)
		if it == null or it.precio_compra_jugador <= 0:
			continue
		var btn: Button = _crear_boton_item(it, true)
		_vbox_comprar.add_child(btn)
	# Pestaña VENDER: mostrar SOLO los items que el jugador tiene
	# Y que la tienda compra
	for i in range(Inventario.slots.size()):
		var slot: Dictionary = Inventario.get_slot(i)
		if slot.is_empty():
			continue
		var id_item: StringName = slot.id
		# ¿La tienda compra este item?
		var it: ItemTienda = _catalogo.get_item_por_id(id_item)
		if it == null or it.precio_venta_jugador <= 0:
			continue
		var btn: Button = _crear_boton_item(it, false)
		_vbox_vender.add_child(btn)

func _limpiar_botones() -> void:
	for hijo in _vbox_comprar.get_children():
		hijo.queue_free()
	for hijo in _vbox_vender.get_children():
		hijo.queue_free()

# ──────────────────────────────────────────────────────────────
# Crear un botón de item (comprar o vender)
# ──────────────────────────────────────────────────────────────
func _crear_boton_item(it: ItemTienda, es_compra: bool) -> Button:
	var btn: Button = Button.new()
	btn.custom_minimum_size = Vector2(0, 48)
	# Obtener nombre del item (override o de la base de datos)
	var nombre: String = it.nombre_override
	if nombre == "":
		var def: ItemDefinicion = ItemDatabase.get_item(it.id_item)
		if def != null:
			nombre = def.nombre_visible
	# Texto del botón
	if es_compra:
		btn.text = "🛒 %s  —  %d oro" % [nombre, it.precio_compra_jugador]
		btn.pressed.connect(_on_comprar.bind(it))
	else:
		var cantidad: int = Inventario.get_cantidad(it.id_item)
		btn.text = "💰 Vender %s (x%d)  —  %d oro" % [nombre, cantidad, it.precio_venta_jugador]
		btn.pressed.connect(_on_vender.bind(it))
	# Estilo
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	return btn

# ──────────────────────────────────────────────────────────────
# ACCIONES: Comprar / Vender
# ──────────────────────────────────────────────────────────────
func _on_comprar(it: ItemTienda) -> void:
	if _catalogo == null:
		return
	var oro: int = Inventario.get_cantidad(ClavesDatos.ID_MONEDA)
	if oro < it.precio_compra_jugador:
		print("[Tienda] ❌ Oro insuficiente. Tienes ", oro, ", necesitas ", it.precio_compra_jugador)
		return
	# Pagar y recibir item
	Inventario.gastar_item(ClavesDatos.ID_MONEDA, it.precio_compra_jugador)
	Inventario.agregar_item(it.id_item, 1)
	print("[Tienda] ✅ Compraste ", String(it.id_item), " por ", it.precio_compra_jugador, " oro")
	# Refrescar UI (oro y pestaña vender)
	_actualizar_oro()
	_construir_ui()

func _on_vender(it: ItemTienda) -> void:
	if _catalogo == null:
		return
	if not Inventario.tiene_item(it.id_item, 1):
		print("[Tienda] ❌ No tienes ", String(it.id_item), " para vender.")
		return
	# Vender: quitar item, dar oro
	Inventario.gastar_item(it.id_item, 1)
	Inventario.agregar_item(ClavesDatos.ID_MONEDA, it.precio_venta_jugador)
	print("[Tienda] ✅ Vendiste ", String(it.id_item), " por ", it.precio_venta_jugador, " oro")
	_actualizar_oro()
	_construir_ui()

# ──────────────────────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────────────────────
func _actualizar_oro() -> void:
	_label_oro.text = "💰 Oro: " + str(Inventario.get_cantidad(ClavesDatos.ID_MONEDA))

func _on_btn_cerrar_pressed() -> void:
	if _npc_owner != null and _npc_owner.has_method("cerrar_tienda"):
		_npc_owner.cerrar_tienda()

# Cerrar con ESC
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var k: InputEventKey = event as InputEventKey
		if k.pressed and not k.echo and k.keycode == KEY_ESCAPE:
			_on_btn_cerrar_pressed()
			get_viewport().set_input_as_handled()
