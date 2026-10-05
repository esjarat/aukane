extends Resource
class_name ItemDefinicion

@export var id: StringName
@export var nombre_visible: String
@export var icono: Texture2D
@export var descripcion: String
@export var precio_compra: int = 1
@export var precio_venta: int = 0
@export var tipo: StringName = &"recurso"   # recurso / herramienta / consumible / semilla / cultivo / arma
@export var stack_maximo: int = 99
@export var herramienta_tipo: StringName = &""  # Solo si tipo=herramienta: hacha / pico / azada / regadera / espada

@export var datos_extra : Dictionary = {}
