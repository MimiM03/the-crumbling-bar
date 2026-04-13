# The Crumbling Bar

A **3D First-Person Bar Simulator Game** built in **Godot 4.6**. You move behind the counter, pick up bottles and tools with the mouse, pour with each hand, and snap items into placement zones (spirits, shaker, and more).

## Requirements

- [Godot 4.6](https://godotengine.org/download)

> **Note:** In `project.godot`, the application name is still set to `test-assets`. You can rename it in **Project → Project Settings → Application → Config Name** to match this repo.

## Run the game

1. Clone or download this repository.
2. Open Godot and use **Import** to select `project.godot`.
3. Press **F5** (or **Project → Run Project**) to play.

The main scene is `scenes/game.tscn` (referenced as the run main scene in the project file).

## Controls

| Action | Input |
|--------|--------|
| Move left / right | **A** / **D** (also **Left** / **Right** arrow) |
| Look around | **Mouse** (captured in-game) |
| Interact (context-sensitive) | **Left mouse button** (`pick`) |
| Pour (right hand) | Hold **E** |
| Pour (left hand) | Hold **Q** |
| Toggle mouse capture | **Escape** |

**Click behavior:** If the crosshair is on a **pickable** object and you have a free hand, you pick it up. If you are holding something and the crosshair is on a **valid empty placement zone** for that item, the same click can place it (zones implement `can_accept` / `place_object`). Zones only accept objects in their configured group (e.g. `whiskey`, `vodka`, `tequila`, `shaker`).

## Project layout

| Path | Role |
|------|------|
| `project.godot` | Engine version, input map, physics (Jolt), renderer |
| `scenes/game.tscn` | Main level: bar, player, drinks, glasses, mixer props, shaker zone |
| `scenes/player.tscn` | First-person character |
| `scenes/bar.tscn` | Bar environment |
| `scenes/base_zone.tscn` | Reusable placement zone (uses `scripts/base_zone.gd`) |
| `scenes/*_bottle.tscn`, `shaker.tscn`, `mixer*.tscn` | Drink and equipment scenes |
| `scripts/player.gd` | Movement, camera, pick/drop/pour |
| `scripts/base_zone.gd` | Zone occupancy, group checks, snap-to-marker |
| `assets/` | Models and textures (Godot `.import` sidecars included) |
| `icon.svg` | Project icon |

## How it works (briefly)

- **Player** (`CharacterBody3D`): WASD-style horizontal movement, mouse-look with clamped pitch/yaw, and a **RayCast3D** from the camera for aiming at pickables and zones.
- **Placement zones** (`Area3D`): Each zone has a `required_group` export. `can_accept` ensures the slot is free and the held object is in the right group; `place_object` snaps the object to a child `SnapPoint`.

