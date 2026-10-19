class_name RecompensaItem
extends Resource

# ═══════════════════════════════════════════════════════════════
# RecompensaItem — UNA entrada de botín garantizado (FASE 13.4)
#
# Resource con campos con NOMBRE y TIPO, en lugar de un Dictionary:
# una clave mal tecleada en un Dictionary falla EN SILENCIO, mientras
# que aquí el Inspector muestra dos casillas fijas e imposibles de
# confundir. Es la misma migración que se hizo en 13.1 con FaseDefinicion.
# ═══════════════════════════════════════════════════════════════

## ID del item a entregar. Debe existir en ItemDatabase.
@export var id_item: StringName = &""
## Cuántas unidades entrega. Mínimo 1 para que la entrada tenga efecto.
@export_range(1, 999, 1) var cantidad: int = 1
