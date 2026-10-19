class_name ItemDefinicion
extends Resource

@export var id: StringName
@export var nombre_visible: String
@export var icono: Texture2D
@export var emoji_hud: String = ""
@export var descripcion: String
@export var precio_compra: int = 1
@export var precio_venta: int = 0
@export var tipo: StringName = &"recurso"
@export var stack_maximo: int = 99
@export var herramienta_tipo: StringName = &""
@export var datos_extra: Dictionary = {}
@export var es_estacion: bool = false
@export var tipo_estacion: StringName = &""
@export var hambre_restaurada: int = 0
@export var vida_restaurada: int = 0
## true = esta herramienta CREA y RETIRA parcelas de cultivo (pala).
## Cero hardcodeo: el jugador NO comprueba "¿es pala?", comprueba este flag.
@export var crea_parcela: bool = false
