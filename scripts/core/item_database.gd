extends Node

var items: Dictionary[StringName, ItemDefinicion] = {}

func _ready() -> void:
	# Cargamos TODOS los items .tres de la carpeta assets/items/
	var items_a_cargar := [
		preload("res://assets/items/item_madera.tres"),
		preload("res://assets/items/item_piedra.tres"),
		preload("res://assets/items/item_oro.tres"),
		preload("res://assets/items/item_semilla.tres"),
		preload("res://assets/items/item_hacha.tres"),
		preload("res://assets/items/item_pico.tres"),
		preload ( "res://assets/items/item_azada.tres" ), 
		preload ( "res://assets/items/item_regadera.tres" ), 
		preload ( "res://assets/items/item_semilla_tomate.tres" ), 
		preload ( "res://assets/items/item_semilla_zanahoria.tres" ), 
		preload ( "res://assets/items/item_tomate.tres" ), 
		preload ( "res://assets/items/item_zanahoria.tres" ),
	]
	
	for item_recurso in items_a_cargar:
		items[item_recurso.id] = item_recurso
	
	print("[ItemDatabase] Cargados ", items.size(), " items correctamente.")

# Función helper rápida para buscar un item (con validación de seguridad)
func get_item(id: StringName) -> ItemDefinicion:
	if items.has(id):
		return items[id]
	push_error("ItemDatabase.get_item: ID de item no encontrado: " + str(id))
	return null
