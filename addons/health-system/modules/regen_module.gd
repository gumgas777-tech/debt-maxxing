@tool
@icon("res://addons/health-system/icons/regen_module.svg")
class_name RegenModule
extends Node
## Heals over time. Place it inside the actor next to its [HealthComponent].
##
## It heals through [method HealthComponent.heal] with the heal type
## [code]regen[/code], so heal modifiers apply to it as well.

## Healing per second.
@export var regen_per_second: float = 5.0
## Seconds without damage before regeneration starts. [code]0[/code] regenerates all the time.
@export var delay_after_damage: float = 0.0
## Seconds between two heals.
@export var tick_interval: float = 0.5
## The component to heal. Empty finds the one of the actor.
@export var health_component: HealthComponent

var _time_since_damage: float = 0.0
var _time_since_tick: float = 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		set_physics_process(false)
		return

	if not health_component:
		health_component = HealthComponent.resolve(self)

	if not health_component:
		push_warning("RegenModule: no HealthComponent found.")
		set_physics_process(false)
		return

	health_component.damaged.connect(_reset_time_since_damage)


func _get_configuration_warnings() -> PackedStringArray:
	return Hurtbox.get_missing_health_warnings(self, health_component)


func _physics_process(delta: float) -> void:
	if not health_component or not health_component.is_alive:
		return

	if health_component.current_health >= health_component.max_health:
		return

	if _time_since_damage <= delay_after_damage:
		_time_since_damage += delta
		return

	_time_since_tick += delta

	if _time_since_tick < tick_interval:
		return

	_time_since_tick -= tick_interval
	health_component.heal(regen_per_second * tick_interval, self, &"regen")


func _reset_time_since_damage(_info: DamageInfo, _result: DamageResult) -> void:
	_time_since_damage = 0.0
