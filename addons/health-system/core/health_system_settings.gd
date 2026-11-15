class_name HealthSystemSettings
extends RefCounted
## Project settings of the health system and the inspector suggestions built from them.
##
## The damage and heal types listed under [b]Project Settings > Health System[/b]
## show up as suggestions wherever a type is entered, so [code]"Fire"[/code]
## instead of [code]"fire"[/code] no longer slips through.

const DAMAGE_TYPES := "health_system/types/damage_types"
const HEAL_TYPES := "health_system/types/heal_types"

const DEFAULT_DAMAGE_TYPES: PackedStringArray = [
	"generic", "physical", "fire", "ice", "lightning", "poison"
]
const DEFAULT_HEAL_TYPES: PackedStringArray = ["generic", "regen", "potion"]


## A copy of the damage types from the project settings, or of the defaults if
## none are set.
static func get_damage_types() -> PackedStringArray:
	var types: PackedStringArray = ProjectSettings.get_setting(DAMAGE_TYPES, DEFAULT_DAMAGE_TYPES)
	return types.duplicate()


## A copy of the heal types from the project settings, or of the defaults if
## none are set.
static func get_heal_types() -> PackedStringArray:
	var types: PackedStringArray = ProjectSettings.get_setting(HEAL_TYPES, DEFAULT_HEAL_TYPES)
	return types.duplicate()


## Adds the settings to the project. Called by the editor plugin.
static func register() -> void:
	_register(DAMAGE_TYPES, DEFAULT_DAMAGE_TYPES)
	_register(HEAL_TYPES, DEFAULT_HEAL_TYPES)


## Turns [param property] into a text field with damage type suggestions.
## Call it from [code]_validate_property()[/code]. Works for [StringName],
## [code]Array[StringName][/code] and [code]Dictionary[StringName, float][/code]
## properties.
static func suggest_damage_types(property: Dictionary) -> void:
	_suggest(property, get_damage_types())


## Turns [param property] into a text field with heal type suggestions.
static func suggest_heal_types(property: Dictionary) -> void:
	_suggest(property, get_heal_types())


## Turns [param property] into a text field with damage and heal type suggestions.
static func suggest_all_types(property: Dictionary) -> void:
	var types := get_damage_types()
	for type in get_heal_types():
		if not types.has(type):
			types.append(type)
	_suggest(property, types)


static func _suggest(property: Dictionary, types: PackedStringArray) -> void:
	var list := ",".join(types)

	var key_hint := "%d/%d:%s" % [TYPE_STRING_NAME, PROPERTY_HINT_ENUM_SUGGESTION, list]

	if property.type == TYPE_ARRAY:
		property.hint = PROPERTY_HINT_TYPE_STRING
		property.hint_string = key_hint
	elif property.type == TYPE_DICTIONARY:
		property.hint = PROPERTY_HINT_TYPE_STRING
		property.hint_string = "%s;%d:" % [key_hint, TYPE_FLOAT]
	else:
		property.hint = PROPERTY_HINT_ENUM_SUGGESTION
		property.hint_string = list


static func _register(setting: String, defaults: PackedStringArray) -> void:
	if not ProjectSettings.has_setting(setting):
		ProjectSettings.set_setting(setting, defaults.duplicate())

	ProjectSettings.set_initial_value(setting, defaults)
	ProjectSettings.set_as_basic(setting, true)
	ProjectSettings.add_property_info(
		{"name": setting, "type": TYPE_PACKED_STRING_ARRAY, "hint": PROPERTY_HINT_NONE}
	)
