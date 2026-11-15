@tool
@icon("res://addons/health-system/icons/heal_over_time_effect.svg")
class_name HealOverTimeEffect
extends StatusEffect
## Heals every tick. Healing scales with the stacks and goes through the modifiers.

## Healing per tick and stack.
@export var heal_per_tick: float = 2.0
## Heal type of every tick.
@export var heal_type: StringName = &"regen"


func _validate_property(property: Dictionary) -> void:
	if property.name == "heal_type":
		HealthSystemSettings.suggest_heal_types(property)


func _on_tick(health: HealthComponent, stacks: int) -> void:
	health.heal(heal_per_tick * stacks, null, heal_type)
