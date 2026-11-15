@tool
@icon("res://addons/health-system/icons/damage_over_time_effect.svg")
class_name DamageOverTimeEffect
extends StatusEffect
## Deals damage every tick, e.g. poison or burning. Damage scales with the stacks.
##
## The damage goes through the normal pipeline, so a [ResistanceModifier] with
## [code]poison: 0.0[/code] prevents it while the effect and its tag stay active.

## Damage per tick and stack.
@export var damage_per_tick: float = 2.0
## Damage type of every tick.
@export var damage_type: StringName = &"poison"


func _validate_property(property: Dictionary) -> void:
	if property.name == "damage_type":
		HealthSystemSettings.suggest_damage_types(property)


func _on_tick(health: HealthComponent, stacks: int) -> void:
	health.damage(damage_per_tick * stacks, null, damage_type)
