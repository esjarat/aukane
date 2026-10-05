extends Control

@onready var btn_hacha: Button = $HBoxContainer/BtnEquiparHacha
@onready var btn_pico: Button  = $HBoxContainer/BtnEquiparPico
@onready var btn_azada: Button  = $HBoxContainer/BtnEquiparAzada
@onready var btn_regadera: Button  = $HBoxContainer/BtnEquiparRegadera

func _ready() -> void:
	btn_hacha.pressed.connect(_on_hacha_pressed)
	btn_pico.pressed.connect(_on_pico_pressed)
	btn_azada.pressed.connect(_on_azada_pressed)
	btn_regadera.pressed.connect(_on_regadera_pressed)
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

	# --- AZADA --- ⭐ NUEVO
	if not Inventario.tiene_item(&"azada", 1):
 	# Si NO la tienes: Gris 
		btn_azada.modulate = Color(0.4, 0.4, 0.4, 1)
	else: 
		# Si la tienes: BLANCO si NO equipada / VERDE si SÍ equipada 
		if Inventario.herramienta_equipada == &"azada":
			btn_azada.modulate = Color(0.2, 1.0, 0.2, 1)
		else:
			btn_azada.modulate = Color(1.0, 1.0, 1.0, 1)
			
	# --- REGADERA --- ⭐ NUEVO
	if not Inventario.tiene_item(&"regadera", 1):
 	# Si NO la tienes: Gris 
		btn_regadera.modulate = Color(0.4, 0.4, 0.4, 1)
	else: 
		# Si la tienes: BLANCO si NO equipada / VERDE si SÍ equipada 
		if Inventario.herramienta_equipada == &"regadera":
			btn_regadera.modulate = Color(0.2, 1.0, 0.2, 1)
		else:
			btn_regadera.modulate = Color(1.0, 1.0, 1.0, 1)
			
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
		
func _on_azada_pressed() -> void:
	if not Inventario.tiene_item(&"azada", 1):
		# NO la tienes → INTENTAS CRAFTEARLA
		if Inventario.craftear("azada"):
			# Si crafteo OK → equiparla inmediatamente (mejor UX)
			Inventario.equipar_herramienta(&"azada")
	else:
		# SÍ la tienes → TOGGLE equipar/desequipar
		Inventario.equipar_herramienta(&"azada")
		
func _on_regadera_pressed() -> void:
	if not Inventario.tiene_item(&"regadera", 1):
		# NO la tienes → INTENTAS CRAFTEARLA
		if Inventario.craftear("regadera"):
			# Si crafteo OK → equiparla inmediatamente (mejor UX)
			Inventario.equipar_herramienta(&"regadera")
	else:
		# SÍ la tienes → TOGGLE equipar/desequipar
		Inventario.equipar_herramienta(&"regadera")
