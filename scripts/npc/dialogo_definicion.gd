class_name DialogoDefinicion
# scripts/npc/dialogo_definicion.gd
extends Resource


# ═══════════════════════════════════════════════════════════════
# RESOURCE DATA-DRIVEN: Un diálogo COMPLETO de un NPC.
# Cada instancia .tres de ESTA = UN diálogo único.
# ═══════════════════════════════════════════════════════════════

# Identificador ÚNICO global. Formato recomendado: "<npc_id>_<accion>
# Ej: &"mercader_saludo_inicial", &"mercader_comprar"
@export var id_dialogo: StringName = &""
# NPC al que pertenece este diálogo
@export var npc_id_propietario: StringName = &""
# Título / nombre del NPC que se muestra en la UI (ej: "Don Mercader")
@export var nombre_mostrar_npc: String = "NPC sin nombre"
# Array de LÍNEAS del diálogo (se muestran en orden pulsando ENTER/Click)
@export var lineas: Array[Resource] = []
# Array de OPCIONES que aparecen DESPUÉS de la ÚLTIMA línea (si hay opciones no hay
# siguiente_dialogo)
@export var opciones: Array[Resource] = []
# (Opcional) Si NO hay opciones, al terminar las líneas se salta automáticamente a este diálogo
@export var id_dialogo_siguiente_automatico: StringName = &""
# (Opcional) Acción especial al terminar:
# Valores posibles:
#   &""                = No hace nada
#   &"abrir_tienda"   = Abre la UI Tienda tras cerrar diálogo
#   &"dar_quest_X"      = (para FASE 4.3)
#   &"cerrar"         = Cerrar diálogo y volver al mundo
@export var accion_al_terminar: StringName = &""

# (Opcional) Parámetro numérico que viaja CON la acción especial.
# Ej: accion_al_terminar = &"abrir_tienda" + parametro_accion = 1
#      → abrir la tienda en la pestaña "Vender". El número vive en el .tres.
@export var parametro_accion: int = 0

func tiene_opciones() -> bool:
	return opciones.size() > 0


func tiene_siguiente_automatico() -> bool:
	return id_dialogo_siguiente_automatico != &""


func tiene_accion_especial() -> bool:
	return accion_al_terminar != &""


func get_accion_string() -> String:
	return String(accion_al_terminar)


# ──────────────────────────────────────────────────────────────
# HELPERS TIPADOS (casteo y validación en runtime — 100% compatible)
# Llamar a ESTOS desde la UI (NO usar .lineas[0] directamente)
# ──────────────────────────────────────────────────────────────
func get_linea(index: int) -> DialogoLinea:
	if index < 0 or index >= lineas.size():
		return null
	var r: Resource = lineas[index]
	if r is DialogoLinea:
		return r as DialogoLinea
	return null


func get_cantidad_lineas() -> int:
	return lineas.size()


func get_opcion(index: int) -> DialogoOpcion:
	if index < 0 or index >= opciones.size():
		return null
	var r: Resource = opciones[index]
	if r is DialogoOpcion:
		return r as DialogoOpcion
	return null


func get_cantidad_opciones() -> int:
	return opciones.size()
