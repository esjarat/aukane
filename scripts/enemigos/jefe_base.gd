class_name JefeBase
extends EnemigoBase

# ═══════════════════════════════════════════════════════════════
# JefeBase — FSM MULTI-FASE + ATAQUES ESPECIALES (13.1 y 13.2)
# Hereda TODA la FSM de EnemigoBase (patrulla/perseguir/atacar),
# el escalado de nivel (12.3), drops y XP.
#
# ⚠️ PRINCIPIO 1: las fases usan MULTIPLICADORES, nunca valores
# absolutos. Si escribiéramos 'daño_ataque = 15', machacaríamos el
# bono de nivel de 12.3. Multiplicando, ambos COMPONEN.
#
# ⚠️ PRINCIPIO 2: los objetivos del ÁREA se buscan por DISTANCIA
# (grupos objetivo), no con Area3D física. Es determinista: no
# depende de capas de colisión ni de frames de física.
# ═══════════════════════════════════════════════════════════════

## Se emite al entrar en una fase. La usará 13.2 (ataques especiales).
signal fase_cambiada(indice: int, nombre: String)
## Se emite al iniciar la telegrafía de un especial (gancho para SFX/UI).
signal telegrafia_iniciada(tipo: StringName)

## Fases del jefe, EN ORDEN. El índice 0 es la inicial (su 'umbral_vida'
## se ignora). Cada fase siguiente se activa al bajar de su umbral.
@export var fases: Array[FaseDefinicion] = []

# ── FASE 13.2: ATAQUES ESPECIALES ──
@export_group("Ataques especiales")
## Cooldown propio de los especiales (independiente del ataque básico).
@export var cooldown_especial: float = 6.0
## Radio del golpe en área, en metros, centrado en el jefe.
@export var radio_area: float = 3.5
## Multiplicador de daño del área sobre 'daño_ataque' (el ya escalado).
@export var mult_daño_area: float = 1.5
## Aviso visual antes de que el área golpee (segundos).
@export var duracion_telegrafia_area: float = 0.8
## Aviso visual antes de que arranque la carga (segundos).
@export var duracion_telegrafia_carga: float = 0.6
## Velocidad de la embestida (m/s). Muy por encima de 'velocidad_perseguir'.
@export var velocidad_carga: float = 7.0
## Alcance máximo para decidir CARGAR en vez de perseguir a pie.
@export var distancia_carga_max: float = 12.0
## Multiplicador de daño del impacto de la carga.
@export var mult_daño_carga: float = 1.2
## Radio de impacto de la carga (m). Debe cubrir el cuerpo del jugador.
@export var ancho_impacto_carga: float = 1.2
## Grupos que reciben el daño del área. Añade &"enemigo" si quieres
## que el jefe también dañe a sus propios secuaces.
@export var grupos_objetivo_area: Array[StringName] = [&"jugador"]
# ── FASE 13.3: ARENA ──
@export_group("Arena")
## Si es TRUE el jefe nace DORMIDO: no persigue, no ataca y no dispara
## especiales hasta que la arena (ArenaJefe) llame a despertar().
@export var inicia_dormido: bool = false
@export_group("Recompensas")
## Botín GARANTIZADO al morir. Va DIRECTO al inventario del jugador
## (el que asestó el golpe final), además de los 'drops' normales.
@export var recompensas: Array[RecompensaItem] = []
const ATAQUE_NINGUNO: int = 0
const ATAQUE_AREA: int = 1
const ATAQUE_CARGA: int = 2

var _fase_actual: int = 0
# Base capturada tras super._ready(), con el nivel de 12.3 YA aplicado.
var _base_velocidad: float = 0.0
var _base_daño: int = 0
var _base_cooldown: float = 0.0
# Estado de los especiales (13.2)
var _cooldown_especial_actual: float = 0.0
var _telegrafia_restante: float = 0.0
var _ataque_pendiente: int = ATAQUE_NINGUNO
var _cargando: bool = false
var _dir_carga: Vector3 = Vector3.ZERO
var _tiempo_carga_restante: float = 0.0
var _carga_ya_impacto: bool = false
var _tween_telegrafia: Tween = null
var _dormido: bool = false

func _ready() -> void:
	# 13.4: si este jefe ya cayó, no vuelve a aparecer. Se consulta el
	# id ANTES de registrarse en el grupo "jefes", así la arena tampoco
	# lo adopta (y sin jefe la arena no cierra: no queda un recinto
	# sellado esperando a un jefe que nunca llega).
	if id_enemigo != &"" and GameState.esta_jefe_derrotado(id_enemigo):
		_esta_muerto = true   # corta _process/_physics_process al instante
		print("[JefeBase] ", name, " ya fue derrotado → no reaparece.")
		queue_free()
		return
	# Primero la base: engancha 'murio', escala por nivel, patrulla.
	super._ready()
	# Después capturamos la base YA escalada. El orden es obligatorio:
	# si capturáramos antes, multiplicaríamos sobre valores sin escalar.
	_base_velocidad = velocidad_perseguir
	_base_daño = daño_ataque
	_base_cooldown = cooldown_entre_ataques

	# 13.3: nos registramos para que la arena pueda localizarnos por grupo.
	if not is_in_group("jefes"):
		add_to_group("jefes")
	# 13.3: nace dormido si vive en una arena.
	_dormido = inicia_dormido
	if _dormido:
		print("[JefeBase] ", name, " 💤 DORMIDO (espera a que se cierre la arena).")

	if damageable != null and damageable.has_signal("vida_cambio"):
		if not damageable.vida_cambio.is_connected(_on_vida_cambio):
			damageable.vida_cambio.connect(_on_vida_cambio)

	if fases.is_empty():
		# ⚠️ AVISO EXPLÍCITO: un array vacío no da error en Godot y el jefe
		# se comportaría como un enemigo normal sin que nada lo indique.
		push_warning("[JefeBase] '%s' NO tiene fases configuradas → se comportará como un enemigo normal." % name)
		return

	_validar_fases()
	# Aplicar la fase 0 también sirve para que sus multiplicadores cuenten.
	_entrar_en_fase(0)

# ═══════════════════════════════════════════════════════════════
# 13.1 — FASES
# ═══════════════════════════════════════════════════════════════
func _on_vida_cambio(vida_nueva: int) -> void:
	# ⚠️ En Damageable, 'vida_cambio' se emite ANTES que 'murio'
	# (líneas 77 y 92), así que en el golpe letal llegaría con 0 ANTES
	# de que _esta_muerto sea true. Por eso cortamos también por <= 0.
	if _esta_muerto or vida_nueva <= 0:
		return
	if fases.size() < 2:
		return
	var vida_max: int = int(damageable.call("get_vida_maxima"))
	if vida_max <= 0:
		return
	var fraccion: float = float(vida_nueva) / float(vida_max)
	# while, no if: un golpe fuerte puede cruzar DOS umbrales de golpe.
	while _fase_actual + 1 < fases.size():
		var siguiente: FaseDefinicion = fases[_fase_actual + 1]
		if siguiente == null or fraccion > siguiente.umbral_vida:
			break
		_entrar_en_fase(_fase_actual + 1)

## Aplica los multiplicadores sobre la BASE (nunca sobre los valores
## actuales) → llamarla dos veces NO acumula.
func _entrar_en_fase(indice: int) -> void:
	if indice < 0 or indice >= fases.size():
		return
	var f: FaseDefinicion = fases[indice]
	if f == null:
		push_warning("[JefeBase] La fase %d es NULL (hueco vacío en el array)." % indice)
		return
	velocidad_perseguir = _base_velocidad * f.mult_velocidad
	daño_ataque = int(round(float(_base_daño) * f.mult_daño))
	cooldown_entre_ataques = _base_cooldown * f.mult_cooldown
	_fase_actual = indice
	var nombre_fase: String = f.nombre if f.nombre != "" else "Fase %d" % indice
	print("[JefeBase] %s → FASE %d (%s) | vel %.2f | daño %d | cooldown %.2f | área %s | carga %s" % [
		name, indice, nombre_fase, velocidad_perseguir, daño_ataque, cooldown_entre_ataques,
		"ON" if f.usa_area else "off", "ON" if f.usa_carga else "off",
	])
	fase_cambiada.emit(indice, nombre_fase)
## 13.3 — La llama la arena al cerrarse. Devuelve el control a la FSM.
func despertar() -> void:
	if not _dormido:
		return
	_dormido = false
	print("[JefeBase] ", name, " ☀️ DESPIERTA (arena cerrada).")

# ═══════════════════════════════════════════════════════════════
# 13.4 — RECOMPENSAS
# ═══════════════════════════════════════════════════════════════
## Entrega el botín garantizado al jugador que dio el golpe final.
## Misma regla que 'Nivel.otorgar_xp_a_atacante': si quien mata no
## pertenece al grupo "jugador" (p. ej. otro enemigo), no hay botín.
func _otorgar_recompensas(atacante_path: NodePath) -> void:
	if recompensas.is_empty():
		return
	var atacante: Node = get_node_or_null(atacante_path)
	if atacante == null or not atacante.is_in_group("jugador"):
		return
	for rec: RecompensaItem in recompensas:
		if rec == null or rec.id_item == &"" or rec.cantidad <= 0:
			continue
		# Diferencial: 'agregar_item' puede meter solo PARTE si el
		# inventario se llena a medias.
		var antes: int = Inventario.get_cantidad(rec.id_item)
		Inventario.agregar_item(rec.id_item, rec.cantidad)
		var entregado: int = Inventario.get_cantidad(rec.id_item) - antes
		var falta: int = rec.cantidad - entregado
		# Una recompensa única no debe perderse por falta de sitio:
		# lo que no cupo cae al suelo como pickup.
		if falta > 0:
			DropManager.soltar(
				[{ "item_id": rec.id_item, "cantidad": falta }],
				global_position,
				null,
				self,
			)
		print("[JefeBase] ", name, " 🎁 Recompensa: ", entregado, "× ", rec.id_item,
			(" | " + str(falta) + " al suelo") if falta > 0 else "")
			
func _validar_fases() -> void:
	for i: int in fases.size():
		if fases[i] == null:
			push_warning("[JefeBase] La fase %d es NULL (hueco vacío en el array)." % i)
			continue
		if i == 0:
			continue
		var anterior: FaseDefinicion = fases[i - 1]
		if anterior == null:
			continue
		if fases[i].umbral_vida >= anterior.umbral_vida:
			push_warning("[JefeBase] Fase %d ('%s'): umbral %.2f NO es menor que el de la fase anterior (%.2f) → nunca se activará." % [
				i, fases[i].nombre, fases[i].umbral_vida, anterior.umbral_vida,
			])

# ═══════════════════════════════════════════════════════════════
# 13.2 — ATAQUES ESPECIALES
# ═══════════════════════════════════════════════════════════════
func _process(delta: float) -> void:
	# 13.3: dormido = sin FSM, sin cooldowns y sin especiales. Solo espera.
	if _dormido:
		return
	super._process(delta)
	if _esta_muerto:
		return

	if _cooldown_especial_actual > 0.0:
		_cooldown_especial_actual = maxf(0.0, _cooldown_especial_actual - delta)

	# Telegrafía en curso: al terminar, se ejecuta el ataque pendiente.
	if _telegrafia_restante > 0.0:
		_telegrafia_restante -= delta
		if _telegrafia_restante <= 0.0:
			_telegrafia_restante = 0.0
			_ejecutar_ataque_pendiente()
		return

	_intentar_especial_por_estado()

func _physics_process(delta: float) -> void:
	if _esta_muerto:
		return
	# 13.3: dormido → solo cae. Si no aplicáramos gravedad, un jefe
	# colocado a media altura en el .tscn se quedaría flotando.
	if _dormido:
		velocity.x = 0.0
		velocity.z = 0.0
		if not is_on_floor():
			velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
		else:
			velocity.y = -0.1
		move_and_slide()
		return
	# La CARGA manda sobre la FSM
	# La CARGA manda sobre la FSM: es un movimiento propio e ininterrumpible.
	if _cargando:
		_procesar_carga(delta)
		return
	# Durante la TELEGRAFÍA el jefe se planta: si siguiera avanzando, el
	# aviso no serviría para saber dónde va a caer el golpe.
	if _telegrafia_restante > 0.0:
		_quedarse_plantado(delta)
		return
	super._physics_process(delta)

## Congela las transiciones de estado mientras dura un especial, para que
## una embestida no se corte a medias por un cambio de estado.
func _ejecutar_transiciones_estado() -> void:
	if _cargando or _telegrafia_restante > 0.0:
		return
	super._ejecutar_transiciones_estado()

## Mientras telegrafía, el jefe NO hace también el ataque básico: sería
## daño gratis que el jugador no puede esquivar.
func _intentar_atacar_jugador() -> void:
	if _telegrafia_restante > 0.0:
		return
	super._intentar_atacar_jugador()

# ──────────────────────────────────────────────────────────────
# ELECCIÓN DEL ESPECIAL (data-driven: lo decide la FASE + la distancia)
# ──────────────────────────────────────────────────────────────
func _intentar_especial_por_estado() -> void:
	if _telegrafia_restante > 0.0 or _cargando:
		return
	if _ataque_pendiente != ATAQUE_NINGUNO:
		return
	if _cooldown_especial_actual > 0.0:
		return
	if _jugador_ref == null or fases.is_empty():
		return
	if _fase_actual < 0 or _fase_actual >= fases.size():
		return
	var f: FaseDefinicion = fases[_fase_actual]
	if f == null:
		return
	# Solo se ataca a alguien a quien ya se ha detectado.
	if estado_actual == Estado.PATRULLA:
		return

	var dist: float = global_position.distance_to(_jugador_ref.global_position)
	if f.usa_area and dist <= radio_area:
		_iniciar_telegrafia(ATAQUE_AREA)
	elif f.usa_carga and dist > radio_area and dist <= distancia_carga_max:
		_iniciar_telegrafia(ATAQUE_CARGA)

func _iniciar_telegrafia(ataque: int) -> void:
	_ataque_pendiente = ataque
	_telegrafia_restante = duracion_telegrafia_area if ataque == ATAQUE_AREA else duracion_telegrafia_carga
	var tipo: StringName = &"area" if ataque == ATAQUE_AREA else &"carga"
	_animar_telegrafia()
	print("[JefeBase] ", name, " ⚠️ TELEGRAFÍA ", String(tipo).to_upper(), " (%.2fs)" % _telegrafia_restante)
	telegrafia_iniciada.emit(tipo)

func _ejecutar_ataque_pendiente() -> void:
	var ataque: int = _ataque_pendiente
	_ataque_pendiente = ATAQUE_NINGUNO
	_resetear_visual()
	_cooldown_especial_actual = cooldown_especial
	match ataque:
		ATAQUE_AREA:
			_ejecutar_area()
		ATAQUE_CARGA:
			_ejecutar_carga()

# ──────────────────────────────────────────────────────────────
# ATAQUE EN ÁREA
# ──────────────────────────────────────────────────────────────
func _ejecutar_area() -> void:
	var daño_area: int = int(round(float(daño_ataque) * mult_daño_area))
	var objetivos: Array[Node] = _objetivos_en_radio(radio_area)
	var impactos: int = 0
	for n: Node in objetivos:
		if _dañar_objetivo(n, daño_area):
			impactos += 1
	print("[JefeBase] ", name, " 💥 ÁREA (r=%.1f) → %d objetivo(s) | daño %d" % [
		radio_area, impactos, daño_area,
	])

# ──────────────────────────────────────────────────────────────
# CARGA (EMBESTIDA)
# ──────────────────────────────────────────────────────────────
func _ejecutar_carga() -> void:
	_cargando = true
	_carga_ya_impacto = false
	_tiempo_carga_restante = maxf(0.15, distancia_carga_max / maxf(0.1, velocidad_carga))
	# ⚠️ El rumbo se FIJA aquí y no se corrige durante el dash: así el
	# jugador puede esquivar apartándose. Si persiguiéramos, sería imbloqueable.
	if _jugador_ref != null:
		var v: Vector3 = _jugador_ref.global_position - global_position
		v.y = 0.0
		if v.length() > 0.01:
			_dir_carga = v.normalized()
			look_at(global_position + _dir_carga, Vector3.UP)
	print("[JefeBase] ", name, " 🐗 CARGA! dir=", _dir_carga, " durante %.2fs" % _tiempo_carga_restante)

func _procesar_carga(delta: float) -> void:
	_tiempo_carga_restante -= delta
	velocity.x = _dir_carga.x * velocidad_carga
	velocity.z = _dir_carga.z * velocidad_carga
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	else:
		velocity.y = -0.1
	move_and_slide()

	if not _carga_ya_impacto:
		_intentar_impacto_carga()
	if not _cargando:
		return
	# Fin de la carga: tiempo agotado o choque contra un muro.
	if _tiempo_carga_restante <= 0.0 or is_on_wall():
		_terminar_carga()

func _intentar_impacto_carga() -> void:
	var daño_carga: int = int(round(float(daño_ataque) * mult_daño_carga))
	for n: Node in _objetivos_en_radio(ancho_impacto_carga):
		if _dañar_objetivo(n, daño_carga):
			_carga_ya_impacto = true
			print("[JefeBase] ", name, " 🐗💥 IMPACTO de carga | daño %d" % daño_carga)
			break
	if _carga_ya_impacto:
		_terminar_carga()

func _terminar_carga() -> void:
	_cargando = false
	_carga_ya_impacto = false
	_tiempo_carga_restante = 0.0
	velocity.x = 0.0
	velocity.z = 0.0
	print("[JefeBase] ", name, " 🐗 CARGA terminada")

# ──────────────────────────────────────────────────────────────
# HELPERS
# ──────────────────────────────────────────────────────────────
## Nodos de los grupos objetivo dentro de 'radio' metros, medidos en el
## plano XZ (ignora la altura, como el resto del proyecto).
func _objetivos_en_radio(radio: float) -> Array[Node]:
	var resultado: Array[Node] = []
	for grupo: StringName in grupos_objetivo_area:
		for n: Node in get_tree().get_nodes_in_group(grupo):
			if n == self or not (n is Node3D):
				continue
			var np: Node3D = n as Node3D
			var dx: float = np.global_position.x - global_position.x
			var dz: float = np.global_position.z - global_position.z
			if Vector2(dx, dz).length() <= radio:
				resultado.append(n)
	return resultado

func _dañar_objetivo(n: Node, cantidad: int) -> bool:
	if n == null or cantidad <= 0:
		return false
	var dam: Node = n.get_node_or_null("Damageable")
	if dam == null or not dam.has_method("recibir_danio"):
		return false
	dam.call("recibir_danio", cantidad, self)
	return true

func _quedarse_plantado(delta: float) -> void:
	if _jugador_ref != null:
		var v: Vector3 = _jugador_ref.global_position - global_position
		v.y = 0.0
		if v.length() > 0.01:
			look_at(global_position + v, Vector3.UP)
	velocity.x = 0.0
	velocity.z = 0.0
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	else:
		velocity.y = -0.1
	move_and_slide()

## El aviso visual: el mesh del jefe crece durante la telegrafía y
## vuelve de golpe al ejecutar. El mesh es hijo (la raíz queda en identidad).
func _animar_telegrafia() -> void:
	var mesh: MeshInstance3D = get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh == null:
		return
	if _tween_telegrafia != null and _tween_telegrafia.is_valid():
		_tween_telegrafia.kill()
	mesh.scale = Vector3.ONE
	_tween_telegrafia = create_tween()
	_tween_telegrafia.tween_property(mesh, "scale", Vector3(1.35, 1.35, 1.35), _telegrafia_restante) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _resetear_visual() -> void:
	var mesh: MeshInstance3D = get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh == null:
		return
	if _tween_telegrafia != null and _tween_telegrafia.is_valid():
		_tween_telegrafia.kill()
	mesh.scale = Vector3.ONE

func _on_murio(atacante_path: NodePath) -> void:
	# Cancelar los especiales ANTES de la muerte: si no, el tween de
	# telegrafía pelearía con el tween de muerte (ambos animan mesh.scale).
	if _tween_telegrafia != null and _tween_telegrafia.is_valid():
		_tween_telegrafia.kill()
	_telegrafia_restante = 0.0
	_ataque_pendiente = ATAQUE_NINGUNO
	_cargando = false
	# 13.4: recompensa y marca de derrotado ANTES de super, porque super
	# arranca el tween de muerte que acaba en queue_free().
	_otorgar_recompensas(atacante_path)
	if id_enemigo != &"":
		GameState.marcar_jefe_derrotado(id_enemigo)
	super._on_murio(atacante_path)
