@tool
extends EditorPlugin

# ═══════════════════════════════════════════════════════════════
# Pincel de Terreno (FASE 10.9.3)
#
# Un EditorPlugin es el ÚNICO punto por el que Godot entrega los clics
# hechos en el viewport 3D del editor (_forward_3d_gui_input no existe
# en Node3D). Este addon solo captura el input; la lógica vive en
# GestorTerreno para no acoplar el juego al editor.
# ═══════════════════════════════════════════════════════════════

var _pintando: bool = false

func _handles(p_objeto: Object) -> bool:
	return p_objeto is GestorTerreno

func _forward_3d_gui_input(p_camara: Camera3D, p_evento: InputEvent) -> int:
	var terreno: GestorTerreno = _terreno_seleccionado()
	if terreno == null or not terreno.pincel_activo:
		return EditorPlugin.AFTER_GUI_INPUT_PASS

	var pos_raton: Vector2 = Vector2.INF
	if p_evento is InputEventMouseButton:
		var clic: InputEventMouseButton = p_evento as InputEventMouseButton
		if clic.button_index != MOUSE_BUTTON_LEFT:
			return EditorPlugin.AFTER_GUI_INPUT_PASS
		if not clic.pressed:
			_pintando = false
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		_pintando = true
		pos_raton = clic.position
	elif p_evento is InputEventMouseMotion:
		var mov: InputEventMouseMotion = p_evento as InputEventMouseMotion
		# Sin botón pulsado no pintamos (dejamos que la cámara orbital normal).
		if not _pintando or not (mov.button_mask & MOUSE_BUTTON_MASK_LEFT):
			return EditorPlugin.AFTER_GUI_INPUT_PASS
		pos_raton = mov.position
	else:
		return EditorPlugin.AFTER_GUI_INPUT_PASS

	var indice: int = terreno.indice_bajo_raton(p_camara, pos_raton)
	if indice < 0:
		return EditorPlugin.AFTER_GUI_INPUT_PASS

	if terreno.pintar_celda(indice, terreno.bioma_pincel_id()):
		EditorInterface.mark_scene_as_unsaved()
	return EditorPlugin.AFTER_GUI_INPUT_STOP

func _terreno_seleccionado() -> GestorTerreno:
	var nodos: Array[Node] = EditorInterface.get_selection().get_selected_nodes()
	for nodo: Node in nodos:
		if nodo is GestorTerreno:
			return nodo as GestorTerreno
	return null
