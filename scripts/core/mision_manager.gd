extends Node

# ──────────────────────────────────────────────────────────────
# SEÑALES (para UI de misiones)
# ──────────────────────────────────────────────────────────────
signal mision_aceptada(id_mision: StringName)
signal mision_actualizada(id_mision: StringName, progreso_actual: int, cantidad_objetivo: int)
signal mision_completada(id_mision: StringName)


# ═══════════════════════════════════════════════════════════════
# SINGLETON AUTOLOAD: Gestiona TODAS las misiones del jugador.
# Estado: misiones activas (en progreso) y misiones completadas.
# ═══════════════════════════════════════════════════════════════

# Key: id_mision StringName → Value: Mision (instancia con progreso del jugador)
var misiones_activas: Dictionary[StringName, Mision] = {}
var misiones_completadas: Array[StringName] = []


# ═══════════════════════════════════════════════════════════════
# API PÚBLICA
# ═══════════════════════════════════════════════════════════════


func _ready() -> void:
	# Cada vez que el inventario cambia, revisamos misiones de recolectar
	Inventario.inventario_cambiado.connect(_on_inventario_cambiado)


func _on_inventario_cambiado() -> void:
	# Solo notificamos items que existen en misiones activas tipo recolectar
	for id in misiones_activas.keys():
		var m: Mision = misiones_activas[id]
		if m.tipo_objetivo == &"recolectar":
			actualizar_progreso(&"recolectar", m.id_objetivo)


# Acepta una misión a partir de un Resource Mision (plantilla).
# Creamos una COPIA para no modificar el .tres original.
func aceptar_mision(p_mision: Mision) -> bool:
	if p_mision == null:
		return false
	var id: StringName = p_mision.id_mision
	if id == &"":
		push_warning("[MisionManager] ❌ Misión sin id_mision.")
		return false
	if misiones_activas.has(id):
		print("[MisionManager] ℹ️ Ya tienes activa la misión: ", String(id))
		return false
	if misiones_completadas.has(id):
		print("[MisionManager] ℹ️ Ya completaste la misión: ", String(id))
		return false

	# Copia profunda de la plantilla (progreso empieza en 0)
	var copia: Mision = p_mision.duplicate(true) as Mision
	misiones_activas[id] = copia
	print("[MisionManager] ✅ Misión aceptada: ", copia.nombre, " (", String(id), ")")
	mision_aceptada.emit(id)
	# 🔄 Actualizar progreso INMEDIATAMENTE (por si ya tiene los items)
	if copia.tipo_objetivo == &"recolectar":
		actualizar_progreso(&"recolectar", copia.id_objetivo)
	return true


func actualizar_progreso(
	p_tipo: StringName,
	p_id_objetivo: StringName,
	p_cantidad: int = 1,
) -> void:
	var misiones_a_completar: Array[StringName] = []

	for id in misiones_activas.keys():
		var m: Mision = misiones_activas[id]
		if m.tipo_objetivo != p_tipo or m.id_objetivo != p_id_objetivo:
			continue

		# Para "recolectar": progreso = cantidad TOTAL en inventario
		if p_tipo == &"recolectar":
			m.progreso_actual = Inventario.get_cantidad(p_id_objetivo)
		else:
			# Para "matar" y "hablar": progreso acumulativo
			m.progreso_actual = min(m.progreso_actual + p_cantidad, m.cantidad_objetivo)

		print(
			"[MisionManager] 📊 Progreso misión '",
			m.nombre,
			"': ",
			m.progreso_actual,
			"/",
			m.cantidad_objetivo,
		)
		mision_actualizada.emit(id, m.progreso_actual, m.cantidad_objetivo)

		# ⚠️ Las misiones "recolectar" NO se autocompletan.
		# El jugador debe volver al NPC y ENTREGAR los items (ver entregar_mision()).
		# Solo "matar" y "hablar" se autocompletan al llegar al objetivo.
		if p_tipo != &"recolectar" and m.progreso_actual >= m.cantidad_objetivo:
			m.completada = true
			misiones_a_completar.append(id)

	for id in misiones_a_completar:
		# 🔑 IMPORTANTE: QUITAR de misiones_activas ANTES de entregar recompensas.
		# Si entregamos recompensas (oro/items), Inventario dispara inventario_cambiado,
		# que vuelve a llamar actualizar_progreso. Si la misión sigue en activas → bucle infinito.
		var mision: Mision = misiones_activas[id]
		misiones_activas.erase(id)
		misiones_completadas.append(id)
		# Ahora SÍ entregamos recompensas (ya no está en activas → no hay recursión)
		_entregar_recompensas(mision)
		mision_completada.emit(id)


# ──────────────────────────────────────────────────────────────
# HELPERS internos
# ──────────────────────────────────────────────────────────────
func _entregar_recompensas(p_mision: Mision) -> void:
	print("[MisionManager] 🎁 Entregando recompensas de: ", p_mision.nombre)
	# Oro
	if p_mision.recompensa_oro > 0:
		Inventario.agregar_item(ClavesDatos.ID_MONEDA, p_mision.recompensa_oro)
		print("[MisionManager] 💰 +", p_mision.recompensa_oro, " oro")
	# Items
	for r in p_mision.recompensas_items:
		if r.has("id") and r.has("cantidad"):
			Inventario.agregar_item(r.id, r.cantidad)
			print("[MisionManager] 📦 +", r.cantidad, "x ", String(r.id))

# ──────────────────────────────────────────────────────────────
# ENTREGA de misión tipo "recolectar":
# El jugador vuelve al NPC, entrega los items y recibe la recompensa.
# Devuelve true si la entrega fue exitosa.
# ──────────────────────────────────────────────────────────────
func entregar_mision(p_id_mision: StringName) -> bool:
	if not misiones_activas.has(p_id_mision):
		print("[MisionManager] ⚠️ No tienes activa la misión: ", String(p_id_mision))
		return false
	var m: Mision = misiones_activas[p_id_mision]
	# Verificar que el jugador tiene los items necesarios
	var cantidad_jugador: int = Inventario.get_cantidad(m.id_objetivo)
	if cantidad_jugador < m.cantidad_objetivo:
		print(
			"[MisionManager] ❌ No puedes entregar. Tienes ",
			cantidad_jugador,
			"/",
			m.cantidad_objetivo,
			" de ",
			String(m.id_objetivo),
		)
		return false
	# 1) Consumir los items del inventario
	Inventario.gastar_item(m.id_objetivo, m.cantidad_objetivo)
	print(
		"[MisionManager] 📦 Entregados ",
		m.cantidad_objetivo,
		"x ",
		String(m.id_objetivo),
	)
	# 2) Quitar de activas ANTES de dar recompensas (evita recursión)
	misiones_activas.erase(p_id_mision)
	misiones_completadas.append(p_id_mision)
	m.completada = true
	# 3) Dar recompensas
	_entregar_recompensas(m)
	mision_completada.emit(p_id_mision)
	print("[MisionManager] ✅ Misión completada por entrega: ", m.nombre)
	return true

# Helper: ¿el jugador puede entregar esta misión? (tiene los items)
func puede_entregar_mision(p_id_mision: StringName) -> bool:
	if not misiones_activas.has(p_id_mision):
		return false
	var m: Mision = misiones_activas[p_id_mision]
	if m.tipo_objetivo != &"recolectar":
		return false
	return Inventario.get_cantidad(m.id_objetivo) >= m.cantidad_objetivo

func get_mision_activa(p_id: StringName) -> Mision:
	return misiones_activas.get(p_id, null)


func tiene_mision_activa(p_id: StringName) -> bool:
	return misiones_activas.has(p_id)


func mision_ya_completada(p_id: StringName) -> bool:
	return misiones_completadas.has(p_id)
