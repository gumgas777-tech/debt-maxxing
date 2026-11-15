class_name DamageInfo
extends RefCounted
## Carries everything about one hit through the modifier pipeline.
##
## [method HealthComponent.apply_damage] runs the modifiers on a [method copy], so
## one info can be passed to several targets, for example by an explosion.

## Damage before any modifier.
var amount: float = 0.0
## The node that caused the hit, usually the attacking actor. Can be [code]null[/code].
var source: Node = null
## Selects resistances, multipliers and action filters, e.g. [code]&"fire"[/code].
var damage_type: StringName = &"generic"
## World position of the hit. 2D games use [member position_2d].
var position: Vector3 = Vector3.ZERO
## The hit position for 2D games. Reads and writes x and y of [member position].
var position_2d: Vector2:
	get:
		return Vector2(position.x, position.y)
	set(value):
		position = Vector3(value.x, value.y, 0.0)
## Free-form data for your own game, e.g. [code]{"critical": true}[/code].
var metadata: Dictionary = {}


func _init(p_amount: float = 0.0, p_source: Node = null, p_type: StringName = &"generic") -> void:
	amount = p_amount
	source = p_source
	damage_type = p_type


## Returns an independent copy, including subclass fields. Dictionaries and
## arrays such as [member metadata] are copied as well, so writing to the copy
## leaves this info unchanged.
func copy() -> DamageInfo:
	if get_script() == DamageInfo:
		var info := DamageInfo.new(amount, source, damage_type)
		info.position = position
		info.metadata = metadata.duplicate()
		return info

	var info: DamageInfo = get_script().new()

	for property in get_property_list():
		# position_2d is only a view on position and would drop its z.
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and property.name != "position_2d":
			var value: Variant = get(property.name)
			info.set(
				property.name, value.duplicate() if value is Array or value is Dictionary else value
			)

	return info
