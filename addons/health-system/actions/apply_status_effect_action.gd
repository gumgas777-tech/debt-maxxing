@tool
@icon("res://addons/health-system/icons/apply_status_effect_action.svg")
class_name ApplyStatusEffectAction
extends HealthAction
## Applies a [StatusEffect] to the actor itself. Combined with
## [member HealthAction.only_types], fire damage can set the actor on fire.
## Creates a [StatusEffectModule] when the actor has none.

## The effect to apply.
@export var effect: StatusEffect


func _init() -> void:
	trigger = Trigger.ON_DAMAGED


func execute(health: HealthComponent, _context: Dictionary) -> void:
	if effect == null:
		push_warning("ApplyStatusEffectAction: no effect set.")
		return

	StatusEffectModule.get_or_create(health).apply_effect(effect)
