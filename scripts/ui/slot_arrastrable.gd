class_name SlotArrastrable
extends Button

# ═══════════════════════════════════════════════════════════════
# SlotArrastrable (FASE 10.8) — casilla con DRAG & DROP PROPIO
#
# ¿Por qué NO usamos _get_drag_data/_can_drop_data del motor?
# Porque Godot añade el preview del arrastre al VIEWPORT (canvas "layer 0"),
# y toda la UI de Aukane vive en un CanvasLayer con layer 1 → el icono que
# arrastras se dibuja POR DEBAJO de la mochila y la hotbar. Como la capa del
# preview nativo no se puede cambiar, hacemos el arrastre a mano: el preview
# es hijo del PROPIO CanvasLayer de la UI con z_index alto → siempre visible.
#
# Sirve igual para MOCHILA y HOTBAR: solo cambia `origen` e `indice`.
# No mueve datos: se lo pide al Inventario, que es el dueño de la verdad.
# ═══════════════════════════════════════════════════════════════

const UMBRAL_ARRASTRE_PX: float = 6.0   # movimiento mínimo para considerarlo arrastre
const Z_OVERLAY_ARRASTRE: int = 4096    # por encima de cualquier Control de la UI
const GRUPO_SLOTS: StringName = &"slots_arrastrables"

var origen: StringName = &"mochila"
var indice: int = -1

var _presionado: bool = false
var _arrastrando: bool = false
var _pos_press: Vector2 = Vector2.ZERO
var _preview: Control = null

func _ready() -> void:
	# Se registra para que las demás casillas puedan encontrarlo al soltar
	add_to_group(GRUPO_SLOTS)

func _exit_tree() -> void:
	# Si cierran la mochila mientras arrastras, no dejamos el preview huérfano
	if _preview != null and is_instance_valid(_preview):
		_preview.queue_free()

func _gui_input(event: InputEvent) -> void:
	if event is not InputEventMouseButton:
		return
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return

	if mb.pressed:
		var slot: Dictionary = Inventario.get_slot_por(origen, indice)
		if slot.is_empty() or not slot.has("id"):
			return  # casilla vacía: el click normal sigue funcionando
		_presionado = true
		_pos_press = get_global_mouse_position()
	else:
		# El botón conserva el foco de ratón, así que el RELEASE llega aquí
		# aunque el cursor esté sobre otra casilla.
		if _arrastrando:
			_terminar_arrastre(get_global_mouse_position())
		_presionado = false

func _process(_delta: float) -> void:
	if _arrastrando:
		_mover_preview()
		return
	if not _presionado:
		return
	# Solo iniciamos arrastre si el ratón se movió lo suficiente (evita que un
	# click normal con pulso tembloroso se convierta en arrastre)
	if get_global_mouse_position().distance_to(_pos_press) < UMBRAL_ARRASTRE_PX:
		return
	_iniciar_arrastre()

# ──────────────────────────────────────────────────────────────
# ARRASTRE
# ──────────────────────────────────────────────────────────────
func _iniciar_arrastre() -> void:
	var capa: CanvasLayer = _buscar_capa_ui()
	if capa == null or icon == null:
		_presionado = false
		return

	_preview = _crear_preview(icon)
	# z_index alto DENTRO del mismo CanvasLayer de la UI → se dibuja por
	# encima de la mochila y de la hotbar.
	_preview.z_index = Z_OVERLAY_ARRASTRE
	capa.add_child(_preview)
	_arrastrando = true
	_mover_preview()

func _mover_preview() -> void:
	if _preview == null or not is_instance_valid(_preview):
		return
	# Centramos el preview bajo el cursor
	_preview.global_position = get_global_mouse_position() - (_preview.size * 0.5)

func _terminar_arrastre(p_pos_global: Vector2) -> void:
	_arrastrando = false
	if _preview != null and is_instance_valid(_preview):
		_preview.queue_free()
	_preview = null

	var destino: SlotArrastrable = _buscar_slot_bajo(p_pos_global)
	if destino == null:
		return  # soltado fuera de cualquier casilla → no pasa nada

	Inventario.mover_entre(origen, indice, destino.origen, destino.indice)

# Cuadrado con el icono que sigue al cursor.
# EXPAND_IGNORE_SIZE evita que el TextureRect adopte la resolución NATIVA del
# icono (que era el bug del "icono gigante"); con KEEP_ASPECT no se deforma.
func _crear_preview(tex: Texture2D) -> Control:
	var tr: TextureRect = TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = custom_minimum_size
	tr.size = custom_minimum_size
	tr.modulate = Color(1, 1, 1, 0.85)  # semitransparente: se ve "agarrado"
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr

# ──────────────────────────────────────────────────────────────
# HELPERS
# ──────────────────────────────────────────────────────────────

## Sube por el árbol hasta el CanvasLayer que contiene toda la UI
func _buscar_capa_ui() -> CanvasLayer:
	var n: Node = get_parent()
	while n != null:
		if n is CanvasLayer:
			return n as CanvasLayer
		n = n.get_parent()
	return null

## Casilla (mochila u hotbar) que está bajo esa posición de pantalla
func _buscar_slot_bajo(p_pos_global: Vector2) -> SlotArrastrable:
	for nodo: Node in get_tree().get_nodes_in_group(GRUPO_SLOTS):
		var s: SlotArrastrable = nodo as SlotArrastrable
		if s == null or not is_instance_valid(s) or not s.is_visible_in_tree():
			continue
		if s.get_global_rect().has_point(p_pos_global):
			return s
	return null
