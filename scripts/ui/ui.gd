extends CanvasLayer

# NO USAMOS class_name Damageable para no pelear con el parser.
# Guardamos referencia como Node, y llamamos métodos por .call()
var _damageable_jugador: Node = null
var _ya_busque: bool = false
var ui_mochila: Control = null
var ui_hotbar: Control = null

@onready var ui_dialogo: UIDialogo = $UiDialogo
@onready var barra_vida_exterior: ColorRect = $BarraVidaExterior
@onready var barra_vida_interior: ColorRect = $BarraVidaExterior/BarraVidaInterior
@onready var barra_hambre_exterior: ColorRect = $BarraHambreExterior
@onready var barra_hambre_interior: ColorRect = $BarraHambreExterior/BarraHambreInterior
@onready var barra_energia_exterior: ColorRect = $BarraEnergiaExterior
@onready var barra_energia_interior: ColorRect = $BarraEnergiaExterior/BarraEnergiaInterior
@onready var _indicador_estacion: Label = $IndicadorEstacion
# FASE 12.4 — Nivel y barra de XP (adelanto del HUD)
@onready var _barra_xp_exterior: ColorRect = $BarraXPExterior
@onready var _barra_xp_interior: ColorRect = $BarraXPExterior/BarraXPInterior
@onready var _label_nivel: Label = $LabelNivel
var _nivel_jugador: Node = null
var _ya_busque_nivel: bool = false
# FASE 12.2 — Panel de atributos (fuerza/constitución/destreza)
@onready var _label_atributos: Label = $LabelAtributos
var _estadisticas_jugador: Node = null
var _ya_busque_estadisticas: bool = false
@export_group("Contadores del HUD")

## Items mostrados como contador (arriba-izquierda). El ORDEN del array es el

## orden en pantalla. Cero hardcodeo: el emoji sale de ItemDefinicion.emoji_hud.
@export var contadores_hud: Array[StringName] = []

@onready var _contenedor_contadores: VBoxContainer = $Contadores
var _labels_contadores: Dictionary[StringName, Label] = {}

# FASE 12.4 — Notificación flotante "¡Nivel X!"
## Formato del aviso. Punto único de verdad por si quieres cambiarlo.
const FORMATO_NOTIFICACION_NIVEL: String = "¡Nivel %d!"
const DURACION_NOTIFICACION: float = 1.6
const ALTURA_NOTIFICACION: float = 50.0

@onready var _notificacion_nivel: Label = $NotificacionNivel
var _tween_notificacion: Tween = null
var _pos_base_notificacion: Vector2 = Vector2.ZERO

var _stats_jugador: Node = null
# Deuda 10.11 — Widgets del HUD que se OCULTAN en modo modal.
# La tienda (npc_tienda.gd) y el crafteo (estacion_crafteo.gd) se añaden a
# get_tree().root → CAPA 0, POR DEBAJO de este CanvasLayer (capa 1). Sin
# ocultarlos, barras y textos se dibujan encima del fondo de esas ventanas.
var _nodos_hud: Array[CanvasItem] = []

func _ready() -> void:
	_crear_contadores()
		# FASE 12.4: recordamos la posición base ANTES de cualquier tween (el
	# aviso sube desde aquí) y arrancamos oculto.
	_pos_base_notificacion = _notificacion_nivel.position
	_notificacion_nivel.visible = false
	actualizar_hud()
	_actualizar_indicador_estacion()
	# La estación cambia (nuevo nombre/emoji) y los días restantes bajan
	# cada día → escuchamos AMBAS señales.
	GestorTiempo.estacion_cambio.connect(_on_estacion_cambio_hud)
	GestorTiempo.dia_cambio.connect(_on_dia_cambio_hud)

	Inventario.inventario_cambiado.connect(actualizar_hud)
	# Cargar mochila
	var escena_mochila: PackedScene = preload("res://escenes/ui/UIMochila.tscn")
	ui_mochila = escena_mochila.instantiate()
	add_child(ui_mochila)
	# Cargar hotbar (FASE 10.8)
	var escena_hotbar: PackedScene = preload("res://escenes/ui/UIHotbar.tscn")
	ui_hotbar = escena_hotbar.instantiate()
	add_child(ui_hotbar)
	_nodos_hud = [
		barra_vida_exterior,
		barra_hambre_exterior,
		barra_energia_exterior,
		_barra_xp_exterior,
		_contenedor_contadores,
		_indicador_estacion,
		_label_nivel,
		_label_atributos,
	]
	# FASE 10.11 — Modal: toda ventana abierta activa MODO_UI (diálogo, tienda,
	# crafteo, mochila). Escuchamos GameState: UNA sola fuente de verdad para
	# las cuatro, presente y futuras. Sin polling, sin tocar cada ventana.
	if not GameState.modo_cambiado.is_connected(_on_modo_global_cambiado):
		GameState.modo_cambiado.connect(_on_modo_global_cambiado)
	_sincronizar_hud_modal()

# ──────────────────────────────────────────────────────────────
# FASE 10.11 — La hotbar se oculta mientras hay una ventana modal
# ──────────────────────────────────────────────────────────────
func _on_modo_global_cambiado(_modo_anterior: StringName, _modo_nuevo: StringName) -> void:
	_sincronizar_hud_modal()

## Oculta el HUD mientras hay una ventana modal abierta.
## Criterio ÚNICO: las 4 ventanas que activan MODO_UI son diálogo, tienda,
## crafteo y mochila.
func _sincronizar_hud_modal() -> void:
	if ui_hotbar != null:
		# EXCEPCIÓN: la mochila también es MODO_UI, pero es la compañera de la
		# hotbar (destino del drag & drop) → con ella abierta la hotbar se ve.
		var mochila_abierta: bool = ui_mochila != null and ui_mochila.visible
		ui_hotbar.visible = not (GameState.esta_en_modo_ui() and not mochila_abierta)
	# El resto del HUD se oculta con CUALQUIER modal (incluida la mochila: su
	# fondo oscuro ya los tapaba, así que el cambio es visualmente neutro).
	var mostrar: bool = not GameState.esta_en_modo_ui()
	for n: CanvasItem in _nodos_hud:
		if n != null:
			n.visible = mostrar

func _process(delta: float) -> void:
	if _damageable_jugador == null and not _ya_busque:
		_intentar_conectar_damageable_jugador()
	if _nivel_jugador == null and not _ya_busque_nivel:
		_intentar_conectar_nivel()
	if _estadisticas_jugador == null and not _ya_busque_estadisticas:
		_intentar_conectar_estadisticas()

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

	# ──────────────────────────────────────────────────────────
	# FASE 8.4: Conectar también el componente Stats (hambre/energía)
	# ──────────────────────────────────────────────────────────
	var st: Node = jugador.get_node_or_null("Stats")
	if st == null:
		push_warning("[UI HUD] El jugador no tiene nodo hijo 'Stats'. Añádelo en Jugador.tscn.")
		return
	_stats_jugador = st
	if st.has_signal("hambre_cambio") and not st.hambre_cambio.is_connected(_on_hambre_cambio):
		st.hambre_cambio.connect(_on_hambre_cambio)
	if st.has_signal("energia_cambio") and not st.energia_cambio.is_connected(_on_energia_cambio):
		st.energia_cambio.connect(_on_energia_cambio)
	# Pintar estado inicial el primer frame
	st.call_deferred("emit_signal", "hambre_cambio", st.call("get_hambre"))
	st.call_deferred("emit_signal", "energia_cambio", st.call("get_energia"))
	print("[UI HUD] ✅ Stats del jugador conectado.")

# ──────────────────────────────────────────────────────────────
# FASE 12.4 — Conectar el componente Nivel (progresión)
# ──────────────────────────────────────────────────────────────
func _intentar_conectar_nivel() -> void:
	var jugador: Node = get_tree().get_first_node_in_group("jugador")
	if jugador == null:
		return

	var comp: Node = jugador.get_node_or_null("Nivel")
	if comp == null:
		_ya_busque_nivel = true
		push_warning("[UI HUD] El jugador no tiene nodo hijo 'Nivel'. Añádelo en Jugador.tscn.")
		return

	_nivel_jugador = comp
	_ya_busque_nivel = true

	if comp.has_signal("xp_cambio") and not comp.xp_cambio.is_connected(_on_xp_cambio):
		comp.xp_cambio.connect(_on_xp_cambio)
	if comp.has_signal("nivel_subido") and not comp.nivel_subido.is_connected(_on_nivel_subido):
		comp.nivel_subido.connect(_on_nivel_subido)

	# Estado inicial: la señal de Nivel._ready() ya se emitió antes de que
	# este HUD existiera, así que pintamos a mano una vez.
	_pintar_xp(
		int(comp.call("get_xp_actual")),
		int(comp.call("get_xp_siguiente")),
		int(comp.call("get_nivel"))
	)
	print("[UI HUD] ✅ Nivel del jugador conectado.")
# ──────────────────────────────────────────────────────────────
# FASE 12.2 — Conectar el componente Estadisticas (atributos)
# ──────────────────────────────────────────────────────────────
func _intentar_conectar_estadisticas() -> void:
	var jugador: Node = get_tree().get_first_node_in_group("jugador")
	if jugador == null:
		return

	var comp: Node = jugador.get_node_or_null("Estadisticas")
	if comp == null:
		_ya_busque_estadisticas = true
		push_warning("[UI HUD] El jugador no tiene nodo hijo 'Estadisticas'. Añádelo en Jugador.tscn.")
		return

	_estadisticas_jugador = comp
	_ya_busque_estadisticas = true

	if comp.has_signal("estadisticas_cambiadas") and not comp.estadisticas_cambiadas.is_connected(_on_estadisticas_cambiadas):
		comp.estadisticas_cambiadas.connect(_on_estadisticas_cambiadas)

	# Estado inicial: igual que con Nivel, la primera señal ya pasó.
	_on_estadisticas_cambiadas()
	print("[UI HUD] ✅ Estadisticas del jugador conectado.")

func _on_estadisticas_cambiadas() -> void:
	if _label_atributos == null or _estadisticas_jugador == null:
		return
	_label_atributos.text = str(_estadisticas_jugador.call("get_texto_hud"))
	
func _crear_contadores() -> void:
	_labels_contadores.clear()
	for id: StringName in contadores_hud:
		if ItemDatabase.get_item(id) == null:
			push_warning("[UI HUD] Contador ignorado: no existe el item " + str(id))
			continue
		var lbl: Label = Label.new()
		_labels_contadores[id] = lbl
		_contenedor_contadores.add_child(lbl)

func actualizar_hud() -> void:
	for id: StringName in _labels_contadores:
		var def: ItemDefinicion = ItemDatabase.get_item(id)
		var emoji: String = def.emoji_hud if def != null else ""
		_labels_contadores[id].text = emoji + " " + str(Inventario.get_cantidad(id))


# ──────────────────────────────────────────────────────────────

# FASE 11.5 — Indicador de estación del año

# ──────────────────────────────────────────────────────────────
func _on_estacion_cambio_hud(_id: StringName) -> void:
	_actualizar_indicador_estacion()

func _on_dia_cambio_hud(_nuevo_dia: int) -> void:
	_actualizar_indicador_estacion()

## Muestra "emoji Nombre — N días". Todo sale de datos:

## el emoji y el nombre del .tres de la estación, y los días del GestorTiempo.
func _actualizar_indicador_estacion() -> void:
	if _indicador_estacion == null:
		return
	var estacion: EstacionDefinicion = GestorTiempo.get_estacion_actual()
	if estacion == null:
		_indicador_estacion.text = ""
		return
	var dias: int = GestorTiempo.get_dias_restantes_estacion()
	_indicador_estacion.text = "%s %s — %d días" % [
		estacion.emoji_hud,
		estacion.nombre_visible,
		dias,
	]

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

	print("[UI HUD] Vida jugador ", vida_nueva, "/", vida_max, " → ", round(pct * 100), "%")
# ──────────────────────────────────────────────────────────────
# FASE 8.4 — Barras de HAMBRE y ENERGÍA
# Función común de pintado (reutilizable por cualquier barra)
# ──────────────────────────────────────────────────────────────
func _actualizar_barra(exterior: ColorRect, interior: ColorRect, pct: float) -> void:
	var ancho_exterior: float = exterior.offset_right - exterior.offset_left
	var alto_exterior: float = exterior.offset_bottom - exterior.offset_top
	const MARGEN: float = 2.0
	var ancho_util: float = ancho_exterior - (MARGEN * 2.0)
	interior.offset_left = MARGEN
	interior.offset_top = MARGEN
	interior.offset_right = MARGEN + (ancho_util * pct)
	interior.offset_bottom = alto_exterior - MARGEN

func _on_hambre_cambio(valor: int) -> void:
	var max_v: int = 100
	if _stats_jugador != null:
		max_v = int(_stats_jugador.get("hambre_max"))
	var pct: float = clampf(float(valor) / float(max_v), 0.0, 1.0)
	_actualizar_barra(barra_hambre_exterior, barra_hambre_interior, pct)

func _on_energia_cambio(valor: int) -> void:
	var max_v: int = 100
	if _stats_jugador != null:
		max_v = int(_stats_jugador.get("energia_max"))
	var pct: float = clampf(float(valor) / float(max_v), 0.0, 1.0)
	_actualizar_barra(barra_energia_exterior, barra_energia_interior, pct)

	# ──────────────────────────────────────────────────────────────
# FASE 4.1 — API Diálogos
# Retorna: UIDialogo (para que NpcTienda se pueda conectar a su señal accion_especial_solicitada)
# ──────────────────────────────────────────────────────────────
func abrir_dialogo_desde_npc(p_id_dialogo: StringName, p_npc: Node) -> UIDialogo:
	print(
		"[UI HUD] 🔵 abrir_dialogo_desde_npc() llamado. ID diálogo=",
		p_id_dialogo,
		" | NPC=",
		p_npc.name if p_npc != null else "nil",
	)
	if ui_dialogo == null:
		print("[UI HUD] 🚨 ONREADY FALLÓ: ui_dialogo es NULL. Verifica que @onready path coincide con nodo en UIHud.tscn.")
		push_warning("[UI HUD] No tengo UIDialogo como hijo. Asegúrate de instanciarlo en UI.tscn.")
		return null
	print("[UI HUD] ✅ UiDialogo encontrado. Llamo a abrir_dialogo_por_id().")
	ui_dialogo.abrir_dialogo_por_id(p_id_dialogo, p_npc)
	return ui_dialogo
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var k: InputEventKey = event as InputEventKey
		if k.pressed and not k.echo and k.keycode == KEY_I:
			if ui_mochila != null and ui_mochila.has_method("toggle"):
				ui_mochila.toggle()
				get_viewport().set_input_as_handled()
# ──────────────────────────────────────────────────────────────
# FASE 12.4 — Nivel y barra de XP
# ──────────────────────────────────────────────────────────────
func _on_xp_cambio(xp_actual: int, xp_necesaria: int) -> void:
	var nv: int = 1
	if _nivel_jugador != null:
		nv = int(_nivel_jugador.call("get_nivel"))
	_pintar_xp(xp_actual, xp_necesaria, nv)

func _on_nivel_subido(nuevo_nivel: int) -> void:
	print("[UI HUD] ⬆️ ¡Nivel ", nuevo_nivel, "!")
	_mostrar_notificacion_nivel(nuevo_nivel)

## Muestra el aviso flotante. Robusto ante subidas múltiples seguidas.
func _mostrar_notificacion_nivel(nuevo_nivel: int) -> void:
	if _notificacion_nivel == null:
		return
	# 1) Si subiste 2 niveles de golpe, el while de Nivel emite dos veces
	#    seguidas: matamos el tween anterior para que no se peleen.
	if _tween_notificacion != null and _tween_notificacion.is_valid():
		_tween_notificacion.kill()
	# 2) Reset COMPLETO antes de animar (un tween interrumpido podría haber
	#    dejado el Label invisible o desplazado).
	_notificacion_nivel.text = FORMATO_NOTIFICACION_NIVEL % nuevo_nivel
	_notificacion_nivel.position = _pos_base_notificacion
	_notificacion_nivel.modulate.a = 0.0
	_notificacion_nivel.visible = true
	# 3) Un solo tween, tres animaciones en paralelo:
	_tween_notificacion = create_tween()
	_tween_notificacion.set_parallel(true)
	#    a) aparece rápido
	_tween_notificacion.tween_property(_notificacion_nivel, "modulate:a", 1.0, 0.2)
	#    b) sube suave (SINE/EASE_OUT = arranca rápido y frena)
	_tween_notificacion.tween_property(_notificacion_nivel, "position:y",
		_pos_base_notificacion.y - ALTURA_NOTIFICACION, DURACION_NOTIFICACION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	#    c) se desvanece al final. set_delay() captura su valor de partida
	#       CUANDO arranca (alpha ya en 1.0), no al crear el tween.
	_tween_notificacion.tween_property(_notificacion_nivel, "modulate:a", 0.0, 0.5) \
		.set_delay(DURACION_NOTIFICACION - 0.5)
	# 4) Ocúltalo cuando TODAS las animaciones paralelas terminen.
	_tween_notificacion.chain().tween_callback(func() -> void:
		if is_instance_valid(_notificacion_nivel):
			_notificacion_nivel.visible = false
	)

## Reutiliza _actualizar_barra() (el mismo pintado de vida/hambre/energía).
func _pintar_xp(xp_actual: int, xp_necesaria: int, nivel_actual: int) -> void:
	if _label_nivel != null:
		_label_nivel.text = "Nv. %d — %d/%d XP" % [nivel_actual, xp_actual, xp_necesaria]
	if _barra_xp_exterior == null or _barra_xp_interior == null:
		return
	var pct: float = 0.0
	if xp_necesaria > 0:
		pct = clampf(float(xp_actual) / float(xp_necesaria), 0.0, 1.0)
	_actualizar_barra(_barra_xp_exterior, _barra_xp_interior, pct)
