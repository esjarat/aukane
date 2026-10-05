extends Node

# ──────────────────────────────────────────────────────────────
# ESTRUCTURA DE DATOS PRINCIPAL
# ──────────────────────────────────────────────────────────────
@export var tamano_maximo_slots: int = 20  # Cantidad de "celdas" en la mochila
var slots: Array[Dictionary] = []         # Cada slot = { id: StringName, cantidad: int } | {} = VACIO

var herramienta_equipada: StringName = &"puños"
var datos_variables_por_item: Dictionary[StringName, Dictionary] = {}
# ──────────────────────────────────────────────────────────────
# SEÑALES (COMUNICACIÓN CON UI Y OTROS SISTEMAS)
# ──────────────────────────────────────────────────────────────
signal inventario_cambiado()
signal item_agregado(id: StringName, cantidad: int)
signal item_gastado(id: StringName, cantidad: int)
signal herramienta_equipada_cambiada(herramienta_anterior: StringName, herramienta_nueva: StringName)

# ──────────────────────────────────────────────────────────────
# INICIALIZACIÓN
# ──────────────────────────────────────────────────────────────
func _ready() -> void:
	# Creamos la mochila VACÍA con el número de slots configurado
	for i in tamano_maximo_slots:
		slots.append({})  # {} = slot vacío
	
	# ✅ Items iniciales para testear (quita los que no quieras tener al empezar)
	# Más adelante esto se cargará desde un Save File
	agregar_item(&"madera", 5)
	agregar_item(&"piedra", 5)
	agregar_item(&"oro", 10)

# ──────────────────────────────────────────────────────────────
# MÉTODOS PRINCIPALES PÚBLICOS (API del Inventario)
# ──────────────────────────────────────────────────────────────

# Agrega un item al inventario. Devuelve true si TODO se agregó, false si faltó espacio.
func agregar_item(id: StringName, cantidad: int) -> bool:
	if cantidad <= 0:
		return false
	
	var definicion := ItemDatabase.get_item(id)
	if definicion == null:
		return false
	
	var cantidad_pendiente: int = cantidad
	
	# PRIMER PASO: Intentar STACKEAR en slots que ya tengan el MISMO item
	if definicion.stack_maximo > 1:
		for indice in range(slots.size()):
			if cantidad_pendiente <= 0:
				break
			
			var slot = slots[indice]
			if slot.is_empty() or slot.id != id:
				continue
			
			var espacio_en_slot: int = definicion.stack_maximo - slot.cantidad
			if espacio_en_slot > 0:
				var a_agregar: int = min(espacio_en_slot, cantidad_pendiente)
				slots[indice].cantidad += a_agregar
				cantidad_pendiente -= a_agregar
	
	# SEGUNDO PASO: Lo que faltó, meter en SLOTS VACÍOS
	while cantidad_pendiente > 0:
		var indice_vacio: int = _buscar_slot_vacio()
		if indice_vacio == -1:
			# No hay espacio → salimos sin agregar el resto
			inventario_cambiado.emit()
			if (cantidad - cantidad_pendiente) > 0:
				item_agregado.emit(id, cantidad - cantidad_pendiente)
			return false  # Faltó espacio
		
		var a_agregar: int = min(definicion.stack_maximo, cantidad_pendiente)
		slots[indice_vacio] = { "id": id, "cantidad": a_agregar }
		cantidad_pendiente -= a_agregar
	
	inventario_cambiado.emit()
	item_agregado.emit(id, cantidad)
	return true

# Gasta un item si hay suficiente. Devuelve true si se gastó TODO.
func gastar_item(id: StringName, cantidad: int) -> bool:
	if cantidad <= 0:
		return false
	if not tiene_item(id, cantidad):
		return false
	
	var cantidad_pendiente = cantidad
	
	for indice in range(slots.size()):
		if cantidad_pendiente <= 0:
			break
		
		var slot = slots[indice]
		if slot.is_empty() or slot.id != id:
			continue
		
		if slot.cantidad <= cantidad_pendiente:
			cantidad_pendiente -= slot.cantidad
			slots[indice] = {}  # Vaciar slot
		else:
			slots[indice].cantidad -= cantidad_pendiente
			cantidad_pendiente = 0
	
	inventario_cambiado.emit()
	item_gastado.emit(id, cantidad)
	return true

# Verifica si el jugador tiene al menos X cantidad de un item
func tiene_item(id: StringName, cantidad_minima: int = 1) -> bool:
	return get_cantidad(id) >= cantidad_minima

# Devuelve cuántas unidades hay TOTALES de un item (sumando todos los slots)
func get_cantidad(id: StringName) -> int:
	var total: int = 0
	for slot in slots:
		if not slot.is_empty() and slot.id == id:
			total += slot.cantidad
	return total

# Obtener datos de un slot por índice (devuelve diccionario o {} si vacío)
func get_slot(indice: int) -> Dictionary:
	if indice < 0 or indice >= slots.size():
		return {}
	return slots[indice]

# ──────────────────────────────────────────────────────────────
# SISTEMA DE EQUIPAR HERRAMIENTAS
# ──────────────────────────────────────────────────────────────

# ══════════════════════════════════════════════════════════════════
# FASE 2.5: Getter / Setter para DATOS VARIABLES por item
# (ej: carga de agua de la regadera, durabilidad de herramientas)
# ══════════════════════════════════════════════════════════════════

## Obtener un dato variable de un item. Si no existe → devuelve `valor_por_defecto`
func get_item_extra(id_item: StringName, clave: String, valor_por_defecto = null) -> Variant:
	if not tiene_item(id_item, 1):
		return valor_por_defecto
	
	# Si NO tenemos datos variables aún para este ID → inicializamos desde ItemDefinicion.datos_extra
	if not datos_variables_por_item.has(id_item):
		var def: ItemDefinicion = ItemDatabase.get_item(id_item)
		if def != null and def.datos_extra != null:
			datos_variables_por_item[id_item] = def.datos_extra.duplicate(true)  # Copia profunda (no modifica Resource original)
		else:
			datos_variables_por_item[id_item] = {}
	
	var dicc: Dictionary = datos_variables_por_item[id_item]
	if dicc.has(clave):
		return dicc[clave]
	return valor_por_defecto

## Asignar un dato variable a un item. Devuelve true si OK.
func set_item_extra(id_item: StringName, clave: String, valor: Variant) -> bool:
	if not tiene_item(id_item, 1):
		print("[Inventario set_item_extra] ❌ No tienes el item ", str(id_item), " en inventario.")
		return false
	# Inicializar si no existe
	if not datos_variables_por_item.has(id_item):
		var def: ItemDefinicion = ItemDatabase.get_item(id_item)
		if def != null and def.datos_extra != null:
			datos_variables_por_item[id_item] = def.datos_extra.duplicate(true)
		else:
			datos_variables_por_item[id_item] = {}
	datos_variables_por_item[id_item][clave] = valor
	# Emitir señal para que UI de crafteo actualice el texto "2/5 agua" inmediatamente
	inventario_cambiado.emit()
	return true
	
func equipar_herramienta(id_herramienta: StringName) -> void:
	# Si no la tienes en inventario, no se puede equipar
	if not tiene_item(id_herramienta, 1):
		print("[Inventario] No tienes esta herramienta: ", str(id_herramienta))
		return
	
	# Validar que sea de tipo herramienta
	var def := ItemDatabase.get_item(id_herramienta)
	if def == null or def.tipo != &"herramienta":
		print("[Inventario] ", str(id_herramienta), " no es una herramienta.")
		return
	
	var anterior: StringName = herramienta_equipada
	
	# Si ya estaba equipada la MISMA → desequipar (toggle)
	if herramienta_equipada == id_herramienta:
		herramienta_equipada = &""
		print("[Inventario] Herramienta desequipada.")
	else:
		herramienta_equipada = id_herramienta
		print("[Inventario] Herramienta equipada: ", def.nombre_visible)
	
	herramienta_equipada_cambiada.emit(anterior, herramienta_equipada)
	inventario_cambiado.emit()

# ──────────────────────────────────────────────────────────────
# CRAFTEO (movido desde inventario)
# ──────────────────────────────────────────────────────────────
# ⚠️ ESTO ES TEMPORAL — En FASE 6 lo cambiaremos por un sistema data-driven.
# Lo mantenemos por ahora para no romper nada del crafteo actual.
func craftear(tipo: String) -> bool:
	if tipo == "pico":
		if tiene_item(&"madera", 1) and tiene_item(&"piedra", 2):
			gastar_item(&"madera", 1)
			gastar_item(&"piedra", 2)
			agregar_item(&"pico", 1)
			print("¡Pico fabricado con éxito!")
			return true
	elif tipo == "hacha":
		if tiene_item(&"madera", 2) and tiene_item(&"piedra", 3):
			gastar_item(&"madera", 2)
			gastar_item(&"piedra", 3)
			agregar_item(&"hacha", 1)
			print("¡Hacha fabricada con éxito!")
			return true
	elif tipo == "azada" :
		if tiene_item(&"madera", 2) and tiene_item(&"piedra", 2):
			gastar_item(&"madera" ,2)
			gastar_item(&"piedra" ,2)
			agregar_item(&"azada" ,1)
			print ( "[Crafteo] ✅ AZADA fabricada con éxito!" )
			return true
			print ( "[Crafteo] ❌ Falta materiales para AZADA. Necesitas: 2 madera + 2 piedra" )
	
	elif tipo == "regadera" :
		# (Lo hacemos en el siguiente mensaje, por ahora comentado)
		if tiene_item(&"madera", 1) and tiene_item(&"piedra" , 3):
			gastar_item (&"madera" , 1 );
			gastar_item (&"piedra", 3 );
			agregar_item (&"regadera", 1 );
			return true
			print ( "[Crafteo] ❌ Falta materiales para REGADERA. Necesitas: 1 madera + 3 piedra" )
	
	print("Recursos insuficientes para fabricar: ", tipo)
	return false

# ──────────────────────────────────────────────────────────────
# HELPERS PRIVADOS (solo se usan DENTRO de este script)
# ──────────────────────────────────────────────────────────────
func _buscar_slot_vacio() -> int:
	for indice in range(slots.size()):
		if slots[indice].is_empty():
			return indice
	return -1  # -1 = ningún slot vacío
