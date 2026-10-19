extends Node

# ──────────────────────────────────────────────────────────────
# SINGLETON / AUTOLOAD — Estado Global del Juego
# Cualquier script puede leer/escribir GameState.lo_que_sea
# ──────────────────────────────────────────────────────────────

# Posibles modos del juego (constantes, evitamos "magic strings")
const MODO_MUNDO: StringName = &"mundo"       # Caminando, explorando (inputs normales)
const MODO_UI: StringName = &"ui"             # Menú / Tienda / Diálogo (inputs mundo desactivados)
const MODO_COMBATE: StringName = &"combate"   # (FASE 3) Combate activo
const MODO_PAUSA: StringName = &"pausa"       # Menú pausa

# ──────────────────────────────────────────────────────────────
# VARIABLE PRIVADA + SETTER (con validación y señal)
# ──────────────────────────────────────────────────────────────
var modo_actual: StringName = MODO_MUNDO:
	set(valor_nuevo):
		if modo_actual == valor_nuevo:
			return  # No cambiamos si es el mismo
		var modo_anterior = modo_actual
		modo_actual = valor_nuevo
		print("[GameState] Modo cambiado: ", str(modo_anterior), " → ", str(modo_actual))
		modo_cambiado.emit(modo_anterior, modo_actual)

signal modo_cambiado(modo_anterior: StringName, modo_nuevo: StringName)


# ──────────────────────────────────────────────────────────────
# HELPERS para no estar comparando Strings por todos lados
# ──────────────────────────────────────────────────────────────
func esta_en_modo_mundo() -> bool:
	return modo_actual == MODO_MUNDO


func esta_en_modo_ui() -> bool:
	return modo_actual == MODO_UI
# ──────────────────────────────────────────────────────────────
# FASE 13.4 — JEFES DERROTADOS
# ⚠️ Vive SOLO en memoria: el proyecto aún no tiene sistema de
# guardado (no hay FileAccess/user://). Al cerrar el juego se
# pierde. Cuando exista guardado, basta serializar este Dictionary.
# ──────────────────────────────────────────────────────────────

## id_enemigo del jefe → true si ya fue derrotado en esta partida.
var jefes_derrotados: Dictionary[StringName, bool] = {}

func marcar_jefe_derrotado(p_id_jefe: StringName) -> void:
	if p_id_jefe == &"":
		push_warning("[GameState] marcar_jefe_derrotado con id vacío: usa 'id_enemigo' del jefe.")
		return
	if jefes_derrotados.get(p_id_jefe, false):
		return
	jefes_derrotados[p_id_jefe] = true
	print("[GameState] ☠️ Jefe DERROTADO: ", p_id_jefe)

func esta_jefe_derrotado(p_id_jefe: StringName) -> bool:
	if p_id_jefe == &"":
		return false
	return jefes_derrotados.get(p_id_jefe, false)
