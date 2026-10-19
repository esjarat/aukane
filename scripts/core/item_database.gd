extends Node

# ──────────────────────────────────────────────────────────────
# DIRECTORIO DE ITEMS (data-driven: añadir un item = crear el .tres)
# ──────────────────────────────────────────────────────────────
const DIRECTORIO_ITEMS: String = "res://assets/items/"

var items: Dictionary[StringName, ItemDefinicion] = {}

func _ready() -> void:
	# FASE 10.5: carga DATA-DRIVEN por carpeta (antes: 26 preload() a mano).
	# Cualquier .tres de tipo ItemDefinicion en assets/items/ se carga solo,
	# usando su campo 'id' como clave. Añadir un item = crear el .tres.
	var dir: DirAccess = DirAccess.open(DIRECTORIO_ITEMS)
	if dir == null:
		push_error("[ItemDatabase] ⚠️ NO EXISTE el directorio: " + DIRECTORIO_ITEMS)
		return

	dir.list_dir_begin()
	var nombre_archivo: String = dir.get_next()
	while nombre_archivo != "":
		if not nombre_archivo.begins_with(".") and nombre_archivo.ends_with(".tres"):
			var ruta: String = DIRECTORIO_ITEMS + nombre_archivo
			var recurso: Resource = load(ruta)
			if recurso != null and recurso is ItemDefinicion:
				var item: ItemDefinicion = recurso as ItemDefinicion
				if item.id == &"":
					push_warning("[ItemDatabase] ⚠️ Item sin campo 'id': " + ruta)
				else:
					items[item.id] = item
			else:
				push_warning("[ItemDatabase] ⚠️ .tres no es ItemDefinicion: " + ruta)
		nombre_archivo = dir.get_next()
	dir.list_dir_end()

	print("[ItemDatabase] Cargados ", items.size(), " items correctamente.")

# Función helper rápida para buscar un item (con validación de seguridad)
func get_item(id: StringName) -> ItemDefinicion:
	if items.has(id):
		return items[id]
	push_error("ItemDatabase.get_item: ID de item no encontrado: " + str(id))
	return null
