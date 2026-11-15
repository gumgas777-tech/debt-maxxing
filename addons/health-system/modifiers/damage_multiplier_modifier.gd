@tool
@icon("res://addons/health-system/icons/damage_multiplier_modifier.svg")
class_name DamageMultiplierModifier
extends HealthModifier
## Multiplies incoming damage. [code]0.5[/code] is a defense buff, [code]1.5[/code]
## a vulnerability debuff. Priority 50.

## Factor for every hit, or only for [member only_damage_type].
@export var multiplier: float = 1.0
## Only hits of this type are multiplied. Empty affects every type.
@export var only_damage_type: StringName = &""


func _init() -> void:
	priority = 50


func _validate_property(property: Dictionary) -> void:
	if property.name == "only_damage_type":
		HealthSystemSettings.suggest_damage_types(property)


func modify_damage(info: DamageInfo, _health: HealthComponent) -> void:
	if only_damage_type != &"" and info.damage_type != only_damage_type:
		return

	info.amount *= multiplier
