# 📋 Plan de Desarrollo - Aukane (Videojuego Isométrico 2.5D en Godot 4.x

> 🎮 Tipo: Farm / Mercado / Crafting / Diálogos / Combate / Recolección
> 🎓 Propósito: Aprender desarrollo en Godot + GDScript de forma incremental

---

## 🔑 **Regla #1 Orden de Fases**: Se debe avanzar estrictamente en este orden. No pasar a la siguiente fase hasta que la anterior esté 100% implementada y probada.**

```
FASE 1 → FASE 2 → FASE 3 → FASE 4 → FASE 5 → FASE 6 → FASE 7
```

## 🔑 **Regla #2 Comunicación / No Suposiciones**: Antes de dar una respuesta final o una corrección, **Siempre revisar el código real del proyecto (archivos .gd, .tscn, .tres)**. No se deben hacer suposiciones sobre lo que el usuario tiene o no tiene implementado. Si se detecta un bug, primero inspeccionar el archivo correspondiente para confirmar la causa raíz y luego explicar al usuario el cambio que debe realizar (el asistente NO edita el código por el usuario).

## 🔑 **Regla #3 El asistente NUNCA edita el código por el usuario**: Todos los cambios en scripts (.gd), escenas (.tscn) o recursos (.tres) los implementa manualmente el usuario siguiendo guías paso a paso. El asistente solo edita este documento PLAN_DESARROLLO_AUKANE.md para registrar reglas, actualizar progreso o corregir el plan.

---

---

## 📌 Estado del Proyecto (Actualizado - 03/10/2026)

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
| Input Map | Project Settings | ✅ 100% | WASD mover, **F = interactuar_mundo**, **ClickIzq/Space = atacar**, **E = Golpear/Rotar herramienta**, **1-5 = cambiar arma**, **Q = toggle puños**, Enter = ui_confirmar |
| Siguiente (FASE 4.1) | `scripts/npc/dialogo_definicion.gd` + `recursos/dialogos/*.tres` | ⏳ En Progreso | Sistema diálogos por Resources data-driven. NPC Don Mercader: saludo / comprar / vender / despedir. |

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
| FASE 4.1 Diálogos Data-Driven por Resources | ⏳ En Progreso | 03/10/2026 | Próximo submódulo oficial según orden FASE 1→2→3→4.
| FASE 4.2 UI Diálogo | ⬜ Pendiente | | |
| FASE 4.3 Misiones | ⬜ Pendiente | | |
| FASE 5.1 Catálogos Tienda | ⬜ Pendiente | | |
| FASE 5.2 UI Tienda 2 pestañas | ⬜ Pendiente | | |
| FASE 5.3 NPC tienda actualizado | ⬜ Pendiente | | |
| FASE 6.1 Recetas crafteo | ⬜ Pendiente | | |
| FASE 6.2 Crafteo Manager | ⬜ Pendiente | | |
| FASE 6.3 UI Crafteo nueva | ⬜ Pendiente | | |
| FASE 6.4 Estaciones mundo | ⬜ Pendiente | | |
| FASE 7.1 Gestor Tiempo | ⬜ Pendiente | | |
| FASE 7.2 Ciclo visual día/noche | ⬜ Pendiente | | |
| FASE 7.3 Integración sistemas | ⬜ Pendiente | | |

---

## 📝 Cómo usar este documento

1. Cuando quieras avanzar elige la **siguiente** submódulo pendiente en la tabla arriba orden estricto FASE → indica cuál quieres implementar.
2. Te explicaré:
   1. Conceptos necesarios (por qué lo hacemos así, explicación teórica
   2. Paso a paso en GDScript/Godot editor)
3. Tú lo implementas manualmente
4. Al terminar, lo marcamos aquí ✅ en la tabla y seguimos con el siguiente
