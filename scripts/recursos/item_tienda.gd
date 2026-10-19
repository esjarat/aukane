extends Resource
class_name ItemTienda

# ═══════════════════════════════════════════════════════════════
# Una ENTRADA del catálogo de una tienda.
# Define QUÉ item vende/compra la tienda y a QUÉ precio.
# ═══════════════════════════════════════════════════════════════

# ID del item que vende/compra (debe existir en ItemDatabase)
@export var id_item: StringName = &""

# Precio al que la TIENDA VENDE el item (lo paga el jugador)
@export var precio_compra_jugador: int = 0

# Precio al que la TIENDA COMPRA el item (lo paga la tienda al jugador)
# 0 = la tienda NO compra este item
@export var precio_venta_jugador: int = 0

# Cantidad máxima que la tienda tiene en stock (-1 = infinito)
@export var stock: int = -1

# Nombre visible para mostrar en la UI (se toma de ItemDefinicion si está vacío)
@export var nombre_override: String = ""
