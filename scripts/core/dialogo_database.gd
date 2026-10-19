# scripts/core/dialogo_database.gd
extends Node

# ═══════════════════════════════════════════════════════════════
# SINGLETON AUTOLOAD: Base de datos GLOBAL de TODOS los diálogos del juego.
# Cargo TODOS .tres de `recursos/dialogos/` en _ready() en un Dictionary indexado por StringName
# ═══════════════════════════════════════════════════════════════

const DIRECTORIO_DIALOGOS: String = "res://recursos/dialogos/"

# Key: id_dialogo StringName → Value: DialogoDefinicion (la instancia Resource cargada)
var _dialogos_por_id: Dictionary = {}


func _ready() -> void:
	_cargar_todos_dialogos_desde_carpeta()
	print("[DialogoDB] ✅ Cargados %d diálogos desde %s" % [_dialogos_por_id.size(), DIRECTORIO_DIALOGOS])


# ──────────────────────────────────────────────────────────────
# CARGA (igual que Armas: escaneo carpeta, 0 hardcode
# ──────────────────────────────────────────────────────────────
func _cargar_todos_dialogos_desde_carpeta() -> void:
	# Godot 4.x: DirAccess.list_dir_begin() NO ACEPTA parámetros.
	# Siempre incluye "." y ".." — filtramos con if nombre_archivo.begins_with(".")
	var dir: DirAccess = DirAccess.open(DIRECTORIO_DIALOGOS)
	if dir == null:
		push_warning("[DialogoDB] ⚠️ NO EXISTE el directorio: " + DIRECTORIO_DIALOGOS + " | Error de DirAccess: " + str( int(DirAccess. get_open_error())))
		return

	# Godot 4.x: NO arguments
	dir.list_dir_begin()
	var nombre_archivo: String = dir.get_next()
	while nombre_archivo != "":
		# 0) Saltar "." , ".." y cualquier archivo oculto empiece por punto
		if not nombre_archivo.begins_with("."):
			# 1) Solo .tres
			if nombre_archivo.ends_with(".tres"):
				var ruta_completa: String = DIRECTORIO_DIALOGOS + nombre_archivo
				var recurso_cargado: Resource = load(ruta_completa)
				if recurso_cargado != null and recurso_cargado is DialogoDefinicion:
					var d: DialogoDefinicion = recurso_cargado as DialogoDefinicion
					if d.id_dialogo == &"":
						push_warning("[DialogoDB] ⚠️ Diálogo sin id: " + ruta_completa)
					elif _dialogos_por_id.has(d.id_dialogo):
						push_warning("[DialogoDB] ⚠️ Diálogo DUPLICADO (id repetido): " + String(d.id_dialogo))
					else:
						_dialogos_por_id[d.id_dialogo] = d
						print("[DialogoDB] 📜 Cargado diálogo '%s' desde %s" % [d.id_dialogo, ruta_completa])
				else:
					if not nombre_archivo.ends_with(".import"):
						push_warning("[DialogoDB] ⚠️ Archivo .tres no es DialogoDefinicion válido: " + ruta_completa)
		nombre_archivo = dir.get_next()
	dir.list_dir_end()


# ──────────────────────────────────────────────────────────────
# API PÚBLICA (usa esta desde NPC / UI)
# ──────────────────────────────────────────────────────────────
func get_dialogo(p_id_dialogo: StringName) -> DialogoDefinicion:
	if _dialogos_por_id.has(p_id_dialogo):
		return _dialogos_por_id[p_id_dialogo]
	push_warning("[DialogoDB] ❓ No existe diálogo con ID: " + String(p_id_dialogo))
	return null


func existe_dialogo(p_id_dialogo: StringName) -> bool:
	return _dialogos_por_id.has(p_id_dialogo)
