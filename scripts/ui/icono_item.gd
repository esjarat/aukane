extends Node
class_name IconoItem
# ═══════════════════════════════════════════════════════════════
# GENERADOR DE ICONOS PLACEHOLDER
# Crea texturas de color simple cuando un item no tiene icono asignado.
# Cachea las texturas por tipo para no recrearlas cada vez.
# ═══════════════════════════════════════════════════════════════

# Cache de texturas generadas (key = tipo de item)
var _cache_texturas: Dictionary[StringName, Texture2D] = {}

# Colores por tipo de item
const COLORES_POR_TIPO: Dictionary = {
	&"recurso": Color(0.6, 0.45, 0.3),      # marrón
	&"herramienta": Color(0.6, 0.6, 0.65),   # gris
	&"semilla": Color(0.4, 0.7, 0.3),        # verde
	&"cultivo": Color(0.9, 0.55, 0.2),       # naranja
	&"consumible": Color(0.85, 0.3, 0.4),    # rojo
	&"arma": Color(0.5, 0.3, 0.7),           # morado
}

const COLOR_DEFAULT: Color = Color(0.4, 0.4, 0.45)  # gris oscuro

# Devuelve el icono del item, o un placeholder si no tiene.
func get_icono(p_item: ItemDefinicion) -> Texture2D:
	if p_item != null and p_item.icono != null:
		return p_item.icono
	# Generar placeholder por tipo
	var tipo: StringName = &""
	if p_item != null:
		tipo = p_item.tipo
	return _get_textura_placeholder(tipo)

# Genera (o recupera de cache) una textura de color para el tipo dado.
func _get_textura_placeholder(p_tipo: StringName) -> Texture2D:
	if _cache_texturas.has(p_tipo):
		return _cache_texturas[p_tipo]
	# Crear imagen 64x64 con color
	var color: Color = COLORES_POR_TIPO.get(p_tipo, COLOR_DEFAULT)
	var img: Image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(color)
	# Borde más oscuro
	var oscuro: Color = color * 0.6
	for x in 64:
		img.set_pixel(x, 0, oscuro)
		img.set_pixel(x, 63, oscuro)
		img.set_pixel(0, x, oscuro)
		img.set_pixel(63, x, oscuro)
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_cache_texturas[p_tipo] = tex
	return tex
