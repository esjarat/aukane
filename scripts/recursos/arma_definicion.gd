class_name ArmaDefinicion
extends Resource


# FASE 3.5: Data class de un arma/tool TODOS LOS PARÁMETROS QUE DEFINEN SU GOLPE.
# NO tiene lógica. Son datos puros. Se usa desde jugador.gd al equipar.

@export var nombre: StringName = &"puños"        # ID único (coincide con herramienta_equipada en Inventario)
@export var nombre_mostrar: String = "Puños"     # Texto que verá el jugador
@export var daño: int = 5                        # Cuánto daño base este golpe
@export var alcance_metros: float = 1.2          # Longitud (cuánto LLEGA hacia delante: eje -Z del VisualHolder)
@export var ancho_metros: float = 0.8            # Ancho del golpe (eje X)
@export var alto_metros: float = 1.2             # Altura del colisionador (eje Y). 1.2 = cubre del suelo a cabeza.
@export var cooldown_segundos: float = 0.55      # Tiempo de enfriamiento ENTRE golpes
@export var duracion_activa_ms: int = 180        # Cuánto TIEMPO está el hitbox ENCENDIDO al atacar (más largo = más facil pegar)
# FASE 10.3: armas a DISTANCIA (arco). Si es false → golpe melee normal.
@export var es_a_distancia: bool = false
@export var velocidad_proyectil: float = 18.0
# Id del item que se consume por disparo. &"" = sin munición (dispara infinito).
@export var id_municion: StringName = &""
# ══════════════════════════════════════════════════════════════
# VISUAL DEL ARMA — data-driven, sin hardcodear en el jugador
# ══════════════════════════════════════════════════════════════
@export_group("Visual")
## Malla que se muestra en la mano al equipar. Vacío = arma sin modelo
## (p. ej. los puños). Al vivir en el recurso, un arma nueva es UN
## archivo: no se toca ni el .gd ni la escena del jugador.
@export var malla: Mesh = null
## Posición/rotación de la malla DENTRO del VisualHolder del jugador.
@export var transform_modelo: Transform3D = Transform3D()
