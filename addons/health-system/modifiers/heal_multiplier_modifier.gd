@tool
@icon("res://addons/health-system/icons/heal_multiplier_modifier.svg")
class_name HealMultiplierModifier
extends HealthModifier
## Multiplies incoming healing. [code]0.5[/code] is a healing reduction such as
## grievous wounds, [code]1.5[/code] a healing boost. Priority 50.

## Factor for every heal, or only for [member only_heal_type].
@export var multiplier: float = 1.0
## Only heals of this type are multiplied. Empty affects every type.
@export var only_heal_type: StringName = &""


func _init() -> void:
	priority = 50


func _validate_property(property: Dictionary) -> void:
	if property.name == "only_heal_type":
		HealthSystemSettings.suggest_heal_types(property)


func modify_heal(info: HealInfo, _health: HealthComponent) -> void:
	if only_heal_type != &"" and info.heal_type != only_heal_type:
		return

	info.amount *= multiplier
