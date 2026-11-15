class_name HealInfo
extends RefCounted
## Carries everything about one heal through the modifier pipeline.
##
## [method HealthComponent.apply_heal] runs the modifiers on a [method copy], so
## the info you pass in stays unchanged.

## Healing before any modifier.
var amount: float = 0.0
## The node that caused the heal, e.g. a potion or a healer. Can be [code]null[/code].
var source: Node = null
## Selects heal multipliers and action filters, e.g. [code]&"potion"[/code].
var heal_type: StringName = &"generic"
## Free-form data for your own game.
var metadata: Dictionary = {}


func _init(p_amount: float = 0.0, p_source: Node = null, p_type: StringName = &"generic") -> void:
	amount = p_amount
	source = p_source
	heal_type = p_type


## Returns an independent copy, including subclass fields. Dictionaries and
## arrays such as [member metadata] are copied as well, so writing to the copy
## leaves this info unchanged.
func copy() -> HealInfo:
	if get_script() == HealInfo:
		var info := HealInfo.new(amount, source, heal_type)
		info.metadata = metadata.duplicate()
		return info

	var info: HealInfo = get_script().new()

	for property in get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var value: Variant = get(property.name)
			info.set(
				property.name, value.duplicate() if value is Array or value is Dictionary else value
			)

	return info
