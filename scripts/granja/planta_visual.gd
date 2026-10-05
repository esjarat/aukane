extends Node3D
class_name PlantaVisual

@export var etapa_0: Node3D
@export var etapa_1: Node3D
@export var etapa_2: Node3D
@export var etapa_3: Node3D

var _ultima_etapa_mostrada: int = -1

func _ready() -> void:
	var etapas_faltantes: Array[String] = []
	if etapa_0 == null: etapas_faltantes.append("etapa_0")
	if etapa_1 == null: etapas_faltantes.append("etapa_1")
	if etapa_2 == null: etapas_faltantes.append("etapa_2")
	if etapa_3 == null: etapas_faltantes.append("etapa_3")
	if etapas_faltantes.size() > 0:
		push_warning("[PlantaVisual] Faltan etapas por asignar en el Inspector: " + str(etapas_faltantes))
	_mostrar_etapa(0)

func set_progreso(progreso_0_1: float) -> void:
	var etapa_indice: int = 0
	if progreso_0_1 >= 1.0:
		etapa_indice = 3
	elif progreso_0_1 >= 0.66:
		etapa_indice = 2
	elif progreso_0_1 >= 0.33:
		etapa_indice = 1
	else:
		etapa_indice = 0
	if etapa_indice != _ultima_etapa_mostrada:
		_mostrar_etapa(etapa_indice)
		_ultima_etapa_mostrada = etapa_indice
		print("[PlantaVisual] Progreso ", round(progreso_0_1*100), "% → cambio a etapa ", etapa_indice)

func _mostrar_etapa(indice: int) -> void:
	var etapas: Array[Node3D] = [etapa_0, etapa_1, etapa_2, etapa_3]
	for i in range(etapas.size()):
		var m: Node3D = etapas[i]
		if m == null:
			continue
		m.visible = (i == indice)
