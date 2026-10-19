class_name ClavesDatos
extends RefCounted

# ═══════════════════════════════════════════════════════════════
# CONTRATOS DE DATOS COMPARTIDOS
#
# Punto ÚNICO de verdad para ids de item, claves de datos_extra y
# nombres de acción usados por varios sistemas. Cero literales
# repetidos. Si un .tres deja de coincidir, se rompe AQUÍ.
# ═══════════════════════════════════════════════════════════════

# ── MONEDA DEL JUEGO ──
const ID_MONEDA: StringName = &"oro"

# ── HERRAMIENTAS (coinciden con ItemDefinicion.herramienta_tipo) ──
const HERR_AZADA: StringName = &"azada"
const HERR_PALA: StringName = &"pala"
const HERR_REGADERA: StringName = &"regadera"

# ── CLAVES DE datos_extra DE LA REGADERA ──
const CLAVE_AGUA_ACTUAL: String = "carga_agua_actual"
const CLAVE_AGUA_MAX: String = "carga_max_agua"
## Solo por si un .tres de regadera no define 'carga_max_agua'.
const AGUA_MAX_POR_DEFECTO: int = 5

# ── ACCIONES ESPECIALES DE DIÁLOGO (contrato con los .tres) ──
const ACCION_ABRIR_TIENDA: StringName = &"abrir_tienda"
const ACCION_CERRAR: StringName = &"cerrar"
const ACCION_ACEPTAR_MISION: StringName = &"aceptar_mision"
const ACCION_ENTREGAR_MISION: StringName = &"entregar_mision"
