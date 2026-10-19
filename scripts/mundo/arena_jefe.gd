class_name ArenaJefe
extends Node3D

# ═══════════════════════════════════════════════════════════════
# ArenaJefe — Zona de combate de jefe (FASE 13.3)
#
# Al entrar el jugador, la arena levanta sus muros y despierta al jefe.
# Al morir el jefe (o el jugador) los muros bajan otra vez.
#
# ⚠️ Los muros se GENERAN EN CÓDIGO y son RECTANGULARES (4 cajas).
#    Un anillo circular NO puede sellar una franja rectangular: por
#    mucho que crezca, siempre le quedan huecos en las esquinas por
#    los que colarse. Cuatro cajas con el largo correcto sellan.
#
# ⚠️ Detección por DISTANCIA (XZ), no por Area3D: no depende de capas
#    de colisión ni de frames de física (misma regla que 13.2).
#
# ⚠️ El jefe se localiza por GRUPO (el más cercano), no por una
#    referencia cableada en el Inspector: mover la escena del jefe de
#    sitio no rompe nada.
#
# El nodo raíz queda en IDENTIDAD; toda la geometría vive en hijos.
# El ORIGEN del nodo es el CENTRO del recinto de combate.
# ═══════════════════════════════════════════════════════════════

const GRUPO_JEFES_POR_DEFECTO: StringName = &"jefes"

@export_group("Referencias")
## Grupo del que se toma el jefe. JefeBase se registra solo en él al
## nacer. Si hay varios candidatos se adopta el MÁS CERCANO al centro.
@export var grupo_jefe: StringName = GRUPO_JEFES_POR_DEFECTO
## Despertar al jefe al cerrarse la arena (requiere 'Inicia Dormido' = ON
## en el jefe).
@export var despertar_jefe_al_activar: bool = true

@export_group("Medidas")
## Ancho del recinto de combate en metros (eje X), centrado en el nodo.
## Igualarlo al ancho del mapa sella toda la franja: imposible rodearla.
@export var ancho_arena: float = 20.0
## Largo del recinto de combate en metros (eje Z), centrado en el nodo.
@export var largo_arena: float = 10.0
## Cuánto debe ADENTRARSE el jugador en el recinto para que se cierre.
## Evita que se dispare con el jugador todavía pisando el borde.
@export var margen_activacion: float = 1.5

@export_group("Muros")
@export var altura_muro: float = 4.0
@export var grosor_muro: float = 0.5
## Capa de colisión del muro CERRADO. Debe incluir una capa que la
## máscara del jugador detecte (por defecto = capa 1).
@export var capa_muro: int = 1
## Malla translúcida para que el jugador vea la barrera cerrarse.
@export var mostrar_muros: bool = true
@export var color_muro: Color = Color(0.42, 0.62, 1.0, 0.35)

# Señales
## Se emite al cerrarse el recinto (empieza el combate).
signal arena_activada()
## Se emite al abrirse el recinto (combate terminado).
signal arena_desactivada()

var _activa: bool = false
## El jefe ya murió: la arena queda consumida y NO vuelve a cerrarse.
var _consumida: bool = false
var _colision: StaticBody3D = null
var _visual: Node3D = null
var _jefe: Node3D = null
var _jugador_ref: Node3D = null


func _ready() -> void:
	_construir_muros()
	_buscar_jugador()
	_buscar_jefe()


func _process(_delta: float) -> void:
	if _activa or _consumida:
		return
	if _jugador_ref == null:
		_buscar_jugador()
	if _jefe == null:
		_buscar_jefe()
	# ⚠️ Sin jugador o sin jefe NO se cierra: si faltara el jefe, el
	# recinto encerraría al jugador en una pelea que no existe.
	if _jugador_ref == null or _jefe == null:
		return
	if _jugador_dentro_del_margen():
		_activar()


# ──────────────────────────────────────────────────────────────
# ABRIR / CERRAR
# ──────────────────────────────────────────────────────────────
func _activar() -> void:
	if _activa or _consumida:
		return
	_activa = true
	_cerrar_muros()
	if despertar_jefe_al_activar and _jefe != null and _jefe.has_method("despertar"):
		_jefe.call("despertar")
	arena_activada.emit()
	print("[ArenaJefe] 🔒 ARENA CERRADA (%.0f×%.0f m) — el jefe ya no puede salir." % [ancho_arena, largo_arena])


func _desactivar() -> void:
	if not _activa:
		return
	_activa = false
	_abrir_muros()
	arena_desactivada.emit()
	print("[ArenaJefe] 🔓 ARENA ABIERTA")


func _cerrar_muros() -> void:
	# 1 sola operación para los 4 muros: comparten cuerpo y contenedor.
	if _colision != null:
		_colision.set_deferred("collision_layer", capa_muro)
	if _visual != null:
		_visual.visible = true


func _abrir_muros() -> void:
	if _colision != null:
		_colision.set_deferred("collision_layer", 0)
	if _visual != null:
		_visual.visible = false


# ──────────────────────────────────────────────────────────────
# CONSTRUCCIÓN DEL RECINTO (runtime)
# ──────────────────────────────────────────────────────────────
func _construir_muros() -> void:
	# UN solo cuerpo con 4 formas: el muro se abre/cierra cambiando la
	# capa de ESTE cuerpo, no la de cada forma.
	var cuerpo: StaticBody3D = StaticBody3D.new()
	cuerpo.name = "Colision"
	cuerpo.collision_layer = 0   # nace ABIERTA: sin colisión
	cuerpo.collision_mask = 0
	_colision = cuerpo
	add_child(cuerpo)

	var contenedor: Node3D = Node3D.new()
	contenedor.name = "Visual"
	contenedor.visible = false
	_visual = contenedor
	add_child(contenedor)

	# Dos formas COMPARTIDAS, una por eje: la horizontal lleva el largo
	# en X y la vertical lo lleva en Z. Ninguna necesita rotarse, que es
	# justo lo que se torcía en los límites del mapa.
	# El '+ grosor*2' sella las 4 esquinas: los muros se solapan un poco.
	var tam_h: Vector3 = Vector3(ancho_arena + grosor_muro * 2.0, altura_muro, grosor_muro)
	var tam_v: Vector3 = Vector3(grosor_muro, altura_muro, largo_arena + grosor_muro * 2.0)

	var forma_h: BoxShape3D = BoxShape3D.new()
	forma_h.size = tam_h
	var forma_v: BoxShape3D = BoxShape3D.new()
	forma_v.size = tam_v

	var malla_h: BoxMesh = null
	var malla_v: BoxMesh = null
	if mostrar_muros:
		# UNA sola material compartida: los 4 muros se ven igual.
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = color_muro
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED   # se ve desde dentro
		malla_h = BoxMesh.new()
		malla_h.size = tam_h
		malla_h.material = mat
		malla_v = BoxMesh.new()
		malla_v.size = tam_v
		malla_v.material = mat

	var mitad_x: float = ancho_arena * 0.5
	var mitad_z: float = largo_arena * 0.5
	var y_centro: float = altura_muro * 0.5

	_crear_muro("Norte", Vector3(0.0, y_centro, -mitad_z), forma_h, malla_h)
	_crear_muro("Sur", Vector3(0.0, y_centro, mitad_z), forma_h, malla_h)
	_crear_muro("Oeste", Vector3(-mitad_x, y_centro, 0.0), forma_v, malla_v)
	_crear_muro("Este", Vector3(mitad_x, y_centro, 0.0), forma_v, malla_v)

	print("[ArenaJefe] 🧱 Recinto de %.0f×%.0f m centrado en %s." % [
		ancho_arena, largo_arena, str(global_position),
	])


func _crear_muro(
	p_nombre: String,
	p_posicion: Vector3,
	p_forma: BoxShape3D,
	p_malla: BoxMesh,
) -> void:
	var cs: CollisionShape3D = CollisionShape3D.new()
	cs.name = p_nombre
	cs.shape = p_forma
	cs.position = p_posicion
	_colision.add_child(cs)

	if p_malla != null:
		var mi: MeshInstance3D = MeshInstance3D.new()
		mi.name = p_nombre + "Malla"
		mi.mesh = p_malla
		mi.position = p_posicion
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_visual.add_child(mi)


# ──────────────────────────────────────────────────────────────
# DESCUBRIMIENTO (orden-independiente: reintenta desde _process)
# ──────────────────────────────────────────────────────────────
func _buscar_jugador() -> void:
	var n: Node = get_tree().get_first_node_in_group("jugador")
	if n == null or not (n is Node3D):
		return
	_jugador_ref = n as Node3D
	var dam: Node = n.get_node_or_null("Damageable")
	if dam != null and dam.has_signal("murio"):
		if not dam.murio.is_connected(_on_jugador_murio):
			dam.murio.connect(_on_jugador_murio)


func _buscar_jefe() -> void:
	if _jefe != null and not is_instance_valid(_jefe):
		_jefe = null
	if _jefe != null:
		return
	var mejor: Node3D = null
	var mejor_dist: float = INF
	for n: Node in get_tree().get_nodes_in_group(grupo_jefe):
		if not (n is Node3D):
			continue
		var d: float = _distancia_xz((n as Node3D).global_position)
		if d < mejor_dist:
			mejor_dist = d
			mejor = n as Node3D
	if mejor == null:
		return
	_jefe = mejor
	var dam: Node = mejor.get_node_or_null("Damageable")
	if dam != null and dam.has_signal("murio"):
		if not dam.murio.is_connected(_on_jefe_murio):
			dam.murio.connect(_on_jefe_murio)
	print("[ArenaJefe] 🎯 Jefe adoptado: %s (a %.1f m del centro)." % [mejor.name, mejor_dist])


# ──────────────────────────────────────────────────────────────
# FINES DEL COMBATE
# ──────────────────────────────────────────────────────────────
func _on_jefe_murio(_atacante: NodePath) -> void:
	# Sin jefe no hay segunda ronda: consumida para siempre. Además así
	# no volvemos a usar un 'jefe' ya liberado con queue_free().
	_consumida = true
	_jefe = null
	_desactivar()


func _on_jugador_murio(_atacante: NodePath) -> void:
	# Si el jugador cae dentro, el recinto se abre: nunca debe quedarse
	# encerrado en una pelea que ya ha terminado.
	_desactivar()


# ──────────────────────────────────────────────────────────────
# HELPERS
# ──────────────────────────────────────────────────────────────
## ¿El jugador está lo bastante ADENTRADO en el recinto para cerrarlo?
func _jugador_dentro_del_margen() -> bool:
	var p: Vector3 = _jugador_ref.global_position
	var dx: float = absf(p.x - global_position.x)
	var dz: float = absf(p.z - global_position.z)
	return (
		dx <= ancho_arena * 0.5 - margen_activacion
		and dz <= largo_arena * 0.5 - margen_activacion
	)


## Distancia en el plano XZ (ignora la altura, como todo el proyecto).
func _distancia_xz(p: Vector3) -> float:
	var dx: float = p.x - global_position.x
	var dz: float = p.z - global_position.z
	return Vector2(dx, dz).length()
