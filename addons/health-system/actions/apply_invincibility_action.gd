@tool
@icon("res://addons/health-system/icons/apply_invincibility_action.svg")
class_name ApplyInvincibilityAction
extends HealthAction
## Makes the actor invincible for a moment after a hit (i-frames).
## Sets the [code]invincible[/code] tag while it lasts, see
## [method HealthComponent.grant_invincibility].

## Seconds of invincibility after a hit that got through.
@export var duration: float = 1.0


func _init() -> void:
	trigger = Trigger.ON_DAMAGED


func execute(health: HealthComponent, context: Dictionary) -> void:
	var result: DamageResult = context.get("result")

	if result and result.was_blocked:
		return
	if health.has_tag(HealthComponent.INVINCIBLE_TAG):
		return

	health.grant_invincibility(duration)
