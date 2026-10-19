extends DirectionalLight3D

# ═══════════════════════════════════════════════════════════════
# CONTROL DEL CICLO DÍA/NOCHE.
# Interpola color, intensidad y rotación de la luz direccional
# según la hora del GestorTiempo.
# ═══════════════════════════════════════════════════════════════

@onready var _world_env: WorldEnvironment = $WorldEnvironment
# Inclinación de la trayectoria del sol (eje Y). 0 = sube y baja recto, 45 = diagonal.
@export var inclinacion_sol_y: float = 120.0
# Colores por tramo de hora
const COLOR_NOCHE: Color = Color(0.15, 0.15, 0.3, 1.0)
const COLOR_AMANECER: Color = Color(1.0, 0.6, 0.3, 1.0)
const COLOR_DIA: Color = Color(1.0, 0.96, 0.85, 1.0)
const COLOR_ATARDECER: Color = Color(1.0, 0.5, 0.3, 1.0)

# Intensidades
const INTENSIDAD_NOCHE: float = 0.15
const INTENSIDAD_DIA: float = 1.2
# ── Modificadores del CLIMA (FASE 11.2) ──
# El clima NO escribe la luz/ambiente: solo aporta factores que el ciclo
# combina con su cálculo por hora. Un solo dueño = sin conflictos.
var _mult_clima_energia: float = 1.0
var _tinte_clima: Color = Color(1, 1, 1)
var _oscuridad_clima: float = 0.0
var _color_fondo_base: Color = Color(0.15, 0.15, 0.25)
# Ángulos de rotación de la luz (X) según la hora
# 0° = sol en el cenit (mediodía), -90° = atardecer, 90° = amanecer
const ANGULO_AMANECER: float = 110.0
const ANGULO_MEDIO: float = 0.0
const ANGULO_ATARDECER: float = -70.0

func _ready() -> void:
	GestorTiempo.minuto_cambio.connect(_actualizar_luz)
	# Guardamos el color de fondo ORIGINAL del Environment para oscurecerlo
	# sin perderlo (se recupera al volver a soleado).
	if _world_env != null and _world_env.environment != null:
		_color_fondo_base = _world_env.environment.background_color
	GestorClima.clima_cambio.connect(_on_clima_cambio)
	# El clima ya emitió su señal antes de que esta escena existiera:
	# leemos su estado actual una vez para arrancar sincronizados.
	_on_clima_cambio(GestorClima.clima_actual)
	_actualizar_luz(GestorTiempo.get_hora(), GestorTiempo.get_minuto())

func _on_clima_cambio(_id: StringName) -> void:
	var clima: ClimaDefinicion = GestorClima.get_clima_actual()
	if clima == null:
		return
	_mult_clima_energia = clima.energia_luz
	_tinte_clima = clima.color_ambiente
	_oscuridad_clima = clima.factor_oscuridad
	_actualizar_luz(GestorTiempo.get_hora(), GestorTiempo.get_minuto())
	
func _actualizar_luz(_hora: int, _minuto: int) -> void:
	var h: float = GestorTiempo.get_hora_decimal()
	# 1) Color de la luz
	light_color = _interpolar_color_por_hora(h)
	# 2) Intensidad (base por hora × factor del clima)
	light_energy = _interpolar_intensidad_por_hora(h) * _mult_clima_energia
	# 3) Rotación (simula el movimiento del sol)
	rotation.x = deg_to_rad(_interpolar_angulo_por_hora(h))
	rotation.y = deg_to_rad(inclinacion_sol_y)
	# 4) Ambiente y fondo (con tinte y oscuridad del clima)
	if _world_env != null and _world_env.environment != null:
		_world_env.environment.ambient_light_color = light_color * 0.3 * _tinte_clima
		var energia_amb: float = 0.4 if es_noche_color(h) else 1.0
		_world_env.environment.ambient_light_energy = energia_amb * _mult_clima_energia
		_world_env.environment.background_color = _color_fondo_base.darkened(_oscuridad_clima)
		
# ──────────────────────────────────────────────────────────────
# INTERPOLADORES
# ──────────────────────────────────────────────────────────────
func _interpolar_color_por_hora(h: float) -> Color:
	if h < 6.0:
		return COLOR_NOCHE
	elif h < 8.0:
		# 6-8: noche → amanecer
		return COLOR_NOCHE.lerp(COLOR_AMANECER, (h - 6.0) / 2.0)
	elif h < 10.0:
		# 8-10: amanecer → día
		return COLOR_AMANECER.lerp(COLOR_DIA, (h - 8.0) / 2.0)
	elif h < 18.0:
		return COLOR_DIA
	elif h < 20.0:
		# 18-20: día → atardecer
		return COLOR_DIA.lerp(COLOR_ATARDECER, (h - 18.0) / 2.0)
	elif h < 22.0:
		# 20-22: atardecer → noche
		return COLOR_ATARDECER.lerp(COLOR_NOCHE, (h - 20.0) / 2.0)
	else:
		return COLOR_NOCHE

func _interpolar_intensidad_por_hora(h: float) -> float:
	if h < 6.0 or h >= 22.0:
		return INTENSIDAD_NOCHE
	elif h < 8.0:
		return lerp(INTENSIDAD_NOCHE, INTENSIDAD_DIA, (h - 6.0) / 2.0)
	elif h < 18.0:
		return INTENSIDAD_DIA
	elif h < 22.0:
		return lerp(INTENSIDAD_DIA, INTENSIDAD_NOCHE, (h - 18.0) / 4.0)
	return INTENSIDAD_NOCHE

func _interpolar_angulo_por_hora(h: float) -> float:
	# De amanecer (6: 90°) → mediodía (12: 0°) → atardecer (18: -90°)
	# Durante la noche queda en -90 (abajo del horizonte)
	if h < 6.0 or h >= 20.0:
		return -90.0
	elif h < 12.0:
		return lerp(ANGULO_AMANECER, ANGULO_MEDIO, (h - 6.0) / 6.0)
	else:
		return lerp(ANGULO_MEDIO, ANGULO_ATARDECER, (h - 12.0) / 6.0)

func es_noche_color(h: float) -> bool:
	return h < 6.0 or h >= 20.0
