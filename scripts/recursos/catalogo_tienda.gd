extends Resource
class_name CatalogoTienda

# ═══════════════════════════════════════════════════════════════
# CATÁLOGO completo de una tienda.
# Un NPC tienda tiene UN CatalogoTienda asignado.
# ═══════════════════════════════════════════════════════════════

@export var id_catalogo: StringName = &""
@export var nombre_tienda: String = "Tienda"
# Lista de items que vende/compra esta tienda
@export var items: Array[ItemTienda] = []

# ──────────────────────────────────────────────────────────────
# HELPERS
# ──────────────────────────────────────────────────────────────
func get_cantidad_items() -> int:
	return items.size()

func get_item(index: int) -> ItemTienda:
	if index < 0 or index >= items.size():
		return null
	return items[index]

# Busca la entrada del catálogo por id de item
func get_item_por_id(p_id: StringName) -> ItemTienda:
	for it in items:
		if it.id_item == p_id:
			return it
	return null

# ¿La tienda compra este item? (precio_venta_jugador > 0)
func tienda_compra_item(p_id: StringName) -> bool:
	var it: ItemTienda = get_item_por_id(p_id)
	if it == null:
		return false
	return it.precio_venta_jugador > 0
