@tool
@icon("res://addons/health-system/icons/armor_modifier.svg")
class_name ArmorModifier
extends HealthModifier
## Subtracts a flat value from every hit. Priority 20, before any multiplier.

## Damage taken off every hit.
@export var armor: float = 5.0
## A hit never drops below this, so armor cannot make an actor immune.
@export var min_damage: float = 1.0


func _init() -> void:
	priority = 20


func modify_damage(info: DamageInfo, _health: HealthComponent) -> void:
	if info.amount <= 0.0:
		return

	info.amount = maxf(info.amount - armor, min_damage)
