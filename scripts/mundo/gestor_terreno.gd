@tool
class_name GestorTerreno
extends Node3D

# ═══════════════════════════════════════════════════════════════
# GestorTerreno — Rejilla de tiles 3D del suelo (FASE 10.9)
#
# Construye el terreno a partir de DATOS:
#   · Un MultiMeshInstance3D por bioma → todas las celdas del mismo
#     tipo se dibujan en 1 sola llamada de dibujo.
#   · Un único StaticBody3D con un CollisionShape3D por celda
#     → colisión agrupada (un solo cuerpo para todo el suelo).
#
# El mapa se guarda como lista plana de ids en `celdas`
# (fila por fila, de izquierda a derecha). Añadir un bioma =
# crear un .tres en res://recursos/terrenos/. Cero hardcodeo.
# ═══════════════════════════════════════════════════════════════

const DIRECTORIO_TERRENOS: String = "res://recursos/terrenos/"
const GRUPO_TERRENO: StringName = &"terreno"
const GROSOR_VISUAL: float = 0.2         # grosor de la caja que se ve (m)
const PROFUNDIDAD_COLISION: float = 2.0  # caja gruesa de colisión (evita tunneling)

@export var ancho_celdas: int = 10:
	set(valor):
		ancho_celdas = maxi(1, valor)
		if is_node_ready():
			generar()
@export var alto_celdas: int = 10:
	set(valor):
		alto_celdas = maxi(1, valor)
		if is_node_ready():
			generar()
@export var tamano_celda: float = 2.0:
	set(valor):
		tamano_celda = maxf(0.1, valor)
		if is_node_ready():
			generar()
@export var bioma_base: StringName = &"hierba"
@export var celdas: Array[StringName] = []

@export_group("Pincel (Editor)")
## Bioma que se pinta con el clic izquierdo. El desplegable se rellena
## solo con los .tres de res://recursos/terrenos/ (cero hardcodeo).
@export var bioma_pincel: String = "tierra"
## Si está activo, el clic izquierdo pinta celdas en el viewport 3D.
@export var pincel_activo: bool = true

var _paleta: Dictionary[StringName, TipoTerreno] = {}

@onready var _visuales: Node3D = $Visuales
@onready var _colision: StaticBody3D = $Colision

func _ready() -> void:
	generar()

# ═══════════════════════════════════════════════════════════════
# GENERACIÓN
# ═══════════════════════════════════════════════════════════════
func generar() -> void:
	if _visuales == null or _colision == null:
		push_error("[GestorTerreno] Faltan los nodos hijos 'Visuales' (Node3D) y 'Colision' (StaticBody3D).")
		return

	_cargar_paleta()
	if not _paleta.has(bioma_base):
		push_warning("[GestorTerreno] El bioma_base '%s' no existe en %s" % [bioma_base, DIRECTORIO_TERRENOS])

	_ajustar_celdas()
	_limpiar_hijos()
	_colision.add_to_group(GRUPO_TERRENO)

	# Una sola malla y una sola forma COMPARTIDAS por todas las celdas
	# (mismo tamaño → un único recurso en memoria, aunque haya 100 celdas).
	var malla: BoxMesh = BoxMesh.new()
	malla.size = Vector3(tamano_celda, GROSOR_VISUAL, tamano_celda)
	var forma: BoxShape3D = BoxShape3D.new()
	forma.size = Vector3(tamano_celda, PROFUNDIDAD_COLISION, tamano_celda)

	for id: StringName in _paleta:
		var indices: Array[int] = _indices_de(id)
		if indices.is_empty():
			continue
		_crear_visual(_paleta[id], indices, malla)
		_crear_colision(_paleta[id], indices, forma)

# ═══════════════════════════════════════════════════════════════
# CONSTRUCCIÓN
# ═══════════════════════════════════════════════════════════════
func _crear_visual(p_tipo: TipoTerreno, p_indices: Array[int], p_malla: BoxMesh) -> void:
	var mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
	mmi.name = "Visual_" + String(p_tipo.id)

	var multi: MultiMesh = MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = p_malla
	multi.instance_count = p_indices.size()
	mmi.multimesh = multi

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = p_tipo.color
	mat.roughness = 1.0
	if p_tipo.textura != null:
		mat.albedo_texture = p_tipo.textura
	mmi.material_override = mat

	_visuales.add_child(mmi)

	# El centro de la caja se baja medio grosor para que la CARA SUPERIOR
	# quede exactamente en y = altura (con altura 0.0 el suelo queda a ras).
	var y: float = p_tipo.altura - GROSOR_VISUAL * 0.5
	for i: int in p_indices.size():
		var centro: Vector2 = _centro_celda(p_indices[i])
		multi.set_instance_transform(i, Transform3D(Basis(), Vector3(centro.x, y, centro.y)))

func _crear_colision(p_tipo: TipoTerreno, p_indices: Array[int], p_forma: BoxShape3D) -> void:
	var y: float = p_tipo.altura - PROFUNDIDAD_COLISION * 0.5
	for indice: int in p_indices:
		var centro: Vector2 = _centro_celda(indice)
		var cs: CollisionShape3D = CollisionShape3D.new()
		cs.shape = p_forma
		cs.position = Vector3(centro.x, y, centro.y)
		_colision.add_child(cs)

# ═══════════════════════════════════════════════════════════════
# DATOS Y AYUDANTES
# ═══════════════════════════════════════════════════════════════
func _cargar_paleta() -> void:
	_paleta.clear()
	var dir: DirAccess = DirAccess.open(DIRECTORIO_TERRENOS)
	if dir == null:
		push_error("[GestorTerreno] NO EXISTE el directorio: " + DIRECTORIO_TERRENOS)
		return
	dir.list_dir_begin()
	var nombre_archivo: String = dir.get_next()
	while nombre_archivo != "":
		if not nombre_archivo.begins_with(".") and nombre_archivo.ends_with(".tres"):
			var recurso: Resource = load(DIRECTORIO_TERRENOS + nombre_archivo)
			if recurso is TipoTerreno:
				var tipo: TipoTerreno = recurso as TipoTerreno
				if tipo.id == &"":
					push_warning("[GestorTerreno] TipoTerreno sin 'id': " + nombre_archivo)
				else:
					_paleta[tipo.id] = tipo
			else:
				push_warning("[GestorTerreno] .tres que no es TipoTerreno: " + nombre_archivo)
		nombre_archivo = dir.get_next()
	dir.list_dir_end()

func _ajustar_celdas() -> void:
	var total: int = ancho_celdas * alto_celdas
	if celdas.size() == total:
		return
	celdas.resize(total)
	for i: int in total:
		if celdas[i] == &"":
			celdas[i] = bioma_base

func _indices_de(p_id: StringName) -> Array[int]:
	var indices: Array[int] = []
	for i: int in celdas.size():
		if celdas[i] == p_id:
			indices.append(i)
	return indices

func _centro_celda(p_indice: int) -> Vector2:
	var columna: int = p_indice % ancho_celdas
	var fila: int = floori(float(p_indice) / float(ancho_celdas))
	var ancho_total: float = float(ancho_celdas) * tamano_celda
	var alto_total: float = float(alto_celdas) * tamano_celda
	var x: float = (float(columna) + 0.5) * tamano_celda - ancho_total * 0.5
	var z: float = (float(fila) + 0.5) * tamano_celda - alto_total * 0.5
	return Vector2(x, z)
# ──────────────────────────────────────────────────────────────
# CONSULTA PÚBLICA — el GestorTerreno es el DUEÑO de su rejilla.
# Cualquier sistema que necesite "dónde cae el tile (col, fila)"
# pregunta aquí, en vez de replicar la fórmula de _centro_celda().
# ──────────────────────────────────────────────────────────────

## Centro de una celda en coordenadas de MUNDO, a la altura de su bioma.
## Inverso legible de indice_desde_punto().
func centro_mundo_de_celda(p_columna: int, p_fila: int) -> Vector3:
	var centro: Vector2 = _centro_celda(p_fila * ancho_celdas + p_columna)
	return to_global(Vector3(centro.x, altura_de_celda(p_columna, p_fila), centro.y))

## Id del bioma pintado en una celda. &"" si la celda está fuera de la rejilla.
func bioma_de_celda(p_columna: int, p_fila: int) -> StringName:
	if p_columna < 0 or p_columna >= ancho_celdas:
		return &""
	if p_fila < 0 or p_fila >= alto_celdas:
		return &""
	var indice: int = p_fila * ancho_celdas + p_columna
	if indice < 0 or indice >= celdas.size():
		return &""
	return celdas[indice]

## Altura del bioma de una celda (0.0 si no existe o está fuera).
func altura_de_celda(p_columna: int, p_fila: int) -> float:
	_asegurar_paleta()
	var id: StringName = bioma_de_celda(p_columna, p_fila)
	if id == &"" or not _paleta.has(id):
		return 0.0
	return _paleta[id].altura

## ¿La celda admite cultivo? Falso si está fuera de la rejilla o si su
## bioma tiene es_cultivable = false (agua, coliseo, arena...).
func es_cultivable_en(p_columna: int, p_fila: int) -> bool:
	_asegurar_paleta()
	var id: StringName = bioma_de_celda(p_columna, p_fila)
	if id == &"" or not _paleta.has(id):
		return false
	return _paleta[id].es_cultivable

## La paleta se carga en generar() (_ready), pero un nodo HERMANO anterior
## en el árbol puede consultar antes de que ese _ready() haya corrido.
func _asegurar_paleta() -> void:
	if _paleta.is_empty():
		_cargar_paleta()
		
func _limpiar_hijos() -> void:
	for hijo: Node in _visuales.get_children():
		_visuales.remove_child(hijo)
		hijo.free()
	for hijo: Node in _colision.get_children():
		_colision.remove_child(hijo)
		hijo.free()
		
# ═══════════════════════════════════════════════════════════════
# PINCEL — lógica de datos (la usa el addon EditorPlugin desde fuera)
# ═══════════════════════════════════════════════════════════════
## Devuelve el bioma seleccionado en el Inspector como StringName.
func bioma_pincel_id() -> StringName:
	return StringName(bioma_pincel)

## Rellena el desplegable del pincel con los biomas existentes.
func _validate_property(p_propiedad: Dictionary) -> void:
	if p_propiedad.name != "bioma_pincel":
		return
	if _paleta.is_empty():
		_cargar_paleta()
	var ids: PackedStringArray = PackedStringArray()
	for id: StringName in _paleta:
		ids.append(String(id))
	if ids.is_empty():
		return
	p_propiedad.hint = PROPERTY_HINT_ENUM
	p_propiedad.hint_string = ",".join(ids)

## Convierte la posición del ratón (viewport) en un índice de celda,
## o -1 si el rayo no toca el plano del terreno / cae fuera de la rejilla.
func indice_bajo_raton(p_camara: Camera3D, p_pos_raton: Vector2) -> int:
	var origen: Vector3 = p_camara.project_ray_origin(p_pos_raton)
	var direccion: Vector3 = p_camara.project_ray_normal(p_pos_raton)
	# Plano horizontal a la altura del nodo (geometría pura: ningún objeto
	# puede "tapar" el suelo, mismo principio que la colocación de la 10.7).
	var plano: Plane = Plane(Vector3.UP, global_position.y)
	var punto: Variant = plano.intersects_ray(origen, direccion)
	if punto == null:
		return -1
	return indice_desde_punto(punto as Vector3)

## Inverso de _centro_celda(): punto de mundo → índice plano de la rejilla.
func indice_desde_punto(p_punto_mundo: Vector3) -> int:
	var local: Vector3 = to_local(p_punto_mundo)
	var ancho_total: float = float(ancho_celdas) * tamano_celda
	var alto_total: float = float(alto_celdas) * tamano_celda
	var columna: int = floori((local.x + ancho_total * 0.5) / tamano_celda)
	var fila: int = floori((local.z + alto_total * 0.5) / tamano_celda)
	if columna < 0 or columna >= ancho_celdas:
		return -1
	if fila < 0 or fila >= alto_celdas:
		return -1
	return fila * ancho_celdas + columna
## Inverso COMPLETO: punto de mundo → (columna, fila). (-1, -1) si cae fuera.
## El jugador lo usa para saber sobre QUÉ TILE apunta con la pala, sin tener
## que hacer él el módulo/división (eso duplicaría la fórmula de la rejilla).
func celda_desde_punto(p_punto_mundo: Vector3) -> Vector2i:
	var indice: int = indice_desde_punto(p_punto_mundo)
	if indice < 0:
		return Vector2i(-1, -1)
	return Vector2i(indice % ancho_celdas, floori(float(indice) / float(ancho_celdas)))
## Pinta una celda con un bioma. Devuelve true solo si hubo cambio real
## (para no regenerar la malla cuando el pincel repasa el mismo bioma).
func pintar_celda(p_indice: int, p_bioma: StringName) -> bool:
	if p_indice < 0 or p_indice >= celdas.size():
		return false
	if celdas[p_indice] == p_bioma:
		return false
	if not _paleta.has(p_bioma):
		push_warning("[GestorTerreno] Bioma '%s' no existe en %s" % [p_bioma, DIRECTORIO_TERRENOS])
		return false
	celdas[p_indice] = p_bioma
	generar()
	return true
