@tool
@icon("res://addons/health-system/icons/health_profile.svg")
class_name HealthProfile
extends Resource
## Describes one type of actor, e.g. a goblin, as a [code].tres[/code] file.
##
## Assign it to [member HealthComponent.health_profile]. Every component gets its
## own copies of the modifiers and actions, so one profile can drive many actors.

## Maximum health. Overrides [member HealthComponent.max_health].
@export var max_health: float = 100.0
## Health at the start, in percent of [member max_health]. [code]0[/code] starts dead.
@export_range(0.0, 100.0) var start_health_percent: float = 100.0
## Percent marks. Crossing one in either direction emits
## [signal HealthComponent.threshold_crossed] and runs [code]ON_THRESHOLD[/code] actions.
@export var thresholds: Array[float] = []
## Modifiers every actor of this type starts with, e.g. armor or resistances.
@export var default_modifiers: Array[HealthModifier] = []
## Actions every actor of this type starts with, e.g. loot and despawn on death.
@export var actions: Array[HealthAction] = []
