extends Node

# ──────────────────────────────────────────────────────────────
# SEÑALES (COMUNICACIÓN CON UI Y OTROS SISTEMAS)
# ──────────────────────────────────────────────────────────────
signal inventario_cambiado()
signal item_agregado(id: StringName, cantidad: int)
signal item_gastado(id: StringName, cantidad: int)
signal herramienta_equipada_cambiada(
	herramienta_anterior: StringName,
	herramienta_nueva: StringName,
)
signal item_consumido(id: StringName, hambre: int, vida: int)
signal hotbar_cambiada()
# ──────────────────────────────────────────────────────────────
# ESTRUCTURA DE DATOS PRINCIPAL
# ──────────────────────────────────────────────────────────────
@export var tamano_maximo_slots: int = 20  # Cantidad de "celdas" en la mochila
const CANTIDAD_SLOTS_HOTBAR: int = 9  # FASE 10.8: casillas propias de la barra rápida
var slots_hotbar: Array[Dictionary] = []  # 9 casillas INDEPENDIENTES de la mochila
var slot_hotbar_seleccionado: int = 0     # casilla activa (0-8)
var slots: Array[Dictionary] = []         # Cada slot = { id: StringName, cantidad: int } | {} = VACIO
var herramienta_equipada: StringName = &"puños"
var datos_variables_por_item: Dictionary[StringName, Dictionary] = {}


# ──────────────────────────────────────────────────────────────
# INICIALIZACIÓN
# ──────────────────────────────────────────────────────────────
func _ready() -> void:
	# Creamos la mochila VACÍA con el número de slots configurado
	for i in tamano_maximo_slots:
		slots.append({})  # {} = slot vacío

	# FASE 10.8: la HOTBAR son 9 casillas PROPIAS (modelo Minecraft/Terraria)
	for i in CANTIDAD_SLOTS_HOTBAR:
		slots_hotbar.append({})

	# ✅ Items iniciales para testear (quita los que no quieras tener al empezar)
	# Más adelante esto se cargará desde un Save File
	agregar_item(&"madera", 5)
	agregar_item(&"piedra", 5)
	agregar_item(&"oro", 10)
	agregar_item(&"semilla", 5)

	# 🧪 TEMPORAL: precarga la hotbar para poder probar sin arrastrar nada.
	# (Se eliminará cuando exista el sistema de guardado)
	slots_hotbar[0] = { "id": &"hacha", "cantidad": 1 }
	slots_hotbar[1] = { "id": &"espada", "cantidad": 1 }
	slots_hotbar[2] = { "id": &"arco", "cantidad": 1 }
	slots_hotbar[3] = { "id": &"flecha", "cantidad": 10 }
	seleccionar_hotbar(0)

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

	# FASE 10.8: la hotbar es parte del inventario TOTAL → se gasta de ambas.
	# Mochila primero (así las flechas de la mochila se consumen antes).
	var pendiente: int = _gastar_en_coleccion(slots, id, cantidad)
	if pendiente > 0:
		pendiente = _gastar_en_coleccion(slots_hotbar, id, pendiente)

	# Si se agotó lo que llevábamos en mano, hay que recalcular
	_equipar_desde_hotbar()
	inventario_cambiado.emit()
	item_gastado.emit(id, cantidad)
	return true

## Helper: gasta hasta `p_pendiente` unidades de `id` dentro de UNA colección.
## Devuelve cuántas unidades quedaron SIN gastar.
func _gastar_en_coleccion(coleccion: Array[Dictionary], id: StringName, p_pendiente: int) -> int:
	var pendiente: int = p_pendiente
	for indice in range(coleccion.size()):
		if pendiente <= 0:
			break
		var slot: Dictionary = coleccion[indice]
		if slot.is_empty() or slot.id != id:
			continue
		if slot.cantidad <= pendiente:
			pendiente -= slot.cantidad
			coleccion[indice] = {}  # Vaciar slot
		else:
			coleccion[indice].cantidad -= pendiente
			pendiente = 0
	return pendiente
# Verifica si el jugador tiene al menos X cantidad de un item
func tiene_item(id: StringName, cantidad_minima: int = 1) -> bool:
	return get_cantidad(id) >= cantidad_minima

# Devuelve cuántas unidades hay TOTALES de un item (mochila + hotbar)
func get_cantidad(id: StringName) -> int:
	return _contar_en_coleccion(slots, id) + _contar_en_coleccion(slots_hotbar, id)

func _contar_en_coleccion(coleccion: Array[Dictionary], id: StringName) -> int:
	var total: int = 0
	for slot in coleccion:
		if not slot.is_empty() and slot.id == id:
			total += slot.cantidad
	return total
	
# Obtener datos de un slot de la MOCHILA por índice ({} si está vacío)
func get_slot(indice: int) -> Dictionary:
	if indice < 0 or indice >= slots.size():
		return {}
	return slots[indice]
# ──────────────────────────────────────────────────────────────
# FASE 10.8 — HOTBAR (barra rápida de 9 casillas)
# ──────────────────────────────────────────────────────────────
## Slot de la colección indicada. tipo = &"mochila" | &"hotbar"
func get_slot_por(tipo: StringName, indice: int) -> Dictionary:
	if tipo == &"hotbar":
		return get_slot_hotbar(indice)
	return get_slot(indice)

## Obtener la casilla de la hotbar por índice ({} si está vacía)
func get_slot_hotbar(indice: int) -> Dictionary:
	if indice < 0 or indice >= slots_hotbar.size():
		return {}
	return slots_hotbar[indice]

## Mueve/intercambia un item entre DOS slots cualesquiera (mochila ↔ hotbar).
## Es la ÚNICA función que mueve datos: la UI solo la llama. Si el destino está
## ocupado → INTERCAMBIA (swap), que es el comportamiento estándar.
func mover_entre(
	p_origen: StringName, p_idx_origen: int,
	p_destino: StringName, p_idx_destino: int,
) -> void:
	var arr_origen: Array[Dictionary] = slots_hotbar if p_origen == &"hotbar" else slots
	var arr_destino: Array[Dictionary] = slots_hotbar if p_destino == &"hotbar" else slots

	if p_idx_origen < 0 or p_idx_origen >= arr_origen.size():
		return
	if p_idx_destino < 0 or p_idx_destino >= arr_destino.size():
		return

	# Guardamos AMBOS antes de escribir (funciona igual si es el mismo array)
	var item_a: Dictionary = arr_origen[p_idx_origen]
	var item_b: Dictionary = arr_destino[p_idx_destino]
	arr_origen[p_idx_origen] = item_b
	arr_destino[p_idx_destino] = item_a

	# Si el movimiento toca la hotbar, re-evaluamos qué llevamos en mano
	if p_origen == &"hotbar" or p_destino == &"hotbar":
		_equipar_desde_hotbar()

	hotbar_cambiada.emit()
	inventario_cambiado.emit()

## Selecciona una casilla de la hotbar y pone su contenido en la mano.
func seleccionar_hotbar(indice: int) -> void:
	if indice < 0 or indice >= slots_hotbar.size():
		return
	slot_hotbar_seleccionado = indice
	_equipar_desde_hotbar()
	hotbar_cambiada.emit()

## Pone en la mano el item de la casilla SELECCIONADA.
## Solo equipa si el item es de tipo "herramienta" (dato del ItemDefinicion:
## cero hardcodeo). Si la casilla está vacía o no es herramienta → puños.
## OJO: NO hace toggle (a diferencia de equipar_herramienta), porque reseleccionar
## la misma casilla no debe desequipar.
func _equipar_desde_hotbar() -> void:
	var nuevo: StringName = &"puños"
	if slot_hotbar_seleccionado >= 0 and slot_hotbar_seleccionado < slots_hotbar.size():
		var slot: Dictionary = slots_hotbar[slot_hotbar_seleccionado]
		if not slot.is_empty() and slot.has("id"):
			var def: ItemDefinicion = ItemDatabase.get_item(slot.id)
			if def != null and def.tipo == &"herramienta":
				nuevo = slot.id

	if nuevo == herramienta_equipada:
		return  # Nada que cambiar (evita refrescos innecesarios de UI)

	var anterior: StringName = herramienta_equipada
	herramienta_equipada = nuevo
	herramienta_equipada_cambiada.emit(anterior, nuevo)
	inventario_cambiado.emit()
# ──────────────────────────────────────────────────────────────
# USAR ITEM EN MANO (comer, beber, pociones...) — FASE 10.10
# Solo funciona con lo que el jugador lleva EN LA MANO: la casilla
# SELECCIONADA de la hotbar. Consume EXACTAMENTE de esa casilla (no
# de las reservas de la mochila). Es consumible si sus DATOS lo dicen
# (cero hardcodeo: hambre_restaurada / vida_restaurada).
# ──────────────────────────────────────────────────────────────
func usar_item_en_mano() -> bool:
	var indice: int = slot_hotbar_seleccionado
	if indice < 0 or indice >= slots_hotbar.size():
		return false
	var slot: Dictionary = slots_hotbar[indice]
	if slot.is_empty() or not slot.has("id"):
		return false

	var id: StringName = slot.id
	var def: ItemDefinicion = ItemDatabase.get_item(id)
	if def == null:
		return false

	# ¿Es consumible? Se decide por DATOS, no por tipo
	if def.hambre_restaurada <= 0 and def.vida_restaurada <= 0:
		print("[Inventario] ", str(id), " no es consumible.")
		return false

	# Consumir 1 unidad SOLO de la casilla en mano
	var restante: int = slot.cantidad - 1
	if restante > 0:
		slots_hotbar[indice].cantidad = restante
	else:
		slots_hotbar[indice] = {}   # Casilla vacía → la mano vuelve a puños

	_equipar_desde_hotbar()
	inventario_cambiado.emit()
	hotbar_cambiada.emit()
	item_consumido.emit(id, def.hambre_restaurada, def.vida_restaurada)
	print(
		"[Inventario] 🍽️ Consumido ",
		str(id),
		" (+", def.hambre_restaurada, " hambre, +", def.vida_restaurada, " vida) desde la mano",
	)
	return true
	
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

	# Si NO tenemos datos variables aún para este ID → inicializamos desde
	# ItemDefinicion.datos_extra
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
# HELPERS PRIVADOS (solo se usan DENTRO de este script)
# ──────────────────────────────────────────────────────────────
func _buscar_slot_vacio() -> int:
	for indice in range(slots.size()):
		if slots[indice].is_empty():
			return indice
	return -1  # -1 = ningún slot vacío
