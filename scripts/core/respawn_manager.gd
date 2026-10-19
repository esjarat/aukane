extends Node

# ═══════════════════════════════════════════════════════════════
# RespawnManager — Autoload (FASE 9.3)
# Registra recursos (árboles/rocas) cortados y los reactiva tras
# N días de JUEGO. Escucha GestorTiempo.dia_cambio (tiempo de
# juego, NO segundos reales), coherente con plantas y tiendas.
# ═══════════════════════════════════════════════════════════════

# Lista de pendientes: [{ "nodo": Node3D, "dias_restantes": int }]
var _pendientes: Array[Dictionary] = []

func _ready() -> void:
	if GestorTiempo != null:
		GestorTiempo.dia_cambio.connect(_on_dia_cambio)

# Lo llama RecursoRespawneable al ser cortado. 'dias' = días de juego.
func registrar(nodo: Node3D, dias: int) -> void:
	if nodo == null or not is_instance_valid(nodo):
		return
	if dias <= 0:
		if nodo.has_method("reactivar"):
			nodo.reactivar()
		return
	_pendientes.append({ "nodo": nodo, "dias_restantes": dias })
	print("[RespawnManager] Registrado ", nodo.name, " → reaparece en ", dias, " día(s)")

# Callback de GestorTiempo.dia_cambio(dia)
func _on_dia_cambio(_dia: int) -> void:
	var seguir: Array[Dictionary] = []
	for p in _pendientes:
		var nodo: Node3D = p["nodo"]
		# El recurso pudo liberarse (fin de escena): lo descartamos sin romper
		if nodo == null or not is_instance_valid(nodo):
			continue
		p["dias_restantes"] = int(p["dias_restantes"]) - 1
		if int(p["dias_restantes"]) <= 0:
			if nodo.has_method("reactivar"):
				nodo.reactivar()
				print("[RespawnManager] 🌱 Reaparece ", nodo.name)
		else:
			seguir.append(p)
	_pendientes = seguir

func get_pendientes() -> int:
	return _pendientes.size()
