@tool
@icon("res://addons/health-system/icons/resistance_modifier.svg")
class_name ResistanceModifier
extends HealthModifier
## Multiplies damage per type. [code]0.0[/code] is immunity, [code]0.5[/code]
## halves, [code]2.0[/code] is a weakness. Types not listed are not changed. Priority 50.

## Damage type to factor, e.g. [code]fire: 0.5[/code].
@export_custom(PROPERTY_HINT_DICTIONARY_TYPE, "StringName;float") var resistances: Dictionary = {}


func _validate_property(property: Dictionary) -> void:
	if property.name == "resistances":
		HealthSystemSettings.suggest_damage_types(property)


func modify_damage(info: DamageInfo, _health: HealthComponent) -> void:
	if resistances.has(info.damage_type):
		info.amount *= resistances[info.damage_type]
