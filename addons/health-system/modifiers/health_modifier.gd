@tool
@icon("res://addons/health-system/icons/health_modifier.svg")
@abstract class_name HealthModifier
extends Resource
## Base class for everything that changes a damage or heal number.
##
## All modifiers of a [HealthComponent] run one after another, lowest
## [member priority] first. Override [method modify_damage], [method modify_heal]
## or both. Each receives a copy of the info, so changing it is safe.

## Order in the pipeline, lowest first. Convention: 20 flat reductions,
## 50 multipliers, 80 caps, 90 hard blocks, 95 pools such as shields.
@export_range(0, 100) var priority: int = 50


## Changes [param info] before the damage is subtracted.
func modify_damage(_info: DamageInfo, _health: HealthComponent) -> void:
	pass


## Changes [param info] before the healing is added.
func modify_heal(_info: HealInfo, _health: HealthComponent) -> void:
	pass
