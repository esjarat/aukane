class_name Cama
# scripts/mundo/cama.gd
# Objeto interactuable que avanza el tiempo y restaura energía.
# Patrón idéntico a pozo.gd (F / get_prompt / puede_interactuar / interactuar).
extends StaticBody3D

# ═══════════════════════════════════════════════════════════════
# 1) EXPORT (ajustable por Inspector)
# ═══════════════════════════════════════════════════════════════
@export var horas_a_dormir: int = 8
@export var solo_de_noche: bool = true
@export var energia_restaurada: int = 100

# ═══════════════════════════════════════════════════════════════
# 2) READY
# ═══════════════════════════════════════════════════════════════
func _ready() -> void:
	if not is_in_group("interactuables"):
		add_to_group("interactuables")

# ═══════════════════════════════════════════════════════════════
# 3) PATRÓN INTERACTUABLE
# ═══════════════════════════════════════════════════════════════
func puede_interactuar() -> bool:
	# Si solo se duerme de noche y es de día → no disponible
	if solo_de_noche and GestorTiempo.es_dia():
		return false
	return true

func get_prompt() -> String:
	if solo_de_noche and GestorTiempo.es_dia():
		return "[F] 😴 Solo puedes dormir de noche"
	return "[F] 😴 Dormir (" + str(horas_a_dormir) + "h)"

func interactuar(jugador: CharacterBody3D) -> void:
	# 1) Validación (por si se llama sin pasar por puede_interactuar)
	if solo_de_noche and GestorTiempo.es_dia():
		print("[Cama] ❌ Todavía es de día, no puedes dormir.")
		return

	# 2) Avanzar el reloj (horas → minutos de juego)
	GestorTiempo.avanzar_tiempo(horas_a_dormir * 60)

	# 3) Restaurar energía del jugador (busca su componente Stats)
	var stats: Node = jugador.get_node_or_null("Stats")
	if stats != null and stats.has_method("descansar"):
		stats.descansar(energia_restaurada)
		print("[Cama] ✅ Energía restaurada a ", stats.get_energia())

	print("[Cama] 😴 Has dormido. Ahora son las ", GestorTiempo.get_tiempo_texto())
