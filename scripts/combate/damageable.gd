class_name Damageable
# scripts/combate/damageable.gd
extends Node

# ═══════════════════════════════════════════════════════════════
# 1) SEÑALES (las que emite Damageable para que otros escuchen)
# ═══════════════════════════════════════════════════════════════
signal danio_recibido(cantidad: int, atacante: NodePath)
signal murio(atacante: NodePath)
signal vida_cambio(vida_nueva: int)

# ═══════════════════════════════════════════════════════════════
# 2) VARIABLES EXPORT (configurables POR CADA ENTIDAD desde el Inspector)
# ═══════════════════════════════════════════════════════════════
@export var vida_maxima: int = 100        # Jugador 100, Slime 20, Arbol 3
@export var tiempo_invulnerabilidad: float = 0.5   # Segundos i-frames tras golpe
@export var es_invulnerable: bool = false  # Marca true para que NUNCA reciba daño (debug/cheats)

# ═══════════════════════════════════════════════════════════════
# 3) VARIABLES INTERNAS (privada
# ═══════════════════════════════════════════════════════════════
var _vida_actual: int = 0
var _temporizador_invulnerabilidad: float = 0.0
var _esta_muerto: bool = false

# ═══════════════════════════════════════════════════════════════
# 4) READY: Inicializar vida actual a vida_maxima
# ═══════════════════════════════════════════════════════════════
func _ready() -> void:
	_vida_actual = vida_maxima
	_esta_muerto = false
	# Emitir señal de inicio para que HUD/otros sepan la vida desde el primer frame
	vida_cambio.emit(_vida_actual)
	print(
		"[Damageable] Inicializado en ",
		get_parent().name,
		" | HP: ",
		_vida_actual,
		"/",
		vida_maxima,
	)

# ═══════════════════════════════════════════════════════════════
# 5) _PROCESS: Contar i-frames hacia atrás
# ═══════════════════════════════════════════════════════════════
func _process(delta: float) -> void:
	if _temporizador_invulnerabilidad > 0.0:
		_temporizador_invulnerabilidad = max(0.0, _temporizador_invulnerabilidad - delta)

# ═══════════════════════════════════════════════════════════════
# 6) MÉTODO PÚBLICO PRINCIPAL: RECIBIR DAÑO
#    LLAMAN DESDE FUERA (jugador, enemigo, hacha, etc.)
# ═══════════════════════════════════════════════════════════════
func recibir_danio(cantidad: int, atacante: Node = null) -> void:
	# a) Validaciones de guardia (si no pasan → early return, no pasa nada)
	if _esta_muerto:
		return
	if es_invulnerable:
		print("[Damageable] ", get_parent().name, " ES INVULNERABLE, no daño.")
		return
	if cantidad <= 0:
		push_warning("[Damageable] Daño <= 0 ignorado.")
		return
	if _temporizador_invulnerabilidad > 0.0:
		# En i-frames → no recibe daño (return silencioso, no spam)
		return

	# b) Restar vida
	_vida_actual = max(0, _vida_actual - cantidad)

	# c) Activar invulnerabilidad temporal (i-frames)
	_temporizador_invulnerabilidad = tiempo_invulnerabilidad

	# d) Emitir señales
	var atacante_path: NodePath = atacante.get_path() if atacante != null else NodePath("")
	danio_recibido.emit(cantidad, atacante_path)
	vida_cambio.emit(_vida_actual)
	print(
		"[Damageable] ",
		get_parent().name,
		" recibe ",
		cantidad,
		" daño → HP ",
		_vida_actual,
		"/",
		vida_maxima,
	)

	# e) ¿Murió?
	if _vida_actual <= 0:
		_esta_muerto = true
		murio.emit(atacante_path)
		print("[Damageable] 💀 ", get_parent().name, " MURIÓ.")

# ═══════════════════════════════════════════════════════════════
# 7) MÉTODO PÚBLICO: SANAR (comer tomate, usar poción)
# ═══════════════════════════════════════════════════════════════
func sanar(cantidad: int) -> void:
	if _esta_muerto:
		return
	if cantidad <= 0:
		return

	_vida_actual = min(vida_maxima, _vida_actual + cantidad)
	vida_cambio.emit(_vida_actual)
	print(
		"[Damageable] ",
		get_parent().name,
		" sana ",
		cantidad,
		" → HP ",
		_vida_actual,
		"/",
		vida_maxima,
	)
# ═══════════════════════════════════════════════════════════════
# 9) CAMBIAR LA VIDA MÁXIMA EN RUNTIME (subir Constitución, equipo...)
#    Si la máxima SUBE, se gana esa diferencia (no se queda con la
#    vida vieja). Si BAJA, se recorta la vida actual.
# ═══════════════════════════════════════════════════════════════
func set_vida_maxima(nueva_max: int, p_ajustar_actual: bool = true) -> void:
	if nueva_max <= 0:
		push_warning("[Damageable] Vida máxima inválida: " + str(nueva_max))
		return
	var anterior: int = vida_maxima
	vida_maxima = nueva_max
	if p_ajustar_actual and not _esta_muerto:
		_vida_actual += nueva_max - anterior
	_vida_actual = clampi(_vida_actual, 0, vida_maxima)
	vida_cambio.emit(_vida_actual)

# ═══════════════════════════════════════════════════════════════
# 8) GETTERS públicos (por si HUD/enemigos quiere LEER HP sin modificar)
# ═══════════════════════════════════════════════════════════════
func get_vida_actual() -> int:
	return _vida_actual

func get_vida_maxima() -> int:
	return vida_maxima

func esta_muerto() -> bool:
	return _esta_muerto

func esta_en_invulnerabilidad() -> bool:
	return _temporizador_invulnerabilidad > 0.0
