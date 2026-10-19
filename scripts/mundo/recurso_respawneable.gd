class_name RecursoRespawneable
extends StaticBody3D

# ═══════════════════════════════════════════════════════════════
# RecursoRespawneable — Árboles y rocas (FASE 9.3)
# Data-driven: los drops se definen en el Inspector y se delegan al
# DropManager (9.1). En lugar de queue_free(), el recurso se OCULTA y
# se registra en RespawnManager para reaparecer tras N días de juego.
# ═══════════════════════════════════════════════════════════════

# Grupos de recurso válidos (el jugador decide la herramienta por ellos)
const GRUPOS_RECURSO: Array[StringName] = [&"arboles", &"rocas"]

@export var drops: Array[Dictionary] = []           # Mismo formato que EnemigoBase/AnimalBase
@export var dias_respawn: int = 2                   # Días de juego hasta reaparecer
@export var grupo_recurso: StringName = &"arboles"  # "arboles" (hacha) o "rocas" (pico)
@export var herramienta_requerida: StringName = &"hacha"  # herramienta_tipo del item que lo tala/mina

var _activo: bool = true
var _capa_colision_original: int = 1

func _ready() -> void:
	_capa_colision_original = collision_layer
	# El @export es la ÚNICA fuente de verdad del grupo: limpiamos cualquier
	# grupo de recurso heredado de la escena que no coincida (evita que una
	# roca quede registrada como "arboles" por descuido).
	for g in GRUPOS_RECURSO:
		if g != grupo_recurso and is_in_group(g):
			remove_from_group(g)
	if grupo_recurso != &"" and not is_in_group(grupo_recurso):
		add_to_group(grupo_recurso)

# Lo llama el jugador con Click/Espacio (hacha para árboles, pico para rocas)
func recibir_golpe() -> void:
	if not _activo:
		return
	# 1) Soltar recursos al suelo (sistema unificado 9.1)
	DropManager.soltar(drops, global_position, null, self)
	# 2) Ocultar y desactivar (NO destruir)
	_desactivar()
	# 3) Programar la reaparición
	RespawnManager.registrar(self, dias_respawn)

func _desactivar() -> void:
	_activo = false
	visible = false                      # oculta todos los MeshInstance3D hijos
	if grupo_recurso != &"":
		remove_from_group(grupo_recurso)  # el jugador deja de detectarlo
	set_deferred("collision_layer", 0)    # deja de colisionar (diferido: seguro en física)

# La llama RespawnManager cuando toca reaparecer
func reactivar() -> void:
	if _activo:
		return
	_activo = true
	visible = true
	if grupo_recurso != &"":
		add_to_group(grupo_recurso)
	set_deferred("collision_layer", _capa_colision_original)
