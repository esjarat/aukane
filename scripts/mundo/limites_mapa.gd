class_name LimitesMapa
extends StaticBody3D

# ═══════════════════════════════════════════════════════════════
# LimitesMapa — Muros invisibles que cierran el mapa (FASE 13.3)
#
# Los 4 muros se GENERAN EN CÓDIGO a partir de las medidas del
# terreno, en lugar de modelarse a mano:
#   · Si mañana cambia 'ancho_celdas' / 'alto_celdas' / 'tamano_celda'
#     del GestorTerreno, los muros se recolocan SOLOS. Cero reedición.
#   · Al ser código no existe un shape compartido entre muros de
#     tamaños distintos ni rotaciones manuales: eran justo las dos
#     causas por las que los 4 muros acabaron cruzando el mapa.
#
# El nodo raíz queda en IDENTIDAD; las formas viven en hijos.
# ═══════════════════════════════════════════════════════════════

@export_group("Medidas")
## Si está activo, el recinto se mide desde el GestorTerreno de la
## escena (celdas × tamaño de celda). Si no hay terreno, o si lo
## desactivas, se usan las medidas manuales de abajo.
@export var tomar_del_terreno: bool = true
## Ancho del recinto en metros (eje X). Respaldo sin terreno.
@export var ancho_manual: float = 20.0
## Largo del recinto en metros (eje Z). Respaldo sin terreno.
@export var largo_manual: float = 30.0

@export_group("Forma del muro")
## Altura de los muros. Alta de sobra para que no se salte por encima.
@export var altura_muro: float = 20.0
## Grosor del muro. 1 m evita atravesarlo al correr contra él.
@export var grosor_muro: float = 1.0

func _ready() -> void:
	_generar()

func _generar() -> void:
	var terreno: GestorTerreno = _buscar_terreno()
	var ancho: float = ancho_manual
	var largo: float = largo_manual
	var centro_x: float = 0.0
	var centro_z: float = 0.0

	if terreno != null and tomar_del_terreno:
		ancho = float(terreno.ancho_celdas) * terreno.tamano_celda
		largo = float(terreno.alto_celdas) * terreno.tamano_celda
	elif terreno == null:
		push_warning("[LimitesMapa] No encontré ningún GestorTerreno en la escena: uso las medidas manuales (%.0f×%.0f m)." % [ancho, largo])

	if terreno != null:
		# El origen del GestorTerreno es el CENTRO de su rejilla.
		centro_x = terreno.global_position.x
		centro_z = terreno.global_position.z

	_limpiar()

	# Dos formas COMPARTIDAS, una por eje: la horizontal lleva el largo
	# en X y la vertical lo lleva en Z. Así ninguna necesita rotarse y
	# ninguna se comparte entre muros de medidas distintas.
	# El '+ grosor*2' en el largo sella las 4 esquinas: los muros se
	# solapan un poco y no queda rendija por la que colarse.
	var forma_h: BoxShape3D = BoxShape3D.new()
	forma_h.size = Vector3(ancho + grosor_muro * 2.0, altura_muro, grosor_muro)
	var forma_v: BoxShape3D = BoxShape3D.new()
	forma_v.size = Vector3(grosor_muro, altura_muro, largo + grosor_muro * 2.0)

	_crear_muro("Norte", Vector3(centro_x, 0.0, centro_z - largo * 0.5), forma_h)
	_crear_muro("Sur", Vector3(centro_x, 0.0, centro_z + largo * 0.5), forma_h)
	_crear_muro("Oeste", Vector3(centro_x - ancho * 0.5, 0.0, centro_z), forma_v)
	_crear_muro("Este", Vector3(centro_x + ancho * 0.5, 0.0, centro_z), forma_v)

	print("[LimitesMapa] 🧱 Recinto de %.0f×%.0f m | centro (%.1f, %.1f) | %d muros" % [
		ancho, largo, centro_x, centro_z, get_child_count(),
	])

# ──────────────────────────────────────────────────────────────
# CONSTRUCCIÓN
# ──────────────────────────────────────────────────────────────
func _crear_muro(p_nombre: String, p_posicion: Vector3, p_forma: BoxShape3D) -> void:
	var cs: CollisionShape3D = CollisionShape3D.new()
	cs.name = p_nombre
	cs.shape = p_forma
	cs.position = p_posicion
	add_child(cs)

## Borra los muros previos (incluidos los que queden guardados en el
## .tscn) para que regenerar nunca duplique geometría.
func _limpiar() -> void:
	for hijo: Node in get_children():
		remove_child(hijo)
		hijo.free()

# ──────────────────────────────────────────────────────────────
# DESCUBRIMIENTO
# ──────────────────────────────────────────────────────────────
## Busca el GestorTerreno por TIPO, no por ruta: moverlo de sitio en
## la escena no rompe nada. (No uso el grupo "terreno" porque ese grupo
## lo registra el propio GestorTerreno en su _ready(), y este nodo puede
## ejecutarse antes.)
func _buscar_terreno() -> GestorTerreno:
	var raiz: Node = get_tree().current_scene
	if raiz == null:
		raiz = get_tree().root
	for nodo: Node in raiz.find_children("*", "GestorTerreno", true, false):
		if nodo is GestorTerreno:
			return nodo as GestorTerreno
	return null
