# Architecture — Snakes & Ladders

A 3D Snakes & Ladders game for Godot 4.7, mirroring Ludo Royale. One entry scene;
visuals are fully procedural (no art assets): 10x10 boustrophedon board, tube
snakes, railed ladders, capsule tokens, fake-tumble die.

## Data flow (mirrors Ludo)

```
INPUT (HUD, raycast picking, InputMap)
   → SnakesAction (command)
      → SnakesSession.dispatch_action → SnakesFSM (State Pattern) → SnakesRules
         → SnakesEvent (notification)
            → SnakesChoreographer (3D world), HUD, replay log
```

The session is fully synchronous: it never awaits presentation. Visual layers
consume the ordered event stream and pace their own input (the AI turn pump
waits for the choreographer to drain; humans self-pace). A complete match can
be played with nothing but `dispatch_action(SnakesAction)` — proven headlessly
by `tests/session_flow.gd`.

## Folders

- `scenes/` — thin shells: `Main.tscn` (director root), `board/Board.tscn`,
  `token/Token.tscn`, `ui/{HUD,SetupScreen,PauseMenu}.tscn`. The director builds
  the live world procedurally in `_ready` — zero-art approach preserved.
- `src/core/` — pure logic, no scene dependencies, headless-testable:
  `path_data.gd` (boustrophedon map + MB classic portals), `snakes_rules.gd`,
  `dice_engine.gd`, `match_session.gd`, `actions/`, `events/`, `fsm/` (AwaitRoll
  → Rolling → Moving → GameOver; no Selecting state — single token auto-moves),
  `data/` (`SnakesMoveOption`, `SnakesMoveResult`, `SnakesMatchSettings`),
  `ai_player.gd` (trivial facade), `serialization/` (JSON saves + replay log).
- `src/gameplay/` — director (`main.gd`, `class_name SnakesMatch`),
  `move_choreographer.gd` (sole event consumer touching 3D; sequential drain,
  `busy` flag), `board_scene.gd` + `board_builder.gd` (RefCounted world
  construction), `board_slotter.gd` (pure stacking layout), `token.gd`,
  `dice.gd` (fake tumble), `camera_director.gd` (orbit + zoom + top-down, no
  addon), `fx.gd`, `synth_audio.gd` (procedural beeps).
- `src/presentation/` — code-built CanvasLayers (HUD layer 10, Setup 20, Rules
  22, Pause 25) + `ui_theme.gd` factory. UI emits intent signals; the director
  translates them into SnakesActions.
- `src/resources/` — `SnakesRuleSet` (finish rule, six/ladder bonuses, portal
  preset) with classic/blitz/quick presets in `resources/`.

## Class index

Core: `SnakesPathData` `SnakesRules` `SnakesDiceEngine` `SnakesSession`
`SnakesAction` `SnakesEvent` `SnakesTurnEndReason` `SnakesFSM` `SnakesState`
`SnakesAwaitRollState` `SnakesRollingState` `SnakesMovingState`
`SnakesGameOverState` `SnakesMoveOption` `SnakesMoveResult`
`SnakesMatchSettings` `SnakesAIPlayer` `SnakesSerializer` `SnakesReplayLogger`

Gameplay: `SnakesMatch` `SnakesBoardScene` `SnakesBoardBuilder`
`SnakesBoardStyle` `SnakesSlotter` `SnakesToken` `SnakesDice`
`SnakesDiceTray` `SnakesSnakeBuilder` `SnakesFlexSnake` `SnakesSnakeScene`
`SnakesLadderBuilder` `SnakesLadderScene`
`SnakesCameraDirector` `SnakesChoreographer` `SnakesFX` `SnakesSynthAudio`

Terraces: `SnakesTerraceSettings` (step height + master knob blueprint;
`resources/snakes_terrace_default.tres`, preview `scenes/board/TerracedBoard.tscn`)

Presentation: `SnakesHUD` `SnakesSetupScreen` `SnakesPauseMenu`
`SnakesRulesPanel` `SnakesUITheme`

Resources: `SnakesRuleSet`

## Autoloads

None. Signals flow bottom-up (UI → director → `dispatch_action`); outcomes flow
back as SnakesEvents. The director keeps presentation mirrors (`state`,
`current`, `die_value`) for HUD/tests; the session is the single source of truth.

## Event conventions

- UI signals: intent nouns (`roll_pressed`, `start_game`).
- SnakesEvent types: `STATE_CHANGED, DICE_ROLLED, TOKEN_MOVED, SNAKE_HIT,
  LADDER_CLIMBED, TURN_ENDED, GAME_OVER`.
- Presentation: `SNAKE_HIT` plays the owning flex-rig strike + gulp +
  digest wave (`snakes_flex` group, head_cell match; arc-slide fallback);
  `LADDER_CLIMBED` hops the straight foot→top segment rung-to-rung.

## Verification

```sh
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
$GODOT --headless --path . --script res://tests/run_all.gd -- fast
$GODOT --headless --path . --script res://tests/run_all.gd -- full
$GODOT --headless --path . --script res://tests/run_tests.gd
$GODOT --headless --path . --script res://tests/session_flow.gd
$GODOT --headless --path . --script res://tests/script_sweep.gd
```
