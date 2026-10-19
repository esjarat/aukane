class_name Stats
# scripts/jugador/stats.gd
# Componente de necesidades básicas (hambre y energía) del jugador.
# Se añade como NODO HIJO (igual que Damageable), NUNCA por herencia.
extends Node

# ═══════════════════════════════════════════════════════════════
# 1) SEÑALES (para que el HUD se actualice SIN polling)
# ═══════════════════════════════════════════════════════════════
signal hambre_cambio(valor: int)
signal energia_cambio(valor: int)
signal hambre_critica
signal agotamiento_cambio(agotado: bool)
# ═══════════════════════════════════════════════════════════════
# 2) EXPORT (ajustables por Inspector para cada entidad)
# ═══════════════════════════════════════════════════════════════
@export var hambre_max: int = 100
@export var energia_max: int = 100
@export var consumo_hambre_por_minuto: float = 0.05   # 100/0.05 = 2000 min juego ≈ 1.4 días
@export var consumo_energia_por_minuto: float = 0.03
@export var danio_por_hambre: int = 5
@export var segundos_entre_danio_hambre: float = 3.0
@export var energia_por_segundo_corriendo: float = 4.0
@export var multiplicador_velocidad_agotado: float = 0.55
@export var porcentaje_recuperacion_energia: float = 0.25   # 25% para salir del agotamiento
# ═══════════════════════════════════════════════════════════════
# 3) ESTADO INTERNO (float para permitir consumos fraccionarios)
# ═══════════════════════════════════════════════════════════════
var _hambre_actual: float = 0.0
var _energia_actual: float = 0.0
var _tiempo_sin_comer: float = 0.0
var _damageable: Node = null
var _sin_energia: bool = false
# ═══════════════════════════════════════════════════════════════
# 4) READY
# ═══════════════════════════════════════════════════════════════
func _ready() -> void:
	_hambre_actual = float(hambre_max)
	_energia_actual = float(energia_max)
	# Buscar el Damageable HERMANO (mismo padre) sin acoplarnos a una ruta fija
	_damageable = get_parent().get_node_or_null("Damageable")
	# Escuchar el paso de CADA MINUTO DE JUEGO (no cada frame real)
	GestorTiempo.minuto_cambio.connect(_on_minuto_cambio)
	Inventario.item_consumido.connect(_on_item_consumido)
	# Emitir estado inicial para que el HUD se pinte en el primer frame
	hambre_cambio.emit(get_hambre())
	energia_cambio.emit(get_energia())

# ═══════════════════════════════════════════════════════════════
# 5) CONSUMO POR MINUTO DE JUEGO
# ═══════════════════════════════════════════════════════════════
func _on_minuto_cambio(_hora: int, _minuto: int) -> void:
	_hambre_actual = max(0.0, _hambre_actual - consumo_hambre_por_minuto)
	_energia_actual = max(0.0, _energia_actual - consumo_energia_por_minuto)
	hambre_cambio.emit(get_hambre())
	energia_cambio.emit(get_energia())
	
func _on_item_consumido(_id: StringName, hambre: int, vida: int) -> void:
	if hambre > 0:
		comer(hambre)
	if vida > 0 and _damageable != null and _damageable.has_method("sanar"):
		_damageable.sanar(vida)
# ═══════════════════════════════════════════════════════════════
# 6) _PROCESS: SOLO para el daño por inanición (tiempo real)
# ═══════════════════════════════════════════════════════════════
func _process(delta: float) -> void:
	if _hambre_actual > 0.0:
		_tiempo_sin_comer = 0.0
		return
	# Hambre a 0 → aplicar daño de inanición cada X segundos REALES
	_tiempo_sin_comer += delta
	if _tiempo_sin_comer >= segundos_entre_danio_hambre:
		_tiempo_sin_comer = 0.0
		hambre_critica.emit()
		if _damageable != null and _damageable.has_method("recibir_danio"):
			_damageable.recibir_danio(danio_por_hambre, null)

# ═══════════════════════════════════════════════════════════════
# 7) API PÚBLICA (la usan consumibles y la cama)
# ═══════════════════════════════════════════════════════════════
func comer(monto: int) -> void:
	_hambre_actual = min(float(hambre_max), _hambre_actual + float(monto))
	_tiempo_sin_comer = 0.0
	hambre_cambio.emit(get_hambre())

func descansar(monto: int) -> void:
	_energia_actual = min(float(energia_max), _energia_actual + float(monto))
	energia_cambio.emit(get_energia())
	_actualizar_agotamiento ()
# Gasto continuo al correr (lo llama jugador.gd cada frame mientras corre)
func gastar_energia_correr(delta: float) -> void:
	_energia_actual = max(0.0, _energia_actual - energia_por_segundo_corriendo * delta)
	energia_cambio.emit(get_energia())
	_actualizar_agotamiento ()
	
func get_hambre() -> int:
	return int(round(_hambre_actual))

func get_energia() -> int:
	return int(round(_energia_actual))

func esta_agotado() -> bool:
	return _hambre_actual <= 0.0

# ──────────────────────────────────────────────────────────────
# FASE 8.5b — AGOTAMIENTO (con histéresis para evitar parpadeo)
# ──────────────────────────────────────────────────────────────
func _actualizar_agotamiento() -> void:
	var nuevo_estado: bool = _sin_energia
	if not _sin_energia and _energia_actual <= 0.0:
		nuevo_estado = true
	elif _sin_energia and _energia_actual >= float(energia_max) * porcentaje_recuperacion_energia:
		nuevo_estado = false

	if nuevo_estado != _sin_energia:
		_sin_energia = nuevo_estado
		agotamiento_cambio.emit(_sin_energia)
		print("[Stats] 🥵 Agotamiento: ", _sin_energia)

func esta_sin_energia() -> bool:
	return _sin_energia

# ¿Puede correr ahora? No si está agotado o sin energía
func puede_correr() -> bool:
	return not _sin_energia and _energia_actual > 0.0

# Multiplicador de velocidad actual (1.0 normal, reducido si agotado)
func get_multiplicador_velocidad() -> float:
	if _sin_energia:
		return multiplicador_velocidad_agotado
	return 1.0
