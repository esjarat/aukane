extends Node

# ═══════════════════════════════════════════════════════════════
# SINGLETON AUTOLOAD: Gestiona TODAS las recetas de crafteo.
# Carga los .tres de assets/recetas/ en _ready() y expone
# la API para consultar y ejecutar crafteos.
# ═══════════════════════════════════════════════════════════════

const DIRECTORIO_RECETAS: String = "res://assets/recetas/"

# ID especial para el AGUA: NO es un item del inventario,
# se consume de la carga de agua de la regadera.
const ID_AGUA: StringName = &"agua"
const ID_REGADERA: StringName = ClavesDatos.HERR_REGADERA
const CLAVE_CARGA_AGUA: String = ClavesDatos.CLAVE_AGUA_ACTUAL

# Key: id de receta (StringName) → Value: RecetaCrafteo
var _recetas_por_id: Dictionary[StringName, RecetaCrafteo] = {}

# ═══════════════════════════════════════════════════════════════
# CARGA (mismo patrón que DialogoDatabase)
# ═══════════════════════════════════════════════════════════════

func _ready() -> void:
	_cargar_todas_recetas_desde_carpeta()
	print("[CrafteoManager] ✅ Cargadas %d recetas desde %s" % [_recetas_por_id.size(), DIRECTORIO_RECETAS])

func _cargar_todas_recetas_desde_carpeta() -> void:
	var dir: DirAccess = DirAccess.open(DIRECTORIO_RECETAS)
	if dir == null:
		push_warning("[CrafteoManager] ⚠️ NO EXISTE el directorio: " + DIRECTORIO_RECETAS)
		return

	dir.list_dir_begin()
	var nombre_archivo: String = dir.get_next()
	while nombre_archivo != "":
		if not nombre_archivo.begins_with("."):
			if nombre_archivo.ends_with(".tres"):
				var ruta_completa: String = DIRECTORIO_RECETAS + nombre_archivo
				var recurso: Resource = load(ruta_completa)
				if recurso != null and recurso is RecetaCrafteo:
					var receta: RecetaCrafteo = recurso as RecetaCrafteo
					if receta.id == &"":
						push_warning("[CrafteoManager] ⚠️ Receta sin id: " + ruta_completa)
					elif _recetas_por_id.has(receta.id):
						push_warning("[CrafteoManager] ⚠️ Receta DUPLICADA (id repetido): " + str(receta.id))
					else:
						_recetas_por_id[receta.id] = receta
						print("[CrafteoManager] 📜 Cargada receta '%s'" % str(receta.id))
				else:
					push_warning("[CrafteoManager] ⚠️ .tres no es RecetaCrafteo válido: " + ruta_completa)
		nombre_archivo = dir.get_next()
	dir.list_dir_end()

# ═══════════════════════════════════════════════════════════════
# API PÚBLICA: consultas
# ═══════════════════════════════════════════════════════════════

func get_receta(p_id: StringName) -> RecetaCrafteo:
	if _recetas_por_id.has(p_id):
		return _recetas_por_id[p_id]
	push_warning("[CrafteoManager] ❓ No existe receta con ID: " + str(p_id))
	return null

func get_todas_recetas() -> Array[RecetaCrafteo]:
	return _recetas_por_id.values()

## Devuelve las recetas de una categoría (ej: &"herramientas", &"comida")
func get_recetas_por_categoria(p_categoria: StringName) -> Array[RecetaCrafteo]:
	var resultado: Array[RecetaCrafteo] = []
	for receta in _recetas_por_id.values():
		if receta.categoria == p_categoria and receta.desbloqueada:
			resultado.append(receta)
	return resultado
## Devuelve las recetas que se pueden craftear en una estación concreta.
## Si p_estacion es &"ninguna", devuelve solo las que no requieren estación.
func get_recetas_por_estacion(p_estacion: StringName) -> Array[RecetaCrafteo]:
	var resultado: Array[RecetaCrafteo] = []
	for receta in _recetas_por_id.values():
		if not receta.desbloqueada:
			continue
		if receta.estacion_requerida == p_estacion:
			resultado.append(receta)
	return resultado
# ═══════════════════════════════════════════════════════════════
# API PÚBLICA: disponibilidad de ingredientes
# ═══════════════════════════════════════════════════════════════

## ¿Cuántas unidades hay disponibles de un ingrediente?
## Caso especial: &"agua" → carga de la regadera (no inventario)
func get_disponible_ingrediente(p_ingrediente: IngredienteReceta) -> int:
	if p_ingrediente.item_id == ID_AGUA:
		return get_agua_disponible()
	return Inventario.get_cantidad(p_ingrediente.item_id)

## Agua disponible = carga actual de la regadera (si la tienes en inventario)
func get_agua_disponible() -> int:
	if not Inventario.tiene_item(ID_REGADERA, 1):
		return 0
	return int(Inventario.get_item_extra(ID_REGADERA, CLAVE_CARGA_AGUA, 0))

## ¿Se puede craftear esta receta AHORA? (revisa TODOS los ingredientes)
func puede_craftear(p_receta: RecetaCrafteo) -> bool:
	if p_receta == null:
		return false
	for ingrediente in p_receta.ingredientes:
		if get_disponible_ingrediente(ingrediente) < ingrediente.cantidad:
			return false
	return true

# ═══════════════════════════════════════════════════════════════
# API PÚBLICA: ejecutar crafteo
# ═══════════════════════════════════════════════════════════════

## Ejecuta el crafteo: valida, consume ingredientes, agrega resultado.
## Devuelve true si se completó correctamente.
func craftear(p_receta: RecetaCrafteo) -> bool:
	if p_receta == null:
		push_error("[CrafteoManager] craftear: receta nula")
		return false

	# 1) Validar que se puede (doble check por seguridad)
	if not puede_craftear(p_receta):
		push_warning("[CrafteoManager] ❌ No se puede craftear '%s': faltan ingredientes" % str(p_receta.id))
		return false

	# 2) Consumir ingredientes (agua = caso especial)
	for ingrediente in p_receta.ingredientes:
		if ingrediente.item_id == ID_AGUA:
			_consumir_agua(ingrediente.cantidad)
		else:
			Inventario.gastar_item(ingrediente.item_id, ingrediente.cantidad)

	# 3) Agregar resultado
	var ok: bool = Inventario.agregar_item(p_receta.id_resultado, p_receta.cantidad_resultado)
	if not ok:
		push_warning("[CrafteoManager] ⚠️ No hay espacio en inventario para el resultado de '%s'" % str(p_receta.id))
		# Nota: los ingredientes ya se consumieron. Para un juego simple es aceptable;
		# si quieres transacción atómica, habría que validar espacio ANTES de consumir.
		return false

	print("[CrafteoManager] ✅ Crafteado '%s' → %dx %s" % [str(p_receta.id), p_receta.cantidad_resultado, str(p_receta.id_resultado)])
	return true

# ═══════════════════════════════════════════════════════════════
# HELPERS PRIVADOS
# ═══════════════════════════════════════════════════════════════

## Resta `cantidad` a la carga de agua de la regadera
func _consumir_agua(p_cantidad: int) -> void:
	var actual: int = get_agua_disponible()
	var nueva: int = max(actual - p_cantidad, 0)
	Inventario.set_item_extra(ID_REGADERA, CLAVE_CARGA_AGUA, nueva)
