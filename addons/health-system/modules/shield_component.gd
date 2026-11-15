@tool
@icon("res://addons/health-system/icons/shield_component.svg")
class_name ShieldComponent
extends Node
## A separate pool that absorbs damage before it reaches the health value.
## Place it inside the actor next to its [HealthComponent].
##
## It hooks into the pipeline with a [ShieldAbsorbModifier] at priority 95, so it
## only absorbs what armor, caps and blocks let through.

signal shield_changed(old_value: float, new_value: float)
signal shield_broken
signal shield_restored

## Shield at the start and the upper limit for [method restore_shield].
@export var max_shield: float = 50.0
## The component to protect. Empty finds the one of the actor.
@export var health_component: HealthComponent

## The shield left. Setting it emits [signal shield_changed].
var current_shield: float:
	set(value):
		var old_shield := current_shield
		current_shield = clampf(value, 0.0, max_shield)

		if old_shield == current_shield:
			return

		shield_changed.emit(old_shield, current_shield)

		if not _started:
			return

		if current_shield == 0.0:
			shield_broken.emit()
		elif current_shield == max_shield:
			shield_restored.emit()

var _shield_absorb_modifier: ShieldAbsorbModifier
var _started := false


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		return

	if not is_instance_valid(health_component):
		health_component = HealthComponent.resolve(self)

	if not health_component:
		push_warning("ShieldComponent: no HealthComponent found, the shield has no effect.")
		return

	if _shield_absorb_modifier == null:
		_shield_absorb_modifier = ShieldAbsorbModifier.new()
		_shield_absorb_modifier.shield = self

	health_component.add_modifier(_shield_absorb_modifier)


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	current_shield = max_shield
	_started = true


func _exit_tree() -> void:
	if _shield_absorb_modifier == null or not is_instance_valid(health_component):
		return

	health_component.remove_modifier(_shield_absorb_modifier)


func _get_configuration_warnings() -> PackedStringArray:
	return Hurtbox.get_missing_health_warnings(self, health_component)


func restore_shield(amount: float) -> void:
	current_shield += amount


func break_shield() -> void:
	current_shield = 0.0
