extends Node

# ═══════════════════════════════════════════════════════════════
# SINGLETON AUTOLOAD: GestorClima (FASE 11.1)
# Sortea el clima cada N minutos de JUEGO y avisa por señal.
# Los climas son data-driven: se cargan de res://recursos/climas/.
# ═══════════════════════════════════════════════════════════════

const DIRECTORIO_CLIMAS: String = "res://recursos/climas/"

# ── Configuración ──
## Cada cuántos minutos de JUEGO se sortea un clima nuevo (rango aleatorio).
## OJO: GestorTiempo corre a 50 min/s → un día dura ~29 s reales; por eso
## el rango es alto (240-600 min = 4-10 h de juego ≈ 5-12 s reales).
@export var min_minutos_entre_cambios: int = 240
@export var max_minutos_entre_cambios: int = 600
## Clima con el que arranca la partida (si no existe, se usa el primero cargado).
@export var clima_inicial: StringName = &"soleado"

# ── Estado ──
var climas: Dictionary[StringName, ClimaDefinicion] = {}
var clima_actual: StringName = &""
var _minutos_para_siguiente_cambio: int = 0

signal clima_cambio(clima_nuevo: StringName)

func _ready() -> void:
	_cargar_climas()
	if climas.is_empty():
		push_error("[GestorClima] ⚠️ No se cargó ningún clima. Revisa " + DIRECTORIO_CLIMAS)
		return

	var id_inicial: StringName = clima_inicial
	if not climas.has(id_inicial):
		id_inicial = _primer_clima_id()
	set_clima(id_inicial)
	_programar_siguiente_cambio()

	# GestorTiempo es Autoload; se resuelve por ruta para no depender del orden.
	var tiempo: Node = get_node_or_null("/root/GestorTiempo")
	if tiempo != null:
		tiempo.minuto_cambio.connect(_on_minuto_cambio)
	else:
		push_error("[GestorClima] ⚠️ No encontré GestorTiempo para escuchar el tiempo.")

# ──────────────────────────────────────────────────────────────
# CARGA DATA-DRIVEN (mismo patrón que ItemDatabase)
# ──────────────────────────────────────────────────────────────
func _cargar_climas() -> void:
	var dir: DirAccess = DirAccess.open(DIRECTORIO_CLIMAS)
	if dir == null:
		push_error("[GestorClima] ⚠️ NO EXISTE el directorio: " + DIRECTORIO_CLIMAS)
		return
	dir.list_dir_begin()
	var nombre_archivo: String = dir.get_next()
	while nombre_archivo != "":
		if not nombre_archivo.begins_with(".") and nombre_archivo.ends_with(".tres"):
			var ruta: String = DIRECTORIO_CLIMAS + nombre_archivo
			var recurso: Resource = load(ruta)
			if recurso != null and recurso is ClimaDefinicion:
				var clima: ClimaDefinicion = recurso as ClimaDefinicion
				if clima.id == &"":
					push_warning("[GestorClima] ⚠️ Clima sin campo 'id': " + ruta)
				else:
					climas[clima.id] = clima
			else:
				push_warning("[GestorClima] ⚠️ .tres no es ClimaDefinicion: " + ruta)
		nombre_archivo = dir.get_next()
	dir.list_dir_end()
	print("[GestorClima] Cargados ", climas.size(), " climas correctamente.")

# ──────────────────────────────────────────────────────────────
# RELOJ DE JUEGO (1 llamada por minuto de juego)
# ──────────────────────────────────────────────────────────────
func _on_minuto_cambio(_hora: int, _minuto: int) -> void:
	_minutos_para_siguiente_cambio -= 1
	if _minutos_para_siguiente_cambio <= 0:
		cambiar_clima_aleatorio()

func _programar_siguiente_cambio() -> void:
	var minimo: int = mini(min_minutos_entre_cambios, max_minutos_entre_cambios)
	var maximo: int = maxi(min_minutos_entre_cambios, max_minutos_entre_cambios)
	_minutos_para_siguiente_cambio = randi_range(minimo, maximo)

# ──────────────────────────────────────────────────────────────
# API PÚBLICA
# ──────────────────────────────────────────────────────────────
## Fuerza un clima concreto (pruebas o eventos de guion).
func set_clima(nuevo_id: StringName) -> void:
	if not climas.has(nuevo_id):
		push_warning("[GestorClima] ⚠️ Clima inexistente: " + str(nuevo_id))
		return
	clima_actual = nuevo_id
	clima_cambio.emit(nuevo_id)
	print("[GestorClima] 🌤️ Clima: ", get_clima_actual().nombre_visible)

## Sortea un clima nuevo (nunca repite el actual) y reprograma el reloj.
func cambiar_clima_aleatorio() -> void:
	var elegido: StringName = _sortear_clima()
	if elegido != &"":
		set_clima(elegido)
	_programar_siguiente_cambio()

func get_clima_actual() -> ClimaDefinicion:
	return climas.get(clima_actual, null)

func get_minutos_restantes() -> int:
	return _minutos_para_siguiente_cambio

## Sortea un clima aplicando el PESO BASE × el multiplicador de la estación.
## Los climas con peso efectivo 0 (p. ej. nieve en verano) no participan.
func _sortear_clima() -> StringName:
	var estacion: EstacionDefinicion = GestorTiempo.get_estacion_actual()

	var candidatos: Array[StringName] = []
	var pesos: Array[float] = []
	var peso_total: float = 0.0

	for id: StringName in climas:
		var peso: float = _peso_efectivo(id, estacion)
		if peso <= 0.0:
			continue
		candidatos.append(id)
		pesos.append(peso)
		peso_total += peso

	if candidatos.is_empty() or peso_total <= 0.0:
		return &""

	var tirada: float = randf() * peso_total
	var acumulado: float = 0.0
	for i: int in candidatos.size():
		acumulado += pesos[i]
		if tirada <= acumulado:
			return candidatos[i]
	return candidatos[candidatos.size() - 1]

## Peso del clima ya multiplicado por la estación actual (1.0 = sin cambio).
func _peso_efectivo(p_id: StringName, p_estacion: EstacionDefinicion) -> float:
	var peso: float = maxf(0.0, climas[p_id].peso)
	if p_estacion != null:
		peso *= p_estacion.multiplicador_para(p_id)
	return peso

func _primer_clima_id() -> StringName:
	for id: StringName in climas:
		return id
	return &""
