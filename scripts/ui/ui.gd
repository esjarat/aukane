extends CanvasLayer

@onready var label_madera: Label = $LabelMadera
@onready var label_piedra: Label = $LabelPiedra
@onready var label_oro: Label = $LabelOro
@onready var label_semilla: Label = $LabelSemilla
@onready var barra_vida_exterior: ColorRect = $BarraVidaExterior
@onready var barra_vida_interior: ColorRect = $BarraVidaExterior/BarraVidaInterior
@onready var ui_dialogo: UIDialogo = $UiDialogo

# NO USAMOS class_name Damageable para no pelear con el parser.
# Guardamos referencia como Node, y llamamos métodos por .call()
var _damageable_jugador: Node = null
var _ya_busque: bool = false

func _ready() -> void:
	actualizar_hud()
	Inventario.inventario_cambiado.connect(actualizar_hud)

func _process(delta: float) -> void:
	if _damageable_jugador == null and not _ya_busque:
		_intentar_conectar_damageable_jugador()

func _intentar_conectar_damageable_jugador() -> void:
	var jugador = get_tree().get_first_node_in_group("jugador")
	if jugador == null:
		return

	var dam: Node = jugador.get_node_or_null("Damageable")
	if dam == null:
		_ya_busque = true
		push_warning("[UI HUD] Jugador detectado pero NO TIENE nodo hijo 'Damageable'. Crea el nodo en Jugador.tscn.")
		return

	# ✅ Hemos localizado el Damageable. Conectar señal con has_signal + connect CALLABLE.
	_damageable_jugador = dam
	_ya_busque = true

	if dam.has_signal("vida_cambio"):
		if not dam.vida_cambio.is_connected(_on_jugador_vida_cambio):
			dam.vida_cambio.connect(_on_jugador_vida_cambio)

	dam.call_deferred("emit_signal", "vida_cambio", dam.call("get_vida_actual"))
	print("[UI HUD] ✅ Damageable del jugador conectado.")

func actualizar_hud() -> void:
	print( "[UI HUD] actualizar_hud() llamada" )
	label_madera.text = "🪵 " + str(Inventario.get_cantidad(&"madera"))
	label_piedra.text = "🪨 " + str(Inventario.get_cantidad(&"piedra"))
	label_oro.text = "🪙 " + str(Inventario.get_cantidad(&"oro"))
	label_semilla.text = "🌰 " + str(Inventario.get_cantidad(&"semilla"))

func _on_jugador_vida_cambio(vida_nueva: int) -> void:
	if _damageable_jugador == null:
		return

	var vida_max: int = 100
	if _damageable_jugador.has_method("get_vida_maxima"):
		vida_max = int(_damageable_jugador.call("get_vida_maxima"))

	var pct: float = 0.0
	if vida_max > 0:
		pct = clampf(float(vida_nueva) / float(vida_max), 0.0, 1.0)

	# Cálculo robusto: offsets reales, no .size
	var ancho_exterior: float = barra_vida_exterior.offset_right - barra_vida_exterior.offset_left
	var alto_exterior: float  = barra_vida_exterior.offset_bottom - barra_vida_exterior.offset_top

	const MARGEN_X: float = 2.0   # 2px de margen izq y dcha (mismo que pusimos en la escena)
	const MARGEN_Y: float = 2.0   # 2px de margen arriba y abajo

	var ancho_util: float  = ancho_exterior - (MARGEN_X * 2.0)
	var ancho_rojo: float  = MARGEN_X + (ancho_util * pct)   # = margen izq + % del espacio útil
	var alto_final: float  = alto_exterior - MARGEN_Y

	# Asignamos 4 offsets al completo (no dependemos de valores residuales):
	barra_vida_interior.offset_left   = MARGEN_X
	barra_vida_interior.offset_top    = MARGEN_Y
	barra_vida_interior.offset_right  = ancho_rojo
	barra_vida_interior.offset_bottom = alto_final

	print("[UI HUD] Vida jugador ", vida_nueva, "/", vida_max, " → ", round(pct*100), "%")
	
	# ──────────────────────────────────────────────────────────────
# FASE 4.1 — API Diálogos
# Retorna: UIDialogo (para que NpcTienda se pueda conectar a su señal accion_especial_solicitada)
# ──────────────────────────────────────────────────────────────
func abrir_dialogo_desde_npc(p_id_dialogo: StringName, p_npc: Node) -> UIDialogo:
	print("[UI HUD] 🔵 abrir_dialogo_desde_npc() llamado. ID diálogo=", p_id_dialogo, " | NPC=", p_npc.name if p_npc != null else "nil")
	if ui_dialogo == null:
		print("[UI HUD] 🚨 ONREADY FALLÓ: ui_dialogo es NULL. Verifica que @onready path coincide con nodo en UIHud.tscn.")
		push_warning("[UI HUD] No tengo UIDialogo como hijo. Asegúrate de instanciarlo en UI.tscn.")
		return null
	print("[UI HUD] ✅ UiDialogo encontrado. Llamo a abrir_dialogo_por_id().")
	ui_dialogo.abrir_dialogo_por_id(p_id_dialogo, p_npc)
	return ui_dialogo
