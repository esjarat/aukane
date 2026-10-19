class_name DialogoLinea
# scripts/npc/dialogo_linea.gd
extends Resource


# ═══════════════════════════════════════════════════════════════
# UNA SOLA LÍNEA dentro de un diálogo.
# Permite metadata futura: emote que hace el NPC, efecto de sonido, delay.
# ═══════════════════════════════════════════════════════════════

# Texto que dice el NPC (puedes usar \n para saltos de línea)
@export var texto: String = ""
# (Opcional-FASE 4.2) ID de animación/emote del NPC mientras habla (ej: "sonreir", "enojado")
@export var animacion_npc: StringName = &""
# (Opcional) Delay extra antes de avanzar auto (0 = el jugador tiene que pulsar)
@export var delay_auto_avance_seg: float = 0.0
