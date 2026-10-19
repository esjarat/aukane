class_name FaseDefinicion
extends Resource

# ═══════════════════════════════════════════════════════════════
# FaseDefinicion — Una fase de un jefe (FASE 13.1)
# Resource data-driven, igual que ClimaDefinicion / EstacionDefinicion.
# A diferencia de un Dictionary, cada campo es @export CON TIPO: el
# Inspector lo muestra como casilla fija → imposible teclear mal una
# clave y fallar en silencio.
# ═══════════════════════════════════════════════════════════════

## Nombre visible de la fase (para el print y para 13.2).
@export var nombre: String = ""

## Fracción de vida por debajo de la cual se activa (0.0 - 1.0).
## La fase inicial (índice 0) lo IGNORA: se activa al aparecer.
## Ej: 0.6 → se activa al bajar del 60% de vida.
@export_range(0.0, 1.0, 0.05) var umbral_vida: float = 0.0

# ── Multiplicadores. 1.0 = sin cambio. NUNCA valores absolutos: así
#    COMPONEN con el bono de nivel de 12.3 en vez de machacarlo. ──
@export_range(0.1, 5.0, 0.05) var mult_velocidad: float = 1.0
@export_range(0.1, 5.0, 0.05) var mult_daño: float = 1.0
## Cooldown entre ataques: MENOR = ataca más seguido (0.6 → 40% más rápido).
@export_range(0.1, 3.0, 0.05) var mult_cooldown: float = 1.0
# ── FASE 13.2: ATAQUES ESPECIALES HABILITADOS EN ESTA FASE ──
## Habilita el ataque en ÁREA (golpe alrededor del jefe, con telegrafía).
@export var usa_area: bool = false
## Habilita la CARGA (embestida en línea recta hacia el jugador).
@export var usa_carga: bool = false
