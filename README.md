# The Crumbling Bar

A **3D first-person bar simulator** built in **Godot 4.6**. You move behind the counter, pick up bottles and tools with the mouse, pour with each hand, snap items into placement zones (spirits, shaker, and more), and serve customers that spawn into the bar.

## Requirements

- [Godot 4.6](https://godotengine.org/download) (project targets **GL Compatibility** rendering and **Jolt** physics)

## Run the game

1. Clone or download this repository.
2. Open Godot and use **Import** to select `project.godot`.
3. Press **F5** (or **Project → Run Project**) to play.

The **run main scene** is `scenes/main_menu.tscn` (main menu). **Start** loads `scenes/game.tscn`, where gameplay happens.

## Controls

Default bindings come from **Project → Project Settings → Input Map**. You can change movement, interact, pour, and related keys from **Options → Key Bindings** in the UI (which edits the same `InputMap` at runtime).

| Action | Default input |
|--------|----------------|
| Move forward / back | **W** / **S** |
| Move left / right | **A** / **D** |
| Look around | **Mouse** (captured while playing) |
| Interact (context-sensitive) | **Left mouse button** (`pick`) |
| Pour — left / right hand | Hold **Q** / **E** |
| Pause menu — frees mouse and pauses | **Escape** (`mouse_vis`) |

**Interact behavior:** If the crosshair is on a **pickable** object and you have a free hand, you pick it up. If you are holding something and the crosshair is on a **valid empty placement zone** for that item, the same click can place it (zones implement `can_accept` / `place_object`). Zones only accept objects in their configured group (for example `whiskey`, `vodka`, `tequila`, `shaker`).

**Pause menu:** From the game, **Escape** opens the overlay (game is paused, mouse visible). You can **Resume**, open **Options** (mouse sensitivity and key bindings), return **Back to menu**, or **Quit**.

## Settings

- **`scripts/settings.gd`** is registered as an autoload singleton **`Settings`** (`project.godot`).
- **Mouse look sensitivity** is stored in `Settings.mouse_sens` and exposed via the Options slider; the player reads it during mouse look.

## Project layout

| Path | Role |
|------|------|
| `project.godot` | Application name, main scene, input map, autoloads, physics (Jolt), renderer |
| `default_bus_layout.tres` | Default audio bus layout |
| `scenes/main_menu.tscn` | Entry menu (Start, Settings, Exit); embeds Options |
| `scenes/game.tscn` | Main level: bar, player, navigation, customers, pause UI |
| `scenes/pause_menu.tscn` | Pause overlay (instanced from game) |
| `scenes/options.tscn` | Options UI (sensitivity, key bindings via `hotkey.tscn`) |
| `scenes/player.tscn` | First-person character |
| `scenes/bar.tscn` | Bar environment |
| `scenes/customer.tscn` | Customer NPC |
| `scenes/base_zone.tscn` | Reusable placement zone (`scripts/base_zone.gd`) |
| `scenes/hotkey.tscn` | Single rebinding row (`scenes/hotkey.gd`, class `Hotkey`) |
| `scenes/*_bottle.tscn`, `shaker.tscn`, `mixer*.tscn`, `juice.tscn`, `*_glass(es).tscn` | Drink and equipment scenes |
| `scripts/player.gd` | Movement, camera, pick/drop/pour |
| `scripts/base_zone.gd` | Zone occupancy, group checks, snap-to-marker |
| `scripts/customer.gd`, `scripts/customer_spawn_point.gd` | Customer AI and spawning |
| `scripts/order_gen.gd`, `scripts/recipes.json` | Drink data and random order helpers |
| `scripts/pause_menu.gd`, `scripts/options.gd`, `scripts/main_menu.gd` | Menu and settings wiring |
| `assets/` | Models and textures (Godot `.import` sidecars included) |
| `icon.svg` | Project icon |

## How it works (briefly)

- **Player** (`CharacterBody3D`): Horizontal movement, mouse look with clamped pitch, **`Settings.mouse_sens`** for sensitivity, and a **RayCast3D** from the camera for aiming at pickables and zones.
- **Placement zones** (`Area3D`): Each zone has a `required_group` export. `can_accept` ensures the slot is free and the held object matches the group; `place_object` snaps the object to a child snap marker.
- **Customers**: Spawn from a **`CustomerSpawnPoint`** (`scripts/customer_spawn_point.gd`), use **NavigationAgent3D**, claim **seats** or **wait areas**, and receive orders derived from **`scripts/recipes.json`** via **`OrderGen`**.
- **Pause**: `get_tree().paused` is a **global SceneTree flag**. Opening the pause menu sets it to `true`. If you return to the main menu **without** setting `paused` back to `false`, the new scene can remain frozen for input. Clear pause when leaving gameplay (for example in **Back to menu** alongside `change_scene_to_file`).
