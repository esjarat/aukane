extends Resource
class_name IngredienteReceta

# ═══════════════════════════════════════════════════════════════
# Un INGREDIENTE de una receta de crafteo.
# Se usa dentro del Array "ingredientes" de RecetaCrafteo.
# ═══════════════════════════════════════════════════════════════

# ID del item que se necesita (debe existir en ItemDatabase)
@export var item_id: StringName = &""

# Cantidad necesaria de ese item
@export var cantidad: int = 1
