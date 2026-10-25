# BellBee

> Personal tribute to Konami's **TwinBee** (1985) — a cute vertical shoot 'em up with bells. Built to play myself.

Gameplay follows the original as closely as possible. All art, music and names are original:
every sprite is drawn in code, and the music is a synthesised chiptune written for this project.

---

## How to Play

Double-click `Play.bat`.

Godot 4.5.1 (portable) is needed in `Tools/Godot_4.5.1/`. If it is not there, `Play.bat` uses the copy in
the sibling project `../Territory/Tools/Godot_4.5.1/`. The binary is not in git.

### Controls

| Action | Keyboard | Joypad |
|---|---|---|
| Move | Arrow keys / WASD | D-pad / left stick |
| Shoot (air) | Z / J (hold) | A |
| Bomb (ground) | X / K (hold) | B / X |
| Start / Continue | Enter / Space | Start |
| Pause | Esc / P | Start |
| Quit to title (paused) | Q | Back |
| Quit game (title) | Esc | — |

### Rules

- **Shoot** hits things in the air. **Bomb** hits things on the ground at the crosshair ahead of the ship.
- **Clouds** hide bells. Shoot a cloud to knock a bell out.
- **Bells**: each shot bounces a bell up. Every 5 hits it changes colour: yellow → blue → white → green → red.
  Five more hits on a red bell break it.

  | Bell | Effect |
  |---|---|
  | Yellow | Points. Catch yellows in a row for 500 → 1000 → 2000 → 4000 → 6000 → 8000 → 10000. Letting a yellow fall off the bottom, or dying, resets the chain |
  | Blue | Speed up (5 levels) |
  | White | Twin shot |
  | Green | Option: a ghost ship that follows you and shoots (max 2) |
  | Red | Barrier: absorbs 8 hits |

- **Arms**: a hit knocks off an arm. With an arm missing you **cannot bomb**; with both missing you also lose the twin shot.
  A hit with no arms left loses a life. An **ambulance** flies up from the bottom — touch it to get your arms back.
- **Huts** drop fruit when bombed. Fly over fruit for 500 → 1000 → 2000 → 3000 → 5000.
- Shoot down a whole **saucer formation** for a 1000 bonus and a bell. Big **kettles** drop a bell too.
- Each stage ends with a **boss**. After stage 3 the game loops, harder.
- Extra life at 30,000 and every 80,000 after that. Dying resets speed, twin shot, options and barrier.

---

## Development

| Item | Value |
|---|---|
| Engine | Godot 4.5.1 (GL Compatibility) |
| Language | GDScript |
| Resolution | 480 × 640 (window 600 × 800, scales) |
| Visual check | `Godot --path Game res://Tests/capture.tscn -- <out dir> [stage 0-2] [full\|quick]` — scripted pilot saves screenshots |

### Code Map

| Path | Purpose |
|---|---|
| `Game/Scripts/Stage/stage.gd` | Scrolling, spawning, collisions, bells, arms/ambulance, death, boss, clear, continue |
| `Game/Scripts/Stage/stage_plan.gd` | Seeded spawn timeline per stage |
| `Game/Scripts/Stage/themes.gd` | Per-stage palettes and water layout (mirrors the shader) |
| `Game/Shaders/ground.gdshader` | Patchwork fields, river / coast, haze |
| `Game/Scripts/Stage/ground.gd` | Trees, houses, scorch marks on top of the shader |
| `Game/Scripts/Entities/` | Player, bells, clouds, air and ground enemies, boss, ambulance, fruit, projectiles |
| `Game/Scripts/UI/art.gd` | Shared drawing: shaded balls, ship, bell, glows |
| `Game/Scripts/Autoload/` | `Game` (run state, inputs, high score), `Audio` (synthesised SFX and music) |

---

## License

Personal, non-commercial project. TwinBee is a trademark of Konami; this project is not affiliated with Konami
and uses none of its assets.
