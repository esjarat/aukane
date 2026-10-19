class_name DialogoOpcion
# scripts/npc/dialogo_opcion.gd
extends Resource


# ═══════════════════════════════════════════════════════════════
# OPCIÓN de respuesta QUE PUEDE ELEGIR EL JUGADOR al final de un diálogo.
# Ej: Botón "¿Cuánto cuesta la semilla?"
# ═══════════════════════════════════════════════════════════════

# TEXTO del botón visible para el jugador
@export var texto_opcion: String = ""
# DIÁLÓGIA SIGUIENTE si el usuario elige ESTA opción.
# &"" = cerrar el diálogo (no salta a ningún lado)
@export var id_siguiente_dialogo: StringName = &""
# (Opcional FASE 4.3) REQUISITO para QUE ESTA OPCIÓN APAREZCA:
#   - item_requerido_id: StringName (ej &"semilla_tierra"
#   - item_cantidad_minima_requerida: int
#   - Si NO se cumple, esta opción NO se muestra o está deshabilitada
@export var id_item_requerido: StringName = &""
@export var cantidad_item_requerido: int = 0
# (Opcional FASE 4.3) Acción especial que se ejecuta al ELEGIR ESTA OPCIÓN.
# Ejemplos: &"aceptar_mision", &"abrir_tienda", &"" = no hace nada (solo cierra)
@export var accion_especial: StringName = &""

# (Opcional) Igual que en DialogoDefinicion.parametro_accion, para opciones.
@export var parametro_accion: int = 0

@export var requiere_mision_activa: StringName = &""
@export var requiere_mision_no_activa : StringName = &""
