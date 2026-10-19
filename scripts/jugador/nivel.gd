class_name Nivel
extends Node

# ═══════════════════════════════════════════════════════════════
# Nivel — Componente de progresión (FASE 12.1)
# Node HIJO del jugador (mismo patrón que Damageable y Stats).
# NUNCA por herencia: el jugador conserva su lógica de movimiento.
# ═══════════════════════════════════════════════════════════════

# ── Señales (el HUD se pinta SIN polling) ──
signal xp_cambio(xp_actual: int, xp_necesaria: int)
signal nivel_subido(nuevo_nivel: int)

# ── Configuración (balance = editar en el Inspector, no en código) ──
## XP necesaria para pasar del nivel 1 al 2 (umbral base de la curva).
@export var xp_base: int = 100
## Exponente de la curva: umbral(nivel) = xp_base * nivel^exponente.
## 1.0 = lineal (100, 200, 300...). 1.5 = curva clásica de RPG.
@export var exponente_curva: float = 1.1

# ── Estado (xp_actual = progreso DENTRO del nivel actual) ──
var nivel: int = 1
var xp_actual: int = 0
var xp_siguiente_nivel: int = 0

func _ready() -> void:
	_recalcular_umbral()
	# Estado inicial: el HUD (12.4) se pintará en el primer frame.
	xp_cambio.emit(xp_actual, xp_siguiente_nivel)

# ──────────────────────────────────────────────────────────────
# API PÚBLICA
# ──────────────────────────────────────────────────────────────
func ganar_xp(cantidad: int) -> void:
	if cantidad <= 0:
		return
	xp_actual += cantidad
	# Bucle (no "if"): una sola muerte puede subir VARIOS niveles de golpe.
	while xp_actual >= xp_siguiente_nivel:
		xp_actual -= xp_siguiente_nivel
		nivel += 1
		_recalcular_umbral()
		nivel_subido.emit(nivel)
		print("[Nivel] ⬆️ Nivel ", nivel, " | siguiente umbral: ", xp_siguiente_nivel, " XP")
	xp_cambio.emit(xp_actual, xp_siguiente_nivel)

func get_nivel() -> int:
	return nivel

func get_xp_actual() -> int:
	return xp_actual

func get_xp_siguiente() -> int:
	return xp_siguiente_nivel

# ──────────────────────────────────────────────────────────────
# INTERNO
# ──────────────────────────────────────────────────────────────
func _recalcular_umbral() -> void:
	xp_siguiente_nivel = int(round(float(xp_base) * pow(float(nivel), exponente_curva)))
	if xp_siguiente_nivel <= 0:
		xp_siguiente_nivel = xp_base

# ──────────────────────────────────────────────────────────────
# PUNTO ÚNICO de reparto: dado el atacante que mató, decide quién
# recibe la XP. Así EnemigoBase/AnimalBase no duplican la regla ni
# conocen la estructura interna del jugador (escala a co-op).
# ──────────────────────────────────────────────────────────────
static func otorgar_xp_a_atacante(p_atacante: Node, p_cantidad: int) -> void:
	if p_atacante == null or p_cantidad <= 0:
		return
	if not p_atacante.is_in_group("jugador"):
		return
	var comp: Node = p_atacante.get_node_or_null("Nivel")
	if comp != null and comp.has_method("ganar_xp"):
		comp.call("ganar_xp", p_cantidad)
