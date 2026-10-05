extends StaticBody3D
class_name Parcela

# ════════════════════════════════════════════════════════════════════
# 1) STATE MACHINE: 5 ESTADOS (constantes)
# ════════════════════════════════════════════════════════════════════
const ESTADO_VACIO: int = 0
const ESTADO_ARADA: int = 1
const ESTADO_PLANTADA: int = 2
const ESTADO_LISTO: int = 3
const ESTADO_MARCHITO: int = 4

# ════════════════════════════════════════════════════════════════════
# 2) VARIABLES
# ════════════════════════════════════════════════════════════════════
var estado: int = ESTADO_VACIO:
	set(valor_nuevo):
		if estado != valor_nuevo:
			estado = valor_nuevo
			# Cada vez que cambia de estado → actualizar color de tierra VISUAL
			_actualizar_visual_tierra()
			print("[Parcela ", str(self), "] Cambio estado: ", _get_nombre_estado(valor_nuevo))

var semilla_id: StringName = &""
var progreso: float = 0.0   # 0.0 → 1.0
var regado: bool = false

# Configurables por Inspector (puedes cambiarlos por Parcela sin tocar código)
@export var velocidad_crecimiento_por_segundo: float = 0.05 # 1 / 0.02 = 50 segundos totales para testear rápido
@export var color_tierra_sin_arar: Color =Color(0.146, 0.146, 0.611, 1.0)  # marron oscuro
@export var color_tierra_arada: Color = Color(0.214, 0.465, 0.272, 1.0) # marron mas claro/rojizo (arado)
@export var color_tierra_regada: Color = Color(0.393, 0.047, 0.185, 1.0) # marron MUY oscuro (mojado)

# Referencia al mesh visual (MeshTierra hijo de Parcela)
@onready var _mesh_tierra: MeshInstance3D = $MeshTierra

# Referencia al nodo de la Planta Visual (cuando la instanciemos al plantar)
var _planta_visual: Node3D = null

# ════════════════════════════════════════════════════════════════════
# 3) READY (inicializar)
# ════════════════════════════════════════════════════════════════════
func _ready() -> void:
	add_to_group("parcelas")  # Seguridad por si olvidaste el grupo en la escena
	if _mesh_tierra != null: 
		var mat_original: Material = _mesh_tierra.material_override 
		if mat_original != null: 
			_mesh_tierra.material_override = mat_original.duplicate(true) # duplicate(true) = copia profunda
	_actualizar_visual_tierra()  # Color inicial según estado = VACIO

# ════════════════════════════════════════════════════════════════════
# 4) PROCESS: CRECIMIENTO
# ════════════════════════════════════════════════════════════════════
func _process(delta: float) -> void:
	# SÓLO crece si ESTADO = PLANTADA Y YA FUE REGADO
	if estado == ESTADO_PLANTADA and regado:
		progreso = min(progreso + delta * velocidad_crecimiento_por_segundo, 1.0)
		
		# FASE 2.3: avisar a la planta visual para que cambie de etapa mesh según progreso
		if _planta_visual != null and _planta_visual.has_method("set_progreso"):
			_planta_visual.set_progreso(progreso)
		
		# Si progreso llega a 1.0 = CULTIVO LISTO PARA COSECHAR
		if progreso >= 1.0:
			estado = ESTADO_LISTO
			progreso = 1.0
			if _planta_visual != null and _planta_visual.has_method("set_progreso"):
				_planta_visual.set_progreso(1.0)

# ════════════════════════════════════════════════════════════════════
# 5) ACCIONES PUBLICAS (llamadas por JUGADOR con tecla F)
# ════════════════════════════════════════════════════════════════════

## Arar: Solo estado VACIO + necesita herramienta = AZADA
func arar(herramienta_tipo: StringName) -> bool:
	if estado != ESTADO_VACIO:
		print("[Parcela] No se puede arar. Estado actual: ", _get_nombre_estado(estado))
		return false
	if herramienta_tipo != &"azada":
		print("[Parcela] Arar: necesitas EQUIPAR la AZADA (no: ", str(herramienta_tipo), ")")
		return false
	
	print("[Parcela] ✅ Arada correctamente.")
	estado = ESTADO_ARADA
	return true

## Plantar semilla: Solo estado ARADA + hay semilla en inventario (gastamos 1)
func plantar(jugador: Node) -> bool:
	if estado != ESTADO_ARADA:
		print("[Parcela] No puedes plantar aquí (tierra no arada o ya plantada).")
		return false
	
	# BUSCAR LA PRIMERA SEMILLA QUE HAYA EN INVENTARIO (tipo == "semilla")
	var semilla_a_usar: StringName = _elegir_primera_semilla_en_inventario()
	if semilla_a_usar == &"":
		print("[Parcela] ⚠️ No hay SEMILLAS en el inventario. Ve a comprar al mercado.")
		return false
	
	# Gastar 1 semilla del inventario
	if not Inventario.gastar_item(semilla_a_usar, 1):
		return false
	
	semilla_id = semilla_a_usar
	progreso = 0.0
	regado = false
	
	# Si la semilla trae "segundos_crecimiento" → sobrescribimos velocidad
	var def_semilla: ItemDefinicion = ItemDatabase.get_item(semilla_a_usar)
	if def_semilla != null and def_semilla.datos_extra.has("segundos_crecimiento"):
		var seg: float = float(def_semilla.datos_extra["segundos_crecimiento"])
		if seg > 0.0:
			velocidad_crecimiento_por_segundo = 1.0 / seg
	
	# ✅ INSTANCIAR LA PLANTA VISUAL (FASE 2.3)
	_instanciar_planta_visual()
	
	estado = ESTADO_PLANTADA
	print("[Parcela] 🌱 Plantado! ID semilla: ", str(semilla_id))
	return true


## Regar: Solo ESTADO_PLANTADA y no regado aún. Requiere REGADERA equipada Y CARGA DE AGUA > 0.
func regar(herramienta_tipo: StringName) -> bool:
	if estado != ESTADO_PLANTADA:
		print("[Parcela] No hay nada que regar.")
		return false
	if regado:
		print("[Parcela] Ya fue regada este ciclo. Espera al siguiente día.")
		return false
	if herramienta_tipo != &"regadera":
		print("[Parcela] Necesitas EQUIPAR la REGADERA para regar (tienes: ", str(herramienta_tipo), ").")
		return false
	
	# ⭐ NUEVO FASE 2.5: COMPROBAR AGUA ACTUAL
	var agua_actual: int = Inventario.get_item_extra(&"regadera", "carga_agua_actual", 0)
	if agua_actual <= 0:
		print("[Parcela] ❌ Regadera VACÍA. Ve al POZO a llenarla.")
		return false
	
	# Gastar 1 agua
	Inventario.set_item_extra(&"regadera", "carga_agua_actual", agua_actual - 1)
	
	regado = true
	_actualizar_visual_tierra()
	print("[Parcela] 💧 Regada correctamente. Agua restante regadera: ", agua_actual - 1, ". Ahora empezará a crecer.")
	return true

## Cosechar. Solo estado LISTO. Usa datos_extra de la semilla plantada.
func cosechar(jugador: Node) -> Array[Dictionary]:
	var drops_vacios: Array[Dictionary] = []
	if estado != ESTADO_LISTO:
		print("[Parcela] Aún no está listo para cosechar (progreso: ", round(progreso*100), "%)")
		return drops_vacios
	
	# 1) Obtener cultivo_id / min / max DESDE LOS DATOS_EXTRA DE LA SEMILLA
	var def_semilla: ItemDefinicion = ItemDatabase.get_item(semilla_id)
	var cultivo_id: StringName = &"tomate"
	var min_cant: int = 1
	var max_cant: int = 3
	if def_semilla != null:
		if def_semilla.datos_extra.has("cultivo_id"):
			cultivo_id = StringName(def_semilla.datos_extra["cultivo_id"])
		if def_semilla.datos_extra.has("min_cosecha"):
			min_cant = int(def_semilla.datos_extra["min_cosecha"])
		if def_semilla.datos_extra.has("max_cosecha"):
			max_cant = int(def_semilla.datos_extra["max_cosecha"])
	
	# 2) Cantidad aleatoria entre min y max
	var cantidad: int = randi_range(min_cant, max_cant)
	
	# 3) Destruir planta visual (si existe)
	if _planta_visual != null:
		_planta_visual.queue_free()
		_planta_visual = null
	
	# 4) Resetear variables semilla y progreso
	semilla_id = &""
	progreso = 0.0
	regado = false
	
	# 5) Cambiar estado a ARADA (lista para replantar)
	estado = ESTADO_ARADA
	
	# 6) Crear drops y añadir al inventario
	var drops: Array[Dictionary] = [
		{"id": cultivo_id, "cantidad": cantidad}
	]
	for drop in drops:
		Inventario.agregar_item(drop.id, drop.cantidad)
	
	print("[Parcela] ✅ Cosechado: ", cantidad, " ", str(cultivo_id), ".")
	return drops

## Limpiar parcela marchita (solo ESTADO_MARCHITO). Necesita azada. Vuelve a VACIO.
func limpiar(herramienta_tipo: StringName) -> bool:
	if estado != ESTADO_MARCHITO:
		return false
	if herramienta_tipo != &"azada":
		return false
	
	semilla_id = &""
	progreso = 0.0
	regado = false
	if _planta_visual != null:
		_planta_visual.queue_free()
		_planta_visual = null
	estado = ESTADO_VACIO
	return true

# ════════════════════════════════════════════════════════════════════
# 6) FASE 1.2: PATRÓN INTERACTUABLE (get_prompt / interactuar / puede_interactuar)
#     Con esto JUGADOR detecta la Parcela sin tocar código jugador ✨
# ════════════════════════════════════════════════════════════════════
func puede_interactuar() -> bool:
	return true  # Siempre se puede (el prompt te dirá qué falta)

func get_prompt() -> String:
	var herr: StringName = Inventario.herramienta_equipada
	
	match estado:
		ESTADO_VACIO:
			if herr == &"azada":
				return "[F] Arar (azada equipada)"
			else:
				return "[F] (Equipa la AZADA para arar)"
		
		ESTADO_ARADA:
			var hay_semilla: StringName = _elegir_primera_semilla_en_inventario()
			if hay_semilla != &"" :
				var def: ItemDefinicion = ItemDatabase.get_item(hay_semilla)
				var nombre: String = def.nombre_visible if def != null else str(hay_semilla)
				return "[F] Plantar 1 semilla" + nombre
			else:
				return "[F] (Compra semillas en el Mercado)"
		
		ESTADO_PLANTADA:
			if !regado:
				if herr == &"regadera":
					return "[F] Regar (regadera equipada)"
				else:
					return "... Creciendo " + str(round(progreso*100)) + "%  💧 Sin regar (Equipa REGADERA)"
			else:
				return "... Creciendo " + str(round(progreso*100)) + "%  💧 Regado ✓"
		
		ESTADO_LISTO:
			var cultivo_nombre : String = _get_cultivo_nombre ()
			return "[F] ✅ Cosechar " + cultivo_nombre.to_upper()
		
		ESTADO_MARCHITO:
			if herr == &"azada":
				return "[F] Limpiar parcela marchita (azada)"
			else:
				return "[F] Marchito. Limpiar con AZADA"
	return "[F] ???"

## FUNCIÓN LLAMADA POR JUGADOR AL PULSAR F
func interactuar(jugador: CharacterBody3D) -> void:
	var herr: StringName = Inventario.herramienta_equipada
	match estado:
		ESTADO_VACIO:
			arar(herr)
		ESTADO_ARADA:
			plantar(jugador)
		ESTADO_PLANTADA:
			regar(herr)
		ESTADO_LISTO:
			cosechar(jugador)
		ESTADO_MARCHITO:
			limpiar(herr)

# ════════════════════════════════════════════════════════════════════
# 7) HELPERS PRIVADOS
# ════════════════════════════════════════════════════════════════════

## Actualiza el COLOR del mesh tierra según estado y regado
func _actualizar_visual_tierra() -> void:
	if _mesh_tierra == null:
		return
	var mat: Material = _mesh_tierra.material_override
	if mat == null or not (mat is StandardMaterial3D):
		return
	var sm: StandardMaterial3D = mat as StandardMaterial3D
	
	match estado:
		ESTADO_VACIO:
			sm.albedo_color = color_tierra_sin_arar
		ESTADO_ARADA:
			sm.albedo_color = color_tierra_arada
		ESTADO_PLANTADA:
			sm.albedo_color = color_tierra_regada if regado else color_tierra_arada
		ESTADO_LISTO:
			sm.albedo_color = color_tierra_regada
		ESTADO_MARCHITO:
			sm.albedo_color = Color(0.2, 0.15, 0.1, 1.0)  # grisaseo marchito

## Helper para debug print del nombre del estado (no números)
func _get_nombre_estado(estado_int: int) -> String:
	match estado_int:
		0: return "VACIO"
		1: return "ARADA"
		2: return "PLANTADA"
		3: return "LISTO"
		4: return "MARCHITO"
	return "DESCONOCIDO (" + str(estado_int) + ")"


# ──────────────────────────────────────────────────────────────

# HELPERS PRIVADOS NUEVOS FASE 2.3

# ──────────────────────────────────────────────────────────────

## Devuelve el ID de la PRIMERA semilla que encuentre en inventario. &"" si nada.
func _elegir_primera_semilla_en_inventario() -> StringName:
	for i in range(Inventario.slots.size()):
		var slot: Dictionary = Inventario.get_slot(i)
		if slot.is_empty():
			continue
		var id_slot: StringName = slot.id
		var def: ItemDefinicion = ItemDatabase.get_item(id_slot)
		if def != null and def.tipo == &"semilla" and slot.cantidad >= 1:
			return id_slot
	return &""

## Carga e instancia PlantaTomate.tscn / PlantaZanahoria.tscn (segun semilla_id)
func _instanciar_planta_visual() -> void:
	# Por si acaso: limpiar planta anterior
	if _planta_visual != null:
		_planta_visual.queue_free()
		_planta_visual = null
	
	# 1) Obtener la ruta desde datos_extra de la semilla
	var def_semilla: ItemDefinicion = ItemDatabase.get_item(semilla_id)
	if def_semilla == null:
		push_error("[Parcela] semilla_id no existe en ItemDatabase: ", str(semilla_id))
		return
	if not def_semilla.datos_extra.has("planta_escena_path"):
		push_warning("[Parcela] semilla " + str(semilla_id) + " NO tiene 'planta_escena_path' en datos_extra. No se mostrará planta.")
		return
	var escena_path: String = def_semilla.datos_extra["planta_escena_path"]
	
	# 2) Cargar PackedScene
	var planta_packed: PackedScene = load(escena_path)
	if planta_packed == null:
		push_error("[Parcela] No se pudo cargar escena planta: ", escena_path)
		return
	
	# 3) Instanciar y añadir como HIJO de la Parcela
	_planta_visual = planta_packed.instantiate()
	if _planta_visual == null:
		push_error("[Parcela] instantiate() devolvió null para: ", escena_path)
		return
	
	_planta_visual.position = Vector3(0.0, 0.1, 0.0)
	add_child(_planta_visual)
	
	# Iniciar en etapa 0 (brote)
	if _planta_visual.has_method("set_progreso"):
		_planta_visual.set_progreso(0.0)
	
	print("[Parcela] 🌿 Planta visual instanciada correctamente desde: ", escena_path)

## Devuelve nombre visible del cultivo (para el prompt ESTADO_LISTO)
func _get_cultivo_nombre() -> String:
	var def_semilla: ItemDefinicion = ItemDatabase.get_item(semilla_id)
	if def_semilla != null and def_semilla.datos_extra.has("cultivo_id"):
		var cid: StringName = StringName(def_semilla.datos_extra["cultivo_id"])
		var def_cultivo: ItemDefinicion = ItemDatabase.get_item(cid)
		if def_cultivo != null:
			return def_cultivo.nombre_visible
	return "cultivo"
