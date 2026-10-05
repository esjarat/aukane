extends Control

@onready var btn_hacha: TextureButton = $HBoxContainer/BtnEquiparHacha
@onready var btn_pico: TextureButton = $HBoxContainer/BtnEquiparPico

func _ready() -> void:
	btn_hacha.pressed.connect(_on_hacha_pressed)
	btn_pico.pressed.connect(_on_pico_pressed)
	# Actualizamos por señal también, no por _process
	Inventario.inventario_cambiado.connect(_actualizar_botones)
	Inventario.herramienta_equipada_cambiada.connect(func(_a, _b): _actualizar_botones())
	_actualizar_botones()

# Ya no usamos _process() 🙌
func _actualizar_botones() -> void:
	# --- HACHA ---
	if not Inventario.tiene_item(&"hacha", 1):
		btn_hacha.modulate = Color(0.4, 0.4, 0.4, 1)  # Gris = no la tienes
	else:
		if Inventario.herramienta_equipada == &"hacha":
			btn_hacha.modulate = Color(0.2, 1.0, 0.2, 1)  # Verde = equipada
		else:
			btn_hacha.modulate = Color(1.0, 1.0, 1.0, 1)  # Normal = lista

	# --- PICO ---
	if not Inventario.tiene_item(&"pico", 1):
		btn_pico.modulate = Color(0.4, 0.4, 0.4, 1)
	else:
		if Inventario.herramienta_equipada == &"pico":
			btn_pico.modulate = Color(0.2, 1.0, 0.2, 1)
		else:
			btn_pico.modulate = Color(1.0, 1.0, 1.0, 1)

func _on_hacha_pressed() -> void:
	if not Inventario.tiene_item(&"hacha", 1):
		if Inventario.craftear("hacha"):
			Inventario.equipar_herramienta(&"hacha")
	else:
		Inventario.equipar_herramienta(&"hacha")

func _on_pico_pressed() -> void:
	if not Inventario.tiene_item(&"pico", 1):
		if Inventario.craftear("pico"):
			Inventario.equipar_herramienta(&"pico")
	else:
		Inventario.equipar_herramienta(&"pico")
