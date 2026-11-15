# Health System

A health and damage system for Godot 4.7. You add a `HealthComponent` to your actor. Everything else is set up as resources and nodes in the inspector: armor, resistances, poison, potions, loot drops, invincibility frames.

A goblin with armor, a loot drop and a despawn on death needs no GDScript at all. Neither does the spike trap that kills it.

`HealthComponent` extends `Node`, not `Node2D` or `Node3D`. The same profiles work in a platformer and in a first-person shooter. Only the hurtbox and hitbox wrappers contain 2D or 3D specific code.

## Installation

1. Copy `addons/health-system/` into your project
2. Go to **Project → Project Settings → Plugins** and enable `health-system`

## An enemy in 60 seconds

**Build the scene.** A `CharacterBody2D` as the root, with a `HealthComponent` underneath:

```
Goblin (CharacterBody2D)
├── Sprite2D
├── CollisionShape2D
├── HealthComponent
└── Hurtbox2D
    └── CollisionShape2D
```

The `Hurtbox2D` finds the `HealthComponent` on its own. It can sit anywhere inside the actor, also on a bone.

**Create a profile.** Right-click in the FileSystem, pick **New Resource**, choose `HealthProfile` and save it as `goblin.tres`:

| Field | Value |
|---|---|
| `max_health` | `30` |
| `default_modifiers` | one `ArmorModifier` with `armor = 3` |
| `actions` | one `SpawnSceneAction` (`scene = coin.tscn`, `spawn_count = 2`) and one `QueueFreeAction` |

**Assign it.** Drag `goblin.tres` into the `health_profile` field of the `HealthComponent`.

**Hurt it.** Add a `Hitbox2D` with a `CollisionShape2D` to your spikes and set `damage = 10`. Every actor that walks in takes 10 damage through its hurtbox.

That is the whole setup. The goblin has 30 HP, takes 3 less damage per hit, drops two coins when it dies and removes itself from the tree. Every other enemy is another `.tres` file, not another script.

To deal damage from game code:

```gdscript
var health := HealthComponent.find(goblin)
var result := health.damage(10.0, self, &"fire")

print(result.final_amount)  # 7.0, the armor took 3 off
```

The demo scene in the [repository](https://git.johnsoellner.me/swoopy/health-system) shows a poison swamp, a potion, an enemy, a boss with an enrage phase and a player with lives, all without glue scripts.

---

## Concepts

### HealthComponent

This is the only node you always need. It stores the health value, runs the modifier pipeline and sends the signals.

```gdscript
@export var health_profile: HealthProfile
@export var max_health: float = 100.0   # hidden while a profile is set

var current_health: float
var is_alive: bool
```

The methods you will use most:

```gdscript
health.damage(25.0, attacker, &"fire")   # -> DamageResult
health.heal(10.0, potion, &"potion")     # -> DamageResult
health.kill()
health.revive(50.0)                      # percent of max_health, only while dead
health.get_health_percent()              # 0.0 .. 100.0
health.grant_invincibility(1.5)          # i-frames, see Tags
```

You can also set the values directly. The same rules apply as for a hit: `current_health = 0` kills the actor, including the `died` signal and the death actions, and a value above 0 brings a dead actor back. Lowering `max_health` lowers the current health with it.

The component sets itself up on first use. So you can configure an actor in code and hit it before it enters the tree, the profile is already in effect.

`damage()` and `heal()` are shortcuts. If you need to pass more data along, like a hit position for particles or your own metadata, build the info object yourself:

```gdscript
var info := DamageInfo.new(25.0, attacker, &"fire")
info.position_2d = hit_position          # info.position in 3D
info.metadata["critical"] = true

var result := health.apply_damage(info)
```

The modifiers work on a copy, so your `info` stays as it is. An explosion can pass the same info to every target it hits. The `damaged` signal and the actions get the modified copy.

Both calls return a `DamageResult`:

| Field | Meaning |
|---|---|
| `final_amount` | what was actually subtracted after all modifiers |
| `blocked_amount` | how much less that is than the incoming value, so armor, resistance and shield together |
| `overkill` | damage dealt past 0 HP |
| `was_lethal` | this hit killed |
| `was_blocked` | nothing got through |

Two static functions take you from any node to a component:

- `HealthComponent.find(goblin)` searches inside a node, nearest first. That is the usual way to get from a bullet to its target.
- `HealthComponent.resolve(node)` finds the component of the actor that `node` belongs to, e.g. from a weapon, a bone or a module. It walks up and stops at the actor: the first physics body or the root of the actor's scene. There it also looks into plain `Node` folders such as `Components`.

### Profiles

A `HealthProfile` is a `.tres` file that describes one type of actor. It has five fields:

```gdscript
@export var max_health: float = 100.0
@export var start_health_percent: float = 100.0
@export var thresholds: Array[float] = []
@export var default_modifiers: Array[HealthModifier] = []
@export var actions: Array[HealthAction] = []
```

`thresholds` are percentage marks. When health crosses one of them in either direction, the component emits `threshold_crossed` and runs the `ON_THRESHOLD` actions. So a boss with `[25.0]` tells you itself when its enrage phase starts.

Every component gets its own copies of the modifiers and actions, so one profile can drive any number of goblins.

### Modifiers

A `HealthModifier` sits between the incoming damage and the health value and can change the number. All modifiers on an actor run one after another, sorted by `priority`, lowest first.

These come with the addon:

| Class | Priority | Effect |
|---|---|---|
| `ArmorModifier` | 20 | flat reduction, never below `min_damage` |
| `ResistanceModifier` | 50 | multiplier per damage type, `0.0` for immunity, `2.0` for a weakness |
| `DamageMultiplierModifier` | 50 | multiplier for all damage or one type, e.g. a defense buff |
| `HealMultiplierModifier` | 50 | multiplier for healing, e.g. grievous wounds at `0.5` |
| `DamageCapModifier` | 80 | limit per hit, either flat or as a percentage of max health |
| `BlockAllDamageModifier` | 90 | sets the hit to 0 |
| `ShieldAbsorbModifier` | 95 | takes from the shield pool, managed by `ShieldComponent` |

You can attach one at runtime, with or without a duration:

```gdscript
var shout := ArmorModifier.new()
shout.armor = 10.0

health.add_modifier(shout, 5.0)   # armor buff for five seconds
health.remove_modifier(shout)     # or take it off yourself
```

Without a duration the modifier stays until someone removes it. The timer stops while the game is paused, unless the actor runs with `PROCESS_MODE_ALWAYS`.

Adding the same instance again refreshes it: a timed modifier runs for the new duration if that ends later, and a duration of `0` makes it permanent. So a sword that applies grievous wounds on every hit keeps the debuff up instead of stacking it. Two separate instances do stack.

### The priority convention

The numbers are a convention. Nothing in the code enforces them. They exist so that modifiers from different sources end up in a sensible order:

| Range | For | Reason |
|---|---|---|
| 20 | flat reductions | they should run before anything multiplies |
| 50 | multipliers | resistances, weaknesses, vulnerability windows |
| 80 | caps | limit what is left after armor and multipliers |
| 90 | hard blocks | i-frames, cutscenes |
| 95 | pools | a shield only absorbs what got through, and i-frames protect it too |

The order changes the result. `(40 - 5) * 0.5 = 17.5`, but `40 * 0.5 - 5 = 15`. Which number the player sees depends on the priority.

### Actions

Modifiers change numbers. Actions react to events. You put them in the profile or add them at runtime, and they replace the signal wiring you would otherwise write in an enemy script.

There are five triggers, shown as a dropdown in the inspector:

| Trigger | Context |
|---|---|
| `ON_DAMAGED` | `{"info": DamageInfo, "result": DamageResult}` |
| `ON_HEALED` | `{"info": HealInfo, "result": DamageResult}` |
| `ON_DEATH` | `{"info": DamageInfo}` |
| `ON_THRESHOLD` | `{"threshold": float, "going_down": bool}` |
| `ON_REVIVE` | `{}` |

Every action has a **Filters** group that narrows the trigger down:

| Filter | Effect |
|---|---|
| `chance` | `0.3` runs the action in 30 % of all cases, e.g. a rare loot drop |
| `only_types` | only these damage types, or heal types for `ON_HEALED`, e.g. `fire` |
| `skip_if_blocked` | `ON_DAMAGED` ignores hits that did nothing, e.g. during i-frames |
| `only_thresholds` | `ON_THRESHOLD` only at these marks, e.g. `[25]` |
| `direction` | `ON_THRESHOLD` only while health goes down, or only up |

These come with the addon:

- **`QueueFreeAction`** removes the actor on death. It has an optional `delay` so a death animation can finish first.
- **`SpawnSceneAction`** creates `scene` as a sibling of the actor, `spawn_count` times. If the actor is a Node2D or Node3D, matching instances get its position, spread over `scatter_radius`.
- **`ApplyInvincibilityAction`** gives i-frames after a hit.
- **`PlaySoundAction`** plays a sound at the actor, with `pitch_variation` against repetition. The player sits next to the actor, so a death sound keeps playing when the actor is removed.
- **`PlayAnimationAction`** plays an animation on an `AnimationPlayer`, `AnimatedSprite2D` or `AnimatedSprite3D` of the actor. Without a path it takes the first one it finds.
- **`CallMethodAction`** calls a method on a node of the actor, e.g. `show` on an enrage sprite, or `set` with `["modulate", Color.RED]`. It is the bridge to the rest of your game when nothing else fits.
- **`ApplyStatusEffectAction`** applies a status effect to the actor itself. With `only_types = [fire]`, fire damage sets it on fire.
- **`EmitEventAction`** sends `event_name` through the `action_event` signal. Connect your event bus there.

A boss whose enrage sprite appears at 25 %: a `CallMethodAction` with `trigger = ON_THRESHOLD`, `only_thresholds = [25]`, `direction = GOING_DOWN`, `target = EnrageSprite` and `method = show`. No script.

### Tags

Tags are how the health system talks to the rest of your game. They are counted, so if two sources set `stunned`, only removing the second one emits `tag_removed`.

```gdscript
health.add_tag(&"burning")
health.has_tag(&"burning")     # true
health.get_tags()              # Array[StringName]
health.remove_tag(&"burning")
```

`grant_invincibility()` sets the tag `invincible` for as long as it lasts, and status effects set their own `tag`. That means the blinking during i-frames needs to know nothing about modifiers:

```gdscript
func _ready() -> void:
	health.tag_added.connect(func(tag): if tag == &"invincible": _start_blink())
	health.tag_removed.connect(func(tag): if tag == &"invincible": _stop_blink())
```

### Damage and heal types

Types are plain `StringName`s like `&"fire"`. List the ones your game uses under **Project Settings → Health System → Types**. Every type field in the inspector then suggests them, which keeps `"Fire"` and `"fire"` from drifting apart. Without the setting, the suggestions are `generic`, `physical`, `fire`, `ice`, `lightning` and `poison` for damage, and `generic`, `regen` and `potion` for healing.

---

## Modules

These nodes are optional. Whatever you do not put in the tree does not exist at runtime. Every module finds the `HealthComponent` of its actor on its own and shows a warning in the scene tree if there is none.

### Hurtbox2D and Hurtbox3D

They receive hits for the actor. A hit arrives in one of three ways:

- a `Hitbox2D` or `Hitbox3D` enters, see below
- any area or body with a `damage` entry under **Node → Metadata** enters, optionally with `damage_type`. Lava with `damage = 100` needs nothing else.
- game code calls `hurtbox.receive_damage(100.0, self, &"fire")` or `hurtbox.receive_hit(info)`

`damage_multiplier` scales every hit on that hurtbox. A head hurtbox with `2.0` on the head bone gives you headshots. `receive_damage` returns the `DamageResult`, or `null` with a warning if no `HealthComponent` was found.

### Hitbox2D and Hitbox3D

The attacking side. A hitbox hits every actor that enters it, through its hurtbox or, with `hit_bodies`, through a physics body that carries a `HealthComponent`. An actor is hit once per entry, even when its body and its hurtbox overlap at the same time. A hitbox never hits its own actor.

| Field | Effect |
|---|---|
| `damage`, `damage_type` | damage per hit |
| `heal`, `heal_type` | healing per hit |
| `status_effect` | applied on every hit, a `StatusEffectModule` is added if needed |
| `modifier`, `modifier_duration` | added on every hit, a new hit refreshes it |
| `mode` | `ON_ENTER` hits once per entry, `WHILE_INSIDE` hits again every `interval` seconds |
| `target_group` | only hit actors in this group, e.g. `player` |
| `free_on_hit` | remove the hitbox after its first hit |
| `source` | passed as the attacker, defaults to the actor the hitbox belongs to |

Collision layers and masks decide who can be hit at all. Some setups without a script:

| Thing | Setup |
|---|---|
| spikes | `damage = 10` |
| poison swamp | `damage = 0`, `status_effect = poison.tres`, `mode = WHILE_INSIDE`, `interval = 0.5` |
| potion | `damage = 0`, `heal = 30`, `free_on_hit = true` |
| cursed blade | `damage = 10`, `modifier = grievous_wounds.tres`, `modifier_duration = 10` |

After every hit the hitbox emits `hit(health, result)`. `apply_to(health)` hits from code, e.g. from an attack animation.

### ShieldComponent

A separate pool that soaks up damage before it reaches the health value. Put it inside the actor. It hooks into the pipeline through a modifier at priority 95, so the core knows nothing about it, and i-frames protect the shield as well.

```gdscript
signal shield_changed(old_value: float, new_value: float)
signal shield_broken
signal shield_restored

@export var max_shield: float = 50.0

shield.restore_shield(20.0)
shield.break_shield()
```

### RegenModule

Heals over time:

```gdscript
@export var regen_per_second: float = 5.0
@export var delay_after_damage: float = 0.0
@export var tick_interval: float = 0.5
```

It heals through the normal `heal()` API, so regeneration goes through the modifier pipeline like everything else. A modifier that halves healing also halves regeneration. The heal type is `&"regen"` if you want to treat it separately.

### StatusEffectModule

Runs timed effects such as poison. Hitboxes and `ApplyStatusEffectAction` add one on their own when the actor has none, so you only place it yourself to connect its signals.

A `StatusEffect` is a resource with `duration`, `tick_interval`, `max_stacks` and a `tag` that is set while it is active. Applying an active effect again refreshes its duration and adds a stack. Two kinds come with the addon:

- **`DamageOverTimeEffect`**: `damage_per_tick` of `damage_type` per tick and stack. It goes through the pipeline, so a resistance of `poison: 0.0` makes an actor immune.
- **`HealOverTimeEffect`**: `heal_per_tick` per tick and stack.

Effects with the same `id` count as one effect. Without an `id`, every `.tres` file counts as its own effect. All effects end when the actor dies.

```gdscript
effects.apply_effect(preload("res://effects/poison.tres"))
effects.has_effect(&"poison")
effects.get_stacks(&"poison")
effects.remove_effect(&"poison")
```

For your own effect, extend `StatusEffect` and override `_on_applied()`, `_on_tick()` or `_on_removed()`.

### LivesComponent

Manages lives and respawning. Each death consumes one life. With lives remaining, it emits `life_lost` and respawns after `respawn_delay`; at zero lives, it emits `game_over` and stays dead.

| Field | Effect |
|---|---|
| `max_lives` | lives at the start and after `reset()` |
| `respawn_point` | a `Marker2D` or `Marker3D`, the actor is moved there on respawn |
| `respawn_health_percent` | health after a respawn |
| `respawn_invincibility` | seconds of i-frames after a respawn, `0` disables them |
| `auto_respawn` | `false` lets you call `respawn()` yourself |

`lives_changed(current, maximum)` fires on every change, including at startup, so a lives display only has to listen. `add_life()` followed by `respawn()` allows a continue after game over. `reset()` restores `max_lives`; it does not revive the actor or cancel a pending respawn.

```gdscript
# hud.gd
func _ready() -> void:
	%Player/LivesComponent.lives_changed.connect(func(lives, _max): %LivesLabel.text = str(lives))
```

### HealthBar

Extends `ProgressBar` and displays a `HealthComponent`:

```gdscript
@export var health: HealthComponent
@export var target_group: StringName
@export var animate: bool = true
@export var show_damage_delay: bool = false
@export var hide_when_full: bool = false
```

Put it inside the actor for a bar above its head; it finds the component on its own. For a HUD in another scene, set `target_group` to the group of your player. The bar waits until a member of the group exists and moves on to the next one when it is freed. `health` can also be assigned at any time.

The bar reads the initial health, follows changes of `max_health` and resets both fills on revival. `animate = false` applies health changes immediately. Animation, damage delay and auto-hide can be switched at runtime. The durations are configured with `animation_duration` (0.2 s), `damage_delay` (0.35 s) and `damage_delay_duration` (0.6 s).

Visible styles come from your theme. The generated trail uses the `HealthBarDamageDelay` theme variation, based on `ProgressBar`; set its `fill` style to distinguish it from the main fill. With the trail enabled, the original background is drawn beneath both fills, and a `StyleBoxEmpty` suppresses the duplicate background on the main bar. Disabling the trail restores the original background override or theme lookup.

---

## Writing your own modifier

Anything that changes a damage or heal number is a modifier. Four steps.

**1. Create the file** and extend `HealthModifier`.

```gdscript
class_name GlassCannonModifier
extends HealthModifier
## Below a health threshold, every hit lands harder.
```

**2. Add the settings as exports.** Whatever you put here is what a designer fills in inside the `.tres` file.

```gdscript
@export var threshold_percent: float = 30.0
@export var multiplier: float = 2.0
```

**3. Set the priority.** Multipliers belong around 50, see the convention above.

```gdscript
func _init() -> void:
	priority = 50
```

**4. Override `modify_damage()`.** The second parameter is the `HealthComponent`. That is what it is for, when your modifier needs to know the state of the actor.

```gdscript
func modify_damage(info: DamageInfo, health: HealthComponent) -> void:
	if health.get_health_percent() > threshold_percent:
		return

	info.amount *= multiplier
```

The info is a copy made for this hit, so you can change it freely. For healing there is `modify_heal(info: HealInfo, health: HealthComponent)`. Both are optional, so override only what you need.

When you are done, list it under `default_modifiers` in a `.tres` file, or attach it at runtime.

## Writing your own action

Anything that reacts to an event instead of changing a number.

**1. Create the file** and extend `HealthAction`.

```gdscript
class_name GrantExperienceAction
extends HealthAction
## Awards experience to whoever landed the killing blow.
```

**2. Add the settings as exports.**

```gdscript
@export var experience: int = 10
```

**3. Set a default trigger.** It stays editable in the inspector, and so do the filters.

```gdscript
func _init() -> void:
	trigger = Trigger.ON_DEATH
```

**4. Override `execute()`.** The context is a `Dictionary`. Which keys it holds depends on the trigger, see the table above.

```gdscript
func execute(_health: HealthComponent, context: Dictionary) -> void:
	var info: DamageInfo = context["info"]

	if info.source and info.source.has_method("grant_experience"):
		info.source.grant_experience(experience)
```

Hitboxes and hurtboxes pass the attacking actor as `source`, so this works for a player whose sword is a `Hitbox2D`.

For a condition of your own, override `should_execute(health, context)` and call `super(health, context)` to keep the filters.

When you are done, list it under `actions` in a `.tres` file, or call `health.add_action(action)` at runtime.

---

## Signals

On the `HealthComponent`:

| Signal | Arguments | When |
|---|---|---|
| `health_changed` | `old_value: float`, `new_value: float` | on any change to the health value, including at startup |
| `max_health_changed` | `old_value: float`, `new_value: float` | when `max_health` changes, also from the profile |
| `damaged` | `info: DamageInfo`, `result: DamageResult` | after every hit, even one that was blocked completely |
| `healed` | `info: HealInfo`, `result: DamageResult` | after every heal |
| `died` | `info: DamageInfo` | once per death |
| `revived` | none | after `revive()` or when a dead actor's health is set above 0 |
| `threshold_crossed` | `threshold: float`, `going_down: bool` | when health crosses a profile mark in either direction |
| `tag_added` | `tag: StringName` | when a tag is set for the first time |
| `tag_removed` | `tag: StringName` | when the last source gives it up |
| `modifier_added` | `modifier: HealthModifier` | on `add_modifier()`, not on a refresh |
| `modifier_removed` | `modifier: HealthModifier` | on `remove_modifier()` and when a duration runs out |
| `action_added` | `action: HealthAction` | on `add_action()` |
| `action_removed` | `action: HealthAction` | on `remove_action()` |
| `action_event` | `event_name: StringName`, `context: Dictionary` | from an `EmitEventAction` |

On the modules:

| Node | Signal | Arguments |
|---|---|---|
| `ShieldComponent` | `shield_changed` | `old_value: float`, `new_value: float` |
| `ShieldComponent` | `shield_broken`, `shield_restored` | none |
| `Hitbox2D`, `Hitbox3D` | `hit` | `health: HealthComponent`, `result: DamageResult` |
| `StatusEffectModule` | `effect_applied` | `id: StringName`, `stacks: int` |
| `StatusEffectModule` | `effect_removed` | `id: StringName` |
| `LivesComponent` | `lives_changed` | `current: int`, `maximum: int` |
| `LivesComponent` | `life_lost` | `lives_remaining: int` |
| `LivesComponent` | `respawned`, `game_over` | none |

## License

MIT, Copyright (c) 2026 John Söllner. The full text is in [LICENSE](LICENSE).

The editor icons in `addons/health-system/icons/` come from the [@icons](https://github.com/Voxybuns/at-icons) set by Valentin Fossati (Voxybuns), which is MIT as well. Its license sits unchanged in the same folder and covers those SVG files. The two hurtbox icons are the exception: they were drawn for this addon and fall under its own license. The icons are copied into the addon instead of referenced, so you do not need the icon plugin installed.

---

## How AI was used here

I build this addon to learn Godot and to get better at architecture. So I write the source code by hand. The component layout, the modifier pipeline, the priority model, the action system and the modules are mine, both the design and the typing. An assistant that hands me a finished file would defeat the point.

I did use AI in these places.

**Tests:** The gdUnit4 suites are written by AI, based on the acceptance criteria in my own tickets. The loop was the same every time. I hand over the ticket, I get tests back, I run them, I look at what turned red. It found a good number of real bugs that I would otherwise have run into in the game.

**Comments and documentation:** The doc comments and this README. Writing is not my strong side, and a reference implementation that nobody can follow is not much of a reference.

**Commit messages:** it is just easier and helps others understand my changes :3

**CI/CD.**

**Version 1.1:** An AI review built the addon into a foreign game and listed what got in the way. The fixes from that review, the hitboxes, the action filters, the new actions and the reworked demo were written by AI at my request.
