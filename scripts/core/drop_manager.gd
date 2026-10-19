extends Node

# ═══════════════════════════════════════════════════════════════

# DropManager — Autoload (FASE 9.1)

# Sistema de DROPS UNIFICADO y data-driven.
#

# Uso:

#     DropManager.soltar(drops, global_position, null, self)
#

# 'drops' es un Array de Dictionary con este formato:

#     { "item_id": &"cuero", "cantidad": 2, "probabilidad": 0.7 }        # 70% de soltar 2

#     { "item_id": &"carne", "cantidad": 0, "cantidad_max": 3 }          # 0–3 aleatorio

#   - item_id      : id registrado en ItemDatabase

#   - cantidad     : unidades MÍNIMAS (por defecto 1)

#   - cantidad_max : unidades MÁXIMAS (opcional; si falta, la cantidad es fija = 'cantidad')

#   - probabilidad : 0.0–1.0 (por defecto 1.0 = siempre)

# ═══════════════════════════════════════════════════════════════

const ESCENA_PICKUP: PackedScene = preload("res://escenes/mundo/PickupItem.tscn")

# Ajustables desde el Inspector del Autoload
@export var dispersion_xz: float = 0.9
@export var altura_spawn: float = 0.15
@export var radio_test_libre: float = 0.25   # Radio de la sonda que comprueba que hay hueco
@export var intentos_dispersion: int = 8     # Reintentos antes de rendirse y soltar sin dispersión


# ──────────────────────────────────────────────────────────────

# API PRINCIPAL

# ──────────────────────────────────────────────────────────────
func soltar(drops: Array, posicion: Vector3, padre: Node = null, excluir: Node3D = null) -> void:
	if drops.is_empty():
		return
	# Diferimos: 'soltar' puede llamarse desde una señal de física (área/body_entered),
	# y el raycast al suelo debe hacerse fuera del "flushing" del motor de física.
	call_deferred("_soltar_diferido", drops, posicion, padre, excluir)

# ──────────────────────────────────────────────────────────────

# IMPLEMENTACIÓN (diferida)

# ──────────────────────────────────────────────────────────────
func _soltar_diferido(drops: Array, posicion: Vector3, padre: Node, excluir: Node3D) -> void:
	var contenedor: Node = padre
	if contenedor == null:
		contenedor = get_tree().current_scene
	if contenedor == null:
		push_warning("[DropManager] No hay contenedor donde soltar drops.")
		return

	var soltados: int = 0
	for d in drops:
		if typeof(d) != TYPE_DICTIONARY:
			continue
		var dic: Dictionary = d
		if not _pasa_probabilidad(dic):
			continue
		var id: StringName = dic.get("item_id", &"")
		var cant: int = _cantidad_aleatoria(dic)
		if id == &"" or cant <= 0:
			continue
		_spawnear_pickup(id, cant, posicion, contenedor, excluir)
		soltados += 1

	if soltados > 0:
		print("[DropManager] 🎁 Soltados ", soltados, " drops en ", posicion)

# ──────────────────────────────────────────────────────────────

# HELPERS PRIVADOS

# ──────────────────────────────────────────────────────────────
func _pasa_probabilidad(dic: Dictionary) -> bool:
	var p: float = float(dic.get("probabilidad", 1.0))
	if p >= 1.0:
		return true
	if p <= 0.0:
		return false
	return randf() <= p

# Cantidad: fija si no hay 'cantidad_max'; aleatoria [cantidad, cantidad_max] si lo hay.
func _cantidad_aleatoria(dic: Dictionary) -> int:
	var minimo: int = int(dic.get("cantidad", 1))
	if not dic.has("cantidad_max"):
		return minimo
	var maximo: int = int(dic.get("cantidad_max", minimo))
	if maximo <= minimo:
		return minimo
	return randi_range(minimo, maximo)

func _spawnear_pickup(id: StringName, cant: int, posicion: Vector3, contenedor: Node, excluir: Node3D) -> void:
	if ESCENA_PICKUP == null:
		push_warning("[DropManager] Falta PickupItem.tscn.")
		return
	var pickup: Pickup = ESCENA_PICKUP.instantiate() as Pickup
	if pickup == null:
		return

	# 1) Datos ANTES de entrar al árbol
	pickup.item_id = id
	pickup.cantidad = cant
	contenedor.add_child(pickup)

	# 2) Punto XZ con dispersión, VALIDADO (que no caiga dentro de muros/árboles/rocas)
	var world: World3D = pickup.get_world_3d()
	var objetivo: Vector3 = _punto_objetivo_libre(world, posicion, excluir)

	# 3) Altura del SUELO por raycast
	var y_suelo: float = _altura_suelo(world, objetivo, posicion.y, excluir)
	pickup.global_position = Vector3(objetivo.x, y_suelo + altura_spawn, objetivo.z)

	# 4) Color del mesh según el TIPO del item
	_aplicar_color_por_tipo(pickup, id)


# Busca un punto XZ con dispersión que NO quede dentro de muros/árboles/rocas.

# Si tras N intentos no halla hueco, devuelve el punto base SIN dispersión

# (el sitio donde murió la entidad siempre es alcanzable por el jugador).
func _punto_objetivo_libre(world: World3D, base: Vector3, excluir: Node3D) -> Vector3:
	if world == null:
		return base
	var excluidos: Array[RID] = []
	if excluir != null and is_instance_valid(excluir) and excluir is CollisionObject3D:
		excluidos.append((excluir as CollisionObject3D).get_rid())
	var sonda: SphereShape3D = SphereShape3D.new()
	sonda.radius = radio_test_libre
	for i in intentos_dispersion:
		var candidato: Vector3 = base + Vector3(
			randf_range(-dispersion_xz, dispersion_xz),
			0.0,
			randf_range(-dispersion_xz, dispersion_xz),
		)
		var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
		query.shape = sonda
		# Sondamos a la altura del CUERPO (por encima del suelo) para no chocar con el propio suelo
		query.transform = Transform3D(Basis.IDENTITY, Vector3(candidato.x, base.y, candidato.z))
		query.exclude = excluidos
		query.collide_with_areas = false
		query.collide_with_bodies = true
		if world.direct_space_state.intersect_shape(query, 1).is_empty():
			return candidato
	return base

# el propio enemigo/cadáver no bloquee el rayo. Si no hay suelo, usa la Y de referencia.
func _altura_suelo(world: World3D, punto: Vector3, y_referencia: float, excluir: Node3D) -> float:
	if world == null:
		return y_referencia
	var desde: Vector3 = Vector3(punto.x, y_referencia + 3.0, punto.z)
	var hasta: Vector3 = Vector3(punto.x, y_referencia - 5.0, punto.z)
	var excluidos: Array[RID] = []
	if excluir != null and is_instance_valid(excluir) and excluir is CollisionObject3D:
		excluidos.append((excluir as CollisionObject3D).get_rid())
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		desde, hasta, 0xFFFFFFFF, excluidos
	)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var res: Dictionary = world.direct_space_state.intersect_ray(query)
	if res.has("position"):
		return (res["position"] as Vector3).y
	return y_referencia

func _aplicar_color_por_tipo(pickup: Node3D, id: StringName) -> void:
	var mesh: MeshInstance3D = pickup.get_node_or_null("Mesh") as MeshInstance3D
	if mesh == null:
		return
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = _color_para_item(id)
	mesh.material_override = mat

func _color_para_item(id: StringName) -> Color:
	var tipo: StringName = &"recurso"
	if ItemDatabase.items.has(id):
		var def: ItemDefinicion = ItemDatabase.items[id]
		if def != null:
			tipo = def.tipo
	return IconoItem.COLORES_POR_TIPO.get(tipo, IconoItem.COLOR_DEFAULT)
