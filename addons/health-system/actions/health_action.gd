@tool
@icon("res://addons/health-system/icons/health_action.svg")
@abstract class_name HealthAction
extends Resource
## Base class for everything that reacts to a health event instead of changing a number.
##
## Pick the [member trigger] in the inspector and narrow it down with the filters.
## Subclasses override [method execute]. The context depends on the trigger:
## [br]- [code]ON_DAMAGED[/code]: [code]{"info": DamageInfo, "result": DamageResult}[/code]
## [br]- [code]ON_HEALED[/code]: [code]{"info": HealInfo, "result": DamageResult}[/code]
## [br]- [code]ON_DEATH[/code]: [code]{"info": DamageInfo}[/code]
## [br]- [code]ON_THRESHOLD[/code]: [code]{"threshold": float, "going_down": bool}[/code]
## [br]- [code]ON_REVIVE[/code]: [code]{}[/code]

enum Trigger {
	ON_DAMAGED,
	ON_HEALED,
	ON_DEATH,
	ON_REVIVE,
	ON_THRESHOLD,
}

enum Direction {
	ANY,
	GOING_DOWN,
	GOING_UP,
}

## The event this action reacts to.
@export var trigger: Trigger = Trigger.ON_DEATH

@export_group("Filters")
## Chance from 0 to 1 that the action runs when it would. [code]0.3[/code] drops
## loot in 30 % of all deaths.
@export_range(0.0, 1.0, 0.01) var chance: float = 1.0
## Only react to these damage types ([code]ON_DAMAGED[/code], [code]ON_DEATH[/code])
## or heal types ([code]ON_HEALED[/code]). Empty reacts to every type.
@export var only_types: Array[StringName] = []
## [code]ON_DAMAGED[/code]: skip hits that were blocked completely, e.g. during i-frames.
@export var skip_if_blocked: bool = false
## [code]ON_THRESHOLD[/code]: only react to these marks in percent. Empty reacts to every mark.
@export var only_thresholds: Array[float] = []
## [code]ON_THRESHOLD[/code]: only react when health crosses the mark in this direction.
@export var direction: Direction = Direction.ANY


func _validate_property(property: Dictionary) -> void:
	if property.name == "only_types":
		HealthSystemSettings.suggest_all_types(property)


## Does the work. Override it in your own actions.
func execute(_health: HealthComponent, _context: Dictionary) -> void:
	pass


## Applies the filters. [HealthComponent] calls [method execute] only when this
## returns [code]true[/code]. Override it for your own conditions and call
## [code]super()[/code] to keep the filters.
func should_execute(_health: HealthComponent, context: Dictionary) -> bool:
	if not only_types.is_empty() and not only_types.has(_type_of(context.get("info"))):
		return false

	if skip_if_blocked:
		var result: DamageResult = context.get("result")
		if result and result.was_blocked:
			return false

	if context.has("threshold") and not _matches_threshold(context):
		return false

	return chance >= 1.0 or randf() < chance


func _matches_threshold(context: Dictionary) -> bool:
	var going_down: bool = context.get("going_down", true)

	if direction == Direction.GOING_DOWN and not going_down:
		return false
	if direction == Direction.GOING_UP and going_down:
		return false

	if only_thresholds.is_empty():
		return true

	var threshold: float = context["threshold"]
	return only_thresholds.any(func(mark: float) -> bool: return is_equal_approx(mark, threshold))


static func _type_of(info: Variant) -> StringName:
	if info is DamageInfo:
		return info.damage_type
	if info is HealInfo:
		return info.heal_type
	return &""
