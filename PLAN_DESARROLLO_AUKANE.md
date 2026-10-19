# 📋 Plan de Desarrollo - Aukane (Videojuego Isométrico 2.5D en Godot 4.x

> 🎮 Tipo: Farm / Mercado / Crafting / Diálogos / Combate / Recolección
> 🎓 Propósito: Aprender desarrollo en Godot + GDScript de forma incremental

---

## 🔑 **Regla #1 Orden de Fases**: Se debe avanzar estrictamente en este orden. No pasar a la siguiente fase hasta que la anterior esté 100% implementada y probada.**

```
FASE 1 → FASE 2 → FASE 3 → FASE 4 → FASE 5 → FASE 6 → FASE 7 → FASE 8 → FASE 9 → FASE 10 → FASE 11 → FASE 12 → FASE 13 → FASE 22 (Menú Principal + Guardado) → FASE 14 → FASE 15 → FASE 16 → FASE 17 → FASE 18 → FASE 19 → FASE 20 → FASE 21
```

## 🔑 **Regla #2 Comunicación / No Suposiciones**: Antes de dar una respuesta final o una corrección, **Siempre revisar el código real del proyecto (archivos .gd, .tscn, .tres)**. No se deben hacer suposiciones sobre lo que el usuario tiene o no tiene implementado. Si se detecta un bug, primero inspeccionar el archivo correspondiente para confirmar la causa raíz y luego explicar al usuario el cambio que debe realizar (el asistente NO edita el código por el usuario).

## 🔑 **Regla #3 El asistente NUNCA edita el código por el usuario**: Todos los cambios en scripts (.gd), escenas (.tscn) o recursos (.tres) los implementa manualmente el usuario siguiendo guías paso a paso. El asistente solo edita este documento PLAN_DESARROLLO_AUKANE.md para registrar reglas, actualizar progreso o corregir el plan.

---

---

## 📌 Estado del Proyecto (Actualizado - 14/10/2026)

| Componente | Archivo | Estado | Notas |
|---|---|---|---|
| Jugador 3D movimiento isométrico + Quaternion slerp | `scripts/jugador/jugador.gd` + `Jugador.tscn` | ✅ 100% | Movimiento ISO calibrado: W→(-0.707,0,-0.707) / D→(0.707,0,-0.707). Frente canónico -Z = 100% paralelo al movimiento. Sign-flip Slerp anti-oscilación. Patrón 3 niveles VisualHolder → PersonajeVisualRoot → ModeloCuerpo. Sin inclinación residual al mover. |
| Singletons Autoload (3) | `GameState` > `ItemDatabase` > `Inventario` | ✅ 100% | GameState MODO_MUNDO / MODO_UI, personaje se congela |
| Items estructurados | `scripts/recursos/item_definicion.gd` (Resource) + 12 `.tres` en `assets/items/` | ✅ 100% | Resources: madera/piedra/oro/semilla/hacha/pico/azada/regadera/semilla_tomate/semilla_zanahoria/tomate/zanahoria. ItemDefinicion.datos_extra para metadata por item. |
| Inventario Slots + Señales + Equipar Herramienta | `scripts/core/inventario.gd` | ✅ 100% | 20 slots `{id:StringName, cantidad:int}`, stack por item, señales: `inventario_cambiado()`, `item_agregado`, `herramienta_equipada_cambiada`. Herramienta inicial = puños (no StringName vacía). |
| Pickup Genérico (1 script) | `scripts/mundo/pickup.gd` | ✅ 100% | Reemplazó los 3 duplicados. Usa **GRUPOS** (no nombres fragiles). Detecta jugador y agrega a inventario. |
| NPC Base Herencia | `scripts/npc/npc_base.gd` > `scripts/npc/npc_tienda.gd` (Mercado) | ✅ 100% | Patrón Template Method: `get_prompt()`, `interactuar(jugador)`, `puede_interactuar()`. NPC Tienda abre UITienda correctamente. |
| **Interacción F Unificada** | `jugador.gd` `RangoInteraccion` Area3D | ✅ 100% | Solo el JUGADOR escucha la tecla F. Busca `has_method("interactuar")` de los cuerpos dentro. **Selecciona el más CERCANO por distancia**. Sin código duplicado xNPC. |
| Prompt Flotante (Label3D / Canvas) | Integrado en jugador.gd `_actualizar_prompt_interaccion()` | ✅ 100% | "[F] Abrir Mercado" encima de NPC. |
| Arbol / Roca | `scripts/mundo/arbol.gd`, `roca.gd` | ✅ 100% | Requieren Hacha/Pico equipados. Instancian PickupMadera / PickupPiedra (tamaño 0.3m correcto) al romperse. |
| Tienda + Crafteo | `scripts/ui/tienda.gd`, `crafteo.gd` | ✅ 100% | Botones Buttons no TextureButton. Compra semilla: gasta oro. Craftear hacha/pico: gasta materiales → si OK equipa. Actualiza HUD por señales. |
| HUD Recursos (Vida + Recuento) | `scripts/ui/ui.gd` (CanvasLayer) | ✅ 100% | ColorRect gris/rojo, márgenes 2px, cálculo por offsets. Barra de vida reacciona a `Damageable.vida_cambio` sin polling. |
| **Combate: Damageable (Componente)** | `scripts/combate/damageable.gd` (Node hijo, NO herencia) | ✅ 100% | Reutilizable: Jugador, Slimes, Muñeco, Árboles. Vida, i-frames 0.5s, señales danio_recibido/murio/vida_cambio. |
| Jugador Ataque Cuerpo a Cuerpo + Híbrido | `scripts/jugador/jugador.gd` `_intentar_atacar()` | ✅ 100% | Capa1 = Area3D HitboxAtaque body_entered. Capa2 = Cono Frontal Manual (PhysicsShapeQuery SphereShape 55° + distance). **Nunca falla** aunque CharacterBody se repelan físicamente. Anti-autogolpe 3 capas. |
| **Sistema Armas Data-Driven Resources** | `scripts/recursos/arma_definicion.gd` + 5 `.tres` | ✅ 100% | ArmaPunos/Hacha/Pico/Azada/Regadera. Carga automática desde carpeta (DirAccess). Modifica BoxShape3D runtime (sin recrear recursos). Rango calibrado ISO 1.6m→2.3m. |
| Hotkeys cambio de herramienta | `scripts/jugador/jugador.gd` `_unhandled_input()` | ✅ 100% | Key_1 Hacha, Key_2 Pico, Key_3 Azada, Key_4 Regadera, Key_5 Puños, Key_Q toggle puños/hacha. |
| Enemigos IA FSM (PATRULLA / PERSEGUIR / ATACAR) | `scripts/enemigos/enemigo_base.gd` > `EnemigoSlime.tscn` | ✅ 100% | Slime HP 50, daño 5, rango ataque ≥1.6m ISO. Drops oro+gel. Ataque cooldown 1.35s. |
| Spawner de Enemigos Genérico | `scripts/mundo/enemigo_spawner.gd` (Node3D) | ✅ 100% | PackedScene export, anillo seguridad 1-6m, max activos, cooldown anti-flood, conexión Damageable.murio + bind + varargs. |
| **Barra Vida 3D Reutilizable** | `scripts/combate/damageable_barra_3d.gd` class_name extends Node3D | ✅ 100% | SubViewport 512×96 + ColorRect (Fondo/Frente/Bordes) + Sprite3D Billboard. Sin Unicode █░⠀. Frente reduce solo lado derecho (izquierdo fijo). Sombra doble Label 3px (contorno números). Componente genérico (Slime, Muñeco, Boss…). @export ajustables por escena (ancho/alto/altura/fuente). |
| Granja + Siembra/Cosecha | `scripts/granja/parcela.gd` FSM 5 estados | ✅ 100% | VACIO/ARADA/PLANTADA/LISTO/MARCHITO. 4 etapas visuales PlantaTomate/PlantaZanahoria. Azada + Regadera + Pozo. |
| Input Map | Project Settings | ✅ 100% | WASD mover, **F = interactuar_mundo**, **ClickIzq/Space = atacar**, **E = Golpear/Rotar herramienta**, **1-5 = cambiar arma**, **Q = toggle puños**, **I = abrir mochila**, Enter = ui_confirmar |
| **FASE 4 — Diálogos + Misiones** | `scripts/npc/dialogo_*.gd` + `recursos/dialogos/*.tres` + `scripts/core/mision_manager.gd` | ✅ 100% | 3 Resources anidados (DialogoDefinicion > DialogoLinea > DialogoOpcion). DialogoDatabase escanea carpeta. Misiones data-driven con MisionManager. Flujo RPG: recolectar NO autocompleta (entrega manual). Opciones con `requiere_mision_activa` / `requiere_mision_no_activa`. |
| **FASE 5 — Mercado Data-Driven** | `scripts/recursos/catalogo_tienda.gd` + `item_tienda.gd` + `scripts/ui/tienda.gd` + `recursos/catalogos/Catalogo_Mercader.tres` | ✅ 100% | CatalogoTienda con Array[ItemTienda] (id_item, precio_compra_jugador, precio_venta_jugador, stock). UI 2 pestañas Comprar/Vender generada dinámicamente. NPC tienda integrado con `get_catalogo()`. |
| **Mochila / Inventario UI** | `scripts/ui/mochila.gd` + `icono_item.gd` + `escenes/ui/UIMochila.tscn` | ✅ 100% | GridContainer 5 columnas × 20 slots. Iconos placeholder por tipo de item (colores) si no hay textura. Apertura/cierre con tecla **I**. Refresco por señal `inventario_cambiado`. |
| Siguiente (FASE 6.1) | `scripts/recursos/receta_crafteo.gd` + `recursos/recetas/*.tres` | ⏳ Pendiente | Reemplazar crafteo hardcodeado por sistema data-driven con Resources: RecetaCrafteo + IngredienteReceta. Categorías y estaciones de crafteo. |
| **FASE 6 — Crafteo** | `receta_crafteo.gd`, `ingrediente_receta.gd`, `crafteo_manager.gd` (Autoload), `crafteo.gd`, `crafteo_manual.gd`, `estacion_crafteo.gd` | ✅ 100% | Recetas data-driven en `assets/recetas/`. CrafteoManager carga por carpeta (DirAccess). UI por estación (banco_trabajo/horno/molino) + crafteo manual en mochila (recetas `estacion_requerida=ninguna`). Estaciones son items colocables (tecla B) con preview translúcido. Agua como carga de regadera (no item). |
| **FASE 7 — Tiempo** | `gestor_tiempo.gd` (Autoload), `ciclo_dia_noche.gd` | ✅ 100% | GestorTiempo: minutos/horas/días, señales minuto_cambio/hora_cambio/dia_cambio, minutos_por_segundo exportable. Ciclo día/noche: luz direccional interpola color/intensidad/rotación por tramos de hora, inclinación de sol configurable. Integración: tiendas cierran de noche, parcelas solo crecen de día y reset riego cada día, spawners con `solo_noche`. |
| **FASES 8–21 — Expansión del Juego** | (ver detalle más abajo en el documento) | ⏳ Pendiente | Supervivencia (hambre/sueño), fauna/respawn, armas (espada/arco), clima/estaciones, niveles/XP, bosses, raids, biomas, mapa procedural, historia/NPCs, co-op, modelos 3D, renovación visual de HUD/UI, pulido final. |

---

## ✅ Checklist FASE 1 — 100% COMPLETADA

---

## ✅ Checklist FASE 1 — 100% COMPLETADA (25/09/2026)

| SubMódulo | Status |
|---|---|
| 1.1 Sistema Items Estructurados (ItemDefinicion + ItemDatabase + Inventario Slots + Señales) | ✅ 100% |
| 1.2 Interacción Unificada (Jugador escucha F, objetos implementan interactuar()/get_prompt()) | ✅ 100% |

> 🎯 **Aprendizajes clave FASE 1**:
> 1. **Resources custom (`.tres`) son la forma PROFESIONAL de guardar datos de items (no hardcodear diccionarios)**
> 2. **Singletons separados por responsabilidad**: GameState > ItemDatabase > Inventario (nunca todo en 1)
> 3. **Programación reactiva con SEÑALES**: UI no hace polling en `_process`, se actualiza cuando cambia algo.
> 4. **DRY Principle (Don't Repeat Yourself)** → 1 script `pickup.gd` reemplaza a 3 scripts duplicados.
> 5. **Herencia Template Method**: `NpcBase` clase padre → `NpcTienda` hija (override de métodos).
> 6. **DUCK TYPING + Método común `interactuar()`** = NO hay que escribir input listeners en cada NPC.
> 7. **ESCALA GLOBAL DEL PERSONAJE = 1.0 SIEMPRE**. Usar `VisualHolder` Node3D hijo para reducir mesh. No `0.1` en CharacterBody3D (evita bugs de tamaño/posición infinitos).
> 8. **Validación de inputs**: `GameState` modo_mundo / modo_ui → si UI abierta, personaje CONGELADO (no input mundo) → importante en TODO juego.

---

## 📦 FASE 2 — Módulo de Granja (Siembra → Cultivo → Cosecha)
> **Objetivo**: Sistema de **Parcela de Tierra** funcionando completo con ciclo de vida de semillas, integrado a la Interacción Unificada de FASE 1.2.
> **Aprendizajes clave al final**: State Machine, Duck Typing extendido, Item Semillas con datos extra, Tween interpolación visual, herramientas con durabilidad/carga (agua).

### ⏳ Orden de submódulos FASE 2 (NO saltarse pasos)
```
2.1 Parcela (State Machine) → 2.2 Items: Semillas + Cultivos (Resource .tres) → 2.3 PlantaVisual Prefab → 2.4 Herramienta: AZADA → 2.5 Herramienta: REGADERA + Pozo → 2.6 Integrar Jugador → 2.7 Test Ciclo Completo en mapa
```

---

### 2.1 Entidad Parcela (Tierra cultivable + State Machine 5 estados)

**Nuevos Archivos:**
- `scripts/granja/parcela.gd` (extends StaticBody3D)
- `escenes/granja/Parcela.tscn`

**Escena Parcela.tscn Jerarquía:**
```
Parcela (StaticBody3D)
├─ CollisionShape3D (BoxShape3D: size=1.0,0.1,1.0  → 1x1 metro, altura 10cm tierra)
├─ MeshInstance3D (Mesh: PlaneMesh / BoxMesh. Al principio texture tierra marrón)
└─ (vacío, luego meteremos el nodo PlantaVisual aquí)
```

**State Machine - 5 Estados (Constantes):**
| # | Constante | Descripción |
|---|---|---|
| 0 | `ESTADO_VACIO` | Tierra sin arar (pastito, no se puede plantar) |
| 1 | `ESTADO_ARADA` | Arada (azada), lista para poner semilla |
| 2 | `ESTADO_PLANTADA` | Tiene semilla, está creciendo (progreso 0%→100%) |
| 3 | `ESTADO_LISTO` | Cultivo MADURO, listo para cosechar |
| 4 | `ESTADO_MARCHITO` | Murió (3 días sin regar) - hay que limpiar con azada |

**Variables que tendrá `parcela.gd`** (hacerlo con @export lo máximo posible):
- `estado: int = ESTADO_VACIO`
- `semilla_id: StringName = &""` (cuando se planta, qué semilla tiene)
- `progreso: float = 0.0` (0.0 → 1.0 de crecimiento, 1.0 = ESTADO_LISTO)
- `regado: bool = false`
- `@export var velocidad_crecimiento_por_segundo: float = 0.02` (TEMPORAL hasta que tengamos GestorTiempo FASE 7. Con esto crece en 50s aprox, para testear rápido)
- `@export var dias_sin_regar_antes_marchitar: int = 3`

**Métodos PÚBLICOS:**
```gdscript
# Retornan BOOL para que el JUGADOR sepa si lo consiguió o informar al HUD:
func arar(herramienta_tipo: StringName) -> bool:     # Solo ESTADO_VACIO && herramienta == &"azada" → cambia a ARADA, cambia color mesh
func plantar(jugador: Node, semilla_id: StringName) -> bool: # Solo ESTADO_ARADA && hay semilla en inventario. Gasta 1 semilla. Cambia a PLANTADA, instancia PlantaVisual
func regar() -> bool:        # Solo ESTADO_PLANTADA. marca regado=true (solo se puede 1 vez al ciclo)
func avanzar_crecimiento(delta: float) -> void:  # _process(delta) si ESTADO_PLANTADA Y regado => progreso += delta * velocidad. Si progreso >=1 → ESTADO_LISTO + PlantaVisual cambia a etapa LISTO
func cosechar(jugador: Node) -> Array[Dictionary]:  # Solo ESTADO_LISTO. Devuelve Array de drops (para el jugador añadir al inventario / mostrar notificación). Cambia a ESTADO_ARADA, destruye PlantaVisual. Ej: [{id:"tomate", cant:3}]
func limpiar() -> bool:   # Solo ESTADO_MARCHITO. Vuelve a VACIO.
```

**Integrar con FASE 1.2: Métodos `interactuar()`, `get_prompt()`, `puede_interactuar()` (para F Unificada):**
```gdscript
func get_prompt() -> String:
    # Devolver texto según estado y herramienta equipada del jugador (lo puedes leer de Inventario.herramienta_equipada directamente dentro de este método, ya que Inventario es Autoload):
    match estado:
        ESTADO_VACIO: return "[F] Arar (necesita AZADA)" if Inventario.herramienta_equipada == &"azada" else "[F] (necesitas equipar la AZADA para arar)"
        ESTADO_ARADA: return "[F] Plantar SEMILLA" (if tienes alguna semilla en inventario else "[F] Sin semillas en el inventario"
        ESTADO_PLANTADA: return ("[F] Regar (REGADERA)" if Inventario.herramienta_equipada == &"regadera" and !regado else "... Creciendo " + str(round(progreso*100)) + "%  (Regado: " + str(regado) + ")")
        ESTADO_LISTO: return "[F+E?] ✅ Cosechar LISTO"
        ESTADO_MARCHITO: return "[F] Marchito (limpiar con AZADA)"

func interactuar(jugador: CharacterBody3D) -> void:
    # Hace la accion correcta segun estado:
    match estado:
        ESTADO_VACIO: arar(Inventario.herramienta_equipada)
        ESTADO_ARADA: plantar(jugador, _elegir_semilla())  # (toma la 1ª semilla que encuentre en inventario)
        ESTADO_PLANTADA: regar()
        ESTADO_LISTO: _aplicar_drops_a_inventario(cosechar(jugador))
        ESTADO_MARCHITO: limpiar()
```

---

### 2.2 Items NUEVOS: Semillas y Cultivos (extender .tres)

**Agregar a `scripts/recursos/item_definicion.gd`:** (NO romperá los .tres actuales - default vacíos):
```gdscript
@export var datos_extra: Dictionary = {}
```
O más tipado (mejor pero requiere nueva Resource): crear `scripts/granja/datos_semilla.gd` extends Resource:
```gdscript
@export var cultivo_resultado_id: StringName = &""  # id del item cosechado
@export var cantidad_por_cosecha_min: int = 1
@export var cantidad_por_cosecha_max: int = 3
@export var segundos_crecimiento_base: float = 45.0  # TEMPORAL (luego dias FASE 7)
```

**Crear nuevos .tres en `assets/items/` (empezar por 2 para testear):**

| Archivo `.tres` | id (StringName) | tipo | stack_max | datos extra |
|---|---|---|---|---|
| `item_semilla_tomate.tres` | `semilla_tomate` | semilla | 50 | `{cultivo: "tomate", min:2, max:4}` |
| `item_semilla_zanahoria.tres` | `semilla_zanahoria` | semilla | 50 | `{cultivo: "zanahoria", min:1, max:2}` |
| `item_tomate.tres` | `tomate` | cultivo | 99 | Precio venta: 5 oro |
| `item_zanahoria.tres` | `zanahoria` | cultivo | 99 | Precio venta: 3 oro |
| `item_azada.tres` | `azada` | herramienta | 1 | `herramienta_tipo = "azada"` |
| `item_regadera.tres` | `regadera` | herramienta | 1 | `herramienta_tipo = "regadera"`, `carga_agua_max = 5` (usar datos_extra) |

**IMPORTANTE**: Registrar estos 6 items NUEVOS en el array `items_a_cargar` de `scripts/core/item_database.gd` (añadir 6 `preload("res://assets/items/xxxx.tres"),`) ¡Si no se te olvida dará error al agregar_item!

---

### 2.3 Prefab Planta Visual (Por tipo de cultivo, 4 etapas mesh)

**Archivos:**
- `scripts/granja/planta_visual.gd` (extends Node3D)
- `escenes/granja/plantas/PlantaTomate.tscn`, `PlantaZanahoria.tscn`

**Dentro de cada escena (ej: PlantaTomate):**
```
PlantaTomate (Node3D - root)
├─ Etapa0 (MeshInstance3D, default visible: true)   # brote pequeño (Sphere escala 0.05 color verde)
├─ Etapa1 (MeshInstance3D, visible: false)           # planta mediana (cylinder 0.1 alto 0.15)
├─ Etapa2 (MeshInstance3D, visible: false)           # grande (altura 0.3)
└─ Etapa3 (MeshInstance3D, visible: false)           # LISTA: añadir esferas rojas = tomates :)
```

**Método `planta_visual.gd`:**
```gdscript
@onready var etapas: Array[MeshInstance3D] = [
    $Etapa0, $Etapa1, $Etapa2, $Etapa3
]

# Llamado por parcela.gd cuando progreso cambia:
func set_progreso(progreso_0_1: float) -> void:
    # Determina etapa (0..3) según progreso:
    var etapa_indice: int = 0
    if progreso_0_1 >= 1.0:
        etapa_indice = 3
    elif progreso_0_1 >= 0.66:
        etapa_indice = 2
    elif progreso_0_1 >= 0.33:
        etapa_indice = 1
    
    # Muestra SÓLO esa etapa, oculta el resto:
    for i in etapas.size():
        etapas[i].visible = (i == etapa_indice)
    
    # (OPCIONAL FUTURO): Tween suave interpolando scale para hacerlo crecer "animado"
```

**En `parcela.gd`:** Al plantar → `instanciar PlantaTomate.tscn` como hijo de Parcela, set `position.y=0.1`, y en cada tick `avanzar_crecimiento()` → `planta_visual.set_progreso(progreso)` si existe la referencia.

---

### 2.4 Herramienta AZADA (crafteable)

- Añade al **selector de herramientas (crafteo UI)** la **AZADA**:
  - Usa el mismo patrón que Hacha/Pico → nueva receta hardcodeada en `Inventario.craftear()`:
    ```gdscript
    elif tipo == "azada":
        if tiene_item(&"madera", 2) and tiene_item(&"piedra", 2):
            gastar_item(&"madera", 2); gastar_item(&"piedra", 2); agregar_item(&"azada", 1); return true
    ```
  - En `scripts/ui/crafteo.gd`: Añade **tercer Button** dentro del HBoxContainer (con texto: "⚒️ Azada"). Misma lógica que hacha: si no la tienes craftea, si la tienes equipa/desequipa toggle.
- En `scripts/jugador/jugador.gd` `_process()`: si `herramienta_equipada == &"azada"` → **visible = true** su mesh (debes crear un nodo `ModeloAzada` en `Jugador.tscn/VisualHolder`, igual que Hacha/Pico — usar una mesh cubo inclinado 45°)

---

### 2.5 Herramienta REGADERA + Objeto Pozo (llenar agua)

- **Item `regadera`** crafteable: `1 madera + 3 piedra`. Botón #4 en Crafteo UI.
- **Datos Regadera**: Usar `Inventario.datos_extra["carga_agua_actual"] = 0` y `max = 5`. O mejor variable global temporal por ahora.
- **Objeto POZO** en `mundo.tscn` (StaticBody3D interactuable, implementa `get_prompt()` y `interactuar()`):
  - Si jugador tiene regadera EQUIPADA → `[F] Llenar REGADERA (5/5)`. Al interactuar: llena `carga_agua_actual = max`.
- Al `parcela.regar()`: hay que gastar **1 unidad de agua** de la regadera. Si 0 → mostrar prompt: "Regadera VACÍA. Ve al pozo a llenarla"

---

### 2.6 Integrar TODO con Jugador (paso crucial)

**`jugador.gd` ya tiene todo. No tocar jugador!** (eso es lo bonito del patrón Fase 1.2):
- Parcelas tienen los métodos `interactuar(jugador)` → Jugador F llama a eso y se acabó.
- En `_actualizar_prompt_interaccion()` jugador ya detecta `has_method("get_prompt")` → Parcela también lo tiene → funciona sin cambios. ✅

Solo hay que **ASEGURARSE de que la Parcela StaticBody3D** pertenezca a **Capa Física visible** para que `RangoInteraccion` (jugador) la detecte (Collision Mask). Debería funcionar ya.

---

### 2.7 Colocar 6 Parcelas de PRUEBA en mundo.tscn

1. Abre mundo.tscn, crea carpeta vacía `Granja` como nodo padre.
2. Dentro → instancia `Parcela.tscn` 6 veces (grid 3x2):
   ```
   [Parcela] [Parcela] [Parcela]
   [Parcela] [Parcela] [Parcela]
   ```
   Position x, z separados 1.2 unidades (no se solapen). Position y = 0.05 para que se vea la tierra por encima del suelo.
3. Dale Play:
   - Acercar Parcela 1 (VACÍA) → prompt: "[F] (necesitas equipar la AZADA)". ✅
   - Equipar AZADA + F → "ARADA". Cambia color mesh tierra ✅.
   - Abrir Mercado (NPC Tienda) → Comprar 2 semillas tomate → F en Parcela arada → plantó, mesh PlantaVisual aparece, stage 0.
   - Equipar REGADERA (no olvides llenarla en pozo antes) → F en plantada → regado = true.
   - Esperar 45 segundos → progreso 100% → LISTO. prompt: "✅ Cosechar".
   - F → Ganas 2-4 tomates en inventario. Parcela vuelve a ARADA para replantar.
4. Si pasa todo esto → ✅ FASE 2 COMPLETA 100%

---

## 📦 FASE 3 — Módulo de Combate y Enemigos
> Objetivo: Sistema de vida, enemigos con IA, combate cuerpo a cuerpo, drops, experiencia.

### 3.1 — Componente Damageable (Vida/Daño)

Reusable para Jugador, Enemigos, incluso Objects rompibles.

**Archivo**: `scripts/combate/damageable.gd` (extends Node, se agrega como hijo NODO)

**Variables**:
- `@export var vida_maxima: int = 100`
- `var vida_actual: int` (inicializar en _ready = vida_maxima)
- `@export var es_invulnerable: bool = false`
- `@export var tiempo_invulnerabilidad: float = 0.5` (segundos tras recibir golpe)

**Señales**:
- `signal danio_recibido(cantidad: int, atacante: Node)`
- `signal murio(atacante: Node)`
- `signal vida_cambio(vida_nueva: int)`

**Métodos**:
- `recibir_danio(cantidad: int, atacante: Node)` → si no es invulnerable: restar vida, emitir señales, empezar timer invulnerabilidad, si <=0 emitir murio`
- `sanar(cantidad: int)`
- `_on_timer_invulnerabilidad_timeout()`

**Añadir como hijo**:
- En `Jugador.tscn` hijo `Damageable` con vida_max=100
- En cada Enemigo

### 3.2 — Jugador: Ataque Cuerpo a Cuerpo

En `scripts/jugador.gd`:

**Añadir**:
- Input: "atacar" (clic izquierdo o Espacio)
- Variables:
  - `@export var daño_ataque: int = 15`
  - `@onready var hitbox_ataque: Area3D = $HitboxAtaque` (Area3D de rango corto frente al jugador
  - `var ataque_cooldown: float = 0.4` seg
  - `var _tiempo_restante_cooldown: float = 0`
- En `_physics_process(delta)`: decrementar cooldown
- En `_unhandled_input`:
  - Si pulsa atacar Y cooldown == 0 → activar hitbox brevemente (0.2 seg con Timer)
  - Animación: con Tween rotar mesh de espada/hacha
- Conectar `hitbox_ataque.body_entered`:
  - Si body tiene nodo hijo Damageable → `damageable.recibir_danio(daño_ataque, self)`

### 3.3 — Enemigos: IA con Máquina de Estados (3 estados)

**Patrón**: Clase base `enemigo_base.gd` (extends CharacterBody3D) + hijo por tipo.

**Archivo**: `scripts/enemigos/enemigo_base.gd`

**Estados**:
```
ESTADO_PATRULLA = 0    # camina aleatorio por su zona
ESTADO_PERSEGUIR = 1    # sigue al jugador
ESTADO_ATACANDO = 2    # está cerca, golpea
```

**Variables (base**:
- `@export var rango_deteccion: float = 6.0`
- `@export var rango_ataque: float = 1.8`
- `@export var velocidad_patrulla: float = 1.2`
- `@export var velocidad_persecucion: float = 2.5`
- `@export var daño: int = 10`
- `@export var cooldown_ataque: float = 1.2`
- `@export var drops: Array[Dictionary]` → `[{id: StringName, probabilidad: float 0.0-1.0, min: int, max: int}]`
- `var estado_actual = ESTADO_PATRULLA`
- `var objetivo: Node3D` (referencia al jugador, buscar con `get_tree().get_first_node_in_group("jugador")` poner a Jugador en grupo "jugador")

**Lógica por estado en `_physics_process`**:
- **PATRULLA**: cada X segundos escoge punto aleatorio en radio → moverse hacia él; si distancia al jugador `< rango_deteccion → PERSEGUIR
- **PERSEGUIR**: velocity hacia global_position del jugador; si está `< rango_ataque → ATACANDO; si se aleja mucho → volver PATRULLA
- **ATACANDO**: parar, si cooldown listo → llamar `Jugador.damageable.recibir_danio(daño); si jugador se aleja → PERSEGUIR

**Conectar `damageable.murio`**:
- Instanciar drops como Pickups (de FASE 1)
- Spawn de enemigo eliminar nodo, queue_free()
- Añadir XP (si se implementa XP)
- Partículas/sonido opcional

**Primer enemigo**: `scripts/enemigos/enemigo_slim.gd` → `extends EnemigoBase` con Mesh cápsula azul, 20 de vida, 5 de daño, drops = moco + oro

### 3.4 — Spawner de Enemigos

**Archivo**: `scripts/mundo/enemigo_spawner.gd`
- Variables: `escena_enemigo: PackedScene`, `max_enemigos: int = 4`, `radio_spawn: float = 40`, `intervalo: float = 15.0`
- Cada `Timer` cada intervalo → si enemigos_vivos < max → posicion aleatoria alrededor del spawn, al menos radio X metros del jugador → instanciar escena_enemigo
- Colocar Spawner.tscn en el mundo

---

## 🔧 FASE 3.X — Correcciones de Pilares Técnicos (OBLIGATORIAS ANTES DE FASE 3.4)

> **Motivo**: Al detectarse que la cadena de transforms de Jugador/Cámara/HUD tenía "parches compensatorios" (rotación 45° en raíz, Camera.tscn escala ×0.1, TextureRect sin textura) que generaban bugs encadenados (WASD invertido, jugador invisible, barra vida no se ve), se realiza esta fase intermedia de limpieza técnica para que todos los sistemas queden en **IDENTIDAD / BASES CANÓNICAS** y no sigan apareciendo bugs nuevos por compensación.
>
> **Regla canónica adoptada para siempre (igual que "scale=1.0 global")**: 
> 1. Nodo raíz CharacterBody3D = Transform3D **IDENTIDAD** (rotation=0, scale=1)
> 2. PackedScene Camara.tscn = Transform3D **IDENTIDAD** (nunca encapsular escala/rotación en él)
> 3. VisualHolder = Nodo3D hijo de Jugador, donde reside TODA la rotación/escala visual de modelos. La Camera NUNCA es hija de VisualHolder (solo de la raíz).
> 4. HUD Barras: usar `ColorRect` (no `TextureRect`) para elementos de UI sólidos. No depender de SubResources de textura que se pierden.

### Orden estricto 3.X.A → 3.X.B → 3.X.C:
```
3.X.A (HUD ColorRect) → 3.X.B (Camara + Vectores ISO) → 3.X.C (Foco VisualHolder Quaternion.slerp)
```

---

### 3.X.A — HUD Barra de Vida: TextureRect → ColorRect + Cálculo Robusto

**Objetivo**: Que la barra sea 100% visible el 1er frame, sin dependencia de texturas.

**Archivos a modificar**:
- `escenes/ui/UIHud.tscn`
- `scripts/ui/ui.gd`

**Paso a paso detallado**: (Ver guía en el chat del 27/09/2026)

**Checklist de éxito**:
- [ ] `BarraVidaExterior` es de tipo `ColorRect`, `color` gris oscuro alpha 0.85, tamaño ~250×32 px, posición esquina izq-medio pantalla (≈ offset 10,150 → 260,182).
- [ ] `BarraVidaInterior` es de tipo `ColorRect` (hija de Exterior), `color` rojo intenso. Offsets iniciales: left=2, top=2, right=248, bottom=30 (margen de 2px por los 4 lados dentro de la caja exterior).
- [ ] `ui.gd` → `@onready` tipados como `ColorRect` (no TextureRect).
- [ ] `_on_jugador_vida_cambio`: cálculo ancho basado en `(offset_right - offset_left)` del padre, const MARGEN_X/Y = 2.0, `offset_right = MARGEN_X + (ancho_util * pct)`.
- [ ] Consola muestra: `"[UI HUD] ✅ Damageable del jugador conectado."` + `"[UI HUD] Vida jugador 100/100 → 100%"`.
- [ ] Al entrar en contacto con `PinchitoPrueba`: barra roja se reduce proporcionalmente en PIXELES REALES (no ancho=0).

---

### 3.X.B — Cadena Cámara Isométrica Canónica (Base Identidad everywhere)

**Objetivo**: Resetear todos los "parches de rotación/escala encapsulada" para que velocity coincida con ejes mundanos. Jugador siempre visible en el centro.

**Archivos a modificar**:
- `escenes/mundo_base/Camara.tscn`
- `escenes/jugador/Jugador.tscn`
- `scripts/jugador/jugador.gd`

**Paso a paso detallado**: (Ver guía en el chat del 27/09/2026)

**Checklist de éxito**:
- [ ] `Camara.tscn` (nodo Camera3D packed scene) = **SIN transform asignado** → identidad total. Solo `projection=1` (ortográfica).
- [ ] `Jugador.tscn` raíz Jugador (CharacterBody3D) = Transform3D IDENTIDAD (rotation=0,0,0; scale=1,1,1; position=0,0,0).
- [ ] `Jugador.tscn` nodo Camera (instancia hija de Jugador): position=(15,18,15) local, Basis=IDENTIDAD, current=true, size≈14.0.
- [ ] `jugador.gd` `@onready var camara: Camera3D = $Camera` añadido.
- [ ] `jugador.gd` `_ready()` → `camara.look_at(global_position, Vector3.UP)` SIEMPRE antes de cualquier cosa.
- [ ] Al dar Play: modelo cápsula Jugador visible en el CENTRO de la ventana, vista diamante isométrica. Consola: `"[Jugador] Cámara enfocada al jugador desde pos=(15, 18, 15)"`.

---

### 3.X.C — Movimiento ISO calibrado + Foco Frontal VisualHolder (Quaternion.slerp)

**Objetivo**: WASD coincida con intuición visual (W=arriba, D=derecha, S=abajo, A=izq). VisualHolder gira suavemente hacia la dirección de movimiento SIN descuadre de posición.

**Archivos a modificar**:
- `scripts/jugador/jugador.gd` → reescribir bloque `_procesar_movimiento()`

**Paso a paso detallado**: (Ver guía en el chat del 27/09/2026)

**Vectores ISO canónicos (4 combinaciones posibles — calibrar por observación con FrenteMesh)**:

> **Método infalible de calibración:**
> 1. Añade un `MeshInstance3D` llamado `FrenteMesh` (ej: un `BoxMesh` delgado alargado `size=(0.08,0.08,0.8)`) **como hijo de `VisualHolder`** en posición local `(0, 0.3, -0.8)`. Esta "flecha" muestra hacia dónde apunta el eje `-Z` (forward) local de VisualHolder tras el look_at.
> 2. Añade un `Label3D` DEBUG `DebugMov` (hijo de Jugador, posición global 3m sobre el jugador, `billboard = 1` enabled) que muestre en texto plano los signos actuales y la dirección visual.
> 3. Pulsa **solo W** y observa hacia qué punta del rombo apunta `FrenteMesh`:
>    - Si apunta a **PUNTA DERECHA** (tu síntoma actual) = los vectores canónicos #1 están **rotados 90° en sentido horario respecto al mapa real**. Solución directa → **Combinación #3**.
>    - Si apunta a **PUNTA SUPERIOR** = canónico perfecto → **Combinación #1**.

| Comb. | `iso_arriba` (W) | `iso_derecha` (D) | Resultado visual | Cuándo usar |
|---|---|---|---|---|
| #1 (Canónico) | `( 1, 0,-1)` | `( 1, 0, 1)` | W = punta sup-izq / D = punta inf-der | Si +X se ve como "arriba-izquierda" visual |
| #2 (Rot 90° antihorario) | `(-1, 0,-1)` | `( 1, 0,-1)` | W = arriba / D = derecha estándar | Si con #1 FrenteMesh W apunta a PUNTA IZQUIERDA |
| #3 (Rot 90° horario) | `( 1, 0, 1)` | `( 1, 0,-1)` | **W = arriba / D = derecha** (CASO DE AUKANE 28/09/2026) | Si con #1, al pulsar **W** → FrenteMesh apunta a **PUNTA DERECHA** (tu síntoma) |
| #4 (Rot 180°) | `(-1, 0, 1)` | `(-1, 0,-1)` | W = abajo / D = izquierda (todo invertido) | Si todo sale al revés (rot total 180) |

*👉 **Tu fix inmediato (basado en tu evidencia de FrenteMesh = punta derecha W):** cambia las 2 líneas de los vectores ISO a la **Combinación #3**.*

---

**Rotación VisualHolder — Patrón PROFESIONAL (nunca usar Transform3D.interpolate_with en nodos en movimiento)**:
- Extraer `Quaternion` actual y objetivo de la `Basis` del global_transform.
- `Quaternion.slerp(objetivo, factor)` → giro suave esférico (nunca pasa por singularidades de Euler).
- Reconstruir la `Basis` con ese cuaternión → asignar SÓLO `.basis` al global_transform (nunca tocar `.origin`).
- Factor de slerp = `clamp(delta * 12.0, 0.0, 1.0)` (12 = velocidad de giro; ajustar entre 8-20).

**Checklist de éxito**:
- [ ] WASD: W=arriba visual diamante, D=derecha, S=abajo, A=izquierda. Velocidad andar/correr idéntica en las 8 direcciones (gracias a `.normalized()` final).
- [ ] Mientras se mueve: la herramienta equipada (hacha/pico/etc.) apunta suavemente hacia la dirección de movimiento. Giro fluido sin saltos al cambiar bruscamente W → D.
- [ ] Cuando el jugador SE DETIENE: VisualHolder se queda "congelado" mirando hacia la última dirección (útil después para hitbox direccional de armas).
- [ ] La camera PERMANECE SIEMPRE fija (no rota, no se mueve de su posición relativa 15,18,15).
- [ ] No aparece ningún "drift" / desvío gradual de posición del VisualHolder respecto al Jugador después de 2 min andando en círculos.

---

## 📦 FASE 4 — Módulo de Diálogos y Sistema NPC
> Objetivo: Árboles de diálogo data-driven, misiones.

### 4.1 — Sistema de Diálogo con Resources

**3 Resources anidados**:
1. `scripts/recursos/dialogo_opcion.gd` → `texto_opcion: String`, `siguiente_dialogo: StringName`, `efecto: StringName` (&"" = nada), `parametros_efecto: String`
2. `scripts/recursos/dialogo_linea.gd` → `personaje: String`, `texto: String`, `opciones: Array[DialogoOpcion]`
3. `scripts/recursos/dialogo.gd` → `id: StringName`, `lineas: Array[DialogoLinea]`

**Base de Datos Diálogos**: `scripts/core/dialogo_database.gd` (Autoload)
- Diccionario `var dialogos: Dictionary[StringName, Dialogo]`
- Cargar todos `.tres` de `assets/dialogos/`
- Método `get_dialogo(id) -> Dialogo`

**Crear diálogos ejemplo en `assets/dialogos/`**:
- `dialogo_alfonso_bienvenida.tres` (3-4 líneas + 2 opciones: "¿Qué vendes?" → efecto abrir tienda", "Adiós" → cerrar)

### 4.2 — UI Panel de Diálogo

**Escena**: `escenes/ui/UIDialogo.tscn` (CanvasLayer / Control:
- `Label Nombre NPC (arriba)
- `RichTextLabel` Texto (centro, grande)
- `VBoxContainer` Opciones (abajo, botones dinámicos)

**Script**: `scripts/ui/ui_dialogo.gd`:
- Métodos:
  - `abrir(dialogo_id: StringName)`
  - `mostrar_linea(indice_linea: int)` → actualizar labels, limpiar botones, si opciones vacías → botón "Siguiente" (solo un botón de siguiente, si es última línea → cerrar)
  - `_on_opcion_pressed(indice_opcion: int)`
  - `ejecutar_efecto(efecto, params)` → switch en efecto: abrir_tienda → llamar NPC.activar_mision → MisionManager.aceptar, dar_item → Inventario.agregar

### 4.3 — Sistema de Misiones

**Resource Mision.gd**:
- `scripts/recursos/mision.gd` → id, nombre, descripcion
- `objetivo_tipo: StringName` (recolectar / matar / hablar)
- `objetivo_item_id: StringName`
- `objetivo_cantidad: int`
- `progreso_actual: int = 0` (no export, runtime)
- `recompensas_items: Array[Dictionary]`
- `recompensa_oro: int`

**Manager Misiones** `scripts/core/mision_manager.gd` (Autoload):
- Variables misiones_activas: Array[Mision]
- misiones_completadas: Array[Dictionary]
- Métodos aceptar_mision(mision_id)
- actualizar_progreso(tipo_objetivo, id_item/cantidad
- completar_mision(indice)
- Señales mision_aceptada, mision_actualizada, mision_completada

**Conectar Progreso**:
  - Inventario.inventario_cambiado → revisar misiones de recolectar
  - EnemigoBase.murio → revisar misiones matar
  - NPC.interactuar → revisar misiones hablar

**Actualizar `npc_1.gd` de FASE 1: su `interactuar()` abre UI Dialogo con `DialogoDatabase.get_dialogo(dialogo_inicial_id)`.

---

## 📦 FASE 5 — Módulo de Mercado Completo
> Objetivo: Catálogos por tienda, vender, precios variables.

### 5.1 — Catálogos Tienda Data-driven

**Resource `scripts/recursos/tienda_catalogo.gd`
- Variables:
  - `id_tienda: StringName`
  - `nombre_tienda: String`
  - `entradas_venta: Array[EntradaTienda]`
    - Cada entrada (otro Resource `EntradaVenta`: `item_id: StringName`, `precio: int`, `stock: int` (-1 infinito)
  - `ids_compra: Array[StringName]` (items que la tienda compra al jugador)
  - `multiplicador_compra: float = 0.5` (50% del precio base del item)
  - `horario_apertura: int = 8`
  - `horario_cierre: int = 20`

**Crear catálogos `.tres` en `assets/catalogos_tienda/`**:
- `tienda_semillas.tres` (vende semillas + azada + regadera; compra cultivos)
- `tienda_herrero.tres` (vende pico mejorado, compra piedra/oro)

### 5.2 — UI Tienda con 2 Pestañas

**Nueva escena `UITienda.tscn` reemplaza la tienda actual:
- `TabContainer` → Pestaña COMPRAR / Pestaña VENDER
- **Pestaña COMPRAR**: Grid de `ItemTiendaEntry (icono, nombre, precio, botón Comprar, SpinBox cantidad
- **Pestaña VENDER**: Lista de items del inventario que estan en ids_compra, mostrar precio_venta, botón Vender, SpinBox

**Script `scripts/ui/ui_tienda.gd`
- Método `abrir(catalogo: TiendaCatalogo, npc_referencia: Node)`
- Métodos internos `_comprar(item_id, cantidad)`:
  - Validar oro >= gastar_item("oro")
  - Validar stock
  - Agregar item a inventario
  - Restar stock si no es infinito
- `_vender(item_id, cantidad)`:
  - Agregar oro
  - Quitar item

### 5.3 — NPC actualizar NPCs que son Tienda

Actualizar `npc_1.gd` (o crear `tienda_nuevo) con variable `catalogo_asignado: TiendaCatalogo` y al abrir tienda, pasa su catálogo a la UI.
- `puede_interactuar()`: si GestorTiempo.hora está entre apertura/cierre horas horario → true; si no → diálogo "Cerrado"

---

## 📦 FASE 6 — Crafting Avanzado
> Objetivo: Reemplazar 2 recetas hardcodeadas. Categorías + estaciones.

### 6.1 — Sistema de Recetas con Resources

**`scripts/recursos/receta_crafteo.gd`
- `id: StringName`
- `nombre_resultado_id: StringName`, `cantidad_resultado: int`
- `ingredientes: Array[IngredienteReceta]` (otro Resource: `item_id`, `cantidad`)
- `categoria: StringName` (herramientas/comida/edificios/mejoras)
- `estacion_requerida: StringName` (&"ninguna", "banco_trabajo", "horno", "yunque")
- `desbloqueado_por_defecto: bool = true`

Crear carpeta `assets/recetas/` con:
- `receta_hacha.tres`, `receta_pico.tres`, `receta_azada.tres`, `receta_regadera.tres`, `receta_pan.tres` (harina + agua en horno)

### 6.2 — Crafteo Manager

**`scripts/core/crafteo_manager.gd`** (Autoload o no, o como componente):
- Carga todas las recetas
- `todas_recetas: Array[RecetaCrafteo]` o diccionario
- Métodos:
  - `get_recetas_por_categoria(categoria, estacion_actual)`
  - `puede_craftear(receta) -> bool` (revisa inventario tiene todos los ingredientes)
  - `craftear(receta) -> bool` (gasta ingredientes, agrega resultado

### 6.3 — UI Crafteo Nueva

Reemplaza `scripts/crafteo.gd`:
**Escena** `UICrafteo.tscn`:
- Panel izquierdo: Tabs categorías
- Panel derecho: Lista recetas (filtrada por categoría + estación)
  - Cada entry: icono, nombre, listado ingredientes (verde si tiene, rojo si falta)
  - Botón craftear (solo activo si puede_craftear

### 6.4 — Estaciones Crafteo (objetos en el mundo
`scripts/mundo/estacion_crafteo.gd`
- StaticBody3D Interactuable
- `@export var tipo: StringName` = banco_trabajo
- Al interactuar abre UICrafteo filtrada por ese tipo
- Ejemplos: BancoTrabajo.tscn, Horno.tscn, Yunque.tscn

---

## 📦 FASE 7 — Sistema Día/Noche y Tiempo
> Objetivo: Unifica todo, todo el progreso del juego.

### 7.1 — Gestor de Tiempo Autoload

**`scripts/core/gestor_tiempo.gd`** (Autoload):

**Concepto Tiempo**:
```
1 segundo real = X minutos juego (configurable
Así 1 día juego = 24 min real aprox.)
```

**Variables**:
- `@export var minutos_por_segundo_real: int = 60`
- `var hora: int = 6`
- `var minuto: int = 0`
- `var dia: int = 1`
- `var mes: int = 1`
- `var estacion: StringName = &"primavera"`
- `var año: int = 1`
- `var _acumulador_minutos: float = 0.0`

**Señales CRÍTICAS**:
```gdscript
signal tiempo_cambio(hora, minuto)   # cada minuto juego
signal hora_cambio(nueva_hora)    # cada hora juego
signal nuevo_dia(dia, mes, estacion, año)
signal nueva_estacion(estacion_nueva, anterior)
```

**Lógica `_process(delta)`**:
```
_acumulador_minutos += delta * minutos_por_segundo_real
mientras _acumulador_minutos >= 1:
    _acumulador_minutos -= 1
    minuto += 1
    si minuto >=60: minuto=0; hora++ → emitir hora_cambio
    emitir tiempo_cambio
fin
    si hora>=24: hora=0; dia++, emitir nuevo_dia, actualizar estaciones
```

### 7.2 — Ciclo Visual Día/Noche

**En `scripts/mundo/luz.gd` (asociado a `luz.tscn DirectionalLight3D + WorldEnvironment)**:
- Conectado a `GestorTiempo.tiempo_cambio`
- Interpolar con Tween cada cambio de hora:
  - `light_energy` (0.15 noche → 1.0 al 12h → 0.15)
  - `light_color` (#203060 noche → naranja amanecer 6h → blanco 10-14h → naranja atardecer 19h → azul noche)
  - `rotation_degrees.x/y` (mover sol por cielo de amanecer a atardecer)
  - `environment ambient_color` WorldEnvironment.sky (opcional)

### 7.3 — Integrar en todos los sistemas

- **Granja Parcela**: escuchar `GestorTiempo.nuevo_dia` → llamar `avanzar_un_dia()` de cada parcela
- **Spawner Enemigos**: `GestorTiempo.hora >=20 or <=5` → activar spawn; si no, desactivar
- **Tiendas NPC**: `puede_interactuar()` revisa `GestorTiempo.hora` entre apertura y cierre
- **NPC diálogos diferentes según la hora

---

## 🗂️ Estructura Carpetas Final

```
aukane/
├── assets/
│   ├── items/                      (*.tres: item_madera.tres, item_hacha.tres...)
│   ├── dialogos/                (*.tres diálogos)
│   ├── recetas/                 (*.tres recetas crafteo)
│   ├── catalogos_tienda/            (*.tres catálogos)
│   ├── misiones/                (*.tres misiones)
│   ├── iconos/                  (.png texturas UI)
│   └── modelos/                    (modelos 3D, materiales)
├── scripts/
│   ├── core/                    (Autoloads: inventario.gd, item_database.gd, gestor_tiempo.gd, dialogo_database.gd, mision_manager.gd, crafteo_manager.gd)
│   ├── recursos/               (item_definicion.gd, dialogo.gd, receta_crafteo.gd, tienda_catalogo.gd, mision.gd)
│   ├── jugador/              (jugador.gd, daño, anim)
│   ├── combate/             (damageable.gd + hitbox utilidades)
│   ├── mundo/             (pickup.gd, arbol.gd, roca.gd, enemigo_spawner.gd, estacion_crafteo.gd)
│   ├── granja/            (parcela.gd, planta_visual.gd)
│   ├── enemigos/          (enemigo_base.gd, enemigo_slime.gd, enemigo_lobo.gd)
│   ├── npc/               (npc_base.gd, npc_1.gd...)
│   └── ui/                (ui.gd HUD, ui_tienda.gd, ui_dialogo.gd, ui_inventario.gd, ui_crafteo.gd, ui_misiones.gd)
└── escenes/
    ├── ui/                 (UITienda.tscn, UIDialogo.tscn, UICrafteo.tscn, UIMisiones.tscn)
    ├── granja/             (Parcela.tscn, PlantaTomate.tscn...)
    ├── enemigos/          (EnemigoSlime.tscn)
    ├── estaciones/        (BancoTrabajo.tscn, Horno.tscn)
    └── mundo.tscn (mundo principal)
```

---

## ✅ Registro de Progreso Manual

Cada vez que se complete una fase o submódulo se marca aquí para seguimiento:

| Fase / Módulo | Estado | Fecha | Notas |
|---|---|---|---|
| FASE 1.1 Sistema Items estructurado | ✅ Completado | 25/09/2026 | ItemDefinicion + ItemDatabase + Inventario 20 slots + señales |
| FASE 1.2 Interacción unificada | ✅ Completado | 25/09/2026 | Jugador escucha F. Objetos implementan interactuar()/get_prompt()/puede_interactuar(). RangoInteraccion Area3D selecciona objeto MAS CERCANO. |
| FASE 2.1 Parcela (State Machine 5 estados) | ✅ Completado | 25/09/2026 | 5 estados VACIO/ARADA/PLANTADA/LISTO/MARCHITO. Integración con patrón Interactuar Unificado F. |
| FASE 2.2 Items: Semillas y Cultivos (Resources) | ✅ Completado | 26/09/2026 | 12 items .tres registrados en ItemDatabase: madera/piedra/oro/hacha/pico/azada/regadera/semilla/semilla_tomate/semilla_zanahoria/tomate/zanahoria. ItemDefinicion.datos_extra para metadatos. |
| FASE 2.3 Prefab PlantaVisual | ✅ Completado | 26/09/2026 | planta_visual.gd (4 etapas Node3D, set_progreso, cache _ultima_etapa_mostrada). Escenas PlantaTomate.tscn / PlantaZanahoria.tscn con etapas asignadas por Inspector. |
| FASE 2.4 Herramienta AZADA | ✅ Completado | 26/09/2026 | Crafteable: 2 madera + 2 piedra. Arar valida tipo de herramienta equipada. Mesh Azada en jugador VisualHolder. |
| FASE 2.5 REGADERA + POZO | ✅ Completado | 26/09/2026 | Crafteable: 1 madera + 3 piedra. Inventario.datos_variables_por_item (carga_agua_actual / carga_max_agua). Pozo estático interactuable llena la regadera. Parcela valida CARGA > 0 antes de regar. |
| FASE 2.6 Integrar con Jugador | ✅ Completado | 25/09/2026 | Sin cambios en jugador.gd — patrón Duck Typing + métodos interactuar() de la Parcela se integran automáticamente por RangoInteraccion. |
| FASE 2.7 Test ciclo completo (6 parcelas grid 3x2) | ✅ Completado | 26/09/2026 | 6 parcelas colocadas grid 3x2 en nodo Granja (mundo.tscn). FIX CRÍTICO: material de cada Parcela se .duplicate(true) en _ready() para evitar SubResource compartido (sino todas cambiaban color a la vez). Tienda ampliada a 3 botones compra: Semilla Básica, Semilla Tomate, Semilla Zanahoria. Bucle completo validado: Arar → Plantar → Llenar regadera (Pozo) → Regar → Esperar crecimiento 4 etapas visuales → Cosechar (drops aleatorios tomate/zanahoria con min/max por semilla) → Replantar sin volver a arar. |
| FASE 3.1 Damageable (vida/daño reusable Componente) | ✅ Completado | 26/09/2026 | damageable.gd (nodo hijo extends Node, NO herencia). Señales: danio_recibido / murio / vida_cambio. Variables @export vida_maxima, tiempo_invulnerabilidad (i-frames 0.5s), es_invulnerable. Métodos recibir_danio(), sanar(), getters. Jugador.tscn: agregado nodo hijo Damageable + script adjunto (100 HP). UIHUD.tscn barra de vida roja 200x25 conectada a vida_cambio (poll _process hasta encontrar Damageable por grupo "jugador"). Test pinchito_prueba.gd (Area3D pulsos 1.5s) valida recibir_danio(10), barra baja al 90%, i-frames evitan multi-golpes <0.5s. |
| FASE 3.2 Jugador ataque cuerpo a cuerpo | ✅ Completado | 26/09/2026 | Jugador.tscn nodo hijo HitboxAtaque (Area3D monitoring=OFF base, collision_mask=1, pos Z+1.4 size 1.2×1.4×1.2). jugador.gd: input ataque (click izquierdo DIRECTO InputEventMouseButton + Space/Enter fallback), cooldown 0.6s, hitbox activo 250ms, overlap check al activar (await process_frame + get_overlapping_bodies) para no perder cuerpos ya solapados, _objetos_golpeados_en_este_golpe Array[NodePath] anti-spam mismo objetivo, filtro no auto-dañarse (is_ancestor_of). Daño 15. Test: MuñecoPractica StaticBody3D (HP 60, Damageable hijo, script muneco_practica.gd conecta danio_recibido/murio, desaparece con tween.queue_free). 4 golpes = muerte, cooldown respeta 0.6s. |
| FASE 3.3 Enemigos IA (State Machine) | ✅ Completado | 26/09/2026 | enemigo_base.gd FSM (PATRULLA / PERSEGUIR / ATACAR). EnemigoSlime.tscn: CharacterBody3D + Damageable hijo (HP 20, daño 5, velocidad 2.5/3.5, rango detección 6). Ataque por proximidad: `get_tree().get_first_node_in_group("jugador")` + DistanceTo. Drops: PickupOro 50% (1-2) + gel slime 100% (1). Collision Mask correctamente configurada. Filtro no atacar objetos Suelo/LimitesMapa. Procesamiento overlaps solapados con `call_deferred` (no await) para consistencia física. |
| FASE 3.X.A HUD Vida ColorRect robusto | ✅ Completado | 27/09/2026 | BarraVidaExterior/Interior = ColorRect gris/rojo. Márgenes de 2px. Cálculo por offsets no .size. Consola confirma conexión y % vida visible correctamente. |
| FASE 3.X.B Cadena Cámara Identidad Canónica | ✅ Completado | 27/09/2026 | Camara.tscn = IDENTIDAD. Jugador.tscn raíz = IDENTIDAD. Camera hija posición (15,18,15) + `camara.look_at(global_position, Vector3.UP)` en _ready(). Vista diamante isométrica perfecta, jugador siempre centrado. |
| FASE 3.X.C Movimiento ISO + Quaternion.slerp VisualHolder | ✅ Completado | 28/09/2026 | Calibración ISO confirmada para este mapa: `ISO_ARRIBA(-0.707,0,-0.707)`, `ISO_DERECHA(+0.707,0,-0.707)` (W→P.Superior, D→P.Derecha). Rotación Quaternion.slerp aplicada solo a `VisualHolder.transform` (no raíz, no cámara). Fix crítico **Sign-flip Slerp**: `if q_actual.dot(q_objetivo)<0: q_objetivo=-q_objetivo` (elige siempre arco corto ≤180°, elimina oscilación cíclica infinita). Rotación inicial `_ready()` = mirar a la cámara. Caso idle = slerp suave volver a mirar cámara (factor 5). Estrategia escalable personaje 3D externo (Patrón 3 niveles): `VisualHolder (único que gira) → PersonajeVisualRoot (rot 0) → ModeloCuerpo (solo rot LOCAL para calibrar orientación mesh; personaje Blender export +Z → rot Y=180° local ModeloCuerpo, 0 líneas código cambiar).` Debug_FrenteCanonico (-Z frente visible permanente, elimina adivinanzas). Prueba matemática OK: `movimiento.dot(-Z_Holder) ≈ 1.0` (paralelismo perfecto). 🧠 Lecciones parser GDScript 2 guardadas: (1) NUNCA usar inferencia `:=` para Transform3D/Basis/Quaternion; tipar explícito. (2) NUNCA `.normalized()` o métodos en inicializaciones de variables globales fuera de funciones; usar literales numéricos precalculados (`0.70710678 = 1/√2`). (3) Identación de scripts = TABS (no espacios), usar `Edit → Convert Indent to Tabs` tras cada copiar/pegar de chat.
| FASE 3.4 Spawner | ✅ Completado | 28/09/2026 | `scripts/mundo/enemigo_spawner.gd` (Node3D): sistema genérico y 100% desacoplado por `@export var escena_enemigo: PackedScene` (mismo spawner para Slimes / Esqueletos / Orcos sin cambiar código). Características: (1) Anillo de spawn seguridad: `radio_min_spawn`/`radio_max_spawn` (no spawnea encima del jugador → área de spawn en forma de anillo alrededor). (2) Población máxima por spawner: `max_enemigos_simultaneos` (anti-overload CPU). (3) Cooldown anti-flood: `cooldown_entre_spawns` (3-5s entre intentos). (4) Eficiente 0 polling: conexión DIRECTA a la señal `Damageable.murio` de cada enemigo al instanciarlo + `.bind(instancia)` para saber cuál enemigo concreto muere. (5) Callbacks "varargs" (múltiples parámetros opcionales) en `_on_enemigo_murio()` — compatible con CUALQUIER signatura de la señal (0 / 1 / N parámetros), no falla por incompatibilidad. (6) Fallbacks safety: si la señal no llega, cuenta de activos no se queda pillada (descuento preventivo). (7) Jerarquía limpia: enemigos instanciados como hijos del PADRE del spawner (no del spawner) → mover el spawner no arrastra los slimes. Test OK: 4/5 slimes spawneados, matar 1 → pasa a 3/5, a los 3s se rellena el hueco automáticamente hasta volver a 5/5 y se detiene. 🧠 Calibración histórica guardada para mapas isométricos: rango ataque cuerpo a cuerpo enemigo (collision hitbox distancia al jugador) **≥ 1.6**; valores <1.5 no alcanzan al jugador por compresión visual de la cámara ortográfica isométrica (distancia euclídea en XZ no coincide con distancia visual en pantalla). Como nodo: NO hay escena Spawner dedicada, el script se adjunta a un Node3D genérico en `mundo.tscn` (SpawnerSlimes / SpawnerZonaNorte, etc. múltiples spawners independientes, mismo script). Uso de `randf()*TAU` + `cos/sin` para puntos aleatorios en círculo polar XZ (posición en anillo), `set_process(false)` si faltan exports para no gastar CPU en spawners rotos. |
| FASE 3.5 Sistema de Armas y Alcance + Barras de Vida 3D | ✅ Completado | 03/10/2026 | **Arquitectura de Armas Data-Driven (Resources)**: `scripts/recursos/arma_definicion.gd` Resource class con campos: `nombre`, `nombre_mostrar`, `daño:int`, `alcance_metros:float`, `ancho_metros:float`, `alto_metros:float`, `cooldown_segundos:float`, `duracion_activa_ms:int`. 5 `.tres`: ArmaPunos/Hacha/Pico/Azada/Regadera. Alcances calibrados ISO: Puños 1.6m / Hacha 2.3m / Pico 2.1m / Azada 1.7m / Regadera 1.4m. **Sistema carga desde carpeta**: `_cargar_mapa_armas_desde_recursos()` usa `DirAccess.open(RECURSOS_ARMAS_DIR).get_files()` escaneando `.tres` — no hay hardcode de armas nuevas = añadir `ArmaEspada.tres` funciona sin tocar código. **Función `_aplicar_arma_por_herramienta_equipada()`** modifica TAMAÑO BoxShape3D runtime sin recrear recurso (`_hitbox_shape.size = Vector3(ancho, alto, LARGO)`). Posición Z hitbox = frente -Z canónico con formula exacta: `OFFSET_SALIDA_CUERPO(0.45m) + mitad_largo_shape` → PUNTA del hitbox a `-alcance_metros` exactos. **Sistema Híbrido de Golpe (INFALIBLE)**: Capa1 = Area3D body_entered para StaticBody. Capa2 = **Cono Frontal Manual** (sweep esférico `PhysicsDirectSpaceState3D.intersect_shape(SphereShape3D)` con `collision_mask = 0x7FFFFFFF` → busca TODOS los cuerpos sin depender de layers). Filtros: (A) Distancia < alcance+margen. (B) Ángulo dentro de CONO 55° (`cosAng >= cos(55°)=0.57` → coseno es barato, no acos). (C) Buscar Damageable por Duck Typing + buscar en padre. Resultado: incluso cuando los CharacterBody se repelen físicamente (0 overlaps), el cono manual SIEMPRE detecta y daña. Fix anti-autogolpe 3 capas: nombre=="Jugador" OR jerarquía is_ancestor_of OR is_in_group("jugador"). **Hotkeys Teclado**: Key_1 Hacha, Key_2 Pico, Key_3 Azada, Key_4 Regadera, Key_5 Puños, Key_Q Toggle puños/hacha. **Barras de Vida 3D Reutilizables** (`damageable_barra_3d.gd` class_name extends Node3D): Sistema profesional render SubViewport (512×96) + 3 ColorRect (Fondo blanco semi 22% opaco / Frente color variable / 4 Bordes negros 4px) + Label números (doble Label shadow stroke 3px para contorno). Sprite3D billboard = siempre mira a cámara. NO hay Unicode █░⠀ (tenían bugs de ancho y rejilla). El frente solo reduce .size.x → solo la DERECHA disminuye, lado IZQUIERDO fijo. Componente 100% genérico: se adjunta como Node3D hijo de CUALQUIER cosa con Damageable (Slime, Muñeco, Boss, Árbol, Orco) y muestra vida automáticamente por señal `Damageable.vida_cambio`. @export ajustable por escena: `ancho/alto_barra_metros`, `altura_sobre_cabeza`, `tamano_fuente_numeros`, colores umbrales 0.65 verde / 0.32 amarillo / rojo. Muerte: 💀 0.4s y oculta. 🧠 Aprendizajes parser Godot 4.7 guardados: Label3D NO TIENE: bbcode_enabled, bbcode_text, outline_size (solo lo tiene Label2D / RichTextLabel en UI). SubViewport NO TIENE: transparent_background (borrado 4.x), background_mode, hdr, world_2d (solo en Viewport viejo 3.x). SubViewport propiedades garantizadas: size, render_target_update_mode, get_texture(). Fondo transparente SIN ENUMS: ColorRect de Color(0,0,0,0) como PRIMER HIJO del SubViewport (ForzarFondoTransparente). Label2D outline inexistente: técnica sombra doble Label idéntico desplazado 3px, z_index 2 vs 3. |
| FASE 4.1 Diálogos Data-Driven por Resources | ✅ Completado | 12/10/2026 | 3 Resources anidados: DialogoDefinicion (id, lineas, opciones, accion_al_terminar) > DialogoLinea (texto, animacion_npc) > DialogoOpcion (texto_opcion, id_siguiente_dialogo, requisitos item). DialogoDatabase Autoload escanea carpeta recursos/dialogos/ (0 hardcode). 5 .tres: Saludo_Inicial / Menu_Comprar / Menu_Vender / Historia / Despedida. Fix crítico: StringName vacíos &"\"\"" → &"" en .tres (el Inspector metía comillas literales). Acciones especiales: abrir_tienda / cerrar. |
| FASE 4.2 UI Diálogo | ✅ Completado | 12/10/2026 | UIDialogo.tscn (ColorRect pantalla completa + MarginContainer + PanelContainer + VBox: LabelNombre + RichTextLabel bbcode + VBoxOpciones dinámicas). ui_dialogo.gd: API abrir_dialogo_por_id(), navegación líneas, botones opciones generados runtime con StyleBoxFlat inline, requisitos item en opciones (Inventario.get_cantidad). **Patrón de input Godot 4 estándar**: teclado (Enter/Espacio) por `_unhandled_input`, mouse (click) por `_gui_input` en el ColorRect raíz. **Regla de mouse_filter escalable**: raíz=STOP, todos los hijos NO interactivos (Labels, RichText, contenedores)=IGNORE para que los clicks pasen al raíz. Fix: InputEventMouseButton NO tiene propiedad `.echo` (solo InputEventKey). Integración NpcTienda: conecta señales accion_especial_solicitada + dialogo_cerrado. |
| FASE 4.3 Misiones | ✅ Completado | 12/10/2026 | **Resource Mision** (`scripts/recursos/mision.gd`): id_mision, nombre, descripcion, tipo_objetivo (recolectar/matar/hablar), id_objetivo, cantidad_objetivo, recompensa_oro, recompensas_items. **MisionManager Autoload** (`scripts/core/mision_manager.gd`): misiones_activas Dictionary[StringName, Mision], misiones_completadas Array. API: aceptar_mision(), actualizar_progreso(), entregar_mision(), puede_entregar_mision(), tiene_mision_activa(), mision_ya_completada(). **Fix crítico Stack Overflow**: entregar recompensas DESPUÉS de `misiones_activas.erase(id)` (si no, inventario_cambiado dispara recursión infinita). **Flujo RPG estándar**: misiones tipo "recolectar" NO se autocompletan — el jugador debe volver al NPC y ENTREGAR los items (se consumen del inventario). Tipos "matar"/"hablar" sí autocompletan. **Integración diálogos**: DialogoOpcion gana 3 campos data-driven: `accion_especial` (acciones por opción, no solo por diálogo), `requiere_mision_activa` (opción aparece solo si misión está activa, ej "Entregar"), `requiere_mision_no_activa` (opción aparece solo si misión NO activa y NO completada, ej "¿Tienes trabajo?"). **Conexión automática**: Inventario.inventario_cambiado → actualiza progreso misiones recolectar. EnemigoBase._on_murio → MisionManager.actualizar_progreso(&"matar"). NpcBase.interactuar → MisionManager.actualizar_progreso(&"hablar"). |
| FASE 5.1 Catálogos Tienda Data-driven | ✅ Completado | 13/10/2026 | **Resources**: `CatalogoTienda` (id_catalogo, nombre_tienda, items: Array[ItemTienda]) + `ItemTienda` (id_item, precio_compra_jugador, precio_venta_jugador, stock, nombre_override). `Catalogo_Mercader.tres` con 5 items (semilla, semilla_tomate, semilla_zanahoria, tomate, zanahoria) con precios de compra/venta. Helpers: `get_item_por_id()`, `tienda_compra_item()`. |
| FASE 5.2 UI Tienda 2 pestañas | ✅ Completado | 13/10/2026 | `tienda.gd` (Control) con TabContainer (Comprar/Vender). Botones generados dinámicamente desde el catálogo. Pestaña Comprar: items con precio_compra_jugador > 0. Pestaña Vender: SOLO items que el jugador tiene Y que la tienda compra (precio_venta_jugador > 0). Acciones: `_on_comprar()` (gasta oro, agrega item, valida stock) y `_on_vender()` (quita item, da oro). Refresco automático tras cada operación. Cierre con ESC o botón. |
| FASE 5.3 NPC tienda actualizado | ✅ Completado | 13/10/2026 | `npc_tienda.gd` con `@export var catalogo_asignado: CatalogoTienda` y método `get_catalogo()`. `asignar_npc_owner(self, p_tab_inicial)` recibe el NPC y construye la UI desde su catálogo. Pestaña inicial determinada por el diálogo que disparó la acción (Comprar → tab 0, Vender → tab 1). |
| Mochila / Inventario UI (extra) | ✅ Completado | 13/10/2026 | `mochila.gd` (Control): GridContainer 5 columnas × 20 slots. `icono_item.gd` (class_name IconoItem): generador de placeholders por tipo de item (colores: recurso=marrón, herramienta=gris, semilla=verde, cultivo=naranja, consumible=rojo, arma=morado) con cache de texturas. `UIMochila.tscn` con ScrollContainer + GridSlots + LabelTooltip. Apertura/cierre con tecla **I** en `ui.gd` (`_unhandled_input` KEY_I). Refresco por señal `Inventario.inventario_cambiado`. Tooltip con nombre + cantidad + descripción. |
| FASE 6.1 Recetas crafteo | ✅ Completado | 14/10/2026 | `receta_crafteo.gd` (id, id_resultado, cantidad_resultado, ingredientes Array[IngredienteReceta], categoria, estacion_requerida, desbloqueada) + `ingrediente_receta.gd` (item_id, cantidad). 8 recetas en `assets/recetas/`: banco_trabajo, horno, molino, hacha, pico, azada, regadera, pan. Items nuevos: cuero, harina, pan, semilla_trigo, trigo. |
| FASE 6.2 Crafteo Manager | ✅ Completado | 14/10/2026 | `crafteo_manager.gd` Autoload (SIN class_name para no colisionar con el nombre del Autoload). Carga recetas desde `assets/recetas/` con DirAccess. API: get_receta(), get_todas_recetas(), get_recetas_por_categoria(), get_recetas_por_estacion(), get_disponible_ingrediente(), puede_craftear(), craftear(). Caso especial del agua: item_id `&"agua"` NO está en inventario, se consume de `carga_agua_actual` de la regadera (métodos get_agua_disponible() y _consumir_agua()). |
| FASE 6.3 UI Crafteo nueva | ✅ Completado | 14/10/2026 | `UICrafteo.tscn` (Panel morado con ScrollContainer de recetas). `crafteo.gd`: filas con icono (Button con icon, mismo patrón que mochila), nombre + cantidad, ingredientes con colores verde/rojo según disponibilidad, botón Craftear (deshabilitado si faltan ingredientes). `crafteo_manual.gd`: panel dentro de la mochila (UIMochila.tscn reestructurado con HBoxContenedor) que muestra solo recetas `estacion_requerida=ninguna` (ej: banco_trabajo). Refresco por señal `Inventario.inventario_cambiado`. |
| FASE 6.4 Estaciones mundo | ✅ Completado | 14/10/2026 | `estacion_crafteo.gd` (StaticBody3D interactuable, igual patrón que NpcBase: AreaInteraccion + body_exited). `EstacionCrafteo.tscn`. Items de estación (ItemDefinicion con `es_estacion=true` + `tipo_estacion`). Sistema de colocación en `jugador.gd`: tecla **B**, preview translúcido verde/rojo por validez, raycast al suelo, instancia estación y gasta item. Recetas: banco_trabajo (5 madera, estación=ninguna), horno (8 piedra, banco_trabajo), molino (6 madera+2 piedra, banco_trabajo). |
| FASE 7.1 Gestor Tiempo | ✅ Completado | 14/10/2026 | `gestor_tiempo.gd` Autoload. @export: hora_inicio, hora_amanecer, hora_atardecer, minutos_por_segundo. Variables: _minutos_totales, dia. Señales: minuto_cambio(hora,minuto), hora_cambio(hora), dia_cambio(dia). Métodos: get_hora(), get_minuto(), get_hora_decimal(), es_dia(), es_noche(), get_tiempo_texto(). **Fix crítico**: el `while` de cambio de día no puede ir comentado (si no, días infinitos cada frame). |
| FASE 7.2 Ciclo visual día/noche | ✅ Completado | 14/10/2026 | `ciclo_dia_noche.gd` en la DirectionalLight3D (Luz.tscn). Interpola light_color (noche azul/amanecer naranja/día blanco/atardecer), light_energy (0.15 noche → 1.2 día), rotation.x (sol sube/baja), rotation.y (inclinación configurable con @export inclinacion_sol_y). Actualiza color ambiente del WorldEnvironment. Conectado a `GestorTiempo.minuto_cambio`. |
| FASE 7.3 Integración sistemas | ✅ Completado | 14/10/2026 | **Tienda** (`npc_tienda.gd`): `puede_interactuar()` comprueba horario 8-20h. **Parcelas** (`parcela.gd`): solo crecen si `GestorTiempo.es_dia()`; `dia_cambio` resetea `regado=false` cada nuevo día. **Spawners** (`enemigo_spawner.gd`): @export `solo_noche` (si true, no spawnea de día). |
| FASE 8.1 Componente Stats (hambre/energía) | ✅ Completado | 15/10/2026 | `scripts/jugador/stats.gd` (class_name Stats, extends Node, nodo hijo del Jugador). Señales `hambre_cambio`, `energia_cambio`, `hambre_critica`. Estado interno en `float` (consumos fraccionarios), getters devuelven `int`. Consumo conectado a `GestorTiempo.minuto_cambio` (hambre baja por minuto de JUEGO, no real). Daño por inanición en `_process` (tiempo real) vía `Damageable` hermano localizado con `get_node_or_null("Damageable")`. API: `comer()`, `descansar()`, `get_hambre()`, `get_energia()`, `esta_agotado()`. |
| FASE 8.2 Cama + Dormir (avanzar tiempo) | ✅ Completado | 15/10/2026 | `GestorTiempo.avanzar_tiempo(minutos)` nuevo método (reutiliza el mismo `while` de salto de día que `_process`, emite `dia_cambio`/`hora_cambio`/`minuto_cambio`). `scripts/mundo/cama.gd` (StaticBody3D interactuable, patrón pozo.gd): `@export horas_a_dormir=8`, `solo_de_noche=true`, `energia_restaurada=100`. Avanza el reloj y llama a `Stats.descansar()` del jugador (busca `get_node_or_null("Stats")`). `escenes/mundo/Cama.tscn` instanciada en `mundo.tscn`. **Bug resuelto**: la escena `Cama.tscn` no tenía el script asignado en el nodo raíz → el Duck Typing del jugador (`body.has_method("interactuar")`) la ignoraba y nunca aparecía el prompt F. Fix: asignar `cama.gd` al nodo raíz desde el Inspector. |
| FASE 8.3 Consumibles data-driven | ✅ Completado | 15/10/2026 | `ItemDefinicion` gana `hambre_restaurada` y `vida_restaurada` (default 0 → .tres viejos intactos). Un item es comestible si sus DATOS lo dicen (cero hardcodeo, sin `if tipo=="comida"`). `Inventario.usar_item(indice)` gasta 1 unidad y emite `item_consumido(id, hambre, vida)`. `Stats._on_item_consumido()` escucha la señal → `comer()` + `Damageable.sanar()`. `mochila.gd` conecta `btn.pressed` de cada slot a `_on_slot_presionado(i)` → `usar_item`. Items marcados: pan (25/5), tomate (10/0), zanahoria (8/0). |
| FASE 8.4 HUD barras hambre/energía | ✅ Completado | 15/10/2026 | `UIHud.tscn` gana `BarraHambreExterior/Interior` (naranja) y `BarraEnergiaExterior/Interior` (verde), duplicadas de `BarraVida`, con `mouse_filter=IGNORE`. `ui.gd`: `_intentar_conectar_damageable_jugador()` conecta también el nodo `Stats` del jugador (búsqueda por grupo "jugador" + `get_node_or_null("Stats")`), señales `hambre_cambio`/`energia_cambio`. Nueva función reutilizable `_actualizar_barra(exterior, interior, pct)` (calcula el ancho por `offset_right - offset_left`, NO por `.size`, para poder mover barras sin tocar código). Los máximos se leen del propio `Stats` (`hambre_max`, `energia_max`). **Bugs resueltos**: (1) nodo mal renombrado al duplicar (`BarraVidaBarraHambreExteriorExterior2`) → null; (2) barras exteriores sin `offset_right`/`offset_bottom` (quedaban a 0 → ancho/alto negativos). |
| FASE 8.5 Integración (correr↔energía + agotamiento) | ✅ Completado | 15/10/2026 | Cierra el bucle de supervivencia: correr consume energía y el agotamiento ralentiza al jugador. `Stats` gana `energia_por_segundo_corriendo=4.0`, `multiplicador_velocidad_agotado=0.55`, `porcentaje_recuperacion_energia=0.25`, señal `agotamiento_cambio(bool)` y API `puede_correr()`, `get_multiplicador_velocidad()`, `esta_sin_energia()`. **Agotamiento con histéresis** (entra a 0 de energía, solo sale al recuperar el 25%) para evitar parpadeo. `jugador.gd`: `_intentar_correr()` delega en `stats.puede_correr()`; `vel_actual` se multiplica por `get_multiplicador_velocidad()`. **Bug resuelto**: había 2 líneas viejas sobrantes (`if Input.is_key_pressed(KEY_SHIFT): vel_actual = VELOCIDAD_CORRER`) que pisaban el resultado de `_intentar_correr()` y anulaban todo el sistema → el jugador siempre podía correr aunque estuviera agotado. Fix: eliminar esas líneas y eliminar el `@export var stats` duplicado. |
| FASE 9.1 Sistema de Drops Unificado (DropManager) | ✅ Completado | 15/10/2026 | Autoload `scripts/core/drop_manager.gd`. API `soltar(drops, posicion, padre=null, excluir=null)`, diferida con `call_deferred` (se invoca desde señales de física). Formato data-driven por drop: `{item_id, cantidad, cantidad_max(opcional), probabilidad}` → `cantidad`=mínimo, `cantidad_max`=máximo (`randi_range`); `probabilidad`=¿aparece o no? (concepto DISTINTO de cantidad). Instancia la escena genérica `PickupItem.tscn` (Area3D + MeshInstance3D `Mesh` + CollisionShape3D con `pickup.gd`) y colorea el mesh según `IconoItem.COLORES_POR_TIPO` (una sola fuente de verdad). **Colocación en el suelo por raycast**: el `Area3D` no tiene gravedad, así que `_altura_suelo()` lanza un rayo hacia abajo y coloca a `y_suelo + altura_spawn`, excluyendo la entidad emisora (`excluir.get_rid()`). **Gotcha del suelo de una sola cara** (`ConcavePolygonShape3D`): un rayo descendente puede impactar la cara por detrás y NO registrarse → documentado el "rayo doble" (abajo, y si falla, arriba). **Verificación real**: el `print` de debug confirmó `y_ref=0.45  y_suelo=0.00  y_final=0.15` → el cubo de 0.3 reposa con su base exactamente en el suelo (no flota). `EnemigoBase` gana `@export var drops: Array[Dictionary]` y llama `DropManager.soltar(drops, global_position, null, self)` en `_on_murio()`. |
| FASE 9.2 AnimalBase (IA de Huida) | ✅ Completado | 15/10/2026 | `scripts/animales/animal_base.gd` (`class_name AnimalBase`, extends CharacterBody3D). FSM de **2 estados** para fauna PASIVA: `PASTAR` (deambula lento con pausas) y `HUIDA` (corre alejándose del jugador). Exports: `velocidad_pastar`, `velocidad_huida`, `rango_alerta`, `distancia_seguridad`, `tiempo_cambio_pastar`, `tiempo_pausa_pastar`, `id_animal`, `drops: Array[Dictionary]` (mismo formato que `EnemigoBase`). Reutiliza `Damageable` (nodo hijo) y `DropManager` (9.1) — cero duplicación. La rotación se aplica **solo al `VisualHolder`** (regla canónica: raíz siempre en identidad). Escenas creadas: `escenes/animales/Conejo.tscn` (esfera r=0.3, HP 15, huida 5.0) y `Ciervo.tscn` (cápsula, HP 45, huida 5.8). `velocidad_huida` se calibró **entre** andar (3.5) y correr (6.5): no te alcanza andando, sí corriendo → caza justa. Items nuevos registrados en `ItemDatabase`: `item_carne_conejo.tres` y `item_carne_ciervo.tres`. **Depredador `Puma.tscn`** (reutiliza `EnemigoBase`, sin código nuevo): `rango_ataque=1.8` (respeta la lección de 3.4: <1.6 nunca conecta en isométrico), `velocidad_perseguir=3.6`, HP 90, drops `carne_puma`. **Bugs resueltos**: (1) el script `damageable.gd` estaba pegado al `MeshInstance3D` y **no existía ningún nodo llamado `Damageable`** → el sistema completo (jugador, barra y drops) lo busca por nombre exacto como hijo directo de la raíz, así que el animal huía pero no recibía daño, no mostraba barra y no soltaba nada. Fix: nodo `Node` llamado literalmente `Damageable` hijo de la raíz (patrón componente, igual que `EnemigoSlime`). (2) Faltaban los nodos `VisualHolder`/`Mesh` → el animal huía pero **no giraba** (ga). Fix: `VisualHolder` (Node3D) con hijo llamado exactamente `Mesh`. (3) Faltaban `ComponenteBarraVida` y los `@export` de la escena. **Diferencia estructural clave**: `AnimalBase` exige `VisualHolder` + mesh llamado `Mesh`; `EnemigoBase` (Puma/Slime) rota la raíz y busca un mesh llamado `MeshInstance3D` como hijo directo. Confundirlos = muerte sin animación. |
| FASE 9.3 Respawn de Recursos | ✅ Completado | 15/10/2026 | Autoload `scripts/core/respawn_manager.gd` (`RespawnManager`): registra recursos cortados en una lista `[{nodo, dias_restantes}]` y los reactiva escuchando `GestorTiempo.dia_cambio`. Usa **días de juego, no segundos reales** (coherente con plantas y tiendas). ⚠️ El autoload debe ir **DESPUÉS de `GestorTiempo`** en la lista, porque los autoloads se inicializan en orden y `_ready()` conecta la señal (si va antes, `GestorTiempo` aún no existe). `scripts/mundo/recurso_respawneable.gd` (`class_name RecursoRespawneable`, extends StaticBody3D) **reemplaza por completo a `arbol.gd` y `roca.gd`**: data-driven (`drops: Array[Dictionary]` + `dias_respawn` + `grupo_recurso`), suelta drops vía `DropManager` (9.1) y en vez de `queue_free()` se **oculta y desactiva** (`visible=false`, `remove_from_group` → borra el prompt [E] al instante, `set_deferred("collision_layer", 0)`). `reactivar()` lo devuelve al mundo. **Gotcha**: cambiar `collision_layer` dentro de un callback de física dispara el *flushing* del motor → obligatorio `set_deferred` (misma lección que el `call_deferred` del `DropManager`). **Eliminado**: `AreaInteraccion` de `Arbol.tscn` (era redundante y sus conexiones apuntaban a métodos inexistentes → errores en consola). Scripts `arbol.gd`/`roca.gd` borrados. |
| FASE 9.4 Spawner de Animales | ✅ Completado | 15/10/2026 | Se **reutilizó `enemigo_spawner.gd`** sin duplicar lógica: como `AnimalBase` también tiene un `Damageable` hijo, el spawner ya lo contaba y conectaba la señal `murio` igual que con los slimes. Cambios: (1) `@export solo_noche: bool` → **enum `Momento {SIEMPRE, SOLO_DIA, SOLO_NOCHE}`** (+`_es_momento_valido()`), porque con dos bools (solo_dia+solo_noche) se pueden dar flags contradictorios que dejan el spawner muerto; un enum es excluyente por construcción. → **Migración obligatoria**: `SpawnerSlimes` debe ponerse en `SOLO_NOCHE`. (2) `_buscar_posicion_valida_en_anillo()` (devuelve `Vector3` o `null`) que lanza un **rayo descendente como validador de límites del mapa**: dentro de la arena hay suelo y el rayo impacta, fuera de los muros no hay nada y el punto se descarta. Así los anillos grandes (10-14 m) son seguros **sin hardcodear las medidas del mapa** (regla cero hardcodeo). Si todos los intentos fallan, se libera la instancia y se reintenta al siguiente cooldown. **Bug real encontrado**: `enemigo_spawner.gd` tenía **código muerto** desde la Fase 3.4 — la función `_posicion_aleatoria_en_anillo_jugador()` hacía `return` en su 3ª línea, dejando inalcanzable el raycast al suelo posterior (con el comentario "En vez de fijar Y…"). Por eso el spawn salía a la altura del spawner (1.13 m) y no al ras. Se eliminó la función completa. **Bug del pegado**: al insertar las funciones nuevas se **sobrescribió la definición de `_buscar_jugador_cache()`** (que seguía llamándose en 2 sitios) → error `Function "_buscar_jugador_cache()" not found in base self`. **Lección**: GDScript valida las llamadas en tiempo de COMPILACIÓN del script; un método llamado y no definido aborta el script **completo**, no solo el punto de la llamada (síntoma: el spawner no arranca en absoluto). Spawners colocados en `mundo.tscn`: `SpawnerConejos` (anillo 8-12, max 6, cd 6 s, SOLO_DIA), `SpawnerCiervos` (10-14, max 3, cd 10 s, SOLO_DIA), `SpawnerPumas` (10-14, max 2, cd 18 s, SOLO_NOCHE). El anillo 8-12 m en conejos garantiza que **no huyan en el instante de aparecer**. Limitación conocida: los animales que huyen hasta el muro quedan ahí y ocupan cupo del spawner; se resolverá con el despawn por lejanía del mapa procedural (Fase 16). |
| FASE 9.5 Integración (Caza) | ✅ Completado | 15/10/2026 | Verificación del bucle de caza completo + corrección de **gaps de datos** (no de código). El flujo ya funcionaba por arquitectura: el jugador golpea (click izq/Espacio → `_intentar_atacar()` → `_on_hitbox_ataque_body_entered()` + `_procesar_golpe_manual_cono_frontal()`), ambos buscan el `Damageable` **hijo por nombre exacto** (`_buscar_damageable_en_nodo`), y el animal muere → `DropManager.soltar()` → pickup → `Inventario`. Daño: puños 5 (`ArmaPunos.tres` no define `daño` → usa el default 5), hacha 18 (`ArmaHacha.tres`) → conejo (15 HP) muere de 1 hachazo, ciervo (20 HP) y puma (50 HP) de varios. `MisionManager.actualizar_progreso(&"matar", id_animal, 1)` tiene la firma correcta (`p_tipo, p_id_objetivo, p_cantidad`). **Gaps corregidos**: (1) `item_carne_ciervo.tres` **no tenía `hambre_restaurada`** (0) → `Inventario.usar_item()` lo rechazaba ("no es consumible") y la caza del ciervo no daba comida; se le puso 15. (2) `item_carne_conejo.tres` tenía `hambre_restaurada = 1` (inútil) → subido a 8. (3) `Puma.tscn` tenía `{cantidad: 0, cantidad_max: 1}` → `_cantidad_aleatoria` devolvía `randi_range(0,1)` y el 50% de las veces salía 0, que `_soltar_diferido` descarta por `cant <= 0` → **el colmillo nunca caía la mitad de las veces** aunque pasara la probabilidad; corregido a `cantidad: 1`. (4) `Ciervo.tscn` no tenía `id_animal` → matar ciervos no progresaba misiones; añadido `&"ciervo"`. (5) `Ciervo.tscn` tenía **2 diccionarios vacíos** en `drops` (inofensivos pero basura) → limpiados. **Nota de diseño**: `colmillo_puma` (precio_venta 50) se dejó como drop **único** del puma (material raro para armas especiales de la Fase 13), a decisión del usuario; no se añadió `carne_puma`. |
| FASE 10.1 Espada (Melee) | ✅ Completado | 15/10/2026 | **El hallazgo importante fue un error del propio plan**: decía que las armas se cargaban "automáticamente por carpeta", y era **falso**. `jugador.gd → _cargar_mapa_armas_desde_recursos()` usaba un `Dictionary` con **5 rutas hardcodeadas** → un `ArmaEspada.tres` nuevo **nunca se cargaba** (la espada se equipaba pero golpeaba con el *fallback* de puños, 5 de daño). Se refactorizó a **escaneo de carpeta con `DirAccess`** (mismo patrón que `CrafteoManager`/`ItemDatabase`), clave = campo `nombre` del `ArmaDefinicion`. **Regla nueva: añadir un arma = crear solo el `.tres`.** Segundo hardcodeo eliminado: la visibilidad de modelos en mano estaba escrita a mano en `_process` (4 líneas `modelo_x.visible = (herramienta_equipada == &"x")`) → refactor a `Dictionary _modelos_arma` + `_actualizar_modelos_arma()`. Creados: `recursos/armas/ArmaEspada.tres` (daño 25, alcance 2.4, cooldown 0.5 — más rápida y fuerte que el hacha: 18/0.65), `assets/items/item_espada.tres` (`tipo = herramienta` **obligatorio**: `equipar_herramienta()` rechaza cualquier otro tipo; `herramienta_tipo = espada`), `assets/recetas/receta_espada.tres` (3 madera + 2 piedra + 1 colmillo_puma en `banco_trabajo` → cierra el bucle caza→arma), nodo `ModeloEspada` en `Jugador.tscn` (duplicado de `ModeloHacha` para heredar su transform), atajo **tecla 6**. |
| FASE 10.2 Sistema de Proyectiles | ✅ Completado | 15/10/2026 | `scripts/combate/proyectil.gd` (`class_name Proyectil`, extends **Area3D**) + `escenes/combate/Proyectil.tscn` (Area3D + `CollisionShape3D` esfera r=0.15 + `Mesh` cilindro rotado 90° en X; el cilindro nace en Y y el proyectil vuela en −Z). **Decisión de arquitectura clave: el proyectil NO conoce a su tirador ni a su arma** — recibe `disparar(direccion, daño, tirador)` por parámetro, así el MISMO proyectil sirve para el arco del jugador, flechas trampa o un enemigo arquero sin tocar código. Movimiento rectilíneo en `_physics_process` (`global_position += dir * velocidad * delta`) porque un `Area3D` **no tiene gravedad**; autodestrucción por `tiempo_vida_max` (2 s) para evitar proyectiles infinitos. **Capas verificadas en el proyecto real**: jugador = `collision_layer 8193` (capas 1 y 14), enemigos = `5` (capas 1 y 3), suelo = capa 1 → **la capa 1 es común a todo**, así que el proyectil usa `Layer 0 / Mask 1`: detecta enemigos y además se detiene contra el escenario. Al jugador se lo descarta por código (mismo filtro anti-autogolpe de 3 capas del melee). `jugador.gd` gana `disparar_proyectil(velocidad, daño)`: origen = `visual_holder.global_position + dir*0.8 + UP*1.1`, dirección = `-visual_holder.global_transform.basis.z` (frente real, porque `VisualHolder` es el único que rota), y el proyectil se añade al **`current_scene`, NO como hijo del jugador** (si fuera hijo heredaría la rotación y saldría torcido). Verificado: la flecha vuela hacia el frente, daña al slime y desaparece al impactar. |
| **FASE 10.5** Refactor ItemDatabase (Cero Hardcodeo) | ✅ Completado | 15/10/2026 | `item_database.gd` tiene **26 `preload()` escritos a mano** en `_ready()` (líneas 8-35). Añadir un item = editar el script. Refactor a **escaneo de carpeta con `DirAccess`** (mismo patrón ya probado en `_cargar_mapa_armas_desde_recursos()` de 10.1). Clave = campo `id` del `ItemDefinicion`. **Regla nueva: añadir un item = crear solo el `.tres`.** |
| **FASE 10.6** Fix Rango de Golpe + Unificar Input | ✅ Completado | 15/10/2026 | **Bug confirmado en `Jugador.tscn` (L144-L148)**: existe un `Area3D` **sin nombre descriptivo** (es el "RangoGolpe", conectado en L177) con `transform z = -1` y `SphereShape3D` de **radio por defecto (1.0)** → **2.0 m de alcance al frente y 0 m detrás/lados** = el "rango distinto según el ángulo" que reportó el usuario. **Bug más grave**: cuelga de la **raíz del jugador**, que por la regla canónica NUNCA rota → el área apunta siempre al **−Z del mundo**, no hacia donde mira el jugador. El nodo hermano `RangoInteraccion` (L150-L156) sí está centrado (cápsula 1.75) — de ahí la incoherencia. Además `_on_rango_golpe_body_entered` guarda el **último** cuerpo que entra en vez del **más cercano** (L537-L544). **Decisión del usuario**: unificar el input → **Click izquierdo / Espacio hace TODO** (atacar enemigos + talar/minar si la herramienta equipada lo permite) y **se elimina la tecla E**. `F` sigue siendo interactuar. **Estrategia**: eliminar el `Area3D` asimétrico y reutilizar `RangoInteraccion` (ya centrado y simétrico) para detectar árboles/rocas por grupo, con un helper `_buscar_recurso_cercano()` que devuelve el más próximo. Cero consultas de física nuevas (se reutilizan los solapamientos que el motor ya calcula). |
| **FASE 10.7** Fix Colocación de Estaciones | ✅ Completado | 15/10/2026 | `jugador.gd` L944: `query.exclude = [self]` — en Godot 4 esa propiedad es **`Array[RID]`**, así que el rayo **impacta la propia cápsula del jugador** en vez de atravesarla. Encaja con el síntoma reportado: el preview se pone verde **sobre el jugador** y hacia "abajo" no llega al suelo porque el rayo se detiene en el cuerpo. **CAUSA RAÍZ CONFIRMADA (verificada en el código real, no hipótesis)**: `Camara.tscn` es **ortográfica** (`projection = 1`) y está en +X+Z mirando al jugador. Con `exclude` inefectivo, la **cápsula del jugador (r=0.5, altura 2) BLOQUEA el rayo** en toda la zona del sprite. Como en isométrico el cuerpo del jugador (y=0..2) se proyecta por encima de sus pies en pantalla, el rayo de la zona "bajo el jugador" choca contra la cápsula y devuelve un punto pegado al jugador → por eso el preview se pone **verde sobre el jugador** y parece que "abajo hay menos rango". Dato de contraste: el rayo SÍ impacta el `Suelo` (verificado en 9.1 con `y_suelo=0.00`) aunque su `ConcavePolygonShape3D` tenga los triángulos con normal hacia −Y: los raycast contra shapes cóncavas no aplican backface culling. **Solución FINAL en 2 pasos** (el simple `exclude = [get_rid()]` NO bastó: solo había "una zona" válida porque el rayo choca con árboles/rocas/muros y devuelve la superficie de ESOS objetos, y devuelve vacío fuera del cuadrado del suelo): (1) `query.exclude = [get_rid()]`; (2) **el raycast se reemplazó por intersección GEOMÉTRICA rayo ∩ plano** → `Plane(Vector3.UP, -y_suelo).intersects_ray(ray_origin, ray_dir)`, con `y_suelo` leído de `current_scene.get_node_or_null("Suelo").global_position.y`. **Por qué es superior**: es álgebra pura, no consulta el servidor de física → **ningún objeto puede "tapar" el suelo**, el preview aparece en TODO el contorno. Además el radio se mide en el **plano XZ** (`Vector2(x,z).distance_to`), no en 3D, para que el área sea un círculo perfecto. **Ajuste de rango**: `DISTANCIA_MAX_COLOCACION` (6.0 m, demasiado grande) → `@export_range(1.0, 12.0, 0.1) distancia_max_colocacion` para calibrar en vivo desde el Inspector. Limitación conocida (menor): se pierde el "apoyo sobre el terreno" si en el futuro hubiera desniveles; con suelo plano es irrelevante. |
| **FASE 10.8** Hotbar de 9 Espacios + Drag & Drop | ✅ Completado | 15/10/2026 | **Decisión del usuario: 9 casillas propias e independientes** (modelo Minecraft/Terraria), NO una vista de las primeras 9 de la mochila. **Arquitectura: `Inventario` es el único dueño de los datos; la UI solo pide "mueve esto de aquí a allá"** → el drag & drop se escribió UNA vez y sirve para mochila y hotbar. (1) `inventario.gd`: señal `hotbar_cambiada`, `const CANTIDAD_SLOTS_HOTBAR = 9`, `slots_hotbar: Array[Dictionary]`, `slot_hotbar_seleccionado`, y API `get_slot_hotbar()`, `get_slot_por()`, `mover_entre()` (swap genérico mochila↔hotbar), `seleccionar_hotbar()`, `_equipar_desde_hotbar()`. **Inventario UNIFICADO (decisión del usuario)**: `get_cantidad()` y `gastar_item()` ahora suman/gastan de mochila **y** hotbar (helper `_gastar_en_coleccion()`, mochila primero) → las flechas de la hotbar sirven para disparar. (2) **Nuevo script `slot_arrastrable.gd`** (`class_name SlotArrastrable extends Button`): un solo componente para mochila y hotbar, parametrizado con `origen` (`&"mochila"`/`&"hotbar"`) e `indice`. (3) **Nueva escena `UIHotbar.tscn`** + `hotbar.gd` (HBox de 9 botones, borde dorado en la casilla seleccionada, número visible en las vacías, instanciada como hijo de `UiHud` **después** de la mochila para dibujarse encima). (4) `mochila.gd` refactorizado: **crear botones UNA vez** (`_crear_slots()`) y solo **refrescar contenido** (`_refrescar_slots()`) — recrearlos en cada señal rompería el arrastre en curso. (5) `jugador.gd`: **eliminado el `match` hardcodeado `KEY_1`…`KEY_7`** (y de paso el `KEY_Q` toggle y el `KEY_T` legado de 10.2) → sustituido por `elif kb.keycode >= KEY_1 and kb.keycode <= KEY_9: Inventario.seleccionar_hotbar(kb.keycode - KEY_1)`. Añadir una casilla = cambiar `CANTIDAD_SLOTS_HOTBAR`, nada más. |
| **FASE 10.8b** Drag & Drop propio (fix capas) + Colocación por Hotbar | ✅ Completado | 15/10/2026 | **Problema 1 — el preview del arrastre se dibujaba POR DETRÁS de la UI.** Causa raíz: Godot añade el preview de `set_drag_preview()` al **Viewport (canvas "layer 0")**, y toda la UI de Aukane vive en un `CanvasLayer` con `layer = 1` → imposible que se dibuje encima, y la capa del preview nativo **no es configurable**. **Solución: arrastre propio.** Se eliminaron `_get_drag_data`/`_can_drop_data`/`_drop_data` de `slot_arrastrable.gd` y se implementó a mano con `_gui_input` (inicio por `UMBRAL_ARRASTRE_PX = 6` para no confundir click con arrastre) + `_process` (mover preview). El preview se añade como hijo del **mismo `CanvasLayer` de la UI** (`_buscar_capa_ui()` sube por el árbol) con `z_index = 4096` → **siempre por encima**. El destino se resuelve con `_buscar_slot_bajo()` sobre el grupo `&"slots_arrastrables"` + `get_global_rect().has_point()`. `_exit_tree()` limpia el preview si cierran la mochila a mitad de arrastre. **Bug secundario del icono gigante**: `TextureRect` usa `EXPAND_KEEP_SIZE` por defecto, que **adopta la resolución NATIVA de la textura** ignorando el `custom_minimum_size` → con un icono de 256/512px el preview salía enorme. Fix: `expand_mode = EXPAND_IGNORE_SIZE` + `stretch_mode = STRETCH_KEEP_ASPECT_CENTERED`. **Problema 2 — el banco de trabajo no se colocaba desde la hotbar.** Causa raíz: `_buscar_primera_estacion_en_inventario()` recorría **solo `Inventario.slots`** (mochila) → al arrastrar el banco a la hotbar devolvía `&""` y no entraba en modo colocación. **Decisión del usuario: eliminar la tecla `B`.** Nuevo diseño: **seleccionar en la hotbar la casilla que contiene una estación = modo colocación activo** (click izquierdo coloca). Implementado con `_sincronizar_modo_colocacion()`, conectada a la señal `hotbar_cambiada` (la lógica inversa vive en `jugador.gd` porque `Inventario` es Autoload y **no debe conocer al jugador**). Detección **data-driven** vía `ItemDefinicion.es_estacion` (`_estacion_de_hotbar_seleccionada()`), sin preguntar por el id `banco_trabajo`. Se eliminó el bloqueo de movimiento durante colocación (ahora es un modo persistente, congelar dejaba al jugador clavado) y se permitió cambiar de casilla con `1-9` estando en colocación. |
| **FASE 10.9** Terreno por Tiles (Tile3D) — *prerrequisito de FASE 11* | ✅ Completado | 16/10/2026 | **Petición del usuario: "todavía no veamos el clima, quiero tener el suelo tipo tile3d para ir construyendo el suelo base que luego según el clima reaccionará".** El terreno pasa a ser un requisito previo de FASE 11: no tiene sentido un clima que reaccione a un plano único de 20×20. **Estado actual (verificado)**: `Suelo.tscn` = raíz `MeshInstance3D` con `PlaneMesh` (2×2) + hijo `StaticBody3D` con `ConcavePolygonShape3D`; escalado **×10** en `mundo.tscn` → **un solo plano de 20×20 m**. `LimitesMapa.tscn` = 4 `BoxShape3D` escaladas ×20 (muros invisibles). **4 DECISIONES DEL USUARIO**: (1) **creación = pintar en el EDITOR con script `@tool`** (no procedural por ahora); (2) **tile = 2×2 m** → rejilla 10×10 = **100 celdas**; (3) **render = un `MultiMeshInstance3D` por tipo de terreno** (todas las celdas del mismo tipo en 1 sola llamada de dibujo) + **un único `StaticBody3D` con los `CollisionShape3D` de todas las celdas** (colisión agrupada); (4) **terreno PLANO** (sin elevación por ahora). **Arquitectura data-driven**: `TipoTerreno` (Resource) define cada bioma (`id`, `nombre_visible`, `color`, `altura`, `es_agua`) → **añadir un bioma = crear un `.tres`**, cero hardcodeo. **⚠️ 3 dependencias del nombre `"Suelo"` a migrar**: `proyectil.gd:52` y `jugador.gd:708` filtran por `body.name == "Suelo"`, y `jugador.gd:935` hace `get_node_or_null("Suelo")` para leer `y_suelo`. **HALLAZGO**: los dos filtros por nombre son **CÓDIGO MUERTO** — el cuerpo físico del suelo **NO se llama `Suelo`**: el nodo instanciado en `mundo.tscn` sí, pero el `StaticBody3D` que realmente colisiona es su **HIJO**, así que `body.name` devuelve `"StaticBody3D"` (por eso la flecha se destruye por la rama "chocó con algo sin vida", no por la rama del suelo). `LimitesMapa` sí funciona porque su **raíz ES** el cuerpo físico. Con 100–400 cuerpos de terreno esto es insostenible → **migrar a GRUPO `&"terreno"`** (`is_in_group`), la convención que ya usa el proyecto (`arboles`, `rocas`, `interactuables`, `jugador`). **⚠️ COMPATIBILIDAD FUTURA**: `jugador.gd:940` calcula el punto de colocación con un **plano matemático** (`Plane(Vector3.UP, -y_suelo)`), que asume suelo **perfectamente plano a UNA sola altura**; si algún día hay elevación habrá que volver al raycast. **Desglose**: 10.9.1 ✅ `TipoTerreno` + paleta (4 `.tres`: hierba/tierra/arena/agua) · 10.9.2 ✅ `GestorTerreno` (MultiMesh + colisión agrupada) · 10.9.3 ✅ pintado en editor · 10.9.4 ✅ migración `"Suelo"`→grupo `"terreno"` (`proyectil.gd:62`, `jugador.gd:708` y `jugador.gd:935` con `get_first_node_in_group`); `Suelo.tscn` huérfano (sin referencias, se puede borrar). **Hallazgo 10.9.3 (16/10/2026)**: `_forward_3d_gui_input()` **NO existe en `Node3D`** — es método virtual de **`EditorPlugin`**; un `@tool` colgado del nodo **nunca** recibe los clics del viewport 3D. **Solución**: addon `addons/pincel_terreno/` (`EditorPlugin` con `_handles()` + `_forward_3d_gui_input()`) que solo captura input y **delega la lógica en `GestorTerreno`** (datos puros: `indice_bajo_raton()` [rayo∩plano], `indice_desde_punto()`, `pintar_celda()`, `bioma_pincel_id()`, `_validate_property()` para el desplegable de biomas). `pintar_celda()` regenera solo si hay **cambio real**. **3 gotchas resueltos**: (1) `plugin.cfg` debe empezar con `[plugin]` (quedó con 1 carácter → el addon no aparecía en la lista de Plugins); (2) hay que **activarlo** en Configuración del Proyecto (añade la ruta a `[editor_plugins] enabled` de `project.godot`); (3) el nodo `Terreno` es un `Node3D` **sin malla propia** (la geometría son hijos creados en runtime) → el *picking* del viewport es poco fiable; seleccionarlo **desde el Árbol de Escena**, o ampliar `_handles()`/`_terreno_seleccionado()` para **subir por el árbol** hasta hallar el `GestorTerreno` (funciona aunque el editor seleccione `Colision` o un `Visual_*`). **v1 sin** Undo por celda ni preview de la celda bajo el cursor. |
| **FASE 10.3** Arco + Flechas (Munición) | ✅ Completado | 15/10/2026 | **La clave fue NO preguntar por el id del arma.** En vez de `if herramienta_equipada == &"arco"` (hardcodeo), se amplió `ArmaDefinicion` con `es_a_distancia: bool`, `velocidad_proyectil: float` e `id_municion: StringName`. Así **el dato manda**: `_intentar_atacar()` empieza con `if _arma_actual.es_a_distancia: _intentar_disparar(); return`, y añadir una ballesta en la Fase 13 = crear solo el `.tres` (los melee heredan `es_a_distancia = false` → cero regresiones). `_intentar_disparar()` valida `Inventario.tiene_item(id_municion)`, gasta 1 flecha con `gastar_item()` y llama a `disparar_proyectil(velocidad, daño)` de 10.2. **No activa `_esta_atacando`**: un arma a distancia no tiene swing ni hitbox; su único freno es `cooldown_ataque`. Guard `if id_mun != &""` → un arma sin munición configurada dispara infinito (útil para pruebas). Creados: `recursos/armas/ArmaArco.tres` (daño 35, cooldown 0.9, `es_a_distancia=true`, `id_municion=flecha`), `assets/items/item_arco.tres` y `item_flecha.tres` (`tipo = recurso`, stack 99), `recetas/receta_arco.tres` (4 madera + cuero) y `receta_flecha.tres` (**`cantidad_resultado = 4`**: una receta = 4 flechas), nodo `ModeloArco` en `Jugador.tscn`, atajo **tecla 7** (se eliminó la tecla T temporal de 10.2). Verificado: dispara, daña 35, consume flechas y al llegar a 0 imprime "Sin munición" sin disparar. |
| **FASE 10.2b** Fix volumen de impacto de la flecha | ✅ Completado | 16/10/2026 | **Bug real reportado por el usuario**: el arco solo alcanzaba al puma; conejos, slimes y ciervos eran inmunes. **CAUSA RAÍZ (geometría, medida con datos reales)**: la flecha nace en `jugador.gd:244` en `visual_holder.global_position + UP * 1.1`; como el jugador reposa con la cápsula centrada (y≈0.5), el origen queda en **y≈1.6**, y su collider era una `SphereShape3D` de radio **0.15** → ocupaba solo la banda **1.45–1.75**. Techos reales de los colliders: conejo (esfera r=0.3) **0.6**; slime (cápsula r=0.45 h=0.9 → esfera) **0.9**; ciervo (esfera r=0.5) **1.0**; puma (esfera r=1.0) **2.0**. Solo el puma llegaba. No era máscara de colisión ni velocidad: era altura. **Restricción de diseño confirmada**: en isométrico NO se apunta en vertical (no se cambiará), así que la altura de vuelo no debe decidir el impacto. **Solución**: el proyectil gana un **volumen de impacto alto y fino ANCLADO a alturas de MUNDO** (`@export` `ancho_impacto` 0.5, `altura_min_impacto` 0.15, `altura_max_impacto` 2.1) reconstruido en `_ajustar_volumen_impacto()` como `BoxShape3D` (0.5 × 1.95 × 0.5) con `cs.position.y = centro_y - global_position.y`. Funciona porque el proyectil solo rota en **YAW** (vuelo horizontal, `dir.y=0`), así que su eje Y local coincide con el del mundo. Se descartó "esfera más grande": cubrir 0.15–2.0 con una esfera sería enorme y golpearía el suelo; la caja alta y fina barre la trayectoria sin barrer los lados. Banda mínima 0.15 > 0 → **no se autodestruye al nacer** sobre el terreno plano. Cosmético: el origen del disparo bajó de `UP*1.1` a `UP*0.5` (`jugador.gd:244`) para que la flecha no salga por encima de la cabeza. ⚠️ **Efecto visual aceptado**: la flecha golpea al conejo pasando por encima de él. ⚠️ **Limitación**: anclado a suelo plano en y=0; con elevación habría que leer la altura del terreno (igual que 10.9.4). |
| **FASE 10.10** Consumibles desde la mano | ✅ Completado | 16/10/2026 | **Petición del usuario: "para comer debe estar en la hotbar, o sea en la mano".** Antes, hacer clic en un tomate **dentro de la mochila** lo comía (la señal `pressed` del botón se conectaba a `Inventario.usar_item(i)`). **Decisión de diseño**: el consumo sale **SOLO de la casilla SELECCIONADA de la hotbar**, no de `gastar_item()` — si usáramos `gastar_item()` descontaría primero de la mochila (te quitaría el tomate "de reserva" en vez del de la mano). Nueva función `Inventario.usar_item_en_mano()`: lee `slot_hotbar_seleccionado`, comprueba que el item sea consumible **por datos** (`hambre_restaurada > 0 or vida_restaurada > 0`; cero hardcodeo), descuenta 1 **de esa casilla** y, si llega a 0, deja `{}` (la mano vuelve a puños). Emite `inventario_cambiado`, `hotbar_cambiada` e `item_consumido`. **Se eliminó** la vieja `usar_item(indice)` (ya sin llamadores) y la conexión `pressed` en `mochila.gd` (líneas 62 y 108-109). **Input**: **clic derecho** en el mundo ejecuta `usar_item_en_mano()` (`jugador.gd`, justo tras `_intentar_atacar()`); el modo colocación ya retorna antes (usa su propio clic derecho para cancelar), así que no hay conflicto. Se verificó que el drag & drop **no** dependía de `pressed` (vive en `_gui_input` de `SlotArrastrable`). ⚠️ **Nota**: la comida **no** se ve como modelo en mano (`_equipar_desde_hotbar()` solo equipa `tipo == "herramienta"`); lo que importa es la casilla seleccionada. |
| **FASE 10.11** Hotbar oculta en modo modal (todas las ventanas) | ✅ Completado | 16/10/2026 | **Bug reportado**: con el diálogo abierto la hotbar quedaba **delante**, y lo mismo con la tienda del mercader. **CAUSA RAÍZ (dos rutas distintas, un solo criterio)**: (1) la mochila y la hotbar se crean con `add_child()` en `ui.gd` → quedan **después** de `UiDialogo` en el árbol del `CanvasLayer` (capa 1) y por tanto se dibujan encima (la franja inferior del diálogo, 280 px, es justo donde vive la hotbar); (2) la **tienda** (`npc_tienda.gd:124`) y el **crafteo** (`estacion_crafteo.gd:45`) se añaden a `get_tree().root` → **capa 0**, *por debajo* de todo el HUD. **Dato que unifica el arreglo**: los **4 únicos** sitios que activan `MODO_UI` son diálogo, tienda, crafteo y mochila → **`MODO_UI` ≡ "hay una ventana abierta"**. **Solución**: en `ui.gd`, escuchar `GameState.modo_cambiado` (una sola fuente de verdad, cubre presente y futuras) y `_sincronizar_hotbar()` = `ui_hotbar.visible = not (GameState.esta_en_modo_ui() and not mochila_abierta)`. **Única excepción: la mochila** — también es `MODO_UI` pero es la **compañera de la hotbar** (destino del drag & drop), así que con ella abierta la hotbar DEBE verse (se detecta por su propia `visible`, que se pone `true` **antes** de cambiar el modo → verificado). Se descartó conectar `visibility_changed` del diálogo (v1 lo hacía, pero era demasiado estrecho: no cubría tienda ni crafteo). **SEGUNDO BUG (orden de operaciones, `npc_tienda.gd`)**: el flujo hacía `abrir_tienda()` (MODO_UI, pero el diálogo **ya** estaba en MODO_UI → el setter hace `return` y **no emite señal**) y **después** `cerrar_forzado()` del diálogo, que deja `GameState` en `MODO_MUNDO` → **emite señal** → la hotbar **reaparecía con la tienda aún abierta**. Fix: **cerrar el diálogo ANTES de abrir la tienda** (el último en escribir el modo es `MODO_UI`); ambos cambios son síncronos (mismo frame) → sin parpadeo. **Deuda anotada**: `GameState.modo_actual` es **una sola variable** y no representa **ventanas encadenadas** (diálogo→tienda ya obligó a este parche; mochila+tienda fallará). Solución futura: que la hotbar consulte si hay **alguna** ventana modal abierta (grupo `&"ventana_modal"`). ✅ **Efecto secundario CORREGIDO (18/10/2026)**: los labels de recursos y las 3 barras (capa 1) seguían dibujándose **sobre** el fondo de tienda/crafteo (capa 0). Fix en `ui.gd`: `_sincronizar_hotbar()` → renombrada a **`_sincronizar_hud_modal()`**, que además recorre una **lista explícita `_nodos_hud`** (3 barras exteriores + barra XP + contadores + indicador de estación + label nivel + label atributos). Se descartó ocultar un nodo contenedor porque esos widgets están **sueltos** dentro del `CanvasLayer`. ⚠️ **Excepción conservada**: la mochila es `MODO_UI` pero **NO** oculta la hotbar (es su compañera de drag & drop); las barras sí se ocultan con ella (su fondo oscuro ya las tapaba → visualmente neutro). |
| **FASE 10.12** Contadores del HUD data-driven + limpieza de crafteo legado | ✅ Completado | 16/10/2026 | **Petición del usuario: "corrijamos los contadores de materias básicas, madera, piedra y oro; tenemos hardcodeado".** El HUD tenía **4 nodos fijos, 4 ids y 4 emojis** escritos a mano en `ui.gd` (líneas 10-13 y 103-108) → añadir un contador = editar código (viola la regla transversal). **Solución data-driven**: (1) `ItemDefinicion` gana `@export var emoji_hud: String` → el **emoji vive en el `.tres` del item** (`🪵` madera, `🪨` piedra, `🪙` oro, `🌰` semilla); (2) `ui.gd` gana `@export var contadores_hud: Array[StringName]` (mismo patrón ya probado de `GestorTerreno.celdas`) → el HUD construye una `Label` por id, en el **orden del array**; (3) nuevo nodo `Contadores` (`VBoxContainer`) en `UIHud.tscn`; (4) `_crear_contadores()` + `actualizar_hud()` reescrito para leer de `ItemDatabase` (con guardia `push_warning` si el array está vacío o el id no existe). **GOTCHA importante**: el sistema "no funcionaba" **sin error en consola** porque el array `contadores_hud` estaba **vacío** en la escena (un `@export` con su valor por defecto no aparece en el `.tscn` si nadie lo rellena) → el bucle no ejecutaba ni una vez. Se detectó por inspección del `.tscn`, no por consola. **Limpieza**: se **eliminó la función `craftear(tipo)` legada** de `inventario.gd` (recetas de pico/hacha/azada/regadera escritas a mano) — **código muerto** (nadie la llamaba; todo usa `CrafteoManager`) y además tenía `print` **inalcanzables** tras `return`. Se de paso quitó el `print("[UI HUD] actualizar_hud() llamada")` que ensuciaba la consola en cada cambio de inventario. **Regla nueva: añadir un contador = añadir el id al array del Inspector + `emoji_hud` en el `.tres`.** |
| **FASE 10.13** Contratos de datos (`ClavesDatos`) + limpieza de hardcodeo | ✅ Completado | 16/10/2026 | **Petición del usuario: auditar todo el hardcodeo del proyecto antes de la FASE 11.** **Auditoría**: 10 candidatos revisados; **3 de alta/media prioridad** eran legítimos de corregir. **Solución: nuevo `scripts/core/claves_datos.gd`** (`class_name ClavesDatos extends RefCounted`) como **punto ÚNICO de verdad** para ids de item, claves de `datos_extra` y nombres de acción: `ID_MONEDA` (`&"oro"`), `HERR_AZADA`/`HERR_REGADERA`, `CLAVE_AGUA_ACTUAL`/`CLAVE_AGUA_MAX`/`AGUA_MAX_POR_DEFECTO`, y `ACCION_ABRIR_TIENDA`/`ACCION_CERRAR`/`ACCION_ACEPTAR_MISION`/`ACCION_ENTREGAR_MISION`. **Migrados**: `tienda.gd` (4), `mision_manager.gd` (1), `pozo.gd` (9), `parcela.gd` (8), `crafteo_manager.gd` (2 constantes ahora apuntan a `ClavesDatos`). **CAMBIO #4 (mejora sobre el plan) — pestaña de tienda data-driven**: la pestaña se decidía por **el id del diálogo** (`if _id_diag == &"mercader_menu_vender"`), que sigue siendo un dato en el código. Se aprovechó el hueco `_p1`/`_p2` (parámetros de la señal, antes sin usar) → nuevo `@export var parametro_accion: int` en `DialogoDefinicion` **y** `DialogoOpcion`; `ui_dialogo.gd` emite `parametro` como 3.er argumento de `accion_especial_solicitada`; `npc_tienda.gd` lo usa (`tab_inicial = int(_p1)`) → **la pestaña la declara el `.tres`** (`Dialogo_Mercader_Menu_Vender.tres → parametro_accion = 1`; el de Comprar usa el default 0). **⚠️ GOTCHA GDScript**: `signal` **NO admite valores por defecto** en sus argumentos → el `parametro: int = 0` que se puso inicialmente en la señal dio **`Parser Error: Could not parse global class "UIDialogo"`** (y como efecto colateral el FileSystem reportó como inexistentes `.tres` que sí existían). Fix: quitar `= 0` de la firma (los `emit_signal` ya pasan los 3 argumentos). **Literales que se mantienen a propósito** (no son deuda): `jugador.gd:875-876` (nombres de **nodo** del modelo en mano → se limpian en FASE 13 con #3), `inventario.gd:41-44` (bloque **TEMPORAL** de items iniciales) y `claves_datos.gd` (la definición). **Deuda consciente diferida**: #3 modelos de arma hardcodeados → **antes de FASE 13**; #6 colores por tipo en `icono_item.gd` (placeholder, no tocar hasta tener iconos reales); #8 fallbacks `100` (guardas correctas, no tocar). |
| **FASE 11.1** `GestorClima` (Autoload) | ✅ Completado | 16/10/2026 | **2 DECISIONES DEL USUARIO**: (1) **cada clima es un `.tres`** → `ClimaDefinicion` (Resource) nuevo; (2) **cadencia = rango aleatorio min-max**. **Arquitectura data-driven** (mismo patrón que `ItemDatabase`/`CrafteoManager`): `scripts/recursos/clima_definicion.gd` (`class_name ClimaDefinicion`) con `id`, `nombre_visible`, **`peso`** (probabilidad RELATIVA, no %), `energia_luz`, `color_ambiente`, `factor_oscuridad`, `particulas`, `velocidad_viento`. **4 `.tres` en `recursos/climas/`**: `ClimaSoleado` (peso 4), `ClimaLluvioso` (2), `ClimaVentoso` (2), `ClimaNevado` (1) → total 9 → soleado **44%**, lluvioso 22%, ventoso 22%, nevado 11%. **`gestor_clima.gd`** (Autoload, registrado DESPUÉS de `GestorTiempo`): carga por `DirAccess`, `_on_minuto_cambio` descuenta el contador y sortea, **sorteo PONDERADO** respetando `peso`, señal `clima_cambio(clima_nuevo)`, API `set_clima()` / `cambiar_clima_aleatorio()` / `get_clima_actual()` / `get_minutos_restantes()`. ~~**Detalle clave**: el sorteo **excluye el clima actual** cuando hay más de uno.~~ ⚠️ **REVERTIDO en 11.3**: esa exclusión **renormalizaba** las probabilidades y hacía **imposible** repetir clima (llover 2 días seguidos). Se eliminó → el reparto es ahora el ponderado real. **⚠️ CALIBRACIÓN DE TIEMPO**: `GestorTiempo.minutos_por_segundo = 50` → **1 día de juego ≈ 29 s reales**; por eso la cadencia se expresa en minutos de juego con `@export min/max_minutos_entre_cambios` (**240-600** = 4-10 h de juego ≈ 5-12 s reales), calibrable en el Inspector. **Verificado en consola**: 10 cambios consecutivos, **sin repetir el mismo dos veces seguidas**, con el reparto esperado (soleado el más frecuente). |
| **FASE 11.2** Efectos visuales del clima | ✅ Completado | 16/10/2026 | **Decisión de arquitectura (evita 2 escritores sobre la misma propiedad)**: `ciclo_dia_noche.gd` es el **ÚNICO dueño** de `light_energy`, `light_color` y del `WorldEnvironment`; el clima **NO los escribe**, solo aporta un **modificador** (`energia_luz` multiplicador, `color_ambiente` tinte, `factor_oscuridad` sobre el fondo vía `Color.darkened()`). Así se elimina el bug clásico de "el ciclo pisa al clima cada minuto". `ciclo_dia_noche.gd` guarda el `background_color` original en `_ready()` (para poder recuperarlo al volver a soleado) y escucha `GestorClima.clima_cambio` + lee `GestorClima.clima_actual` una vez al arrancar (el Autoload ya emitió su señal antes de que la escena existiera). **`EfectosClima.tscn` + `efectos_clima.gd`** (nuevo): 2 `GPUParticles3D` (`Lluvia`/`Nieve`) que **siguen a la cámara** en `_process` a `altura_seguimiento = 8 m`, leen `ClimaDefinicion.particulas` para decidir cuál emite, e inclinan el sistema según `velocidad_viento` (`inclinacion_por_viento = 12°`). Instanciado en `mundo.tscn` como **hermano de `Luz`**. **3 GOTCHAS documentados** (ver sección 11.2): `.tscn` pegado **sin saltos de línea** (Godot lee línea por línea → descarta los `[sub_resource]` siguientes → `draw_pass_1` inexistente → invisible **sin error**), **escena nunca instanciada** en `mundo.tscn` (el script no corría; la consola sí cambiaba porque `GestorClima` es Autoload), y **`GPUParticles3D` vacío** = válido pero invisible. **Lección**: configurar partículas **por Inspector**, no pegando `.tscn`; y ante un nodo "que no hace nada" sin errores → verificar primero que esté **instanciado**. ✅ Verificado en juego: lluvia/nieve visibles y siguiendo al jugador; soleado recupera luz y fondo. |
| **FASE 11.3** Estaciones del año | ✅ Completado | 16/10/2026 | **3 DECISIONES DEL USUARIO**: (1) **cada estación es un `.tres`**; (2) **30 días de juego por estación** (ciclo 120 días ≈ 58 min reales); (3) la estación **modifica el PESO** de cada clima (no filtra cuáles pueden salir). **Arquitectura**: `scripts/recursos/estacion_definicion.gd` (`class_name EstacionDefinicion`) con `id`, `nombre_visible`, **`orden`**, `dias_duracion`, `multiplicadores_peso` (diccionario clima→factor) y helper `multiplicador_para()` (comprueba clave `StringName` y `String`, porque el Inspector guarda las claves de un `Dictionary` como **`String`**). **4 `.tres` en `recursos/estaciones/`**: Primavera (1), Verano (2, `nevado = 0.0`), Otoño (3), Invierno (4, `nevado = 4.0`). **`GestorTiempo` EXTENDIDO** (se descartó un Autoload `GestorEstaciones` aparte por **orden de carga**: `GestorClima` necesita leer la estación ya en su `_ready()`, y `GestorTiempo` carga antes): `_cargar_estaciones()` por `DirAccess` + `sort_custom` por `orden`, cálculo por **días ACUMULADOS** (admite duraciones distintas por estación), `estacion_actual`, `get_estacion_actual()`, `get_dias_restantes_estacion()` y señal `estacion_cambio`. Se engancha a su **propia** `dia_cambio` → no hubo que tocar los dos sitios que la emiten. **`GestorClima._sortear_clima()` reescrito**: construye candidatos con **peso efectivo = `peso_base × multiplicador_estacion`** y filtra los de peso ≤ 0 (así Verano nunca tiene nieve, y lo hace el DATO, no una regla en código). **⚠️ GOTCHA — orden empatado = bug SILENCIOSO**: los 4 `.tres` se crearon **sin** rellenar `orden`, así que Primavera/Otoño/Invierno quedaron en `1`, `sort_custom` no pudo desempatar y se conservó el orden **alfabético de `DirAccess`** (Invierno, Otoño, Primavera, Verano) → **el juego arrancaba en Invierno**. Se añadió un `push_warning` opcional si dos estaciones comparten `orden`. Otros despistes detectados en los `.tres`: clave `"lluvios"` (typo, sin la `o`) en Primavera y la clave **`nevado` ausente** en los 4 → el multiplicador de nieve no se aplicaba **en silencio** (un typo en una clave de diccionario **no** da error). **CAMBIO post-verificación (petición del usuario: "podría repetirse el clima, como que llueva 2 días seguidos")**: se **eliminó la exclusión del clima actual** en `_sortear_clima()` (las 3 líneas del `continue`) → esa exclusión **renormalizaba** las probabilidades sobre los demás y hacía la repetición **imposible por construcción**. Ahora la repetición es posible, con la frecuencia que dictan los pesos (en Primavera lluvia ≈35% → dos días seguidos ≈12%). ✅ Verificado en juego: arranca en **Primavera**, el ciclo avanza y el clima puede repetirse. |
| **FASE 11.4** Impacto del clima en la jugabilidad | ✅ Completado | 16/10/2026 | **Petición del usuario: que el clima "deje de ser decorativo". Regla aplicada: cada efecto se declara en el DATO, no en el código** → 3 campos nuevos en Resources ya existentes, así el balance se cambia editando un `.tres`: `ClimaDefinicion.riega_cultivos` (lluvia riega parcelas **sin gastar agua**), `ClimaDefinicion.multiplicador_velocidad_jugador` (nieve **0.65**), `EstacionDefinicion.multiplicador_crecimiento_cultivos` (Invierno **0.4**, Otoño 0.9, Primavera 1.2, Verano 1.3). **`parcela.gd`**: escucha `GestorClima.clima_cambio` + `GestorTiempo.estacion_cambio` y **sincroniza con el estado actual en `_ready()`** (ambas señales ya se emitieron antes de que la parcela existiera — mismo gotcha de 11.2); `_process` multiplica el crecimiento por el factor de estación; `_riego_por_clima()` marca `regado = true` sin tocar la regadera, y se invoca también al **plantar bajo la lluvia** y en **`_on_nuevo_dia`** (si sigue lloviendo al amanecer). **`jugador.gd`**: `_mult_velocidad_clima` con `clampf(..., 0.2, 1.0)` → el clima **nunca acelera** ni detiene al jugador; fórmula final `base × energía(stats) × clima`. **Decisión del usuario**: el **viento** se queda sin efecto de gameplay por ahora. ✅ Verificado en juego. |
| **FASE 11.5** Indicador de estación en el HUD | ✅ Completado | 16/10/2026 | **Petición del usuario: "agreguemos indicador de estación".** `EstacionDefinicion.emoji_hud: String` (mismo patrón data-driven que `ItemDefinicion.emoji_hud` de 10.12) → el emoji vive en el `.tres` (`🌸` Primavera, `☀️` Verano, `🍂` Otoño, `❄️` Invierno); **añadir una estación nueva no requiere tocar el HUD**. `Label` **`IndicadorEstacion`** en `UIHud.tscn` (posición `x=5, y=150`, debajo de los contadores). `ui.gd`: `_actualizar_indicador_estacion()` lee `emoji_hud` + `nombre_visible` del `.tres` y `GestorTiempo.get_dias_restantes_estacion()`. Se refresca con **`estacion_cambio`** (cambia nombre/emoji) **y `dia_cambio`** (bajan los días restantes). Formato: `🌸 Primavera — 30 días`. ✅ Verificado en juego. |
| **FASE 12.1** Componente Nivel/XP | ✅ Completado | 17/10/2026 | **Nuevo `scripts/jugador/nivel.gd`** (`class_name Nivel extends Node`) como **Node HIJO del jugador** (mismo patrón componente que `Damageable` y `Stats`, nunca por herencia → en co-op cada jugador tiene el suyo). `xp_base` (100) + `exponente_curva` (1.5) → **la curva es balance editable en el Inspector**, no código. Umbral = `xp_base × nivel^exponente`. `ganar_xp()` usa **`while` y no `if`**: una sola muerte puede subir varios niveles; el **sobrante se arrastra** al siguiente nivel (**se resta ANTES de recalcular el umbral**, porque el umbral depende del nivel nuevo). Señales `xp_cambio(xp_actual, xp_necesaria)` y `nivel_subido(nuevo_nivel)`. **Punto ÚNICO de reparto: `static func otorgar_xp_a_atacante(p_atacante, p_cantidad)`** → comprueba `is_in_group("jugador")` y busca el hijo `Nivel`; así `EnemigoBase`/`AnimalBase` **no duplican la regla** ni conocen la estructura interna del jugador. `@export var xp_al_morir: int = 0` en `enemigo_base.gd` y `animal_base.gd` (recompensa por enemigo, data-driven); `_on_murio(atacante_path)` (⚠️ el parámetro dejó de estar sin usar y se le quitó el guion bajo) llama `Nivel.otorgar_xp_a_atacante(get_node_or_null(atacante_path), xp_al_morir)` → **la XP va a quien mató de verdad** (jugador y flecha ya se pasan a sí mismos como atacante desde 10.2/10.3), y `get_node_or_null` de un path vacío/inválido devuelve `null` **sin crash** (inanición, trampa, atacante ya liberado). Repartido: Conejo 3, Ciervo 10, Puma 20, Slime 8. ✅ Verificado en juego. |
| **FASE 12.4** Recompensas: HUD de XP + notificación de nivel | ✅ Completado | 17/10/2026 | **Petición del usuario: "no vemos la experiencia"** — 12.1 era motor puro y su único `print` sale **al SUBIR de nivel**, así que con `xp_base = 100` hacían falta ~33 conejos para ver algo (silencio = ¿bug?) → se adelantó la parte visual de 12.4. **Sin polling**: el HUD escucha `xp_cambio` y `nivel_subido`. **Sincronización inicial obligatoria**: el `xp_cambio.emit()` del `Nivel._ready()` ocurre **antes** de que el HUD conecte (el HUD busca al jugador en su primer `_process`) → `_intentar_conectar_nivel()` pinta el estado una vez a mano con `get_xp_actual()`/`get_xp_siguiente()`/`get_nivel()` (mismo patrón ya usado con `Stats`). `_pintar_xp()` **reutiliza `_actualizar_barra()`** (la misma que vida/hambre/energía) → cero código nuevo de pintado. `_on_xp_cambio` **vuelve a leer el nivel** porque la señal no lo trae; el orden es correcto porque `ganar_xp()` sube el nivel **antes** de emitir `xp_cambio`. Nodos en `UIHud.tscn`: `BarraXPExterior` (250×12) + `BarraXPInterior` + `LabelNivel`. Formato `Nv. N — X/Y XP`. Después, a petición del usuario, se añadió la **notificación flotante "¡Nivel X!"** (`NotificacionNivel`, label dorado `Font Size 32`, `mouse_filter = Ignore`) con `_mostrar_notificacion_nivel()`: se eligió **Label de HUD y no `Label3D`** porque el aviso es información **de pantalla**, no del mundo. Cubre **3 peligros**: (1) subir 2 niveles de golpe → `Nivel.ganar_xp()` usa `while` y emite `nivel_subido` varias veces → **`kill()` del tween previo**; (2) tween interrumpido que dejaría el Label invisible/descolocado → **reset completo** (texto, posición, alpha) antes de cada animación; (3) parpadeo de 1 frame → alpha a **0 ANTES** de `visible = true`. **Posición base capturada en `_ready()`** y no por aviso (si no, el Label iría trepando por la pantalla). Un solo `Tween` con `set_parallel(true)` (entrada 0.2 s, subida `TRANS_SINE`/`EASE_OUT` 1.6 s, desvanecido con `set_delay(1.1)` — que captura el valor de partida al arrancar, no al crear). ✅ Verificado en juego. **FASE 12 cerrada al 100%.** |
| **FASE 12.2** Estadísticas (atributos) | ✅ Completado | 17/10/2026 | **Petición del usuario: "no entiendo qué debería pasar si subo de nivel, no me sube ningún stat."** Diagnóstico: el motor de 12.2 funcionaba, pero **no había ninguna UI que mostrara los atributos** → el sistema era invisible (mismo patrón que ya nos mordió con la XP). **Nuevo `scripts/jugador/estadisticas.gd`** como **Node hijo** del jugador (hermano de `Damageable`/`Stats`/`Nivel`). **⚠️ DESVIACIÓN CONSCIENTE DEL PLAN**: el plan pedía `vida_max = 100 + constitucion*10` / `daño_base = fuerza*2`, pero con los atributos iniciales en 5 eso daba **150 HP y 15 de daño desde el nivel 1** (regresión de balance). Se introduce **`@export atributo_base: int = 5`** (valor NEUTRO): con los tres atributos = `atributo_base` el juego se comporta **idéntico a antes de 12.2**; poner `atributo_base = 0` recupera las fórmulas literales del plan → **un solo knob cambia entre ambas interpretaciones**. **Reparto automático por tabla** (elegido por el usuario): `@export crecimiento_por_nivel` (`{fuerza:1, constitucion:1, destreza:1}`) aplicado al escuchar `Nivel.nivel_subido`; la lógica itera con **`get(clave)`/`set(clave)`** → **atributo nuevo = un `@export` + una clave, sin tocar la lógica** (cero hardcodeo). **Destreza → velocidad de ataque** (elegida por el usuario; el plan no la definía): reduce el cooldown con tope `reduccion_cooldown_maxima`. **Punto único de verdad del daño**: `jugador.gd` gana `_daño_efectivo()` (arma + `get_bono_daño()`) y `_cooldown_de_arma()` (arma × `get_multiplicador_cooldown()`), y los **3 sitios** que repartían daño + los **3** que fijaban cooldown pasan a llamarlas. **Vida máxima**: nuevo `Damageable.set_vida_maxima(nueva_max, p_ajustar_actual)` (único dueño de las variables; si sube, gana la diferencia) aplicado desde **`Jugador._ready()`** y NO desde `Estadisticas._ready()`, porque **en Godot los hijos corren `_ready()` ANTES que el padre** y se pisaría. **Panel de atributos en el HUD**: `Estadisticas.get_texto_hud()` construye el texto recorriendo `@export abreviaturas` (`{fuerza:"FUE",...}`) con `get()` → **el HUD no conoce ningún atributo**; `LabelAtributos` en `UIHud.tscn`, repintado por `estadisticas_cambiadas` **sin polling**. ⚠️ Lección: con la vida a tope la barra NO se ve cambiar al subir (100/100 → 110/110, misma proporción) — no es bug, `set_vida_maxima` regala la vida nueva. ✅ Verificado en juego. |
| **FASE 12.3** Enemigos con Nivel | ✅ Completado | 17/10/2026 | **Desviación consciente del plan**: el plan pedía *"zonas más alejadas = enemigos de mayor nivel"*, pero **la arquitectura no tiene zonas** — `enemigo_spawner.gd` genera en un **anillo alrededor del jugador** (8-18 m), así que la posición del spawner NO decide dónde aparece el enemigo; además los spawners de Conejo/Ciervo/Puma usan **`AnimalBase`**, no `EnemigoBase`. **Modelo elegido por el usuario: "nivel por spawner/tipo"** (cada spawner sortea `nivel_min`..`nivel_max` por instancia; "zona" = spawner) → cero cambios a la arquitectura de spawn. Añadido en **`EnemigoBase` y `AnimalBase`** (duplicado a propósito, mismo criterio que `xp_al_morir`, porque el spawner es genérico): `@export nivel: int = 1` + `vida_por_nivel` / `daño_por_nivel` / `xp_por_nivel`. **Fórmula `final = base + (nivel-1) × incremento`** → con nivel 1 no cambia nada (**cero regresión**). `_vida_base` se lee de `Damageable.vida_maxima` en `_ready()` y se aplica con **`Damageable.set_vida_maxima()`** (el mismo contrato del jugador); `daño_ataque`/`xp_al_morir` se suman directo. En `AnimalBase` se omite el daño (FSM pasiva, no existe `daño_ataque`). **`enemigo_spawner.gd`**: `nivel_min/nivel_max` y el nivel se asigna con `instancia.set("nivel", nv)` **ANTES de `add_child()`** — orden crítico, porque **`add_child()` dispara `_ready()`**, donde corre el escalado (setearlo después = fallo silencioso). **Config**: Slime `6/2/4` nv1-2, Conejo `2/0/1` nv1, Ciervo `5/0/2` nv1-2, Puma `10/0/6` nv2-3. ⚠️ **Lecciones**: (1) **`print` con menos argumentos que huecos NO da error** → GDScript imprime la cadena **literal con los `%s`** (fue el `[Spawner %s]...` sin reemplazar: faltaba `nv` en el array); (2) **`@CharacterBody3D@NNN`** = Godot renombra así los nodos cuando el nombre **se repite entre hermanos** (cosmético; se arregla con `add_child(instancia, true)`); (3) el **texto "50/50" duplicado en la barra** NO era la vida repetida sino **DOS Labels superpuestos**: `NumVida_Sombra` recibía offsets explícitos (texto centrado) y `NumVida_Frente` no (texto pegado a la izquierda) → se sustituyó el truco de 2 labels por **UN Label con `outline_size` + `font_outline_color` reales** (el comentario *"Label 2D NO TIENE outline_size"* era **falso**: eso vale para `Label3D`, no para `Label`); (4) `_on_enemigo_murio` tiene una rama que **descuenta el contador SIN imprimir 💀** cuando el nodo ya fue liberado → explica logs tipo `1/5 → 1/5 → 2/5`. ⚠️ **Corrección de un diagnóstico previo**: se creyó que un `add_child` duplicado provocaba **doble `_ready()` y doble escalado de vida** — **era FALSO**: se verificó con grep que no existe ningún `_enter_tree`/`request_ready`/`_notification` en `scripts/`, y `_ready()` corre **una sola vez** por nodo. El duplicado es solo ruido (borrar la línea sobrante). ✅ Verificado en juego (`nv 1`/`nv 2`/`nv 3` correctos). |

---

## 📐 REGLA TRANSVERSAL — Cero Hardcodeo (Escalabilidad)
A partir de la FASE 8, **nunca** se escribirán contadores, valores de balance, listas de items/enemigos/recetas directamente en el código. Todo dato configurable debe vivir en:
- **Resources `.tres`** (items, recetas, enemigos, armas, biomas, eventos).
- **`@export`** en los scripts para valores ajustables por escena.
- **Autoloads managers** que carguen datos desde carpetas (`DirAccess`), igual que `ItemDatabase`, `CrafteoManager` y `DialogoDatabase`.

Si una fase requiere un "contador fijo" (ej: vida máxima de un slime), se modela como campo `@export` o campo del Resource correspondiente.

---

## 📦 FASE 8 — Supervivencia Básica (Hambre, Sueño y Consumibles)
> **Objetivo**: Añadir necesidades básicas al jugador que creen un bucle de supervivencia y den propósito a la comida/cama. Se apoya en el patrón de **Componente** (igual que `Damageable`).
> **Aprendizajes**: Componente reutilizable `Stats`, objetos que modifican el tiempo (cama), consumibles data-driven, HUD multi-barra.

### ⏳ Orden de submódulos FASE 8 (NO saltarse pasos)
```
8.1 Componente Stats (hambre/energía) → 8.2 Cama + Dormir (avanzar tiempo) → 8.3 Consumibles (Items tipo "comida") → 8.4 HUD hambre/energía → 8.5 Integración día/noche y daño por hambre
```

### 8.1 Componente `Stats` (Hambre + Energía)
- **Archivo**: `scripts/jugador/stats.gd` (extends Node, se agrega como hijo del Jugador, igual que `Damageable`).
- **Variables @export**: `hambre_max: int = 100`, `energia_max: int = 100`, `consumo_hambre_por_minuto: float = 0.05`, `consumo_energia_por_minuto: float = 0.03`.
- **Señales**: `hambre_cambio(valor:int)`, `energia_cambio(valor:int)`, `hambre_critica`, `agotamiento_cambio(agotado:bool)`.
- Decrecer hambre/energía según `GestorTiempo.minuto_cambio` (no por frame real, sino por minuto de juego → coherente con el ciclo día/noche).
- Si `hambre <= 0` → el jugador recibe daño periódico vía `Damageable.recibir_danio()`.
- Métodos públicos: `comer(monto:int)`, `descansar(monto:int)`, `gastar_energia_correr(delta)`, `puede_correr()`, `get_multiplicador_velocidad()`, `get_hambre()`, `get_energia()`.

### 8.2 Cama: Objeto Interactuable que Avanza el Tiempo
- **Archivo**: `scripts/mundo/cama.gd` (StaticBody3D interactuable, mismo patrón `interactuar/get_prompt`).
- Al presionar F: avanza `GestorTiempo` varias horas (ej: 8h), restaura energía al 100%.
- Llama a `GestorTiempo.avanzar_tiempo(minutos)` (método que respeta las señales `hora_cambio`/`dia_cambio`).

### 8.3 Consumibles (Extender `ItemDefinicion`)
- Añadir a `item_definicion.gd` campos nuevos con default 0: `hambre_restaurada: int`, `vida_restaurada: int`. Un item es comestible **si sus datos lo dicen** (sin `if tipo=="comida"`).
- Items `.tres` marcados: pan (25/5), tomate (10/0), zanahoria (8/0).
- Método `Inventario.usar_item(indice)`: gasta 1 unidad y emite `item_consumido(id, hambre, vida)`. `Stats` escucha y aplica `comer()` + `Damageable.sanar()`.

### 8.4 HUD: Barras de Hambre y Energía
- Extender `UIHud.tscn` y `ui.gd`: añadir 2 barras `ColorRect` al lado de la de vida.
- Conectar señales `Stats.hambre_cambio` y `Stats.energia_cambio` (sin polling). Función reutilizable `_actualizar_barra()`.

### 8.5 Integración y Test (correr ↔ energía + agotamiento)
- Verificar: dormir en cama → salta el sol, energía llena; no comer → hambre baja → daño; comer tomate → hambre sube.
- **Correr consume energía**; al llegar a 0 el jugador entra en **agotamiento** (no puede correr y anda a velocidad reducida). Se sale del agotamiento al recuperar el 25% de energía (histéresis).

---

## 📦 FASE 9 — Fauna (Animales) y Respawn de Recursos
> **Objetivo**: El mundo se sienta vivo y no se agote. Animales pasivos con drops + sistema de respawn para árboles, rocas y animales.
> **Aprendizajes**: IA de huida, sistema de respawn desacoplado, drops unificados.

### ⏳ Orden de submódulos FASE 9
```
9.1 Sistema de Drops Unificado (DropManager) → 9.2 AnimalBase (conejo/ciervo) → 9.3 Respawn árboles/rocas → 9.4 Spawner de animales → 9.5 Integración (caza)
```
> **Nota de reordenación**: se colocó el sistema de drops en 9.1 (antes era 9.2) porque es la infraestructura que consumen tanto los animales como el propio `EnemigoBase` (que a día de hoy NO suelta nada). Construir la base primero evita reescribirla.

### 9.1 Sistema de Drops Unificado (`DropManager`)
- **Hallazgo real**: `EnemigoBase._on_murio()` actualmente NO suelta drops (no hay nada hardcodeado, simplemente no existe la lógica). `arbol.gd` y `roca.gd` sí sueltan, pero con `item_id` y `PackedScene` **hardcodeados** cada uno por su lado.
- Crear un **Autoload `DropManager`** (`scripts/core/drop_manager.gd`) con API `soltar(drops: Array, posicion: Vector3, padre: Node = null, excluir: Node3D = null)`.
- Formato de cada drop (data-driven, mismo en enemigos/animales/recursos): `{"item_id": StringName, "cantidad": int, "cantidad_max": int (opcional), "probabilidad": float}`.
  - `cantidad` = mínimo; `cantidad_max` (opcional) = máximo → cantidad aleatoria `randi_range(min, max)`. Si falta `cantidad_max`, la cantidad es fija.
  - `probabilidad` = probabilidad de que el drop aparezca (0.0–1.0). Es un concepto DISTINTO de la cantidad.
- Instancia una **escena genérica `PickupItem.tscn`** (Area3D + MeshInstance3D llamado `Mesh` + CollisionShape3D, con `pickup.gd`) en lugar de una escena por item. El color del mesh se deriva del **tipo** del item reutilizando la tabla `IconoItem.COLORES_POR_TIPO` (una sola fuente de verdad para colores).
- **Colocación en el suelo por raycast**: `Area3D` NO tiene física/gravedad (no cae). El origen de los enemigos está a ~0.45 m (cápsula centrada en el origen), por lo que sumar `altura_spawn` sobre el origen los dejaba flotando. Solución: `_altura_suelo()` hace un raycast hacia abajo (`direct_space_state.intersect_ray`) y coloca el pickup a `y_suelo + mitad_alto` donde `mitad_alto` se **deriva del `BoxShape3D` real de la escena** (no hardcodeado). El raycast **excluye la entidad emisora** (`excluir.get_rid()`) para que el enemigo/cadáver no bloquee el rayo.
- **Gotcha del suelo de una sola cara**: el suelo es un `ConcavePolygonShape3D` (trimesh). Los raycast respetan la orientación de la cara; si la malla "mira" hacia abajo, un rayo descendente la impacta por detrás y NO se registra → el rayo cae al `return y_referencia` (altura del enemigo ≈0.45) y el drop flota. Solución: `_altura_suelo()` lanza el rayo hacia abajo y, si no impacta, **reintenta hacia arriba** desde debajo del suelo (cubre ambas orientaciones).
- `soltar()` se ejecuta vía `call_deferred`: puede invocarse desde señales de física (body_entered/murio) y el raycast al `direct_space_state` debe hacerse fuera del *flushing* del motor de física.
- Los drops se añaden al `current_scene` (raíz del mundo) con una pequeña dispersión aleatoria en XZ.
- **Uso**: `EnemigoBase` gana `@export var drops: Array[Dictionary] = []` y llama a `DropManager.soltar(drops, global_position, null, self)` en `_on_murio()`.

### 9.2 `AnimalBase` (IA de Huida)
- **Archivo**: `scripts/animales/animal_base.gd` (extends CharacterBody3D).
- Estados FSM: `PASTAR` (deambula lento) y `HUIDA` (corre del jugador si está dentro de `rango_alerta`).
- `@export`: velocidad de pastoreo, velocidad de huida, rango_alerta, drops (`Array[Dictionary]`, mismo formato que `EnemigoBase`).
- Conejo: rápido, poca vida, drops cuero/carne. Ciervo: más vida, drops más carne/cuero.
- Usa el `Damageable` existente y `DropManager` (9.1).

### 9.3 Respawn de Recursos (Árboles/Rocas)
- Árboles y rocas hoy son `StaticBody3D` con `recibir_golpe()` que se **autoeliminan** con `queue_free()` (un solo golpe). Para respawnear hay que dejar de destruirlos: en su lugar, **ocultar mesh + colisión** y arrancar un temporizador.
- **Enfoque elegido**: un `RespawnManager` (Autoload) que registra recursos y los restablece cada X **días de juego** escuchando `GestorTiempo.dia_cambio` (coherente con el resto del tiempo del juego, no segundos reales).
- Refactorizar `arbol.gd`/`roca.gd` para que sueltan drops vía `DropManager` (9.1) y se desactiven/reactiven en lugar de `queue_free()`.

### 9.4 Spawner de Animales
- Reutilizar `enemigo_spawner.gd` (ya desacoplado vía `PackedScene`) para animales pasivos.
- Máximo por zona, cooldown, y (opcional) `solo_dia`/`solo_noche` reutilizando `GestorTiempo.es_dia()`.

### 9.5 Integración (Caza)
- Confirmar que el jugador puede cazar animales con hacha/espada (reutilizando el flujo de `Damageable`) y recoger sus drops del suelo.

---

## 📦 FASE 10 — Arsenal Ampliado: Espada, Arco y Proyectiles
> **Objetivo**: Nuevas armas, incluyendo combate a distancia. Se apoya en el sistema de armas data-driven ya existente (`ArmaDefinicion`).
> **Aprendizajes**: proyectiles (`RigidBody3D` o `Area3D` en movimiento), munición en inventario, armas a distancia.

### ⏳ Orden de submódulos FASE 10
```
10.1 Espada (melee) → 10.2 Sistema de Proyectiles → 10.3 Arco + Flechas (munición) → 10.4 Balance y recetas
```

### 10.1 Espada (Arma Cuerpo a Cuerpo)
- Crear `recursos/armas/ArmaEspada.tres` (mayor daño y alcance que el hacha).
- Añadir item `item_espada.tres` y receta `receta_espada.tres` (en `banco_trabajo`; el `yunque` no existe todavía).
- ⚠️ **CORRECCIÓN AL PLAN (15/10/2026)**: este documento afirmaba "Reutiliza el flujo existente de `ArmaDefinicion` (**carga automática por carpeta**)". Eso era **FALSO**. `jugador.gd → _cargar_mapa_armas_desde_recursos()` usaba un `Dictionary` con **5 rutas escritas a mano** (`res://recursos/armas/ArmaPunos.tres`, `ArmaHacha`, `ArmaPico`, `ArmaAzada`, `ArmaRegadera`). Consecuencia real: un `ArmaEspada.tres` **nunca se cargaba** → la espada se equipaba en el inventario pero golpeaba con las estadísticas del *fallback* (puños). Viola la regla de **cero hardcodeo**. **Fix (10.1)**: refactor a **escaneo de carpeta con `DirAccess`** (mismo patrón que `CrafteoManager` y `ItemDatabase`), con clave = el campo `nombre` del `ArmaDefinicion`. A partir de ahí, **añadir un arma = crear solo el `.tres`**.
- **Segundo hardcodeo relacionado**: el refresco de modelos en mano estaba escrito a mano en `_process` (4 líneas `modelo_x.visible = (Inventario.herramienta_equipada == &"x")`). Se refactoró a un `Dictionary` modelo↔id para que añadir un arma no obligue a tocar el bucle de dibujo.
- **Tercer hardcodeo (CERRADO 18/10/2026)** — **el `Dictionary` de 10.1 seguía siendo hardcodeo**. Consumía 6 `@onready` con nombre fijo (`$VisualHolder/ModeloHacha`, `ModeloPico`, `ModeloAzada`, `ModeloRegadera`, `ModeloEspada`, `ModeloArco` — [jugador.gd L63-68]) y los mapeaba a mano en `_init_modelos_arma()`. Añadir un arma exigía **3 ediciones**: nodo nuevo en `Jugador.tscn` + `@onready` + entrada en el `Dictionary`. Eso **bloqueaba el arma legendaria de 13.4**: sus `ItemDefinicion`/`ArmaDefinicion` son datos, pero el visual obligaba a tocar escena y código.
- **Fix aplicado**: `ArmaDefinicion` gana `@export var malla: Mesh` + `@export var transform_modelo: Transform3D` (grupo `Visual`). La escena del jugador pasa de 6 nodos a **UNO solo** (`ModeloArmaActual`), y `_aplicar_visual_arma()` hace `mesh = arma.malla; transform = arma.transform_modelo`. **El arma es ahora 100% autocontenida: un arma nueva = UN archivo `.tres`, sin tocar `.gd` ni `.tscn`.** Los 6 nombres de arma desaparecieron por completo del código.
- **⚠️ Lección — el orden de filas de `Transform3D()` en el `.tscn` NO es el orden de los campos del Inspector**: el literal `Transform3D(a,b,c, d,e,f, g,h,i, x,y,z)` va por **filas** de la base, mientras que los campos `X`/`Y`/`Z`/`Origin` del Inspector son las **columnas** (los ejes del modelo). Pegar el literal del `.tscn` en los campos del Inspector produce la **transpuesta** → el arma queda girada ~150° (apuntando hacia atrás). **Método fiable: copiar la propiedad `Transform Modelo` completa** (`Ctrl+C`/`Ctrl+V` entre `.tres`), no teclear los números.
- **⚠️ Lección — `Origin` incompleto pasa desapercibido**: a la espada se le perdió la componente Z del `Origin` (`-0.42557475` → `0`). Como el frente del `VisualHolder` es `-Z`, eso coloca el arma **centrada en el torso** en vez de delante de la mano. Un `Transform3D` con 12 números tiene **12 oportunidades de error**: comparar el literal completo caracter a caracter, no a ojo.
- **Nota de arquitectura**: el sistema de equipar (`Inventario.equipar_herramienta`) exige `ItemDefinicion.tipo == &"herramienta"`, por eso la espada se registra con `tipo = &"herramienta"` (y `herramienta_tipo = &"espada"`). Renombrar el concepto a "arma" es un refactor mayor que se hará en la Fase 20 (renovación de UI).

### 10.2 Sistema de Proyectiles
- **Escena**: `escenes/combate/Proyectil.tscn` (Area3D con Mesh, script `proyectil.gd`).
- El proyectil se mueve en línea recta (`_physics_process` → `position += direccion * velocidad * delta`).
- Al hacer `body_entered`: si tiene `Damageable` → `recibir_danio(daño, tirador)`; luego `queue_free()`.
- Tiempo de vida máximo (ej: 3s) para evitar proyectiles infinitos.

### 10.3 Arco + Flechas (Munición)
- `ArmaArco.tres`: tipo a distancia, daño, velocidad proyectil.
- Munición: item `item_flecha.tres` (stackeable). Al disparar: `Inventario.tiene_item(&"flecha", 1)` → si no, no dispara; si sí, consume 1.
- El jugador instancia `Proyectil.tscn` en la posición del arco, dirección = frente del jugador (eje -Z de `VisualHolder`).

### 10.4 Balance y Recetas
- Receta del arco y las flechas en `assets/recetas/`. ✅ (hecho en 10.3)
- ⚠️ **CORRECCIÓN AL PLAN**: decía "Testear: **espada golpea a distancia**". Es un error de redacción: la espada es **melee**. Lo correcto es "la espada golpea a 2.4 m (alcance melee ampliado) y el arco dispara flechas que desaparecen al impactar".

#### 📊 Auditoría de balance (15/10/2026) — datos reales leídos del proyecto

**Tabla de armas (del código/`.tres` reales):**

| Arma | Daño | Cooldown | DPS | Alcance | Receta | Coste materiales (a `precio_venta`) |
|---|---|---|---|---|---|---|
| Puños | 5 | 0.55 | 9.1 | 1.6 | — | — |
| Azada | 8 | 0.7 | 11.4 | 1.7 | 2 madera + 2 piedra | 14 |
| Pico | 14 | 0.6 | 23.3 | 2.1 | 2 madera + 4 piedra | 22 |
| Hacha | 18 | 0.65 | 27.7 | 2.3 | 2 madera + 4 piedra | 22 |
| Espada | 25 | 0.5 | **50.0** | 2.4 | 2 madera + **1 colmillo_puma** + 3 piedra | **68** |
| Arco | **35** | 0.9 | 38.9 | ∞ (rango) | 4 madera + **1 cuero** | **15** |

#### 🔴 Problema de balance #1 — El arco rompe la progresión del arsenal
El arco hace **35 de daño por impacto, MÁS que la espada (25)**, y su receta cuesta **15 de materiales vs 68** (4.5× más barato), **sin requerir el drop raro** (`colmillo_puma`, que solo suelta el puma de noche al 60%). Es decir: un jugador racional **nunca fabrica la espada**. Lo único que compensa es el DPS (38.9 < 50) y el consumo de munición — pero el arco es **seguro** (a distancia), así que sale ganando en la práctica.

> **DECISIÓN DEL USUARIO (15/10/2026): SE DEJA COMO ESTÁ (daño 35, receta 4 madera + 1 cuero).** Criterio de diseño elegido: **priorizar que el combate a distancia sea divertido desde pronto** por encima del rigor de la curva de progresión. El arco queda como el arma más eficiente del juego en esta etapa; la progresión "hacha < arco < espada" **no se aplica**. Se reevaluará cuando lleguen las armas especiales de la Fase 13 (donde el `colmillo_puma` tendrá más usos y la espada podrá reposicionarse como arma de mayor daño).

#### ✅ RESUELTO — Problema #2 — Cantidades implícitas (16/10/2026)
**HALLAZGO TÉCNICO DECISIVO**: Godot **no serializa en el `.tres` las propiedades cuyo valor coincide con el *default* del script**. Por eso `cantidad = 1` **nunca se escribe** en el archivo: es **indistinguible** de no poner nada. Evidencia cruzada en el propio proyecto (4 propiedades, mismo patrón): `cantidad` (default 1 → solo se guardan 4/2/3), `precio_venta` (default 0 → solo se guarda 10), `stack_maximo` (default 99 → solo se guarda 1), `tipo` (default `&"recurso"` → solo se guarda `&"herramienta"`). **Consecuencia**: la indicación original del plan ("escribir la cantidad explícita") era **técnicamente imposible** con valor 1, y lo mismo aplicaba al `nombre = &"puños"` de #4 (Godot lo habría borrado igual). La fragilidad **no se elimina escribiendo el valor**; solo se evita **no cambiando nunca el default**. **DECISIONES DEL USUARIO (16/10/2026)**: (a) `receta_flecha.tres` → **`2 madera + 2 piedra` INTENCIONAL** (sube el coste de la munición por decisión de diseño); (b) `cuero` (arco) y `colmillo_puma` (espada) **se dejan en 1 por default**, tratando el default de `IngredienteReceta.cantidad` (1) como **fuente única de verdad** — documentado en el script. Alternativa descartada: cambiar el default a 0/-1 y validar en `CrafteoManager` (más código para el mismo resultado).

#### ✅ RESUELTO — Problema #3 — `precio_venta` e incoherencias de precio (16/10/2026)
`item_arco.tres`: `precio_compra` **200 → 40** y `precio_venta` **30 → 10**. `item_espada.tres`: `precio_venta` **0 → 10** (conserva `precio_compra = 40`). Ahora arco y espada son coherentes entre sí. **DECISIÓN DEL USUARIO (16/10/2026)**: `item_flecha.tres` **se queda SIN `precio_venta` → 0 = NO VENDIBLE (intencional)**: la munición es consumible, no un bien comerciable. ⚠️ No afecta al gameplay hoy: ninguno está en `Catalogo_Mercader.tres` (solo 6 entradas: semilla, semilla_tomate, semilla_zanahoria, tomate, zanahoria, semilla_trigo).

#### ✅ RESUELTO — Problema #4 — `ArmaPunos.tres` / `nombre` (16/10/2026)
**Intento fallido documentado**: se escribió `nombre = &"punos"` (**sin tilde**) en `ArmaPunos.tres`. Como el id real de los puños es `&"puños"` (**con tilde**, en `arma_definicion.gd:8`, `inventario.gd:23` y el fallback de `jugador.gd:788`), el arma se cargaba en `_mapa_armas` bajo la clave `&"punos"`; el jugador arranca con `herramienta_equipada = &"puños"` → `_mapa_armas.has(&"puños")` = false → `else` → `get(&"puños", null)` = **null** → `_aplicar_arma_por_herramienta_equipada()` hacía **`return` sin configurar daño ni hitbox** (puños fallaban en silencio). **Ironía**: funcionaba *por coincidencia* con el default; el intento de hacerlo "explícito" lo rompió. **Solución final**: se **eliminó** el campo `nombre` de `ArmaPunos.tres` → usa el default del script (`&"puños"`, con tilde), que casa con el id del inventario. Aplica el mismo HALLAZGO TÉCNICO de #2: `nombre` con valor igual al default **jamás se serializa**. **Regla adoptada**: el default del script es la **fuente única de verdad** y **NO debe cambiarse**.

#### ✅ Verificado — No hay arbitraje con el mercader
Comprobado contra `Catalogo_Mercader.tres`: comprar `semilla` (2) y venderla (1) da pérdida; ídem `tomate` (5→2) y `zanahoria` (4→2). `semilla_trigo` es comprable (2) pero **no vendible**. No existe bucle de compra→venta con beneficio.

#### ✅ Verificado — El bucle de caza → arma se cierra
`colmillos` del puma (60%, solo noche, max 2 pumas) → `receta_espada` → espada de 25 de daño. DPS y rareza coherentes **una vez aplicado el problema #1**.

### 📋 Checklist de 10.4
- [x] ~~Decidir el ajuste del arco (#1)~~ → **DECIDIDO: se deja como está (35 daño)**, por decisión de diseño del 15/10/2026.
- [x] ~~Escribir la `cantidad` explícita en los 3 ingredientes de #2~~ → **RESUELTO (16/10/2026)**: `receta_flecha.tres` fijado a `2 madera + 2 piedra` (intencional). `cuero` y `colmillo_puma` se dejan en **1 por default** (Godot no serializa valores iguales al default → tratado como fuente única de verdad; regla: **nunca cambiar el default de `IngredienteReceta.cantidad`**).
- [x] ~~Completar `precio_venta` en `item_flecha.tres` y `item_espada.tres`~~ → **RESUELTO (16/10/2026)**: espada `precio_venta = 10`; flecha **se queda en 0 = no vendible (intencional, consumible)**.
- [x] ~~Coherencia `precio_compra`: arco y espada~~ → **RESUELTO (16/10/2026)**: arco `200→40`, venta `30→10`; espada `40 / venta 10`. Coherentes.
- [x] ~~Añadir `nombre = &"puños"` explícito en `ArmaPunos.tres`~~ → **RESUELTO (16/10/2026)** por vía inversa: se **eliminó** el campo (el intento `&"punos"` sin tilde rompía la carga de los puños). Usa el default `&"puños"`.
- [x] ~~Prueba final: equipo hacha → arco → espada y comprobar que cada uno cambia daño/alcance y que el modelo en mano cambia.~~ → **VERIFICADO (16/10/2026)**: puños sobre árbol **no talan** (correcto: `herramienta_tipo` vacío ≠ `hacha` → cae al hitbox y muestra "Arbol NO tiene Damageable", que es el comportamiento esperado; el prompt "Necesitas: hacha" avisa al jugador). Hacha sí tala. El arco daña a puma y conejo (ver 10.2b).

### 🔮 Pendiente para FASE 13 (recompensas únicas)
`colmillo_puma` está diseñado como material raro de armas especiales. En 13 debería existir una **segunda tirada** de uso (ej. `ArcoDePuma` o `DientesGemelos`) para que el drop no sea un cuello de botella único.

---

## 📦 FASE 11 — Sistema de Clima y Estaciones
> **Objetivo**: Condiciones atmosféricas dinámicas que afecten la jugabilidad.
> **Aprendizajes**: `GPUParticles3D`, post-procesado, estados de clima data-driven.

### ✅ Orden de submódulos FASE 11 — COMPLETA
```
11.1 GestorClima Autoload → 11.2 Efectos visuales (lluvia/nieve/viento) → 11.3 Estaciones del año → 11.4 Impacto en jugabilidad → 11.5 Indicador de estación en el HUD
```
**TODOS COMPLETADOS (16/10/2026).** Pendientes menores opcionales: 11.2b (los árboles se mueven con el viento) y 11.3b (tinte de ambiente propio de la estación, requiere combinarlo con `color_ambiente` del clima para no tener 2 escritores).

### 11.1 `GestorClima` (Autoload) — ✅ IMPLEMENTADO (16/10/2026)
- ✅ **No** son estados hardcodeados: cada clima es un `.tres` de `ClimaDefinicion` en `recursos/climas/`.
- ✅ `peso` = probabilidad RELATIVA (no %). Cambia cada `randi_range(min, max)` minutos de JUEGO (240-600).
- ✅ Señal `clima_cambio(clima_nuevo: StringName)`.
- ✅ Sorteo ponderado que **excluye el clima actual** (evita repeticiones seguidas).

### 11.2 Efectos Visuales — ✅ IMPLEMENTADO (16/10/2026)
> **REGLA DE ORO**: `ciclo_dia_noche.gd` es el **ÚNICO escritor** de `light_energy`/`light_color`/`WorldEnvironment`. El clima aporta un **modificador** (`energia_luz` multiplicador, `color_ambiente` tinte, `factor_oscuridad` sobre el fondo), NO escribe la luz directamente → sin conflicto de dos escritores.
- `EfectosClima.tscn` + `efectos_clima.gd`: `GPUParticles3D` para lluvia y nieve (siguen a la cámara, leen `ClimaDefinicion.particulas`).
- Viento (`ClimaDefinicion.velocidad_viento`): por ahora desvía las partículas; mover los árboles del grupo `arboles` queda como 11.2b.
- Oscurecer `WorldEnvironment`/luz cuando llueve o nieva (vía modificadores en `ciclo_dia_noche.gd`).
- **Config de partículas**: `amount` 1500 (lluvia) / 800 (nieve); `preprocess` para que el cielo se rellene al instante; `local_coords = true` (las partículas viajan CON el emisor al seguir a la cámara); `visibility_aabb` ampliado a 32×26×32 y `cast_shadow = 0` (la caja por defecto es ±4 m y las partículas desaparecían al mirar desde ciertos ángulos).
- **⚠️ GOTCHA 1 — `.tscn` pegado sin saltos de línea**: al pegar el texto de la escena, los 5 bloques `[sub_resource]` quedaron **aplastados en una sola línea** → Godot, que lee los `.tscn` línea por línea, solo reconoció el primero y **descartó los demás** → `draw_pass_1` apuntaba a mallas inexistentes y **no se dibujaba nada**, sin error en consola. **Conclusión: preferir configurar partículas por Inspector, no pegando `.tscn`.**
- **⚠️ GOTCHA 2 — escena nunca instanciada**: `EfectosClima.tscn` existía y estaba bien configurada, pero **no estaba instanciada en `mundo.tscn`** → el script nunca corría en el juego (la consola del clima sí cambiaba, porque eso es `GestorClima`, un Autoload). Lección: un nodo que "no hace nada" y sin errores → verificar primero que **esté instanciado** en la escena en ejecución.
- **Lección de diagnóstico**: `GPUParticles3D` **vacío** (sin `process_material` ni `draw_pass_1`) es válido para Godot y no da error, pero **no dibuja nada**. Un emisor sin malla es invisible, aunque `emitting = true`.

### 11.3 Estaciones del Año — ✅ IMPLEMENTADO (16/10/2026)
**3 DECISIONES DEL USUARIO**: (1) **cada estación es un `.tres`** de `EstacionDefinicion`; (2) **30 días de juego por estación** (ciclo de 120 días ≈ 58 min reales, ~15 min por estación); (3) la estación **modifica el PESO** de cada clima (no filtra cuáles salen).
- `scripts/recursos/estacion_definicion.gd` (`class_name EstacionDefinicion`): `id`, `nombre_visible`, **`orden`** (1..4; imprescindible porque `DirAccess` devuelve los archivos en orden arbitrario y el ciclo primavera→verano→otoño→invierno debe ser determinista), `dias_duracion`, `multiplicadores_peso` (diccionario clima→factor), y helper `multiplicador_para(clima_id)` con fallback a clave `String` (el Inspector guarda las claves de un `Dictionary` como `String`, no `StringName`).
- `recursos/estaciones/`: `EstacionPrimavera`, `EstacionVerano`, `EstacionOtono`, `EstacionInvierno`.
- **`GestorTiempo` extendido** (según el plan original; se descartó un Autoload `GestorEstaciones` aparte para evitar problemas de **orden de carga**: `GestorClima` necesita leer la estación ya en su `_ready()`, y `GestorTiempo` carga antes). Añade `_cargar_estaciones()` por `DirAccess` + `sort_custom` por `orden`, cálculo por **días acumulados** (soporta duraciones distintas por estación), `estacion_actual`, `get_estacion_actual()` y señal `estacion_cambio`. Se engancha a su propia `dia_cambio` (`dia_cambio.connect(_on_dia_cambio)`) → no hay que tocar los dos sitios que emiten la señal.
- `GestorClima._sortear_clima()` reescrito: construye candidatos **filtrando peso efectivo 0** (`peso_base × multiplicador_estacion`) y sortea sobre esos pesos.
- **CAMBIO post-verificación**: se **eliminó la exclusión del clima actual** (el `continue` de 11.1) a petición del usuario, para permitir repeticiones (llover 2 días seguidos). La exclusión renormalizaba las probabilidades y hacía la repetición imposible.
- **⚠️ LECCIÓN**: un `sort_custom` **no desempata** — si varios elementos comparten la clave de orden (aquí `orden`), el resultado queda a merced del **orden del sistema de archivos** (`DirAccess`), que en Windows es alfabético. Y un **typo en la clave de un `Dictionary`** (ej. `"lluvios"`) **no produce error**: el multiplicador simplemente no se aplica. En datos de `Dictionary`, verificar siempre las claves contra el id real.
- **Pendiente de esta fase**: tinte de ambiente por estación (habría que combinarlo con `color_ambiente` del clima — segundo escritor sobre el mismo dato) y efecto sobre cultivos → se difieren a **11.3b / 11.4**.

### 11.4 Impacto en Jugabilidad — ✅ IMPLEMENTADO (16/10/2026)
**Regla de diseño: cada efecto se declara en el DATO, no en el código.** 3 campos nuevos en los Resources ya existentes (cambiar el balance = editar un `.tres`):
- `ClimaDefinicion.riega_cultivos: bool` → **lluvia riega** las parcelas plantadas sin gastar agua de la regadera.
- `ClimaDefinicion.multiplicador_velocidad_jugador: float` → **nieve (0.65)** ralentiza al jugador.
- `EstacionDefinicion.multiplicador_crecimiento_cultivos: float` → **Invierno (0.4)** frena los cultivos, Verano (1.3)/Primavera (1.2) aceleran.
- **`parcela.gd`**: escucha `GestorClima.clima_cambio` y `GestorTiempo.estacion_cambio` (+ sincroniza con el estado actual en `_ready()`, porque ambas señales ya se emitieron antes de que la parcela existiera). `_process` multiplica el crecimiento por el factor de estación; `_riego_por_clima()` marca `regado = true` sin gastar agua. Se llama también en `plantar()` (si llueve al plantar) y en `_on_nuevo_dia()` (si sigue lloviendo al amanecer).
- **`jugador.gd`**: `_mult_velocidad_clima` con `clampf(..., 0.2, 1.0)` → el clima **nunca acelera** ni detiene al jugador. Fórmula final: `base × energía(stats) × clima`.
- **Decisión del usuario**: el **viento** se queda sin efecto de gameplay por ahora.
- ✅ Verificado en juego.

### 11.5 Indicador de estación en el HUD — ✅ IMPLEMENTADO (17/10/2026)
- `EstacionDefinicion.emoji_hud: String` (mismo patrón data-driven que `ItemDefinicion.emoji_hud` de 10.12): `🌸` Primavera, `☀️` Verano, `🍂` Otoño, `❄️` Invierno.
- `Label` **`IndicadorEstacion`** en `UIHud.tscn` (posición `x=5, y=150`, debajo de los contadores).
- `ui.gd`: `_actualizar_indicador_estacion()` lee `EstacionDefinicion.emoji_hud` + `nombre_visible` y `GestorTiempo.get_dias_restantes_estacion()`. Se refresca con **`estacion_cambio`** (cambia nombre/emoji) **y `dia_cambio`** (bajan los días).
- Formato: `🌸 Primavera — 30 días`.
- ✅ Verificado en juego (muestra `🌸 Primavera — 30 días`).
- ⚠️ Datos pendientes de limpiar: `EstacionPrimavera.tres` tiene la clave `"lluvios"` (sin `o`) → el multiplicador 2.0 de lluvia nunca se aplica. Corregir a `"lluvioso"`. Eliminar también la clave vacía `""` de `EstacionInvierno.tres`.

---

## 📦 FASE 12 — Progresión: Niveles, XP y Estadísticas
> **Objetivo**: Bucle de RPG: matar enemigos → ganar XP → subir de nivel → más fuerte.
> **Aprendizajes**: curvas de XP, estadísticas derivadas, escalado de dificultad.

### ✅ Orden de submódulos FASE 12 — COMPLETA (17/10/2026)
```
12.1 Componente Nivel/XP ✅ → 12.2 Estadísticas (fuerza/constitución) ✅ → 12.3 Enemigos con nivel ✅ → 12.4 Recompensas de nivel (HUD + notificación) ✅
```

> **FASE 12 cerrada al 100%.** Los 4 submódulos verificados en juego.
> **Deudas diferidas de esta fase**: (a) el panel de atributos **no permite repartir puntos** (el reparto es automático por tabla `crecimiento_por_nivel`); (b) no hay pantalla de subida de nivel con elección de atributo.
> **Deudas menores pendientes (no bloquean)**: borrar el `add_child(instancia)` **duplicado** en `enemigo_spawner.gd` (ruido, no bug) y la **rama de descuento silencioso 💀** de `_on_enemigo_murio` (baja el contador sin imprimir cuando el nodo ya fue liberado).

### 12.1 Componente `Nivel` (XP) — ✅ IMPLEMENTADO (17/10/2026)
- **Archivo**: `scripts/jugador/nivel.gd` (`class_name Nivel extends Node`, **Node hijo** del jugador).
- `@export xp_base: int = 100` y `@export exponente_curva: float = 1.5` → **curva = dato**, editable en el Inspector.
- `nivel: int = 1`, `xp_actual: int = 0` (progreso **dentro** del nivel), `xp_siguiente_nivel` (calculado).
- `ganar_xp(cantidad)`: **`while`**, no `if` → una muerte puede subir varios niveles; el sobrante se arrastra. Emite `xp_cambio` y `nivel_subido(nuevo_nivel)`.
- **`static otorgar_xp_a_atacante(atacante, cantidad)`**: punto único de reparto (comprueba `is_in_group("jugador")` y busca el hijo `Nivel`). `EnemigoBase`/`AnimalBase` no conocen la estructura del jugador.
- Recompensa **data-driven** por entidad: `@export xp_al_morir` en `enemigo_base.gd` y `animal_base.gd`. Jugador: Conejo 3, Ciervo 10, Puma 20, Slime 8.
- ⚠️ **Nota**: el único `print` sale **al subir** de nivel, no al ganar XP → con `xp_base = 100` hacen falta ~33 conejos. Para probar rápido, bajar `xp_base` en el Inspector.
- ✅ Verificado en juego.

### 12.2 Estadísticas — ✅ IMPLEMENTADO (17/10/2026)
- **Archivo**: `scripts/jugador/estadisticas.gd` (`class_name Estadisticas extends Node`, **Node hijo** del jugador, hermano de `Damageable`/`Stats`/`Nivel`).
- Atributos `@export fuerza/constitucion/destreza = 5` + **`@export atributo_base: int = 5`** (valor NEUTRO).
- **Decisión de diseño (desviación consciente del plan literal)**: el plan pedía `vida_max = 100 + constitucion*10` y `daño_base = fuerza*2`, lo que con los atributos iniciales en 5 habría dado **150 HP y 15 de daño desde el nivel 1** (regresión de balance). En su lugar se usa un **atributo neutro**: con los tres atributos = `atributo_base`, el juego se comporta **exactamente igual que antes de 12.2**. Poner `atributo_base = 0` en el Inspector recupera las fórmulas literales del plan → **un solo knob cambia entre ambas interpretaciones**. Fórmulas: `vida_max = vida_base + (constitucion - atributo_base) * vida_por_constitucion`, `bono_daño = (fuerza - atributo_base) * daño_por_fuerza`, `mult_cooldown = clampf(1 - (destreza - atributo_base) * reduccion_cooldown_por_destreza, reduccion_cooldown_maxima, 1.0)`.
- **Reparto automático por tabla** (elegido por el usuario): `@export crecimiento_por_nivel: Dictionary` (`{fuerza:1, constitucion:1, destreza:1}`) aplicado en `_on_nivel_subido` (escucha `Nivel.nivel_subido`, componente hermano). La lógica itera la tabla con **`get(clave)` / `set(clave, ...)`** → **añadir un atributo nuevo = un `@export` + una clave, sin tocar la lógica de crecimiento** (cero hardcodeo).
- **Destreza → velocidad de ataque** (elegido por el usuario; el plan no la definía): reduce el cooldown del arma, con tope `reduccion_cooldown_maxima` (0.5 = mitad).
- **Punto único de verdad para el daño**: `jugador.gd` gana `_daño_efectivo()` ( = daño del arma + `get_bono_daño()`) y `_cooldown_de_arma()` ( = cooldown del arma × `get_multiplicador_cooldown()`). Los **3 sitios** que repartían daño (disparo de arco, cono manual, hitbox) y los **3** que fijaban cooldown pasan a llamar esas funciones.
- ⚠️ **Variable vs función**: `_daño_ataque` es la **variable** (fallback del arma equipada) y `_daño_efectivo()` la **función**. Renombrar la declaración o usarla a la izquierda de un `=` rompe el parser y provoca **recursión infinita**.
- **Vida máxima propiedad de la Constitución**: nuevo método público **`Damageable.set_vida_maxima(nueva_max, p_ajustar_actual)`** (único dueño de `vida_maxima`/`_vida_actual`; si la máxima sube, gana esa diferencia; si baja, recorta). Se aplica desde **`Jugador._ready()`** (no desde `Estadisticas._ready()`), porque **en Godot los hijos corren su `_ready()` ANTES que el padre** y el `Damageable` pisaría el valor. Se reaplica al subir de nivel vía `estadisticas_cambiadas`.
- **Panel de atributos en el HUD** (elegido por el usuario): `Estadisticas.get_texto_hud()` **construye el texto él mismo** recorriendo `@export abreviaturas` (`{fuerza:"FUE", constitucion:"CON", destreza:"DES"}`) con `get()` → **el HUD no conoce ningún atributo** (añadir uno = una línea en el diccionario, el HUD no se toca). `LabelAtributos` en `UIHud.tscn` (`x=5, y=180`), repintado con la señal `estadisticas_cambiadas` (**sin polling**) + sincronización inicial a mano. Formato:
  ```
  FUE 5  CON 5  DES 5
  Vida 100   Daño +0   Ataque ×1.00
  ```
- 💡 **Lección**: al subir de nivel con la vida a tope la barra **no se ve cambiar** (100/100 → 110/110, misma proporción). No es un bug: `set_vida_maxima` regala la vida nueva. Para notar el cambio hay que recibir daño primero.
- ✅ Verificado en juego ("se ve el reflejo de subir de nivel").

### 12.3 Enemigos con Nivel — ✅ IMPLEMENTADO (17/10/2026)
- **Desviación consciente del plan literal**: el plan decía *"zonas más alejadas tienen enemigos de mayor nivel"*, pero la arquitectura **no tiene zonas**: `enemigo_spawner.gd` genera en un **anillo alrededor del jugador** (8-18 m), así que la posición del spawner NO determina dónde aparece el enemigo. Además los spawners de Conejo/Ciervo/Puma usan `AnimalBase`, no `EnemigoBase`. **Modelo elegido por el usuario: "nivel por spawner/tipo"** → cada spawner define `nivel_min`/`nivel_max` y sortea el nivel por instancia. "Zona" = spawner. Cero cambios a la arquitectura de spawn.
- **`EnemigoBase` y `AnimalBase`** (duplicado a propósito, mismo criterio que `xp_al_morir`, porque el spawner es genérico y sirve a ambos): `@export nivel: int = 1` + `@export vida_por_nivel / daño_por_nivel / xp_por_nivel: int = 0`.
- **Fórmula**: `final = base + (nivel - 1) × incremento`. Con `nivel = 1` no cambia nada → **cero regresión**.
- **`_vida_base`**: se lee de `Damageable.vida_maxima` en `_ready()` (los hijos corren `_ready()` antes que el padre, así que a esa altura el Damageable ya inicializó). La vida se aplica con **`Damageable.set_vida_maxima()`** — el mismo contrato que usa el jugador. `daño_ataque` y `xp_al_morir` viven en el enemigo y se suman directo (en `AnimalBase` se omite el daño: la FSM es pasiva, no existe `daño_ataque`).
- **`enemigo_spawner.gd`**: `@export nivel_min/nivel_max: int = 1`; el nivel se sortea con `randi_range` y se asigna con `instancia.set("nivel", nv)` **ANTES de `get_parent().add_child(instancia)`**. El orden es crítico: **`add_child()` dispara `_ready()`**, donde corre el escalado; setear el nivel después no tendría ningún efecto (fallo silencioso).
- **Config aplicada**: Slime (`vida 6 / daño 2 / xp 4` nv 1-2), Conejo (`2/0/1` nv 1 fijo), Ciervo (`5/0/2` nv 1-2), Puma (`10/0/6` nv 2-3).
- ⚠️ **Lecciones**:
  - **`print` con menos argumentos que huecos NO da error**: GDScript falla el formateo e imprime la cadena **literal con los `%s`** (de ahí el `[Spawner %s] 🟢 Spawneado: %s (nv %d)...` que salió sin reemplazar). Al añadir un hueco al formato hay que añadir su argumento.
  - **`@CharacterBody3D@NNN` en los nombres**: Godot renombra así los nodos cuando el nombre se **repite entre hermanos**. Es cosmético (afecta solo a los `print`); se arregla con `add_child(instancia, true)` (`force_readable_name`).
  - **Contador `_cantidad_activos` con rama de descuento SILENCIOSA**: en `_on_enemigo_murio` hay un `return` que decrementa **sin imprimir 💀** cuando el nodo ya fue liberado. Un log tipo `1/5 → 1/5 → 2/5` con el Conejo demostrando que el incremento funciona apunta a esa rama, no a un bug de spawn.

### 12.4 Recompensas — ✅ COMPLETO (17/10/2026)
- ✅ **HUD nivel + barra de XP implementado** (adelanto a petición del usuario, tras 12.1): `ui.gd` conecta `xp_cambio`/`nivel_subido` del componente `Nivel` (con **sincronización inicial a mano**, porque `Nivel._ready()` emite antes de que el HUD exista). Nodos `BarraXPExterior` + `BarraXPInterior` + `LabelNivel` en `UIHud.tscn`. `_pintar_xp()` **reutiliza `_actualizar_barra()`** del HUD (cero código de pintado nuevo). Formato `Nv. N — X/Y XP`.
- ✅ **Notificación flotante "¡Nivel X!"** implementada: `NotificacionNivel` (Label dorado, `Font Size 32`, `mouse_filter = Ignore`) en `UIHud.tscn`; `_mostrar_notificacion_nivel()` en `ui.gd`. **Por qué NO es un `Label3D` sobre el jugador**: el aviso es información **de pantalla** (como la barra de XP), no del mundo; un `Label3D` exigiría billboard, orden de profundidad y ocultarse tras paredes.
- **Tres peligros que el código cubre explícitamente** (y que justifican su longitud):
  1. **Subir 2 niveles de golpe**: el `while` de `Nivel.ganar_xp()` emite `nivel_subido` **varias veces seguidas** → **`_tween_notificacion.kill()`** antes de animar, para que dos tweens no peleen por el mismo Label.
  2. **Tween interrumpido deja basura** (Label invisible o descolocado para siempre) → **reset COMPLETO** (texto, posición, `modulate.a = 0`) **antes** de cada animación.
  3. **Parpadeo de 1 frame** → el alpha se pone a **0 ANTES** de `visible = true`, y solo después empieza el fundido.
- **Posición base capturada en `_ready()`, NO en cada aviso**: si se leyera en cada notificación y la anterior estuviera a medio subir, se tomaría una posición ya desplazada como "base" y el aviso iría **trepando** por la pantalla.
- **Un solo `Tween` con `set_parallel(true)`** para las tres animaciones simultáneas (fundido de entrada 0.2 s, subida `TRANS_SINE`/`EASE_OUT` 1.6 s, desvanecido con `set_delay(1.1)`). `set_delay()` captura el valor de partida **cuando arranca la animación** (alpha ya en 1.0), no al crear el tween. `chain()` + `tween_callback` oculta el Label al terminar.
- Constantes data-driven: `FORMATO_NOTIFICACION_NIVEL` (`"¡Nivel %d!"`), `DURACION_NOTIFICACION` (1.6), `ALTURA_NOTIFICACION` (50.0).
- ✅ Verificado en juego ("se ve bien al subir de nivel"). **FASE 12 cerrada al 100%**.

---

## 📦 FASE 13 — Jefes (Bosses) y Recompensas Únicas
> **Objetivo**: Encuentros desafiantes con mecánicas especiales y botín único.
> **Aprendizajes**: FSM multi-fase, ataques en área, loot de una sola vez.

### 🟡 Orden de submódulos FASE 13
```
13.1 JefeBase (multi-fase) ✅ → 13.2 Ataques especiales (área, carga) ✅ → 13.3 Arenas de boss ✅ → 13.4 Recompensas únicas ✅
```

### 13.1 `JefeBase` (FSM Multi-Fase) — ✅ IMPLEMENTADO (17/10/2026)
- **Archivos**: `scripts/enemigos/jefe_base.gd` (`class_name JefeBase extends EnemigoBase`) + `scripts/recursos/fase_definicion.gd` (`class_name FaseDefinicion extends Resource`).
- **⚠️ Nombre**: se usó **`JefeBase`**, no `BossBase` del plan, por coherencia con el naming en español del proyecto (`EnemigoBase`, `AnimalBase`).
- **Herencia SÍ, aquí**: a diferencia de 12.3 (donde se optó por extender la base), el jefe hereda de `EnemigoBase` porque **13.2/13.3/13.4 son exclusivos de jefes** (ataques en área, arenas con muros, loot único) y meterlos en `EnemigoBase` lo inflaría para el 99% de enemigos que nunca los usarán. Heredar da gratis: FSM (patrulla/perseguir/atacar), detección, cooldown, muerte, drops, XP y **el escalado por nivel de 12.3**.
- **⭐ PRINCIPIO CLAVE — multiplicadores, NUNCA valores absolutos**: 12.3 hace `daño_ataque += extra * daño_por_nivel`. Si una fase escribiera `daño_ataque = 15` (absoluto), **machacaría el bono de nivel**. Con multiplicadores (`_base_daño × mult_daño`) los dos sistemas **COMPONEN**. Es el mismo principio ya aplicado con el clima sobre `ciclo_dia_noche` ("un solo escritor, los demás multiplican") y con `atributo_base` en `Estadisticas`.
- **Base capturada DESPUÉS de `super._ready()`** → obligatorio: en `_ready()` de la base ya corrió `_aplicar_nivel()` (12.3), así que capturar antes multiplicaría sobre valores sin escalar. Y siempre se multiplica `_base_daño` (no `daño_ataque` actual) → **llamar a `_entrar_en_fase` dos veces NO acumula**.
- **Detección por señal, SIN polling**: escucha `Damageable.vida_cambio(vida_nueva)` y calcula `vida_nueva / get_vida_maxima()`. **`while`, no `if`**: un golpe fuerte puede cruzar DOS umbrales de golpe y con `if` se perdería una fase.
- **Guardia del golpe letal**: en `Damageable`, `vida_cambio` se emite **ANTES** que `murio` (líneas 77 y 92), así que en el golpe mortal llega con 0 antes de que `_esta_muerto` sea true → se corta también con `vida_nueva <= 0`.
- **Señal `fase_cambiada(indice, nombre)`** → es el gancho que usará **13.2** (lanzar el ataque en área justo al entrar en «Enfurecido»)
- **Barra 3D grande reutilizada** (`damageable_barra_3d.gd`): en `JefeSlime.tscn` → `ancho 4.0`, `alto 1.6`, `altura_sobre_cabeza 2.5`, `vida_maxima 400`.
- **`JefeSlime.tscn`** creado duplicando `EnemigoSlime.tscn`; instanciado en `mundo.tscn` sin overrides. Escala más que un enemigo normal: `vida_por_nivel 30`, `daño_por_nivel 4`, `xp_por_nivel 15`, `xp_al_morir 120`.
- ⚠️ **LECCIÓN IMPORTANTE — se migró de `Array[Dictionary]` a `Array[FaseDefinicion]`**: la primera versión usaba diccionarios con claves tecleadas a mano (`umbral_vida`, `mult_velocidad`, **`mult_daño`**…). Con el array **VACÍO el sistema fallaba en silencio absoluto** (el `if not fases.is_empty()` simplemente no entraba) → el jefe se comportaba como enemigo normal **sin ningún error en consola** (mismo patrón que `contadores_hud` vacío y `plugin.cfg`). Con `FaseDefinicion` los campos son `@export` **con nombre y tipo** → el Inspector los muestra como casillas fijas con `@export_range` y es **imposible teclear mal una clave**. Además se añadió **`push_warning` explícito si `fases` está vacío** para convertir el silencio en aviso visible.
- ⚠️ **Incidente de pegado**: al añadir `jefe_base.gd`, el pegado cayó en la **pestaña equivocada** del editor y el script completo quedó dentro de `Dialogo_Mercader_Menu_Vender.tres` (líneas 17-131), corrompiendo el diálogo del mercader. Se restauró borrando esas líneas y reponiendo `accion_al_terminar = &"abrir_tienda"` + `metadata/_custom_type_script`. **Lección**: verificar qué pestaña está activa antes de pegar; `Ctrl+Z` inmediato deshace el pegado entero.
- ✅ Verificado en juego: `FASE 0 (Normal) vel 1.80 daño 5 cd 1.35` → `FASE 1 (Enfurecido) vel 2.52 daño 8 cd 1.08` → `FASE 2 (Frenesí) vel 3.24 daño 10 cd 0.81`.

### 13.2 Ataques Especiales (Área y Carga) — ✅ IMPLEMENTADO (18/10/2026)
- **Archivos**: `scripts/enemigos/jefe_base.gd` + `scripts/recursos/fase_definicion.gd` (campos nuevos `usa_area`, `usa_carga`).
- **⚠️ Detección por DISTANCIA, no por `Area3D`**: el plan original proponía «instanciar un `Area3D` temporal». Se descartó: un `Area3D` depende de **capas de colisión** y de **frames de física** (puede perderse un solape si el objetivo entra y sale entre dos ticks). Con `_objetivos_en_radio()` (distancia XZ contra los nodos del grupo `grupos_objetivo_area`) el resultado es **determinista** y no hay nada que configurar en el Inspector. Es la misma regla ya aplicada en la detección de interacción del jugador.
- **Telegrafía obligatoria**: todo especial tiene una fase de aviso (`duracion_telegrafia_area` / `duracion_telegrafia_carga`) en la que el mesh crece a `1.35` con `TRANS_SINE`/`EASE_IN`. Sin aviso el ataque sería injugable. Durante la telegrafía **el jefe queda plantado** y no ataca básico.
- **Temporizadores en `_process`, NUNCA `await` + `Timer`**: con `await` una corrutina quedaría **huérfana** si el jefe muere a mitad de la telegrafía. Con `_telegrafia_restante` como variable no hay corrutina que cancelar.
- **La CARGA manda sobre la FSM** (`_physics_process`): es un movimiento propio e interrumpible durante el cual `_ejecutar_transiciones_estado` está congelada.
- **⭐ La dirección de la carga se FIJA al lanzarla** (no se re-`look_at` al jugador cada frame) → el jugador puede **esquivarla lateralmente**. Si persiguiera en tiempo real sería imposible de evitar.
- **`_on_murio` mata el tween de telegrafía antes de `super._on_murio()`**: un Tween interrumpido deja el mesh escalado en un valor arbitrario; hay que `kill()` + reset completo (`_resetear_visual()`).
- **Data-driven por fase**: qué ataque está disponible lo declara cada `FaseDefinicion` (`usa_area`/`usa_carga`), no un `if` sobre el índice de fase. Añadir un especial a una fase concreta = marcar una casilla.
- **Ajuste de balance recomendado en arena**: con `radio_arena` pequeño, bajar `radio_area` (de 3.5 a 2.5) para que quede margen de esquiva.

### 13.3 Arenas de Jefe — ✅ IMPLEMENTADO (18/10/2026)
- **Archivos**: `scripts/mundo/arena_jefe.gd` (`class_name ArenaJefe extends Node3D`), `escenes/mundo/ArenaJefe.tscn`, `scripts/mundo/limites_mapa.gd` (`class_name LimitesMapa extends StaticBody3D`), `recursos/terrenos/Coliseo.tres` (`&"coliseo"`).
- **⭐ GEOMETRÍA GENERADA EN CÓDIGO, nunca modelada a mano**: los 4 muros de la arena y los 4 límites del mapa se crean en `_ready()`. Consecuencia directa: un solo `@export` (`ancho_arena`, `largo_arena`) recoloca todo, y **no hay recursos `BoxShape3D` compartidos que se puedan pisar entre sí**. Es el mismo patrón de `gestor_terreno.gd` (que ya crea sus `CollisionShape3D` en runtime).
- **⚠️ RECINTO RECTANGULAR, no anillo circular**: la primera versión generaba un anillo de 24 segmentos por rotación. Se descartó porque **un círculo no puede sellar una franja rectangular**: por mucho radio que tenga, siempre quedan **huecos en las esquinas** por los que el jugador bordea la arena sin activarla (dejando la pelea como opcional de facto). Con 4 cajas de largo correcto la franja se sella por completo. Bonus: 4 muros y **0 rotaciones** en vez de 24 y 24.
- **⭐ DOS medidas distintas en `LimitesMapa`: `ancho`/`largo` (dónde va el muro) y `grosor` (cuánto mide)**, y las 4 esquinas se sellan con `+ grosor*2` en el largo. Sin ese solape queda una rendija de `grosor` en cada esquina.
- **⭐ El jefe se localiza por GRUPO, no por referencia cableada**: `JefeBase` se registra solo en `&"jefes"` al nacer, y `ArenaJefe` adopta el **más cercano** al centro. Arrastrar un nodo al slot del Inspector se rompe al mover escenas; `get_nodes_in_group()` no.
- **⭐ JEFE DORMIDO (`inicia_dormido`)**: sin esto el jefe **no se queda en la arena**. `EnemigoBase` tiene `rango_deteccion = 14 m`: desde el centro de la arena (z=15) detecta al jugador en el mercado (z≈-4) y **sale persiguiéndolo por todo el mapa**. La arena lo despierta con `despertar()` al cerrarse. Mientras duerme, `_process` y la FSM están en pausa, pero `_physics_process` **sí aplica gravedad** (si no, un jefe colocado a media altura en el `.tscn` se queda flotando).
- **Descubrimiento TARDÍO tolerado**: `ArenaJefe` reintenta `_buscar_jugador()` / `_buscar_jefe()` desde `_process` hasta encontrarlos. Evita depender del orden de `_ready()` entre nodos hermanos.
- **Doble final, los dos abren el recinto**: muere el jefe → `_desactivar()` + **`_consumida = true`** (sin jefe no hay segunda ronda, y así no se reusa un nodo ya liberado por `queue_free`); muere el jugador dentro → `_desactivar()` también, porque **quedar encerrado en una pelea terminada es un softlock**.
- **Abrir/cerrar es 1 sola operación**: los 4 muros comparten un único `StaticBody3D`, así que basta cambiar **su** `collision_layer` (0 = abierto). Las mallas viven en un `Node3D` contenedor aparte cuyo `visible` se conmuta.
- **⚠️ LECCIÓN — EXPANDIR EL TERRENO EN Z ES SEGURO, EN X NO**: `celdas` es una **lista plana** y `fila = indice / ancho_celdas`. Subir `alto_celdas` (10 → 15) solo **añade celdas al final** conservando índice y fila de todas las existentes → seguro. Subir `ancho_celdas` reinterpreta cada índice como otra fila/columna → **deforma todo el mapa pintado**. Para expandir en X habría que reescribir las 150 celdas a mano.
- **⚠️ El punto dulce: el suelo se RECENTRA al crecer `alto_celdas`** (10 → 15 pasa el centro de z=0 a la fila 7,5). Se compensó con `Terreno` en `Position.z = +5`: la fila 0 vuelve exactamente a z=-9, el mapa viejo queda **idéntico** y crece solo hacia el sur (z ∈ [+10, +20]). `indice_desde_punto()` usa `to_local()`, así que **el pincel sigue funcionando** con el nodo desplazado.
- **⚠️ BUG de `LimitesMapa` original — shape compartido + rotaciones sobrantes**: los 4 `CollisionShape3D` apuntaban al **mismo** `BoxShape3D` (`size = 1×20×30`), imposible de satisfacer dos orientaciones distintas; y dos de ellos estaban **rotados 90°**, lo que hacía saltar el largo de Z a X. Resultado: dos tabiques atravesando el mapa por el centro en vez de un recinto. Ambos defectos desaparecen al generarse en código con **dos formas, una por eje** (la horizontal con el largo en X, la vertical en Z) y **cero rotaciones**.
- **⚠️ BUG del nodo `JefeSlime` en `mundo.tscn` — 16 sobrescrituras a `null`**: `cooldown_especial`, `radio_area`, `velocidad_carga`, `inicia_dormido`, `id_enemigo`, `nivel`… todas `= null`. Es el **mismo accidente que el `Mercado`** (`escena_ui_tienda = null`) y que el revert que se llevó la posición y la misión. La más grave: **`inicia_dormido = null` → el jefe arrancaba despierto** y salía persiguiendo. Revertir 16 propiedades una a una es tedioso y arriesgado → **borrar el nodo y re-instanciar `JefeSlime.tscn`** es más limpio (debe quedar con **2 líneas** de override: `transform` e `inicia_dormido`).
- **⚠️ PATRÓN RECURRENTE CONFIRMADO**: dato/overrides basura escritos sobre un nodo instanciado que **no dan error y fallan en silencio**. Ante «un nodo no hace lo que debería», **primero revisar qué overrides tiene guardados en el `.tscn`** y compararlos con su escena original.
- **Reutilización total**: `ArenaJefe` es agnóstica del jefe concreto (funciona con cualquier nodo del grupo `jefes` que tenga `Damageable` y — opcionalmente — `despertar()`). Sirve para el jefe de la FASE 13 y para **jefes de la FASE 15.3 (mazmorras)**.
- ✅ Verificado en juego: `[ArenaJefe] 🎯 Jefe adoptado: JefeSlime` → `💤 DORMIDO` → `🔒 ARENA CERRADA (20×10 m)` → `☀️ DESPIERTA` → `🔓 ARENA ABIERTA` al morir.

### 13.4 Recompensas Únicas — ✅ IMPLEMENTADO (18/10/2026)
> **Alcance acordado**: solo el *carril* de recompensa (Resource + entrega + marca de derrotado). El arma legendaria queda para más adelante porque exige las **3 piezas** encadenadas (`ItemDefinicion.herramienta_tipo` → `ArmaDefinicion` en `recursos/armas/` → `MeshInstance3D` registrado en `_init_modelos_arma()` de `jugador.gd`) y toca la **deuda de los modelos de arma hardcodeados**.

- **Archivos**: `scripts/recursos/recompensa_item.gd` (`class_name RecompensaItem extends Resource`), `assets/items/item_colmillo_jefe.tres`, `scripts/core/game_state.gd` (flag de derrotados), `scripts/enemigos/jefe_base.gd` (`recompensas` + `_otorgar_recompensas()`).
- **`RecompensaItem` es Resource, NO Dictionary**: el campo legacy `drops: Array[Dictionary]` de `EnemigoBase` (FASE 9.1) **falla EN SILENCIO** si una clave se teclea mal (`"item_id"` vs `"itemId"`). Con `@export var id_item: StringName` y `@export_range(1,999) var cantidad: int` el Inspector muestra **dos casillas fijas e imposibles de confundir**. Es la misma migración que se hizo en 13.1 con `Array[Dictionary]` → `Array[FaseDefinicion]`.
- **⭐ El botín va DIRECTO al inventario, no al suelo**: una recompensa "única" no se debe perder porque el cuerpo cayó en un arbusto o porque el jugador no la alcanza. Lo que **no cabe** en el inventario sí cae al suelo vía `DropManager.soltar()` (diferencial `antes`/`después` de `get_cantidad()`).
- **⚠️ ORDEN CLAVE en `_on_murio()`**: la recompensa y `GameState.marcar_jefe_derrotado()` se ejecutan **ANTES de `super._on_murio()`**, porque `super` arranca el tween de muerte que termina en `queue_free()`. Otorgar después significaría hacerlo sobre un nodo en vías de liberación.
- **`id_enemigo` es el ID del jefe — NO se creó un `id_jefe` nuevo**: reutiliza el campo ya existente de `EnemigoBase`. Ponerlo arregla **dos** cosas a la vez: el flag de derrotado en `GameState` y el reporte a `MisionManager` (que sin id **no progresa ninguna misión de "matar jefe"**).
- **⭐ El id vive en la ESCENA EMPAQUETADA (`JefeSlime.tscn`), no en `mundo.tscn`**: el botín es **dato del jefe**, no dato de colocación. Puesto en la escena empaquetada, cualquier instancia futura (otra arena, una mazmorra de la FASE 15.3) lo hereda gratis. Es lo contrario del desastre del `Mercado`/`JefeSlime` con 8 y 16 overrides `= null` en `mundo.tscn`.
- **`GameState.jefes_derrotados: Dictionary[StringName, bool]`** + `marcar_jefe_derrotado()` / `esta_jefe_derrotado()`.
- **⚠️ Vive SOLO en memoria**: el proyecto **aún no tiene sistema de guardado** (no existe ni un solo `FileAccess` / `user://` en `scripts/`). Al cerrar el juego la marca se pierde. **No es infraestructura muerta**: al recargar con F6 el `JefeBase` que ya cayó **no vuelve a instanciarse** (`_esta_muerto = true` + `queue_free()` en `_ready()`), así que el coliseo queda vacío y **la arena tampoco se cierra** (sin jefe no hay pelea). Cuando exista guardado, basta serializar ese `Dictionary`.
- **⚠️ La comprobación de derrotado va ANTES de `add_to_group("jefes")`**: si se registrara primero, la arena adoptaría un jefe que está a punto de liberarse y quedaría un recinto sellado esperando a un jefe que nunca llega.
- **⭐ BUG REAL diagnosticado — "no dio la recompensa del colmillo"**: el código era **correcto** (los `print` de `cuero` y `oro` salían del propio `_otorgar_recompensas()`). Faltaba la **entrada en el array**: `recompensas` tenía 2 elementos, ninguno el colmillo. **Lección (ya recurrente)**: cuando el sistema funciona pero "falta un dato", el fallo está en el `.tscn`/`.tres` **guardado**, no en el `.gd`. Verificar el array serializado **antes** de tocar código.
- ✅ Verificado en juego: `🎁 Recompensa: 1× colmillo_jefe` + `1× cuero` + `300× oro` → `[GameState] ☠️ Jefe DERROTADO: jefe_slime` → `🔓 ARENA ABIERTA`.
- **13.4 desbloqueado (18/10/2026)**: la deuda de los modelos de arma quedó **cerrada** (ver 10.1, "Tercer hardcodeo"). El visual del arma vive ahora en el propio `.tres` (`ArmaDefinicion.malla` + `transform_modelo`), así que la `ArmaEspadaLegendaria.tres` es **solo un archivo nuevo**: sin tocar `jugador.gd` ni `Jugador.tscn`.
- ✅ **ARMA LEGENDARIA ENTREGADA (18/10/2026)** — cierra la deuda que quedó abierta en 13.4. **CAUSA RAÍZ (verificada en los archivos reales)**: el código de `_otorgar_recompensas()` era correcto; el array `recompensas` de `mundo.tscn` **sobrescribía** el de `JefeSlime.tscn` (3 entradas: `cuero`/`oro×300`/`colmillo_jefe`) → la `espada_legendaria` **nunca se evaluaba**. Es el mismo patrón del `Mercado` (8 overrides `= null`) y del propio `JefeSlime` (16 overrides). **Fix**: se editó el array **en la escena empaquetada** (`JefeSlime.tscn` L71: `espada_legendaria` + `cuero` + `oro×300` + `colmillo_jefe`) y se **revirtió el override** en `mundo.tscn`, que quedó sin `recompensas` y sin los 3 `sub_resource` (Godot borró también el `ext_resource` huérfano). **Una sola fuente de verdad.**
  - ⚠️ **Lección (refuerza la de 13.4)**: ver el valor en el Inspector **NO significa tenerlo guardado**. El Inspector muestra el valor *heredado* de la escena base hasta que tocas la propiedad; en ese momento Godot escribe un **override** en el `.tscn` padre. Y como **los arrays exportados se serializan completos, no se mezclan por índice**, un override de 3 entradas **reemplaza** el array entero.
  - **Criterio**: el botín es **dato del jefe**, no dato de colocación → vive en la escena empaquetada para que cualquier instancia futura (otra arena, la mazmorra de 15.3) lo herede gratis.
  - **Nota menor verificada (no es bug)**: `JefeSlime.tscn` tiene `drops = Array[Dictionary]([{}])`, una **entrada vacía**. `DropManager._soltar_diferido()` hace `dic.get("item_id", &"")` y descarta con `if id == &"": continue` → es **ruido inocuo**, no un fallo silencioso. Se puede limpiar poniendo el array a tamaño 0.

> **Nota — REPINTADO DEL MAPA (18/10/2026, decisión del usuario)**: el usuario **rediseñó a propósito** la pintura del terreno. El mapa original pasó de `tierra 20 + arena 8 + agua 21` a **`hierba 93 + agua 7`** (las 7 de agua forman una línea vertical en el borde este). La zona sur (5 filas nuevas) quedó pintada íntegra como `coliseo` (50 celdas exactas, z ∈ [10,20]), coincidiendo con el recinto de la arena. **Confirmado como intencional** — no es una regresión.

---

## 🔧 CORRECCIÓN — Huerto alineado a la rejilla (parcelas) — 18/10/2026
> **Petición del usuario**: *"las parcelas deberíamos corregirlas, ya que deben ir en concordancia con nuestros tiles de terreno utilizando bien los espacios"*.
> ⚠️ **DEBE HACERSE ANTES DE LA FASE 22 (22.2)**: el guardado serializa las parcelas por nodo; si primero no se les da una **identidad estable basada en la rejilla**, hay que rehacerlo. Con la rejilla, el id sale gratis (`fila * ancho_celdas + columna`).

### ✅ EJECUTADO — Etapa 1 (rejilla + generador) — 18/10/2026
Aplicado y verificado en los archivos reales:
- `TipoTerreno.es_cultivable: bool = true` → `false` en `TerrenoAgua.tres`, `Coliseo.tres` y `TerrenoArena.tres`.
- `GestorTerreno` con la API pública de consulta (`centro_mundo_de_celda`, `bioma_de_celda`, `altura_de_celda`, `es_cultivable_en`, `_asegurar_paleta`).
- `scripts/granja/gestor_huerto.gd` creado; `Granja` sustituido por el nodo `Huerto` (con script) en `mundo.tscn` L108-109; las 6 instancias manuales eliminadas.
- `Parcela.tscn`: `CollisionShape3D` y `MeshTierra` a `Size = Vector3(2, 0.5, 2)`; `Parcela.id_rejilla: Vector2i` añadido.
- `parcela.gd → plantar()`: el riego por lluvia se movió **antes** del `return true` (ahora L145-147). ✅ Código muerto corregido.

### Diagnóstico verificado (medido con los datos reales, no hipótesis)
**Geometría del terreno** (`Terreno` en `mundo.tscn`, instancia de `Terreno.tscn`): `ancho_celdas = 10`, `alto_celdas = 15`, `tamano_celda = 2.0`, con el nodo en **(0, 0, 5)**.
- Centro de celda en mundo: **x = 2·col − 9** (siempre **impar**), **z = 2·fila − 9** (siempre **impar**, ya incluye el +5 del offset).
- Biomas: `agua` en la columna 9, filas 3–9; `coliseo` en las filas 10–14 (z ∈ [10, 20]); el resto `hierba`.

**Posiciones ORIGINALES de las 6 parcelas** (antes de la corrección, nodo `Granja` en x = 6.34):

| Nodo | Posición mundo | Tile que pisaba | Desvío al centro del tile |
|---|---|---|---|
| `Parcela66` | (6.345, 0) | col 8, **borde** fila 4/5 | 0.65 en X |
| `Parcela1` | (7.708, 0) | col 8, **borde** fila 4/5 | 0.71 en X |
| `Parcela22` | (6.345, −1.633) | col 8, fila 4 | 0.65 / 0.63 |
| `Parcela33` | (6.345, 1.440) | col 8, fila 5 | 0.65 / 0.44 |
| `Parcela44` | (7.778, −1.791) | col 8, fila 4 | 0.78 / 0.79 |
| `Parcela55` | (7.811, 1.407) | col 8, fila 5 | 0.81 / 0.41 |

**Los 3 fallos que tenían**:
1. **Las 6 parcelas cabían dentro de 2 tiles**: todas en la columna 8 (x ∈ [6, 8]) repartidas entre las filas 4 y 5 → 8 m² ocupados para 6 parcelas de 1×1 m.
2. **Ninguna centrada en un tile**: desvíos de **0.41 a 0.81 m**, sin coincidir con ninguna sub-rejilla → flotando a mano.
3. **2 parcelas sobre el borde z = 0** entre las filas 4 y 5 → a caballo entre dos tiles.

### Diseño — ✅ DECISIONES DEL USUARIO (18/10/2026)
1. **1 parcela = 1 tile completo (2×2 m)**. 6 parcelas = rectángulo de **3×2 tiles (4×6 m)**. `Parcela.tscn` pasa de 1×1 a **2×2** (mesh Y colisión, misma altura de 0.5 y mismo `y = -0.05` → la cara superior sigue a 0.2 m, **sin regresión**).
2. **Generador de huerto por datos** (`GestorHuerto`), NO posiciones a mano.
3. **Validación de bioma** con **`es_cultivable`** nuevo en `TipoTerreno`.
4. **El huerto lo CREA EL JUGADOR con una PALA** (no se siembra solo) → ver "Etapa 2".
5. **El `Huerto` pasa a ser el CONTENEDOR** de las parcelas del jugador, con `generar_al_iniciar = false`.

#### Arquitectura acordada (cero hardcodeo, cero duplicación de la geometría)
- **`TipoTerreno.es_cultivable: bool = true`** (default `true` porque `hierba`/`tierra` son la mayoría) → **`false` en `TerrenoAgua.tres`, `Coliseo.tres` y `TerrenoArena.tres`**. Nota: el flag **`es_agua` ya existe y hoy no lo usa nadie** (`grep` verificado); `es_cultivable` es independiente porque el coliseo no es agua pero **tampoco** es cultivable.
- **`GestorTerreno` es el DUEÑO de la rejilla** (el huerto NO debe replicar la fórmula de `_centro_celda()`, sería un segundo lugar donde vive la rejilla). API pública: `centro_mundo_de_celda()`, `bioma_de_celda()`, `altura_de_celda()`, `es_cultivable_en()`, `celda_desde_punto()`.
- **`GestorHuerto`** (`scripts/granja/gestor_huerto.gd`, `extends Node3D`): `@export columna`, `fila` (tile de la esquina), `ancho_tiles`, `alto_tiles`, `generar_al_iniciar` → instancia parcelas centradas en su tile con `centro_mundo_de_celda()`. **NO es `@tool`**: si generara en el editor, las parcelas se **hornearían** dentro de `mundo.tscn` como nodos hijos → volvería la fragilidad de overrides que ya nos mordió dos veces. Se genera **solo en runtime** (mismo criterio que `LimitesMapa`).
- **`Parcela.id_rejilla: Vector2i`**: cada parcela guarda su coordenada de rejilla. **Es la razón por la que el generador gana**: da un **ID estable** para el guardado de FASE 22.2 (sobrevive a repintados del mapa, a reordenar nodos y a cambiar el tamaño del tile) — un índice de hijo o un nombre de nodo NO lo hacen. Se asigna **ANTES de `add_child()`** (lección de 12.3).
- **`Granja` desaparece**: el nodo pasa a ser `Huerto` (con el script) y **las 6 instancias manuales se borran de `mundo.tscn`**.
- **Ubicación por defecto**: `columna = 7`, `fila = 4`, `ancho = 2`, `alto = 3` → centros en x = 5 y 7, z = −1, 1 y 3 (junto a la columna de agua, col 9). Ajustable en el Inspector.

---

### Etapa 2 — 3 correcciones pedidas por el usuario (18/10/2026)

#### 2.A — 🎯 La interacción (F) debe elegir según la DIRECCIÓN DE MIRADA
**Decisión del usuario: dirección del PERSONAJE** (no el ratón, no mixto).
- **Causa raíz verificada**: `_recalcular_interactuable_mas_cercano()` (jugador.gd L467-489) elige con `global_position.distance_to()` — **cero dirección**. Además solo se llama desde los 4 eventos `*_entered/*_exited` → si el jugador **gira sin moverse**, la elección queda **congelada**.
- ⚠️ Con parcelas de 2×2 m y un radio de cápsula de **1.75 m**, hasta **4 parcelas** caen dentro del área a la vez → el fallo se vuelve muy visible.
- **Fix**: caché de candidatos (`_candidatos_interaccion`) alimentada por los eventos + recálculo **continuo** en `_process`, puntuando con **cono frontal**:
  - `frente = visual_holder.global_transform.basis.z * -1.0` (la misma dirección que ya usa el arma, L257).
  - Dentro del cono (`ANGULO_CONO_INTERACCION_DEG`, ±45°) → gana el **más cercano**.
  - Sin nadie en el cono → **fallback** al más cercano de todos (no se pierde la interacción con lo que está detrás).
- ⚠️ **Limitación conocida**: para objetos **grandes** (ej. el `Mercado`, un `StaticBody3D`) se mide la dirección a su **`global_position`** (el origen), no a su superficie. Si algún día el Mercado da problemas, la solución es medir la dirección al punto más cercano de su `CollisionShape3D`.

#### 2.B — 🎨 El "agua" que riega era en realidad EL COLOR de la parcela
**Causa raíz verificada (NO era el terreno de agua)**:
- `es_agua` **no tiene ni un solo consumidor** en `scripts/` (grep verificado) → el bioma agua **no puede regar**.
- `regado = true` solo ocurre en `parcela.gd → regar()` y `_riego_por_clima()`, y este último se dispara **exclusivamente** por `_clima_riega` ← `ClimaDefinicion.riega_cultivos`.
- El color de la parcela en `VACIO` era **`Color(0.146, 0.146, 0.611)` = AZUL OSCURO** (B = 0.611), **no marrón** como dice su comentario. Con el huerto en cols 7-8, **pegado a la columna de agua (col 9)**, las parcelas parecían tiles de agua.
- Los comentarios de los 3 colores **no coinciden** con sus valores: `arada` = `(0.214, 0.465, 0.272)` es **verde** ("marrón más claro/rojizo"); solo `regada` = `(0.393, 0.047, 0.185)` es realmente granate oscuro.
- **Fix**: `sin_arar → (0.36, 0.26, 0.18)`, `arada → (0.24, 0.17, 0.11)`, `regada → (0.14, 0.10, 0.07)`. Progresión coherente: tierra seca → removida → mojada.
- ⚠️ **Descartar antes de dar por bueno el fix**: si el prompt de la parcela decía `💧 Regado ✓` sin haber regado, era **lluvia real** (Primavera ≈35%) — eso es diseño, no bug.
- **Lección**: un comentario que contradice su valor es **peor que no tener comentario** — hizo parecer correcto un color azul.

#### 2.C — 🛠️ El huerto lo crea el jugador con una PALA
- **Decisión del usuario**: herramienta **nueva PALA** (no reutilizar la azada). La pala **crea** la parcela (nace en `VACIO`) y, sobre una parcela vacía, la **elimina** (mismo botón + modificador). Mantiene intacta la máquina de 5 estados y todos los prompts.
- **Reutiliza el sistema de colocación existente** (FASE 10.7/10.8b), pero **snapping a la rejilla** en vez de posición libre: `_obtener_punto_suelo_bajo_raton()` → `celda_desde_punto()` → validar `es_cultivable_en()` + celda libre → `centro_mundo_de_celda()`.
- **Cero hardcodeo**: un flag nuevo **`ItemDefinicion.crea_parcela: bool`** decide que la herramienta entra en "modo pala" (mismo criterio data-driven que `es_estacion`).
- **Archivos nuevos**: `assets/items/item_pala.tres`, `recursos/armas/ArmaPala.tres`, `assets/recetas/receta_pala.tres` (el icono `assets/icons/pala.png` **ya existe**). `ClavesDatos.HERR_PALA = &"pala"`.
- **`GestorHuerto`** gana `generar_al_iniciar = false`, `add_to_group("huerto")` y la API: `crear_parcela_en()`, `parcela_en()`, `hay_parcela_en()`, `eliminar_parcela_en()`. El **padre de las parcelas es el `Huerto`** (contenedor estable para que el guardado las encuentre).

> ### 📌 FASE 22.2 — CÓMO SE GUARDA EL HUERTO DINÁMICO (decidido 18/10/2026)
> - Las parcelas **NO se serializan por índice de hijo ni por nombre de nodo**. Se serializa **una entrada por `id_rejilla`**: `"7:4": { estado, semilla_id, progreso, regado }` (clave `"col:fila"`).
> - **La EXISTENCIA de la parcela es el propio dato**: no se guarda un "mundo con parcelas", se guarda la lista de parcelas que el jugador creó. Al cargar, `GestorHuerto` **reconstruye** cada parcela con `crear_parcela_en(col, fila)` y luego le aplica su estado.
> - **Ventaja del `id_rejilla`**: si el mapa se repinta (como el repintado `hierba 93 + agua 7` de la FASE 13) o cambia `tamano_celda`, la parcela sigue apuntando al **mismo tile lógico**. Con `id_rejilla` en una celda que pasó a **no cultivable**, la carga debe **omitir esa parcela con `push_warning`** en vez de crear una parcela flotando sobre agua.
> - El orden importa: `GestorHuerto` debe crear las parcelas **antes** de aplicarles el estado (si no, `deserializar()` escribe sobre nodos que aún no existen). Mismo patrón "cargar escena primero, aplicar estado después" ya anotado en 22.3.

---

## 📦 FASE 14 — Eventos de Ataque (Raid de Enemigos)
> **Objetivo**: Los enemigos atacan la finca de forma aleatoria, creando tensión.
> **Aprendizajes**: sistemas de eventos programados, oleadas, defensas.

### ⏳ Orden de submódulos FASE 14
```
14.1 GestorEventos (ataques random) → 14.2 Ataques individuales/grupales → 14.3 Sistema de oleadas → 14.4 Defensa de la finca
```

### 14.1 `GestorEventos` (Autoload)
- Cada X minutos de juego hay una probabilidad de ataque nocturno.
- Aviso previo: "⚠️ Se escuchan ruidos en el bosque…" 30s antes.

### 14.2 Ataques Individuales/Grupales
- Spawnear grupos de enemigos alrededor de la finca que persiguen al jugador.
- Diferentes dificultades según el nivel del jugador.

### 14.3 Oleadas (Waves)
- Los enemigos vienen en varias tandas; sobrevivir a todas = recompensa.

### 14.4 Defensa
- Posibilidad de construir barricadas/spikes (items colocables como las estaciones de crafteo).

---

## 📦 FASE 15 — Ampliación Manual del Mapa y Zonas/Biomas
> **Objetivo**: Crear un mundo más grande con distintas zonas **a mano** antes de automatizarlo. Esto sirve como "set de datos" para calibrar la generación procedural de la FASE 16.
> **Aprendizajes**: biomas, distribución de recursos, diseño de niveles.

### ⏳ Orden de submódulos FASE 15
```
15.1 Ampliar suelo + zonas → 15.2 Biomas (bosque/montaña/río) → 15.3 Mazmorras → 15.4 Spawners por zona
```

### 15.1 Ampliar el Suelo
- Pasar de un cuadrado a un terreno más grande (ej: 100×100). Usar `MeshInstance3D` con `PlaneMesh` subdividido.
- Crear zonas visibles: caminos, una zona de bosque, una de montaña, un río.

### 15.2 Biomas
- Recurso `BiomaDefinicion.tres` con: color_suelo, recursos (árbol/roca/cantidad), enemigos permitidos.
- Colocar a mano cada bioma con sus recursos característicos.

### 15.3 Mazmorras (Dungeons)
- Escenas interiores separadas (`Mazmorra1.tscn`). Entrada en el mundo que cambia de escena o teletransporta.
- Enemigos dentro + cofre con loot.

### 15.4 Spawners por Zona
- Colocar `enemigo_spawner.gd` en cada bioma con el PackedScene apropiado (lobos en bosque, golems en montaña).

---

## 📦 FASE 16 — Generación Procedural del Mundo
> **Objetivo**: Que el mapa se expanda solo al llegar a los límites. Es la fase más compleja de mundo; se hace después de entender biomas y zonas.
> **Aprendizajes**: chunks, ruido Perlin/Simplex, instanciado masivo, streaming de escenas.

### ⏳ Orden de submódulos FASE 16
```
16.1 Sistema de Chunks → 16.2 Generación de terreno (ruido) → 16.3 Colocación procedural de recursos → 16.4 Carga/descarga (streaming) → 16.5 Transiciones y límites
```

### 16.1 Sistema de Chunks
- El mundo se divide en bloques (chunks) de tamaño fijo (ej: 16×16).
- `ChunkManager` (Autoload) lleva un `Dictionary` de chunks activos según la posición del jugador.

### 16.2 Generación de Terreno
- Usar `FastNoiseLite` (Godot 4 lo trae integrado) para generar altura y tipo de suelo por coordenada.
- Cada chunk es un `MeshInstance3D` con vértices calculados (o varios `PlaneMesh` con desplazamiento de vértices).

### 16.3 Recursos Procedurales
- Según el bioma (calculado por ruido), instanciar árboles/rocas/minerales en posiciones aleatorias pero deterministas (semilla fija → mismo mundo siempre).

### 16.4 Carga/Descarga
- Solo los chunks cercanos al jugador existen. Los lejanos se `queue_free()`.
- Esto permite mundos "infinitos" sin colgar la memoria.

### 16.5 Transiciones y Limites
- Asegurar que los bordes de los chunks coincidan (mismo ruido → misma altura en la frontera).
- Los `LimitesMapa` actuales se eliminan (no hay borde, se genera siempre).

---

## 📦 FASE 17 — Historia, NPCs y Eventos del Calendario
> **Objetivo**: Dar profundidad narrativa. Se apoya en el sistema de diálogos y misiones ya existente.
> **Aprendizajes**: árboles de diálogo ramificados, relaciones, eventos temporizados.

### ⏳ Orden de submódulos FASE 17
```
17.1 NPCs con historias individuales → 17.2 Sistema de afinidad → 17.3 Eventos del calendario → 17.4 Historia principal (misiones en cadena)
```

### 17.1 NPCs con Historias
- Cada NPC tiene varios diálogos que se desbloquean al subir la afinidad o al completar misiones.
- Usar `requiere_mision_activa`/`requiere_mision_no_activa` ya existente + nueva condición `requiere_afinidad_minima`.

### 17.2 Afinidad/Relación
- Diccionario en un `RelacionManager` (Autoload): `afinidad[pnj_id] = 0..10`.
- Regalar items o completar misiones sube la afinidad.

### 17.3 Eventos del Calendario
- `GestorTiempo` emite señal `dia_cambio`. Un `EventoCalendarioManager` revisa fechas especiales (festival de primavera, día del mercader) y desencadena diálogos/escenas.

### 17.4 Historia Principal
- Cadena de misiones que van desbloqueando zonas, armas y lore del mundo.

---

## 📦 FASE 18 — Multijugador Cooperativo (Co-op)
> **Objetivo**: Jugar en red. Es la fase más compleja técnicamente; requiere reestructurar sistemas para networking.
> **Aprendizajes**: High-level multiplayer de Godot (ENet), RPC, sincronización de estado, instancia de servidor y cliente.

### ⏳ Orden de submódulos FASE 18
```
18.1 Setup servidor/cliente → 18.2 Sincronización de jugadores → 18.3 Sincronización de inventario/mundo → 18.4 Drop-in/drop-out
```

### 18.1 Setup Red
- `NetworkManager` (Autoload) con `multiplayer.create_server()` / `create_client()`.
- `multiplayer.spawner` para los jugadores.

### 18.2 Sincronización de Jugadores
- Solo el servidor mueve a los jugadores; los clientes reciben posición vía RPC.
- `@rpc` en métodos de movimiento.

### 18.3 Inventario y Mundo
- Autoridad del servidor para inventario, daño, drops (evitar trampas).
- Recursos/enemigos spawneados por el servidor.

### 18.4 Drop-in/Drop-out
- Jugadores pueden unirse/irse sin reiniciar la partida.

---

## 📦 FASE 19 — Modelos 3D y Pulido Visual
> **Objetivo**: Reemplazar los cubos/placeholder por modelos 3D reales. Se realiza cerca del final, como pulido visual, una vez que las mecánicas y el mundo están definidos. Al usar escenas reutilizables (Arbol.tscn, Roca.tscn), reemplazar los meshes no obliga a recolocar objetos.
> **Aprendizajes**: Importación de glTF/GLB, `AnimationPlayer`, `AnimationTree` (opcional), materiales estándar.

### ⏳ Orden de submódulos FASE 19
```
19.1 Modelo Jugador + VisualHolder → 19.2 Modelos recursos (árbol/roca) → 19.3 Modelos enemigos/NPC → 19.4 Materiales y texturas → 19.5 Animaciones (idle/caminar/atacar)
```

### 19.1 Modelo del Jugador
- **Decisión**: el usuario **modela sus propios** modelos en Blender, estilo **low-poly estilizado** (colores planos, shading flat, sin texturas).
- **Pipeline Blender → Godot** (reglas canónicas):
  - Escala: 1 unidad Blender = 1 metro. Altura jugador ≈ **1.8 m** (coincide con `CapsuleShape3D`).
  - Origen en el **centro entre los pies** (0,0,0); el modelo apoya en el suelo. En Godot `y=0` = suelo.
  - Frente hacia **`-Y` en Blender** (= vista frontal) → se convierte en **`-Z` en Godot** (frente canónico de Aukane, `Vector3.BACK`).
  - `Ctrl+A → All Transforms` antes de exportar (evita escala/rotación encapsulada).
  - Exportar glTF 2.0 `.glb` con **Include → Selected Objects** y **`+Y Up`** activado.
- **Regla canónica**: el nodo raíz `CharacterBody3D` sigue en **IDENTIDAD**. El modelo `.glb` se instancia dentro de `VisualHolder → PersonajeVisualRoot`, reemplazando el placeholder `ModeloCuerpo`, con su `transform` en identidad. Todo ajuste de escala/orientación se hace **en Blender**, nunca en Godot.
- Ruta de importación: `assets/modelos/jugador/jugador.glb`.
- Verificar orientación con una escena temporal en vista Orthogonal Front antes de integrar.
- Ajustar `CollisionShape3D` a las proporciones reales del modelo.

### 19.2 Modelos de Recursos
- `Arbol.tscn` y `Roca.tscn`: reemplazar `MeshInstance3D` de cubos por modelos.
- Mantener `Damageable` y la lógica de drops intacta (solo cambia el mesh).

### 19.3 Modelos de Enemigos y NPCs
- `EnemigoSlime.tscn`, `Mercado.tscn` y futuros animales: modelos 3D.
- Ajustar barra de vida 3D (`damageable_barra_3d.gd`) para que quede sobre la cabeza del modelo.

### 19.4 Materiales y Texturas
- Usar `StandardMaterial3D` o texturas importadas. Configurar sombras (`cast_shadow`).
- Asegurarse de que `DirectionalLight3D` proyecte sombras (ya existe en `Luz.tscn`).

### 19.5 Animaciones
- Importar animaciones del modelo (idle, caminar, atacar) en un `AnimationPlayer`.
- En `jugador.gd`: reproducir `caminar` cuando `velocity.length() > 0.1`, `idle` al pararse, `atacar` al golpear.
- Para empezar basta con `AnimationPlayer.play("nombre")`. El `AnimationTree` (blending) se ve en fase avanzada.

---

## 📦 FASE 20 — Renovación Visual del HUD y la UI
> **Objetivo**: Sustituir la estética provisional (ColorRect planos, botones por defecto) por una interfaz pulida, coherente y con identidad propia. Se hace aquí (tras todas las mecánicas) para no rediseñar pantallas que aún iban a cambiar.
> **Aprendizajes**: `Theme` centralizado, `StyleBoxFlat`/`StyleBoxTexture`, `NinePatchRect`, fuentes y escalado, animaciones de UI con `Tween`, feedback visual.

### ⏳ Orden de submódulos FASE 20
```
20.1 Theme centralizado → 20.2 HUD (vida/hambre/energía + minimapa/hotbar) → 20.3 Paneles (mochila/tienda/crafteo/diálogo) → 20.4 Iconos, fuentes y paleta → 20.5 Animaciones y feedback
```

### 20.1 Theme Centralizado (`Theme`)
- Crear **un único** `Theme` (`.tres`) asignado en el nodo raíz de la UI, o como **Theme por defecto** en `Project Settings → GUI → Theme`.
- Definir ahí los estilos de `Button`, `PanelContainer`, `Label`, `ProgressBar`, `TabContainer`, `LineEdit`… Así **toda la UI hereda el mismo aspecto** sin tocar cada escena (principio escalable: cambiar el Theme cambia todo el juego).
- Ventaja: elimina los `StyleBoxFlat` inline repetidos en `ui_dialogo.gd`, `crafteo.gd`, `tienda.gd`, etc.

### 20.2 HUD
- Reemplazar las barras `ColorRect` por **`ProgressBar`** (o `TextureProgressBar`) con `StyleBoxFlat` (esquinas redondeadas, borde, relleno con degradado).
- Barras finales: **Vida** (rojo), **Hambre** (naranja/amarillo), **Energía** (verde/azul) — apiladas con iconos a la izquierda.
- Añadir **hotbar de herramientas** (1–5) con el icono del arma equipada y su slot resaltado.
- Añadir indicadores: **reloj/fecha** (usa `GestorTiempo.get_tiempo_texto()`), **oro**, **clima** (cuando exista `GestorClima`), **nivel + barra XP** (cuando exista FASE 12).
- Contenedor raíz con `mouse_filter = IGNORE` (regla ya adoptada) para no bloquear los clicks de juego.

### 20.3 Paneles (mochila, tienda, crafteo, diálogo)
- Unificar el **estilo de panel** (fondo, borde, título, botón de cerrar) desde el `Theme`.
- Mochila: slots con marco y estado vacío claro; resaltado al pasar el mouse.
- Tienda: pestañas con estilo, precios con icono de oro, botón deshabilitado visualmente.
- Crafteo: ingredientes con verde/rojo (ya existe) pero con tipografía/iconos consistentes.
- Diálogo: retrato del NPC (opcional), nombre resaltado, caja de texto legible.

### 20.4 Iconos, Fuentes y Paleta
- Definir una **paleta de colores** de la UI (un solo sitio → constante o `Theme`).
- Importar una **fuente** con licencia libre (ej: una pixel/medieval según la ambientación) y aplicarla al Theme.
- Sustituir los placeholders de `icono_item.gd` por iconos definitivos donde existan, manteniendo el generador como fallback.
- Revisar escalado de UI (`stretch mode` / `canvas_items`) para que funcione en distintas resoluciones.

### 20.5 Animaciones y Feedback
- Aparición/cierre de paneles con `Tween` (fade + escala, ~0.15s).
- Feedback al recibir daño (flash rojo en pantalla), al subir de nivel, al recoger item (texto flotante "+1 madera").
- Animación de la barra de vida al cambiar (no salto brusco).
- Cursor/estados hover coherentes en todos los botones.

### ✅ Checklist de éxito FASE 20
- [ ] Existe un `Theme` único aplicado globalmente; ninguna escena de UI usa `StyleBoxFlat` inline.
- [ ] HUD muestra vida, hambre, energía, hotbar, reloj y oro con estilo coherente.
- [ ] Todos los paneles comparten fondo/borde/título comunes.
- [ ] Ninguna apertura de ventana congela el juego ni bloquea el input de mundo (respeta `GameState.modo_ui`).

---

## 📦 FASE 21 — Pulido Final y Build Jugable
> **Objetivo**: Consolidar todo en una experiencia completa y exportable.
> **Aprendizajes**: audio, balance, exportación.

### ⏳ Orden de submódulos FASE 21
```
21.1 Audio (música/SFX) → 21.2 Balance economía/dificultad → 21.3 Menús (principal/pausa/opciones) → 21.4 Misión principal completa → 21.5 Exportar build
```

### 21.1 Audio
- `AudioStreamPlayer` para música ambiente y SFX (golpes, pasos, lluvia).
- Un `AudioManager` sencillo para controlar volúmenes.

### 21.2 Balance
- Ajustar precios de tienda, daño de armas, vida de enemigos, curvas de XP.

### 21.3 Menús
- Menú principal, menú de pausa, pantalla de opciones, guardado/carga.

### 21.4 Misión Principal Completa
- Flujo desde el inicio hasta el "final" del juego.

### 21.5 Exportar
- Configurar export presets (Windows/Linux) y generar build.

---

## 📦 FASE 22 — Menú Principal y Sistema de Guardado (Save/Load)
> **Objetivo**: Dar al juego un punto de entrada real (menú principal → *Nueva partida* / *Continuar*) y **persistir el estado entre sesiones**. Hoy el juego arranca directamente en `mundo.tscn` (F6) y absolutamente todo vive en memoria.
> **Aprendizajes**: `FileAccess` + JSON, serialización de Autoloads, `SceneTree.change_scene_to_file()`, ranuras de partida, `get_tree().paused`.

> ⚠️ **ORDEN DE EJECUCIÓN: esta fase se ejecuta INMEDIATAMENTE DESPUÉS DE LA FASE 13 (antes de la 14)**, aunque su número sea 22. Dos razones:
> 1. **Cuanto antes se serialice, más barato sale**: hoy el mapa es un `.tscn` con 100 celdas pintadas a mano. Después de la FASE 15 (mapa mucho más grande) y sobre todo de la FASE 16 (procedural), el mundo pasa a necesitar semilla + chunks → el guardado se vuelve mucho más complejo.
> 2. **Es el punto de entrada**: sin menú principal no existe "nueva partida vs. continuar". Además hay 2 restos TEMPORALES vivos en `inventario.gd` (items iniciales y precarga de la hotbar) marcados literalmente como *"se eliminará cuando exista el sistema de guardado"*.

### ⏳ Orden de submódulos FASE 22
```
22.1 Formato de guardado (GuardadoManager + JSON) → 22.2 Serializables por sistema → 22.3 Menú principal (ranuras múltiples) → 22.4 Menú de pausa (Guardar/Salir) → 22.5 Autoguardado + limpieza de los temporales de inventario.gd
```

### 22.1 Formato de guardado
- Autoload nuevo `GuardadoManager`. Formato **JSON** en `user://partidas/ranura_N.json` (legible y depurable con un editor de texto, a diferencia de un binario). Detalles de la estructura y de las ranuras en **22.3a**.
- **Contrato**: cada sistema expone `serializar() -> Dictionary` / `deserializar(datos: Dictionary)`. El manager **no conoce campos concretos**: itera una lista de sistemas registrados. Añadir un sistema nuevo = implementar los 2 métodos y registrarlo (cero hardcodeo de campos en el manager).
- ⚠️ **JSON no tiene tipos**: `StringName` → `String`, `Vector3`/`Color` → array. Cada `deserializar()` es responsable de **reconvertir** sus propios tipos (regla: el tipo lo conoce quien lo guarda, no el manager). Los 3 gotchas concretos están listados en 22.3a.

### 22.2 Serializables (por orden de dependencia)
| Sistema | Qué guardar |
|---|---|
| `Inventario` | `slots`, `slots_hotbar`, `slot_hotbar_seleccionado`, `datos_variables_por_item`, `herramienta_equipada` |
| `Jugador` | posición/rotación + `Damageable` (vida), `Stats` (hambre/energía), `Nivel` (nivel/xp), `Estadisticas` (atributos) |
| `GestorTiempo` | `_minutos_totales`, `dia`, y los días acumulados que calculan la estación |
| `GestorClima` | clima actual + minutos restantes (guardar el **id**, no el Resource: el `.tres` se re-resuelve al cargar) |
| `MisionManager` | misiones activas + completadas |
| `GameState` | `jefes_derrotados` (⚠️ ya está preparado: es un `Dictionary[StringName, bool]`) |
| `Parcelas` | estado de cada parcela (arada/plantada/regado/progreso/etapa) |
| `RespawnManager` | recursos cortados + días restantes |

### 22.3 Menú Principal
- Escena `MenuPrincipal.tscn` **como escena inicial del juego** (`project.godot → application/run/main_scene`): *Nueva partida* / *Cargar partida* / *Salir*.
- ⚠️ **Orden crítico de carga**: los nodos que nacen dentro de la escena (jugador, parcelas, spawners) **no existen** hasta que la escena se instancia, y los Autoloads ya corrieron su `_ready()`. Patrón: **cargar la escena primero y aplicar el estado después**, con la propia escena avisando (`_ready()` del jugador pidiendo al manager "¿hay datos que aplicarme?"), o un `call_deferred` tras el `change_scene`. Intentar aplicar el estado *antes* del cambio de escena **falla en silencio**.
- ✅ **DECISIÓN DEL USUARIO (18/10/2026): RANURAS MÚLTIPLES.** Habrá varias partidas guardadas a la vez, no una sola.

#### 22.3a Ranuras múltiples (decisión del usuario)
- **Archivos**: `user://partidas/ranura_%d.json`. La carpeta `user://partidas/` **NO incluye** el nombre del juego porque Godot ya lo aísla solo (`user://` apunta a `%APPDATA%/Godot/app_userdata/<nombre>`), y así el proyecto puede renombrarse sin migrar datos.
- **Cantidad de ranuras**: `const CANTIDAD_RANURAS: int = 5` en `GuardadoManager` (configurable en un solo sitio; cero hardcodeo).
- **`ranura_actual: int = -1`** en `GuardadoManager`: es el **único** sitio que recuerda sobre qué ranura se está jugando. El menú de pausa ("Guardar") escribe ahí sin volver a preguntar. `-1` = partida sin guardar todavía (primera vez).
- **Cabecera dentro de cada archivo** (⭐ decisión clave): cada `ranura_N.json` es `{ "cabecera": {...}, "sistemas": {...} }`. La **cabecera** permite dibujar el menú sin aplicar nada:
  ```
  { "version": 1, "fecha_real": "...", "dia_juego": 14, "nivel": 7,
    "estacion": "primavera", "jefes_derrotados": 1, "tiempo_jugado": 1234.5 }
  ```
  Se descartó un `indice.json` aparte: sería un **segundo lugar** donde vive el dato de la ranura, y para cuando se desincronice (guardado interrumpido, archivo borrado a mano) el menú mostraría partidas fantasma. Leyendo la cabecera de cada archivo, el archivo **es** su propia verdad (17 ranuras leídas de golpe sigue siendo trivial).
- **`version: int`** en la cabecera desde el primer día: es lo que permitirá migrar partidas viejas cuando cambie el formato. Sin él, un campo nuevo en el futuro rompe las partidas existentes sin avisar.
- **UX del menú** (rejilla de tarjetas, una por ranura):
  - Ranura **vacía** → tarjeta "Vacío" → clic = crear partida nueva ahí.
  - Ranura **con datos** → tarjeta con `Día 14 · Nv. 7 · 🌸 Primavera · <fecha real>` → clic abre Cargar / Borrar / Cancelar.
  - **Borrar** pide confirmación (acción irreversible) y borra el archivo (`DirAccess.remove_absolute()`).
- *Nueva partida* y *Cargar partida* llevan **ambos** a la misma rejilla; solo cambia el comportamiento del clic sobre una ranura **ocupada** (Nueva partida avisa de la sobrescritura; Cargar la carga).
- ⚠️ **GOTCHA JSON #1 — todo número vuelve como `float`**: `JSON.parse_string()` mete `7` y devuelve `7.0`. `nivel` o `dia` sin su `int()` explícito se propagan como float y revientan comparaciones/formatos (`"Nv. 7.0"`). Todo entero se reconvierte **en el `deserializar()` de su propio sistema**.
- ⚠️ **GOTCHA JSON #2 — las claves `StringName` se vuelven `String`**: `Dictionary[StringName, bool]` (el caso real: `GameState.jefes_derrotados`) y `datos_variables_por_item` salen con claves `String`. Hay que reconstruir el diccionario tipado con `StringName(clave)`; asignar un `Dictionary[String, x]` a uno `Dictionary[StringName, x]` **falla en runtime**, no en el parser (el tipado de diccionarios es de runtime en GDScript 2.0).
- ⚠️ **GOTCHA JSON #3 — `JSON.parse_string()` devuelve `null` en silencio** si el archivo está corrupto o vacío (y `null` es un JSON válido, así que el error no salta solo). Comprobar `== null` y avisar antes de indexar. Un archivo a medio escribir (crash durante el guardado) es el caso realista.
- **Guardado atómico**: escribir primero en `ranura_N.json.tmp` y luego `DirAccess.rename_absolute()` encima del definitivo. Un corte de luz a mitad del `store_string()` deja la partida **destruida**; con el renombrado, o está la vieja o está la nueva.

### 22.4 Menú de Pausa
- `Esc` → `GameState.MODO_PAUSA` (la constante **ya existe y hoy no se usa**) + `get_tree().paused = true`.
- Botones: Guardar / Guardar como… (elegir otra ranura) / Volver al menú principal.
- **Guardar escribe en `GuardadoManager.ranura_actual`** (no pregunta). "Guardar como…" es el único que abre la rejilla de ranuras.
- ⚠️ **Volver al menú principal con la partida sin guardar**: hay que avisar (o autoguardar). Es la vía realista de perder progreso, porque el jugador cree que "el juego ya se acuerda".
- ⚠️ **`get_tree().paused` es GLOBAL y no se limpia al cambiar de escena**: si sales al menú con el árbol pausado, el menú nace **congelado**. Poner `paused = false` **antes** del `change_scene_to_file()`.
- ⚠️ Todo nodo de UI que deba seguir respondiendo con el árbol pausado necesita `process_mode = PROCESS_MODE_ALWAYS` (si no, los botones del menú de pausa quedan muertos, incluido el propio botón de reanudar).

### 22.5 Autoguardado y limpieza
- **Autoguardado** en los 2 "checkpoints" naturales que ya existen: al dormir en la cama (`cama.gd`) y/o en `GestorTiempo.dia_cambio`. Evita guardado constante.
- ⚠️ El autoguardado escribe en **`ranura_actual`**, y esa variable se asigna **al crear o cargar** la partida en el menú. Si el jugador creó la partida desde el menú, `ranura_actual` ya no es `-1` y el autoguardado tiene destino. Si siguiera en `-1`, el primer autoguardado no sabría dónde escribir (solución: asignarla también en `nueva_partida(ranura)`).
- **Eliminar los 2 bloques TEMPORALES de `inventario.gd`** (items iniciales de prueba + precarga de hotbar) y sustituirlos por los valores de "nueva partida".

> **Deuda que esta fase cierra**: `GameState.jefes_derrotados` (13.4) hoy se pierde al cerrar el juego; varios scripts repiten en sus comentarios *"cuando exista guardado, basta serializar este Dictionary"*.

---

## 📝 Cómo usar este documento

1. Cuando quieras avanzar elige la **siguiente** submódulo pendiente en la tabla arriba orden estricto FASE → indica cuál quieres implementar.
2. Te explicaré:
   1. Conceptos necesarios (por qué lo hacemos así, explicación teórica
   2. Paso a paso en GDScript/Godot editor)
3. Tú lo implementas manualmente
4. Al terminar, lo marcamos aquí ✅ en la tabla y seguimos con el siguiente

---

## 🔍 AUDITORÍA TÉCNICA (12/10/2026)

> Revisión exhaustiva del código real para validar el estado actual y detectar bugs/áreas de mejora antes de continuar.

### 📊 Estado Validado vs Plan

| Fase | Estado Plan | Estado Real | Diferencia |
|---|---|---|---|
| FASE 1 (Items + Interacción) | ✅ 100% | ✅ 100% | Coincide |
| FASE 2 (Granja) | ✅ 100% | ✅ 100% | Coincide |
| FASE 3 (Combate) | ✅ 100% | ✅ 100% | Coincide |
| FASE 4.1 (Diálogos Resources) | ✅ Completada | ✅ 100% | Coincide |
| FASE 4.2 (UI Diálogo) | ✅ Completada | ✅ 100% | Coincide |
| FASE 4.3 (Misiones) | ✅ Completada | ✅ 100% | Coincide |

### 🔴 BUGS CRÍTICOS Detectados (corregir ANTES de continuar)

#### Bug #1: StringName vacíos mal formados en `Dialogo_Mercader_Saludo_Inicial.tres`

**Archivo:** `recursos/dialogos/Dialogo_Mercader_Saludo_Inicial.tres`

**Problema:** Los campos que deberían ser StringName vacío (`&""`) tienen comillas literales incrustadas (`&"\"\""`). Esto hace que:
- Al elegir "👋 Nada más, gracias, adiós" → el sistema busca un diálogo con ID `""` (dos comillas literales) en lugar de cerrar.
- `id_dialogo_siguiente_automatico` y `accion_al_terminar` tampoco se detectan como vacíos.

**Líneas afectadas:**
- Línea 38: `id_siguiente_dialogo = &"\"\""` → debe ser `&""`
- Línea 48: `id_dialogo_siguiente_automatico = &"\"\""` → debe ser `&""`
- Línea 49: `accion_al_terminar = &"\"\""` → debe ser `&""`

**Cómo corregir:** Abrir cada `.tres` en el Inspector de Godot, borrar el contenido del campo y dejarlo vacío (no escribir nada). O editar el texto del `.tres` y reemplazar `&"\"\""` por `&""`.

#### Bug #2: Código muerto en `inventario.gd` (prints después de return)

**Archivo:** `scripts/core/inventario.gd`

**Líneas 224 y 233:** Hay `print()` de error DESPUÉS de `return true`, por lo que NUNCA se ejecutan. No rompen nada pero son código muerto confuso.

### 🟡 MANTENIMIENTO: Archivos temporales `.tmp` que debes borrar

Godot dejó archivos temporales en el árbol del proyecto (no dentro de `.godot/`). Bórralos todos:

```
escenes/jugador/Jugador.tscn11976248236.tmp
escenes/jugador/Jugador.tscn12779285162.tmp
escenes/jugador/Jugador.tscn12792628955.tmp
escenes/jugador/Jugador.tscn1590743942.tmp
escenes/jugador/Jugador.tscn2827538820.tmp
escenes/jugador/Jugador.tscn9685903336.tmp
escenes/mundo.tscn658546652.tmp
escenes/mundo.tscn6671338073.tmp
escenes/mundo.tscn6678094444.tmp
escenes/mundo.tscn6684550246.tmp
escenes/npc/EnemigoSlime.tscn236217771.tmp
escenes/ui/UIHud.tscn7188177707.tmp
escenes/tienda.tscn6953268341.tmp
escenes/tienda.tscn7287686690.tmp
```

### 🟢 MEJORAS RECOMENDADAS (no bloqueantes)

1. **Conectar opción "Adiós" al diálogo de despedida:** Actualmente la opción "Adiós" cierra directamente. Podrías hacer que apunte a `mercader_despedida` para que Don Mercader diga su frase de despedida antes de cerrar.

2. **Eliminar `print()` de debug en producción:** Hay muchos `print()` en `jugador.gd`, `npc_tienda.gd`, `ui_dialogo.gd`. Funcionan pero llenan la consola. Más adelante se pueden reemplazar por `push_warning()` solo para errores.

3. **Tecla 5 en jugador.gd tiene lógica redundante:** Línea 253-254: si ya tiene puños equipados, vuelve a equipar puños (no hace nada). Debería ser un toggle o simplemente no hacer nada.

### ✅ Validaciones POSITIVAS confirmadas

- ✅ `DialogoDatabase` correctamente registrado como Autoload en `project.godot`
- ✅ `UIHud.tscn` tiene `UiDialogo` como hijo (instancia de `UIDialogo.tscn`)
- ✅ `ui.gd` tiene método `abrir_dialogo_desde_npc()` y `@onready var ui_dialogo`
- ✅ `npc_tienda.gd` conecta señales `accion_especial_solicitada` y `dialogo_cerrado`
- ✅ Flujo de acciones: `abrir_tienda` → abre `UITienda.tscn`; `cerrar` → cierra diálogo
- ✅ Inventario tiene `get_cantidad()` (usado por `ui_dialogo.gd` para requisitos de opciones)
- ✅ Movimiento ISO calibrado: `ISO_ARRIBA(-0.707, 0, -0.707)`, `ISO_DERECHA(+0.707, 0, -0.707)`
- ✅ Quaternion.slerp con sign-flip protection en `VisualHolder`
- ✅ Sistema de armas data-driven con carga desde carpeta
- ✅ Damageable como componente (nodo hijo, no herencia)

### 🎯 PRÓXIMO PASO: Reforzar FASE 4 antes de FASE 4.3 (Misiones)

**Orden recomendado:**
1. 🔴 Corregir Bug #1 (StringName vacíos en `.tres`) — **OBLIGATORIO**
2. 🟡 Borrar archivos `.tmp` — **recomendado**
3. 🟡 Corregir código muerto en `inventario.gd` — **opcional**
4. ✅ Probar flujo completo de diálogos con Don Mercader:
   - Acercarse → F → ver saludo
   - Elegir "Comprar" → ver mensaje → se abre tienda
   - Elegir "Vender" → ver mensaje → se abre tienda
   - Elegir "Historia" → leer 3 líneas → opciones
   - Elegir "Adiós" → se cierra diálogo
5. ⬜ Marcar FASE 4.1 y 4.2 como ✅ Completadas en la tabla
6. ⬜ Empezar FASE 4.3 (Sistema de Misiones)
