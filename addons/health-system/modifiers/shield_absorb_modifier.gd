@tool
@icon("res://addons/health-system/icons/shield_absorb_modifier.svg")
class_name ShieldAbsorbModifier
extends HealthModifier
## Takes damage from a [ShieldComponent] before it reaches the health value.
## Created by the shield itself. Priority 95, so it only absorbs what armor,
## caps and blocks let through, and i-frames also protect the shield.

## The shield pool to draw from.
var shield: ShieldComponent


func _init() -> void:
	priority = 95


func modify_damage(info: DamageInfo, _health: HealthComponent) -> void:
	if info.amount <= 0.0 or not is_instance_valid(shield):
		return

	var absorbed := minf(info.amount, shield.current_shield)

	if absorbed <= 0.0:
		return

	shield.current_shield -= absorbed
	info.amount -= absorbed
	info.metadata["shield_absorbed"] = absorbed
