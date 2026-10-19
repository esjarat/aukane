# AGENTS.md — Aukane

Juego isométrico 2.5D en **Godot 4.7.2 / GDScript 2.0**, renderer **GL Compatibility** y física **Jolt**. Todo el proyecto (código, docs, consola) está en español: **responde en español** y mantén el naming existente.

## Fuentes de verdad y estado

- `PLAN_DESARROLLO_AUKANE.md` es el plan y el registro de progreso. La tabla "Estado del Proyecto" del inicio está desfasada; manda el **registro de progreso del final** (filas con fecha). Fase 13 cerrada; la siguiente en el orden acordado es la **22 (menú principal + guardado)**, no la 14. No adelantes fases sin confirmarlo.
- `PROMPT_EXPERTO_GODOT.md` define el modo tutor: inspeccionar los archivos reales antes de diagnosticar, explicar el "por qué", no inventar nodos/señales/rutas. Ese documento prohíbe editar `.gd/.tscn/.tres` (solo el PLAN). Si el usuario pide implementar, edita; si pide tutoría, entrega pasos/parches. Si no está claro, pregunta.
- **Git**: HEAD solo contiene Fases 1–4.2; casi todo el juego está sin commitear o untracked. Nunca uses `git clean`, `git checkout -- .` ni `git reset --hard`. No commitees sin pedirlo.
- No hay tests, CI ni package manager; el único lint es el addon `gdstyle` del editor. Tampoco hay sistema de guardado (`FileAccess`/`user://`): todo vive en memoria hasta la Fase 22.
- Regla transversal del proyecto: **cero hardcodeo**. Balance, items, recetas, climas y biomas van en `.tres` o `@export`; no literales en código.

## Comandos verificados (Windows)

Godot 4.7.2 no está en PATH; el binario actual es:

```bash
"C:/Users/elteb/Downloads/Godot_v4.7.2/Godot_v4.7.2-stable_win64_console.exe" \
  --headless --path . --quit
```

- Instancia `escenes/mundo.tscn` y todos los Autoloads. **Devuelve exit code 0 aunque haya `SCRIPT ERROR`**: filtra la salida (`grep "SCRIPT ERROR"`).
- `--check-only --script res://...gd` da falsos `Identifier not found: GameState/Inventario` porque no carga Autoloads. No lo uses como verificación única.
- Editor: **F5** = escena principal (`escenes/mundo.tscn`); **F6** = escena abierta. No existe "run single test".
- El smoke test no valida render, input ni UI; para eso hay que jugar en el editor.
- El addon `gdstyle` lintea al guardar (el formateo no es automático): mantén tabs y tipado.

## Arquitectura

- Autoloads, en orden de `project.godot`: `GameState`, `ItemDatabase`, `Inventario`, `DialogoDatabase`, `MisionManager`, `CrafteoManager`, `GestorTiempo`, `GestorClima`, `DropManager`, `RespawnManager`.
- El orden importa: `GestorClima` y `RespawnManager` leen `GestorTiempo` en su `_ready()`. Un Autoload nuevo que dependa de otro va después.
- `scripts/jugador/jugador.gd` es el orquestador (~1000 líneas): movimiento ISO, interacción F, combate melee/rango, colocación de estaciones/parcelas, hotbar e input. Un cambio ahí afecta a todo.
- Managers en `scripts/core/`; Resources en `scripts/recursos/`; mundo en `scripts/mundo/`; granja en `scripts/granja/`; enemigos/jefes en `scripts/enemigos/`; animales en `scripts/animales/`; NPC/diálogos en `scripts/npc/`; UI en `scripts/ui/`. Las escenas viven en `escenes/` (no `scenes/`).

## Contenido data-driven

Los managers escanean carpetas; **añadir contenido = crear un `.tres`, no tocar el loader**:

| Carpeta | Resource / clave |
|---|---|
| `assets/items/` | `ItemDefinicion`, clave `id` |
| `assets/recetas/` | `RecetaCrafteo`, clave `id` |
| `recursos/armas/` | `ArmaDefinicion`, clave `nombre` |
| `recursos/dialogos/` | `DialogoDefinicion`, clave `id` |
| `recursos/climas/` | `ClimaDefinicion`, clave `id`; `peso` es relativo |
| `recursos/estaciones/` | `EstacionDefinicion`, clave `orden` (el `sort_custom` no desempata) |
| `recursos/terrenos/` | `TipoTerreno`, clave `id` |

`recursos/catalogos/` y `recursos/misiones/` no se escanean: se asignan desde el Inspector de un NPC (`catalogo_asignado`, `mision_ofrecida`).

Contratos que cruzan archivos:

- **Arma nueva** = `recursos/armas/X.tres` (`nombre`, `malla`, `transform_modelo`) + `assets/items/item_X.tres` con `tipo = &"herramienta"` y `herramienta_tipo = nombre` + receta opcional. No se toca `jugador.gd` ni `Jugador.tscn`.
- Los ids de items deben coincidir en recetas, catálogo, diálogos y misiones. Usa `ClavesDatos` para ids/claves compartidas (oro, azada/pala/regadera, agua, acciones de diálogo).
- El agua de crafteo (`&"agua"`) no es un item: sale de `carga_agua_actual` de la regadera.
- **Bioma nuevo** = `recursos/terrenos/X.tres` (`id`, `color`, `altura`, `es_cultivable`). Se pinta seleccionando `Terreno` en el editor y clic izquierdo; no edites el array `celdas` a mano.
- `GestorTerreno.celdas` es una lista plana fila a fila. Subir `alto_celdas` es seguro (añade al final); cambiar `ancho_celdas` reindexa y deforma todo el mapa.

## Contratos de escena que fallan en silencio

- Los componentes se buscan por **nombre exacto de nodo hijo**: `Damageable`, `Stats`, `Nivel`, `Estadisticas`. Renombrarlos o anidarlos más rompe vida, HUD, XP, drops o barras sin error.
- `VisualHolder` es el único nodo que rota/interpola; la raíz (`CharacterBody3D`/`StaticBody3D`) queda en identidad (`rotation=0`, `scale=1`). La cámara es hija de la raíz, nunca de `VisualHolder`. Escala global 1.0; el tamaño del modelo se ajusta en el hijo.
- `AnimalBase` espera `VisualHolder` y un mesh hijo llamado `Mesh`; `EnemigoBase` rota la raíz y busca `MeshInstance3D`. No unifiques ambas jerarquías sin revisar los dos scripts.
- Asigna propiedades (`nivel`, `id_rejilla`, etc.) **antes** de `add_child()`: `add_child()` dispara `_ready()` y el escalado/registro ocurre ahí.
- Cambiar `collision_layer` o spawnear drops desde callbacks de física requiere `set_deferred`/`call_deferred`.

## GDScript y datos

- Tabs, tipado explícito, `snake_case`/`PascalCase`, comentarios en español.
- Nada de `:=` para `Transform3D`/`Basis`/`Quaternion`; nunca `.normalized()` dentro de un `const` (usa literales).
- Los `signal` no admiten argumentos con default.
- `StringName` vacío en `.tres` se escribe `&""`; `&"\"\""` es un id literal con comillas y rompe el flujo.
- Godot **no serializa valores iguales al default**. No cambies defaults de Resources sin migrar los `.tres` existentes (`IngredienteReceta.cantidad = 1`, `ItemDefinicion.tipo = &"recurso"`, `stack_maximo = 99`, `ArmaDefinicion.nombre = &"puños"`).
- No pongas `class_name` a un script Autoload: colisiona con el nombre global (por eso `CrafteoManager` no lo tiene).
- Evita editar `.tscn`/`.tres` a mano; usa el editor. Si es inevitable: no pegues varios `[sub_resource]` en una línea, no añadas overrides `= null` a instancias y recuerda que un array exportado se serializa completo (reemplaza, no mezcla por índice).

## UI e input

- `GameState.MODO_UI` es la única señal de "hay una ventana abierta": todo panel nuevo debe ponerlo al abrir y restaurar `MODO_MUNDO` al cerrar. El jugador se congela solo.
- En UI, raíz `mouse_filter = STOP`, hijos no interactivos `IGNORE`; si no, los clics no llegan al panel.
- El drag & drop de mochila/hotbar es propio y el preview se añade al `CanvasLayer` de UI con `z_index = 4096`; el preview nativo de Godot queda detrás de la UI.
- Controles: WASD mover, Shift correr, F interactuar, clic izquierdo/Espacio atacar (o talar/minar), clic derecho comer el item de la mano, I mochila, 1–9 hotbar, Esc cerrar ventanas.

## Verificar y cerrar

- Ejecuta el smoke test y busca `SCRIPT ERROR`/`ERROR`. Ante un fallo silencioso, revisa **datos antes que código**: array `@export` vacío, `PackedScene` sin asignar, clave de `Dictionary` con typo, override `= null`, `.tres` cuyo id no coincide.
- Al terminar un submódulo, actualiza `PLAN_DESARROLLO_AUKANE.md`: fila con fecha, archivos, decisiones y gotchas. No marques una fase como completada solo porque compila; el criterio del proyecto es probarla en el editor.
