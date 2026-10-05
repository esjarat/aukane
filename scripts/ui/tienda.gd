extends Control

@onready var btn_comprar: Button = $BotonComprarSemilla
@onready var btn_comprar_tomate: Button = $BotonComprarTomate
@onready var btn_comprar_zanahoria: Button = $BotonComprarZanahoria
@onready var btn_cerrar: Button = $BotonCerrar

var _npc_owner: Node = null

func asignar_npc_owner(npc: Node) -> void:
	_npc_owner = npc

func _ready() -> void:
	if not btn_comprar.pressed.is_connected(_on_btn_comprar_pressed):
		btn_comprar.pressed.connect(_on_btn_comprar_pressed)
	if not btn_comprar_tomate.pressed.is_connected(_on_btn_comprar_tomate_pressed):
		btn_comprar_tomate.pressed.connect(_on_btn_comprar_tomate_pressed)
	if not btn_comprar_zanahoria.pressed.is_connected(_on_btn_comprar_zanahoria_pressed):
		btn_comprar_zanahoria.pressed.connect(_on_btn_comprar_zanahoria_pressed)
	if not btn_cerrar.pressed.is_connected(_on_btn_cerrar_pressed):
		btn_cerrar.pressed.connect(_on_btn_cerrar_pressed)

func _on_btn_comprar_pressed() -> void:
	_comprar_item(&"semilla", 2, "Semilla Básica")

func _on_btn_comprar_tomate_pressed() -> void:
	_comprar_item(&"semilla_tomate", 3, "Semilla de Tomate")

func _on_btn_comprar_zanahoria_pressed() -> void:
	_comprar_item(&"semilla_zanahoria", 2, "Semilla de Zanahoria")

func _comprar_item(id_item: StringName, costo_oro: int, nombre_visible: String) -> void:
	print("[TIENDA] Comprando ", nombre_visible, " (", costo_oro, " oro)")
	if Inventario.gastar_item(&"oro", costo_oro):
		Inventario.agregar_item(id_item, 1)
		print("[TIENDA] ✅ Compra OK: ", nombre_visible)
	else:
		print("[TIENDA] ❌ Oro insuficiente. Tienes ", Inventario.get_cantidad(&"oro"), " oro.")
	_debug_inventario()

func _debug_inventario() -> void:
	print("\n📦 DEBUG INVENTARIO (POST COMPRA):")
	for indice in Inventario.slots.size():
		var slot: Dictionary = Inventario.get_slot(indice)
		if not slot.is_empty():
			var id_item: StringName = slot.id
			var def: ItemDefinicion = ItemDatabase.get_item(id_item)
			var nom: String = def.nombre_visible if def != null else "???"
			print("   [Slot ", indice, "] ", id_item, " (", nom, ") x", slot.cantidad)
	print("═══════════════════════════════════\n")

func _on_btn_cerrar_pressed() -> void:
	if _npc_owner != null:
		_npc_owner.cerrar_tienda()
