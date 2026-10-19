extends Node3D

# ═══════════════════════════════════════════════════════════════
# EfectosClima (FASE 11.2)
# Muestra lluvia/nieve según el clima y sigue a la cámara.
# NO toca la luz ni el ambiente (eso es de ciclo_dia_noche.gd):
# así nunca hay dos escritores sobre la misma propiedad.
# ═══════════════════════════════════════════════════════════════

@onready var _lluvia: GPUParticles3D = $Lluvia
@onready var _nieve: GPUParticles3D = $Nieve

## Altura a la que flotan las partículas sobre la cámara (capturando "cielo").
@export var altura_seguimiento: float = 8.0

## Grado de inclinación por unidad de viento (para inclinar la lluvia/nieve).
@export var inclinacion_por_viento: float = 12.0

var _camara: Camera3D = null

func _ready() -> void:
	if _lluvia == null or _nieve == null:
		push_error("[EfectosClima] ⚠️ Faltan los nodos hijos 'Lluvia' y/o 'Nieve' (GPUParticles3D) en EfectosClima.tscn. El clima no mostrará partículas.")
		return
	GestorClima.clima_cambio.connect(_on_clima_cambio)
	_on_clima_cambio(GestorClima.clima_actual)

func _process(_delta: float) -> void:
	# Las partículas deben seguir a la cámara: si se quedaran fijas, solo
	# llovería en una esquina del mapa (y gastaría partículas lejos).
	if _camara == null or not is_instance_valid(_camara):
		_camara = _get_viewport().get_camera_3d()
	if _camara != null:
		global_position = _camara.global_position + Vector3.UP * altura_seguimiento

func _get_viewport() -> Viewport:
	return get_viewport()

func _on_clima_cambio(_id: StringName) -> void:
	if _lluvia == null or _nieve == null:
		return
	var clima: ClimaDefinicion = GestorClima.get_clima_actual()
	var tipo: StringName = &""
	var viento: float = 0.0
	if clima != null:
		tipo = clima.particulas
		viento = clima.velocidad_viento

	_lluvia.emitting = (tipo == &"lluvia")
	_nieve.emitting = (tipo == &"nieve")

	# El viento se traduce en una INCLINACIÓN del sistema (efecto visual
	# inmediato y barato). Mover los árboles del grupo 'arboles' queda para 11.2b.
	var inclinacion: float = deg_to_rad(viento * inclinacion_por_viento)
	_lluvia.rotation.z = inclinacion
	_nieve.rotation.z = inclinacion
