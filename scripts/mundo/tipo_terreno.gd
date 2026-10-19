class_name TipoTerreno
extends Resource

# ═══════════════════════════════════════════════════════════════
# TipoTerreno — Define UN bioma del suelo (FASE 10.9)
# Añadir un bioma nuevo = crear un .tres nuevo. Cero hardcodeo.
# ═══════════════════════════════════════════════════════════════

@export var id: StringName = &""
@export var nombre_visible: String = ""
@export var color: Color = Color(0.4, 0.4, 0.4)
@export var textura: Texture2D = null   # opcional: si está rellena, tiene prioridad sobre color
@export var altura: float = 0.0         # elevación de la celda (0.0 = plano)
@export var es_agua: bool = false       # el clima y la Fase 12 lo usarán (pesca, reflejos, lentitud)
@export var es_cultivable: bool = true  # solo estos biomas admiten huerto
