extends Node

# ═══════════════════════════════════════════════════════════════
# SINGLETON AUTOLOAD: Tiempo del juego.
# Avanza minutos/horas/días y emite señales.
# ═══════════════════════════════════════════════════════════════

# Configuración (ajustable por Inspector o en el Autoload)
@export var hora_inicio: int = 10        # Hora a la que empieza el juego
@export var hora_amanecer: int = 6        # A partir de aquí es de día
@export var hora_atardecer: int = 20      # A partir de aquí es de noche
@export var minutos_por_segundo: float = 50.0  # Cuántos min de juego pasan por seg real
const DIRECTORIO_ESTACIONES: String = "res://recursos/estaciones/"
# Estado
var _minutos_totales: float = 0.0        # Minutos desde el inicio del día actual
var dia: int = 1
# ── Estaciones del año (FASE 11.3) ──
var estaciones: Array[EstacionDefinicion] = []   # Ordenadas por 'orden'
var estacion_actual: StringName = &""
var _dias_totales_ciclo: int = 0
# Señales (otros sistemas se conectan a ellas)
signal minuto_cambio(hora: int, minuto: int)
signal hora_cambio(hora: int)
signal dia_cambio(dia: int)
signal estacion_cambio(estacion: StringName)

func _ready() -> void:
	_minutos_totales = hora_inicio * 60.0
	_cargar_estaciones()
	_actualizar_estacion()
	# Nos enganchamos a nuestra PROPIA señal: así la estación se recalcula
	# sin tener que tocar los dos sitios que emiten dia_cambio.
	dia_cambio.connect(_on_dia_cambio)
	print("[GestorTiempo] ✅ Iniciado. Día %d, %02d:%02d" % [dia, hora_inicio, 0])
# ──────────────────────────────────────────────────────────────
# BUCLE DE TIEMPO
# ──────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	var minuto_anterior: int = get_minuto()
	var hora_anterior: int = get_hora()

	_minutos_totales += minutos_por_segundo * delta

	# ¿Cambio de día?
	while _minutos_totales >= 1440.0:
		_minutos_totales -= 1440.0
		dia += 1
		dia_cambio.emit(dia)
		print("[GestorTiempo] 🌅 Nuevo día: ", dia)

	# Emitir señales si cambió el minuto
	if get_minuto() != minuto_anterior:
		minuto_cambio.emit(get_hora(), get_minuto())
	# Emitir señal si cambió la hora
	if get_hora() != hora_anterior:
		hora_cambio.emit(get_hora())
	#if get_minuto() == 0 and minuto_anterior != 0:
		#print("[GestorTiempo] ⏰ ", get_tiempo_texto())
# ──────────────────────────────────────────────────────────────
# HELPERS PÚBLICOS
# ──────────────────────────────────────────────────────────────
func get_hora() -> int:
	return int(_minutos_totales) / 60

func get_minuto() -> int:
	return int(_minutos_totales) % 60

func get_hora_decimal() -> float:
	# Devuelve la hora como float (ej: 8.5 = 8:30) para interpolaciones de luz
	return _minutos_totales / 60.0

func es_dia() -> bool:
	return get_hora() >= hora_amanecer and get_hora() < hora_atardecer

func es_noche() -> bool:
	return not es_dia()

func get_tiempo_texto() -> String:
	return "%02d:%02d" % [get_hora(), get_minuto()]
# ──────────────────────────────────────────────────────────────
# AVANZAR TIEMPO DE GOLPE (dormir en cama, viajes rápidos...)
# Suma minutos respetando el salto de hora y de día, y emite
# las señales correspondientes para que todo lo demás se ponga al día.
# ──────────────────────────────────────────────────────────────
func avanzar_tiempo(minutos: int) -> void:
	if minutos <= 0:
		return

	var hora_anterior: int = get_hora()
	var minuto_anterior: int = get_minuto()

	_minutos_totales += float(minutos)

	# ¿Han pasado uno o varios días de golpe?
	while _minutos_totales >= 1440.0:
		_minutos_totales -= 1440.0
		dia += 1
		dia_cambio.emit(dia)

	# Emitir señales finales (una sola vez, con el estado nuevo)
	if get_hora() != hora_anterior:
		hora_cambio.emit(get_hora())
	if get_minuto() != minuto_anterior:
		minuto_cambio.emit(get_hora(), get_minuto())

# ──────────────────────────────────────────────────────────────
# ESTACIONES DEL AÑO (FASE 11.3)
# ──────────────────────────────────────────────────────────────
func _on_dia_cambio(_nuevo_dia: int) -> void:
	_actualizar_estacion()

## Carga los .tres de res://recursos/estaciones/ y los ordena por 'orden'.
func _cargar_estaciones() -> void:
	var dir: DirAccess = DirAccess.open(DIRECTORIO_ESTACIONES)
	if dir == null:
		return
	dir.list_dir_begin()
	var nombre_archivo: String = dir.get_next()
	while nombre_archivo != "":
		if not nombre_archivo.begins_with(".") and nombre_archivo.ends_with(".tres"):
			var recurso: Resource = load(DIRECTORIO_ESTACIONES + nombre_archivo)
			if recurso != null and recurso is EstacionDefinicion:
				estaciones.append(recurso as EstacionDefinicion)
			else:
				push_warning("[GestorTiempo] ⚠️ .tres no es EstacionDefinicion: " + nombre_archivo)
		nombre_archivo = dir.get_next()
	dir.list_dir_end()

	# Orden determinista (DirAccess no garantiza ningún orden).
	estaciones.sort_custom(_ordenar_por_orden)

	_dias_totales_ciclo = 0
	for est: EstacionDefinicion in estaciones:
		_dias_totales_ciclo += maxi(1, est.dias_duracion)

	#if estaciones.is_empty():
		#push_error("[GestorTiempo] ⚠️ No se cargó ninguna estación. Revisa " + DIRECTORIO_ESTACIONES)
	#else:
		#print("[GestorTiempo] Cargadas ", estaciones.size(), " estaciones. Ciclo de ", _dias_totales_ciclo, " días.")

func _ordenar_por_orden(a: EstacionDefinicion, b: EstacionDefinicion) -> bool:
	return a.orden < b.orden

## Recalcula la estación según el día actual (por DÍAS ACUMULADOS, así
## admite duraciones distintas por estación sin tocar código).
func _actualizar_estacion() -> void:
	if estaciones.is_empty() or _dias_totales_ciclo <= 0:
		return
	var dia_en_ciclo: int = (dia - 1) % _dias_totales_ciclo
	var acumulado: int = 0
	var nueva_estacion: StringName = estaciones[0].id
	for est: EstacionDefinicion in estaciones:
		acumulado += maxi(1, est.dias_duracion)
		if dia_en_ciclo < acumulado:
			nueva_estacion = est.id
			break
	if nueva_estacion != estacion_actual:
		estacion_actual = nueva_estacion
		estacion_cambio.emit(nueva_estacion)
		print("[GestorTiempo] 🍃 Estación: ", get_estacion_actual().nombre_visible)

## Devuelve el Resource de la estación actual (o null si no hay estaciones).
func get_estacion_actual() -> EstacionDefinicion:
	for est: EstacionDefinicion in estaciones:
		if est.id == estacion_actual:
			return est
	return null

func get_estacion_id() -> StringName:
	return estacion_actual

## Días de juego que faltan para que cambie la estación (para el HUD).
func get_dias_restantes_estacion() -> int:
	if estaciones.is_empty() or _dias_totales_ciclo <= 0:
		return 0
	var dia_en_ciclo: int = (dia - 1) % _dias_totales_ciclo
	var acumulado: int = 0
	for est: EstacionDefinicion in estaciones:
		acumulado += maxi(1, est.dias_duracion)
		if dia_en_ciclo < acumulado:
			return acumulado - dia_en_ciclo
	return 0
