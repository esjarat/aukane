class_name GestorHuerto
extends Node3D

# ═══════════════════════════════════════════════════════════════
# GestorHuerto — Parcelas alineadas a la rejilla del terreno
#
# Genera ancho_tiles × alto_tiles parcelas, cada una centrada en su
# TILE. La geometría NO se escribe a mano: se pregunta al GestorTerreno,
# que es el dueño de la rejilla (cero duplicación de la fórmula).
#
# ⚠️ NO es @tool A PROPÓSITO: si generara en el editor, las parcelas se
# hornearían dentro de mundo.tscn como nodos hijos (con overrides) y
# volvería la fragilidad que ya rompió la tienda y el botín del jefe.
# Se genera SOLO en runtime, igual que LimitesMapa.
# ═══════════════════════════════════════════════════════════════

const ESCENA_PARCELA: PackedScene = preload("res://escenes/granja/Parcela.tscn")

@export_group("Rejilla")
## Tile (columna) de la esquina del huerto. 0 = borde oeste.
@export var columna: int = 7
## Tile (fila) de la esquina del huerto. 0 = borde norte.
@export var fila: int = 4
## Ancho del huerto en tiles.
@export var ancho_tiles: int = 2
## Alto del huerto en tiles.
@export var alto_tiles: int = 3
@export_group("Generación")
## Si es true, siembra el rectángulo entero al arrancar (útil para testear).
## Con la PALA el huerto lo construye el jugador → false por defecto.
@export var generar_al_iniciar: bool = false

func _ready() -> void:
	# Este nodo es el CONTENEDOR ESTABLE de las parcelas: el guardado
	# (FASE 22.2) las localiza por grupo, sin recorrer la escena entera.
	add_to_group("huerto")
	if generar_al_iniciar:
		generar()

func generar() -> void:
	_limpiar()
	var terreno: GestorTerreno = _buscar_terreno()
	if terreno == null:
		push_warning("[GestorHuerto] No hay GestorTerreno en la escena: huerto no generado.")
		return

	var creadas: int = 0
	for f: int in alto_tiles:
		for c: int in ancho_tiles:
			var col: int = columna + c
			var fil: int = fila + f
			if not terreno.es_cultivable_en(col, fil):
				push_warning("[GestorHuerto] Celda (col %d, fila %d) con bioma '%s' NO es cultivable: parcela omitida." % [col, fil, String(terreno.bioma_de_celda(col, fil))])
				continue
			if _crear_parcela(terreno, col, fil) != null:
				creadas += 1

	print("[GestorHuerto] 🌱 Huerto desde (col %d, fila %d) de %d×%d tiles | %d parcelas" % [columna, fila, ancho_tiles, alto_tiles, creadas])

func _crear_parcela(p_terreno: GestorTerreno, p_columna: int, p_fila: int) -> Parcela:
	var parcela: Parcela = ESCENA_PARCELA.instantiate() as Parcela
	if parcela == null:
		push_error("[GestorHuerto] No se pudo instanciar Parcela.tscn.")
		return null
	parcela.name = "Parcela_%d_%d" % [p_columna, p_fila]
	# ID estable para el guardado. ANTES de add_child(), porque add_child()
	# dispara _ready() y el hijo debe nacer ya identificado.
	parcela.id_rejilla = Vector2i(p_columna, p_fila)
	add_child(parcela)
	# global_position DESPUÉS de add_child(): fuera del árbol no existe.
	parcela.global_position = p_terreno.centro_mundo_de_celda(p_columna, p_fila)
	return parcela

# ──────────────────────────────────────────────────────────────
# API PÚBLICA — la usa la pala (jugador) y el guardado (FASE 22.2).
# La EXISTENCIA de una parcela ES el dato: se identifica por id_rejilla,
# NUNCA por índice de hijo ni por nombre de nodo.
# ──────────────────────────────────────────────────────────────

## Parcela que ocupa la celda (col, fila), o null si está libre.
func parcela_en(p_columna: int, p_fila: int) -> Parcela:
	var objetivo: Vector2i = Vector2i(p_columna, p_fila)
	for hijo: Node in get_children():
		var parcela: Parcela = hijo as Parcela
		if parcela != null and parcela.id_rejilla == objetivo:
			return parcela
	return null

func hay_parcela_en(p_columna: int, p_fila: int) -> bool:
	return parcela_en(p_columna, p_fila) != null

## Crea una parcela en la celda. null si no se puede (bioma no cultivable,
## celda ocupada o fuera de la rejilla).
func crear_parcela_en(p_columna: int, p_fila: int) -> Parcela:
	var terreno: GestorTerreno = _buscar_terreno()
	if terreno == null:
		push_warning("[GestorHuerto] No hay GestorTerreno: parcela no creada.")
		return null
	if not terreno.es_cultivable_en(p_columna, p_fila):
		print("[GestorHuerto] La celda (col %d, fila %d) no es cultivable." % [p_columna, p_fila])
		return null
	if hay_parcela_en(p_columna, p_fila):
		print("[GestorHuerto] La celda (col %d, fila %d) ya tiene parcela." % [p_columna, p_fila])
		return null
	return _crear_parcela(terreno, p_columna, p_fila)

## Retira la parcela de la celda. false si no había ninguna.
func eliminar_parcela_en(p_columna: int, p_fila: int) -> bool:
	var parcela: Parcela = parcela_en(p_columna, p_fila)
	if parcela == null:
		return false
	remove_child(parcela)
	parcela.queue_free()
	print("[GestorHuerto] Parcela retirada en (col %d, fila %d)." % [p_columna, p_fila])
	return true

## Todas las parcelas actuales (base del guardado de FASE 22.2).
func get_parcelas() -> Array[Parcela]:
	var lista: Array[Parcela] = []
	for hijo: Node in get_children():
		var parcela: Parcela = hijo as Parcela
		if parcela != null:
			lista.append(parcela)
	return lista
	
func _limpiar() -> void:
	for hijo: Node in get_children():
		remove_child(hijo)
		hijo.free()

# ──────────────────────────────────────────────────────────────
# DESCUBRIMIENTO
# ──────────────────────────────────────────────────────────────
## Busca el GestorTerreno por TIPO, no por ruta (mismo criterio que
## LimitesMapa): moverlo de sitio en la escena no rompe el huerto.
func _buscar_terreno() -> GestorTerreno:
	var raiz: Node = get_tree().current_scene
	if raiz == null:
		raiz = get_tree().root
	for nodo: Node in raiz.find_children("*", "GestorTerreno", true, false):
		if nodo is GestorTerreno:
			return nodo as GestorTerreno
	return null
