# scripts/combate/damageable_barra_3d.gd
extends Node3D
class_name DamageableBarra3D

# ═══════════════════════════════════════════════════════════════
# BARRA VIDA 3D PROFESIONAL | SubViewport + Sprite3D
# COMPATIBLE Godot 4.x todas las versiones (4.0 a 4.7)
# ═══════════════════════════════════════════════════════════════
var _sprite_3d: Sprite3D = null
var _viewport: SubViewport = null
var _rect_fondo: ColorRect = null
var _rect_frente: ColorRect = null
var _label_numeros: Label = null
var _damageable: Node = null

# Config Inspector
@export var altura_sobre_cabeza: float = 1.25
@export var ancho_barra_metros: float = 1.15
@export var alto_barra_metros: float = 0.18
@export var color_fondo: Color = Color(1.0, 1.0, 1.0, 0.22)   # Blanco liso 22% opaco
@export var color_borde: Color = Color(0.0, 0.0, 0.0, 0.55)
@export var color_saludable: Color = Color(0.05, 0.9, 0.2, 1.0)
@export var color_medio: Color = Color(1.0, 0.88, 0.1, 1.0)
@export var color_peligro: Color = Color(1.0, 0.2, 0.2, 1.0)
@export var mostrar_numeros: bool = true
@export var color_numeros: Color = Color(1, 1, 1, 1)
@export var tamano_fuente_numeros: int = 80

const VIEWPORT_ANCHO: int = 2512
const VIEWPORT_ALTO: int = 296
const BORDE_PX: int = 4

func _ready() -> void:
	# 1) Buscar Damageable
	var padre: Node = get_parent()
	if padre != null:
		_damageable = padre.get_node_or_null("Damageable")
	if _damageable == null and padre != null and padre.get_parent() != null:
		_damageable = padre.get_parent().get_node_or_null("Damageable")
	if _damageable == null:
		push_warning("[Barra3D] ⚠️ No encontré nodo 'Damageable'. Barra desactivada.")
		set_process(false)
		return

	# ───────────────────────────────────────────────────────────────
	# PASO A: SubViewport (COMPATIBILIDAD TOTAL, sin BG_*)
	# Solución: FONDO TRANSPARENTE IMPUESTO POR ColorRect TRANSPARENTE 100% como PRIMER HIJO
	# (funciona en TODAS Godot 4.x sin importar enums background_mode)
	# ───────────────────────────────────────────────────────────────
	_viewport = SubViewport.new()
	add_child(_viewport, true, Node.INTERNAL_MODE_FRONT)
	_viewport.name = "BarraViewport"
	_viewport.size = Vector2i(VIEWPORT_ANCHO, VIEWPORT_ALTO)
	# Actualizar textura cada frame
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	# HDR desactivado (no necesitamos colores >1.0)

	# HIJO 0 = ColorRect TRANSPARENTE TOTAL (ocupa 100% viewport)
	# → garantiza fondo transparente sin depender de enums BG_*
	var _rect_forzar_alpha0: ColorRect = ColorRect.new()
	_viewport.add_child(_rect_forzar_alpha0)
	_rect_forzar_alpha0.name = "ForzarFondoTransparente"
	_rect_forzar_alpha0.color = Color(0, 0, 0, 0)  # 100% transparente
	_rect_forzar_alpha0.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect_forzar_alpha0.z_index = -50

	# PASO B: FONDO barra (blanco liso semitransparente)
	_rect_fondo = ColorRect.new()
	_viewport.add_child(_rect_fondo)
	_rect_fondo.name = "Fondo"
	_rect_fondo.color = color_fondo
	_rect_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect_fondo.offset_left = BORDE_PX
	_rect_fondo.offset_top = BORDE_PX
	_rect_fondo.offset_right = -BORDE_PX
	_rect_fondo.offset_bottom = -BORDE_PX

	# PASO C: 4 bordes negros (aspecto profesional)
	_viewport.add_child(_crear_borde_rect("BordeIzq", color_borde, 0, 0, BORDE_PX, VIEWPORT_ALTO))
	_viewport.add_child(_crear_borde_rect("BordeDer", color_borde, VIEWPORT_ANCHO - BORDE_PX, 0, BORDE_PX, VIEWPORT_ALTO))
	_viewport.add_child(_crear_borde_rect("BordeArr", color_borde, 0, 0, VIEWPORT_ANCHO, BORDE_PX))
	_viewport.add_child(_crear_borde_rect("BordeAbj", color_borde, 0, VIEWPORT_ALTO - BORDE_PX, VIEWPORT_ANCHO, BORDE_PX))

	# PASO D: FRENTE barra (color variable, ancho = %vida, lado IZQ siempre fijo)
	_rect_frente = ColorRect.new()
	_viewport.add_child(_rect_frente)
	_rect_frente.name = "Frente"
	_rect_frente.color = color_saludable
	_rect_frente.position = Vector2(BORDE_PX, BORDE_PX)
	_rect_frente.size = Vector2(VIEWPORT_ANCHO - BORDE_PX * 2, VIEWPORT_ALTO - BORDE_PX * 2)
	_rect_frente.z_index = 2

	# PASO E: Números Label 2D (Shadow Stroke 100% compatible)
	# Label 2D NO TIENE outline_size. Técnica: 2 labels idénticos.
	#   A) NumVida_Sombra: negro, 2px offset, z = 2 (debajo)
	#   B) NumVida_Frente: blanco, sin offset, z = 3 (encima)
	var _label_sombra: Label = Label.new()
	_viewport.add_child(_label_sombra)
	_label_sombra.name = "NumVida_Sombra"
	_label_sombra.z_index = 2
	_label_sombra.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label_sombra.offset_left = 2
	_label_sombra.offset_top = 2
	_label_sombra.offset_right = 2
	_label_sombra.offset_bottom = 2
	_label_sombra.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_sombra.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label_sombra.add_theme_font_size_override("font_size", tamano_fuente_numeros)
	_label_sombra.modulate = Color(0, 0, 0, 0.92)
	_label_sombra.visible = mostrar_numeros
	_label_sombra.text = ""

	_label_numeros = Label.new()
	_viewport.add_child(_label_numeros)
	_label_numeros.name = "NumVida_Frente"
	_label_numeros.z_index = 3
	_label_numeros.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label_numeros.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_numeros.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label_numeros.add_theme_font_size_override("font_size", tamano_fuente_numeros)
	_label_numeros.modulate = color_numeros
	_label_numeros.visible = mostrar_numeros
	_label_numeros.text = ""

	# ───────────────────────────────────────────────────────────────
	# PASO F: Sprite3D (renderiza la textura SubViewport al mundo 3D)
	# ───────────────────────────────────────────────────────────────
	_sprite_3d = Sprite3D.new()
	add_child(_sprite_3d)
	_sprite_3d.name = "BarraSprite"
	_sprite_3d.position = Vector3(0.0, altura_sobre_cabeza, 0.0)
	_sprite_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sprite_3d.no_depth_test = true
	_sprite_3d.centered = true
	_sprite_3d.offset = Vector2.ZERO
	# Textura = textura dinámica del SubViewport
	_sprite_3d.texture = _viewport.get_texture()
	# Tamaño EXACTO en metros (no dependemos de pixel_size)
	var ancho_px_textura: float = float(VIEWPORT_ANCHO)
	_sprite_3d.pixel_size = ancho_barra_metros / ancho_px_textura

	# Señales Damageable (seguras)
	if _damageable.has_signal("vida_cambio") and not _damageable.vida_cambio.is_connected(_on_damageable_vida_cambio):
		_damageable.vida_cambio.connect(_on_damageable_vida_cambio)
	if _damageable.has_signal("murio") and not _damageable.murio.is_connected(_on_damageable_murio):
		_damageable.murio.connect(_on_damageable_murio)

	# Update inicial
	var vida_actual: int = int(_damageable.call("get_vida_actual"))
	var vida_max: int = int(_damageable.call("get_vida_maxima"))
	_actualizar_barra(vida_actual, vida_max)

# ───────────────────────────────────────────────────────────────
# HELPERS
# ───────────────────────────────────────────────────────────────
func _crear_borde_rect(nombre: String, color_b: Color, x: int, y: int, w: int, h: int) -> ColorRect:
	var r: ColorRect = ColorRect.new()
	r.name = nombre
	r.color = color_b
	r.position = Vector2(float(x), float(y))
	r.size = Vector2(float(w), float(h))
	r.z_index = 1
	return r

func _exit_tree() -> void:
	if _damageable != null:
		if _damageable.has_signal("vida_cambio") and _damageable.vida_cambio.is_connected(_on_damageable_vida_cambio):
			_damageable.vida_cambio.disconnect(_on_damageable_vida_cambio)
		if _damageable.has_signal("murio") and _damageable.murio.is_connected(_on_damageable_murio):
			_damageable.murio.disconnect(_on_damageable_murio)

# ───────────────────────────────────────────────────────────────
# CALLBACKS Damageable
# ───────────────────────────────────────────────────────────────
func _on_damageable_vida_cambio(vida_nueva: int, _p1 = null, _p2 = null, _p3 = null) -> void:
	if _damageable == null:
		return
	var vida_max: int = int(_damageable.call("get_vida_maxima"))
	_actualizar_barra(vida_nueva, vida_max)

func _on_damageable_murio(_atacante: NodePath = NodePath(""), _p1 = null, _p2 = null) -> void:
	if is_instance_valid(_label_numeros):
		_label_numeros.visible = false
		# Oculto también la sombra
		if is_instance_valid(_label_numeros.get_parent()) and _label_numeros.get_parent().has_node("NumVida_Sombra"):
			var lbl_sombra: Label = _label_numeros.get_parent().get_node("NumVida_Sombra") as Label
			if lbl_sombra != null:
				lbl_sombra.visible = false
	if is_instance_valid(_rect_frente):
		_rect_frente.visible = false
	if is_instance_valid(_viewport):
		var rip_lbl: Label = Label.new()
		_viewport.add_child(rip_lbl)
		rip_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		rip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rip_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		rip_lbl.modulate = Color(1, 0.2, 0.2, 1)
		rip_lbl.add_theme_font_size_override("font_size", tamano_fuente_numeros + 8)
		rip_lbl.text = "💀"
	var tw: Tween = create_tween()
	tw.tween_interval(0.4)
	tw.tween_callback(func():
		if is_instance_valid(self):
			visible = false
	)

# ───────────────────────────────────────────────────────────────
# RENDER Barra
# ───────────────────────────────────────────────────────────────
func _actualizar_barra(vida_actual: int, vida_max: int) -> void:
	if _rect_frente == null or vida_max <= 0:
		return
	var porcentaje: float = clamp(float(vida_actual) / float(vida_max), 0.0, 1.0)

	# ✅ LADO IZQUIERDO FIJO (BORDE_PX), SOLO VARÍA EL ANCHO por el DERECHO
	var ancho_interno_total: float = float(VIEWPORT_ANCHO - BORDE_PX * 2)
	var ancho_frente: float = ancho_interno_total * porcentaje
	_rect_frente.size = Vector2(ancho_frente, float(VIEWPORT_ALTO - BORDE_PX * 2))

	# Color frente dinámico
	if porcentaje > 0.65:
		_rect_frente.color = color_saludable
	elif porcentaje > 0.32:
		_rect_frente.color = color_medio
	else:
		_rect_frente.color = color_peligro

		# 4) NÚMEROS (actualizo FRENTE + SOMBRA simultáneamente)
	if _label_numeros != null and mostrar_numeros:
		var texto: String = ("%d/%d" % [vida_actual, vida_max])
		_label_numeros.text = texto
		if is_instance_valid(_label_numeros.get_parent()) and _label_numeros.get_parent().has_node("NumVida_Sombra"):
			var lbl_sombra: Label = _label_numeros.get_parent().get_node("NumVida_Sombra") as Label
			if lbl_sombra != null:
				lbl_sombra.text = texto
