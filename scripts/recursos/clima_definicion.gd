class_name ClimaDefinicion
extends Resource

# ═══════════════════════════════════════════════════════════════
# ClimaDefinicion — Define UN estado de clima (FASE 11.1)
# Añadir un clima nuevo = crear un .tres nuevo. Cero hardcodeo.
# ═══════════════════════════════════════════════════════════════

# ── Identidad ──
@export var id: StringName = &""
@export var nombre_visible: String = ""

# ── Sorteo ──
## Peso RELATIVO (no porcentaje). Si tres climas pesan 1.0 y uno 2.0,
## ese último sale el doble de veces. Los pesos no tienen que sumar 100.
@export var peso: float = 1.0

# ── Efectos de luz/ambiente (los aplica 11.2) ──
## Multiplicador de energía de la DirectionalLight3D (1.0 = normal, 0.3 = oscuro).
@export var energia_luz: float = 1.0
## Tinte del ambiente (blanco = sin tinte).
@export var color_ambiente: Color = Color(1, 1, 1)
## Cuánto oscurece el fondo (0 = nada, 1 = negro). Se usa en 11.2.
@export_range(0.0, 1.0, 0.01) var factor_oscuridad: float = 0.0

# ── Efectos de partículas (los usa 11.2) ──
## Qué partículas mostrar: &"" ninguna, &"lluvia", &"nieve".
@export var particulas: StringName = &""
## Intensidad del viento (0 = sin viento). Moverá los árboles en 11.2.
@export var velocidad_viento: float = 0.0
# ── Impacto en la jugabilidad (FASE 11.4) ──
## Si está activo, este clima riega las parcelas plantadas automáticamente,
## sin gastar agua de la regadera.
@export var riega_cultivos: bool = false
## Multiplicador de la velocidad del jugador bajo este clima.
## 1.0 = sin cambio, 0.6 = 40% más lento (nieve).
@export var multiplicador_velocidad_jugador: float = 1.0
