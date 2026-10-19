extends Resource
class_name RecetaCrafteo

# ═══════════════════════════════════════════════════════════════
# Una RECETA de crafteo completa.
# Define: qué se fabrica, qué ingredientes se necesitan,
# en qué estación se fabrica y a qué categoría pertenece.
# ═══════════════════════════════════════════════════════════════

# Identificador único de la receta
@export var id: StringName = &""

# Item resultado (debe existir en ItemDatabase)
@export var id_resultado: StringName = &""
@export var cantidad_resultado: int = 1

# Lista de ingredientes necesarios
@export var ingredientes: Array[IngredienteReceta] = []

# Categoría para filtrar en la UI
# (herramientas / comida / edificios / mejoras)
@export var categoria: StringName = &"herramientas"

# Estación requerida para craftear
# (&"ninguna" = se puede craftear en cualquier sitio)
# (&"banco_trabajo", &"horno", &"yunque", ...)
@export var estacion_requerida: StringName = &"ninguna"

# ¿Está desbloqueada por defecto? (luego se puede bloquear por progreso)
@export var desbloqueada: bool = true
