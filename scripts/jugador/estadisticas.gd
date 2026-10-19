class_name Estadisticas
extends Node

# ═══════════════════════════════════════════════════════════════
# Estadisticas — Atributos de combate y crecimiento (FASE 12.2)
# Node HIJO del jugador (mismo patrón componente que Damageable,
# Stats y Nivel). NUNCA por herencia.
# ═══════════════════════════════════════════════════════════════

signal estadisticas_cambiadas

# ── Atributos ──
@export var fuerza: int = 5
@export var constitucion: int = 5
@export var destreza: int = 5

## Valor NEUTRO de un atributo. Con los tres en este valor, el juego se
## comporta igual que antes de 12.2 (cero regresión de balance).
## Ponlo a 0 si quieres las fórmulas literales del plan.
@export var atributo_base: int = 5

## Cuánto sube cada atributo al subir de nivel (la suma = puntos por
## nivel). Añadir un atributo nuevo = @export arriba + clave aquí.
@export var crecimiento_por_nivel: Dictionary = {
	"fuerza": 1,
	"constitucion": 1,
	"destreza": 1,
}
## Abreviatura mostrada en el HUD por cada atributo. DEBE tener las mismas
## claves que crecimiento_por_nivel. Añadir un atributo nuevo = una línea
## aquí + su @export arriba; el HUD no se toca.
@export var abreviaturas: Dictionary = {
	"fuerza": "FUE",
	"constitucion": "CON",
	"destreza": "DES",
}
# ── Derivadas (todo calibrable por Inspector) ──
@export var vida_base: int = 100
@export var vida_por_constitucion: int = 10
@export var daño_por_fuerza: float = 2.0
## Reducción de cooldown por punto de Destreza sobre la base (0.02 = 2%).
@export var reduccion_cooldown_por_destreza: float = 0.02
## Tope: el cooldown nunca baja de este multiplicador (0.5 = la mitad).
@export var reduccion_cooldown_maxima: float = 0.5

var _nivel: Node = null

func _ready() -> void:
	# Componente hermano: el Nivel del MISMO jugador.
	_nivel = get_parent().get_node_or_null("Nivel")
	if _nivel == null:
		push_warning("[Estadisticas] No existe el nodo hermano 'Nivel'. Los atributos no crecerán.")
		return
	if _nivel.has_signal("nivel_subido"):
		_nivel.nivel_subido.connect(_on_nivel_subido)

# ── Derivadas: lo que leen jugador.gd y Damageable ──
func get_vida_max() -> int:
	return vida_base + (constitucion - atributo_base) * vida_por_constitucion

func get_bono_daño() -> int:
	return int(round(float(fuerza - atributo_base) * daño_por_fuerza))

## Multiplicador del cooldown del arma. 1.0 = sin cambio.
func get_multiplicador_cooldown() -> float:
	var reduccion: float = float(destreza - atributo_base) * reduccion_cooldown_por_destreza
	return clampf(1.0 - reduccion, reduccion_cooldown_maxima, 1.0)

# ── Crecimiento por nivel (data-driven: itera la tabla, cero hardcodeo) ──
func _on_nivel_subido(_nuevo_nivel: int) -> void:
	_aplicar_crecimiento()

func _aplicar_crecimiento() -> void:
	for clave: String in crecimiento_por_nivel:
		if get(clave) == null:
			push_warning("[Estadisticas] Crecimiento ignorado: no existe el atributo '" + clave + "'.")
			continue
		set(clave, int(get(clave)) + int(crecimiento_por_nivel[clave]))
	print("[Estadisticas] ⬆️ fuerza=", fuerza, " | constitucion=", constitucion, " | destreza=", destreza)
	estadisticas_cambiadas.emit()
# ── Texto del panel de atributos del HUD (100% derivado de datos) ──
## Línea 1: los atributos, generados recorriendo 'abreviaturas'.
## Línea 2: las derivadas que de verdad se notan en el juego.
func get_texto_hud() -> String:
	var partes: PackedStringArray = []
	for clave: String in abreviaturas:
		if get(clave) == null:
			push_warning("[Estadisticas] Abreviatura sin atributo: '" + clave + "'.")
			continue
		partes.append("%s %d" % [str(abreviaturas[clave]), int(get(clave))])
	var bono: int = get_bono_daño()
	var texto_bono: String = ("+%d" % bono) if bono >= 0 else str(bono)
	return "%s\nVida %d   Daño %s   Ataque ×%.2f" % [
		"  ".join(partes),
		get_vida_max(),
		texto_bono,
		get_multiplicador_cooldown(),
	]
