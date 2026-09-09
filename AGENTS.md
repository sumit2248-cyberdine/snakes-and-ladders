# AGENTS.md

Instructions for AI coding assistants working in this repository.
Mirrors the adjacent Ludo Royale conventions, simplified for S&L.

## Layer map (one-way)

```
core  (src/core)      pure logic: rules, FSM, session, events, data. No scene
                      tree, no tweens, no node types. Headless-testable.
gameplay (src/gameplay) the 3D world + director: main.gd (SnakesMatch),
                      choreographer, board, tokens, dice, camera.
presentation (src/presentation) UI CanvasLayers + theme. Emits intent signals;
                      never touches core directly.
```

- Only `SnakesSession.dispatch_action` mutates match state; everything else
  consumes the ordered `SnakesEvent` stream.
- Only `move_choreographer.gd` (+ `token.gd`) animate token nodes.
- Tests touch public API only.

## Where to add X

| Task | Files | Guard with |
|---|---|---|
| New rule / variant | `src/core/snakes_rules.gd`, `SnakesRuleSet`; FSM states if it gates actions | unit test in rules suite + fuzz invariant |
| New event type / payload key | `src/core/events/snakes_event.gd` (Type enum + KEYS + accessors) | consumer via accessors only |
| Turn-end reason | `src/core/events/turn_end_reason.gd` ONLY | session suite covers TURN_ENDED |
| New portal map | `SnakesPathData` preset + `SnakesRuleSet.portal_preset` | validate_portals check |
| New HUD control | `hud.gd` widget + one signal connect in `main.gd` | session_flow still green |
| AI scoring change | `src/core/ai_player.gd` | session suite winners sane |

## Definition of done

1. `$GODOT --headless --path . --script res://tests/run_all.gd -- fast`
   after every edit; `-- full` before declaring work done.
2. ARCHITECTURE.md class index updated when adding a `class_name`.
3. New behavior gets a unit/schema test, not just a manual look.

## Forbidden patterns (each one caused a real bug in Ludo)

- **Untracked tweens** — every choreographer tween goes through `_track()`.
- **Raw `create_timer` awaits without gen guards** — restart mid-presentation
  left orphan coroutines; guard with `_gen`.
- **Mirror variables of session state** — use getters/session reads; mirrors in
  `main.gd` are documented and synced on TURN_ENDED/GAME_OVER only.
- **Stringly-typed payloads** — use SnakesEvent accessors.
- **Magic seat numbers** — use `SnakesMatchSettings.seat_layout_for` / active seats.
- **Position literals outside SnakesRules/PathData** — derive from constants.

## GodotPrompter

This is a Godot project with GodotPrompter skills available. Before implementing
any game system, you MUST check for a matching `godot-prompter:*` skill and
invoke it. Key skills: `state-machine`, `scene-organization`,
`resource-pattern`, `godot-ui`, `godot-testing`.
