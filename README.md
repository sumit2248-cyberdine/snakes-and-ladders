# Snakes & Ladders

A polished 3D Snakes & Ladders board game for Godot 4.7 — classic Milton Bradley
rules presented as a stylized miniature diorama. Built **along the lines of the
adjacent Ludo Royale codebase**: the same `dispatch_action → FSM → events →
choreographer` architecture, thin procedural scenes, code-built UI, and headless
test lanes — simplified for the linear 1..100 track (no captures, no deployment).

## Running

Open this folder as a project in Godot 4.7+ and press **Play** (F5), or:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

## How to play

1. **Setup screen** — choose 2–4 players (You + AI, or All-AI demo), a rules preset
   (**Classic / Blitz / Quick**) and an optional seed, then press PLAY.
2. On your turn, press **ROLL** (or click the 3D dice in its tray).
3. Your token hops forward cell by cell. Land on a **ladder foot** to climb;
   land on a **snake head** to slide.
4. Classic rules: exact roll required to reach 100 (overshoot = stay), roll a 6
   for a bonus roll, three 6s in a row forfeits the turn. Ladder 80 → 100 wins
   instantly. Blitz finishes on reach-or-pass with ladder bonuses; Quick uses a
   shorter portal map.
5. First player to reach **100** wins.

### Convenience

- **CONTINUE MATCH** — every turn autosaves to `user://snakes_save.json`.
- **WATCH LAST MATCH** — replays the most recent finished match.
- Drag to orbit the camera; wheel/pinch to zoom; **V** toggles top-down view.

## Tests

```sh
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
$GODOT --headless --path . --script res://tests/run_all.gd -- fast
$GODOT --headless --path . --script res://tests/run_all.gd -- full
$GODOT --headless --path . --script res://tests/run_tests.gd
$GODOT --headless --path . --script res://tests/session_flow.gd
$GODOT --headless --path . --script res://tests/script_sweep.gd
```

## Project layout

```
scenes/Main.tscn            root scene (everything built procedurally)
src/core/                   pure rules + board data + AI + FSM + serialization
src/gameplay/               match director, board builder, choreographer,
                            tokens, dice, camera, FX, synth audio
src/presentation/           theme, setup screen, HUD, pause + rules panels
src/resources/              SnakesRuleSet variants
tests/                      headless suites (rules/session/persistence/arch)
```

## Credits

Board geometry, dice pips and sounds are generated procedurally at runtime.
Rules follow the Milton Bradley classic portal map; origins in Moksha Patam.
Architecture mirrors Ludo Royale (`dispatch_action` + FSM + event stream).
