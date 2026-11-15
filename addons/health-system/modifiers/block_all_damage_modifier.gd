@tool
@icon("res://addons/health-system/icons/block_all_damage_modifier.svg")
class_name BlockAllDamageModifier
extends HealthModifier
## Blocks every hit. Priority 90, so it also protects a shield (95).
## For i-frames use [method HealthComponent.grant_invincibility].


func _init() -> void:
	priority = 90


func modify_damage(info: DamageInfo, _health: HealthComponent) -> void:
	info.amount = 0.0
