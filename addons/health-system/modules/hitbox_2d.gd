@tool
@icon("res://addons/health-system/icons/hitbox_2d.svg")
class_name Hitbox2D
extends Area2D
## The attacking side: damages, heals or applies effects to every actor that enters.
##
## Hits [Hurtbox2D] areas and, with [member hit_bodies], physics bodies that carry
## a [HealthComponent]. An actor is hit once per entry, even when several of its
## shapes overlap. Collision layers and masks decide who can be hit.
## [br][br]
## Examples without a script: spikes ([member damage]), a poison swamp
## ([member status_effect] with [constant Hitbox.Mode.WHILE_INSIDE]), a potion
## ([member heal] with [member free_on_hit]) or a blade that applies grievous
## wounds ([member modifier]).

## Emitted after every hit. [param result] is the damage result, the heal result
## for a hitbox without damage, or [code]null[/code].
signal hit(health: HealthComponent, result: DamageResult)

@export_group("Effect")
## Damage per hit. [code]0[/code] deals none.
@export var damage: float = 10.0
## Damage type, e.g. [code]fire[/code]. Selects resistances and action filters.
@export var damage_type: StringName = &"generic"
## Healing per hit. [code]0[/code] heals nothing.
@export var heal: float = 0.0
## Heal type, e.g. [code]potion[/code].
@export var heal_type: StringName = &"generic"
## Status effect applied on every hit, e.g. poison. A [StatusEffectModule] is
## added to the target if it has none.
@export var status_effect: StatusEffect
## Modifier added on every hit, e.g. grievous wounds. Hitting again refreshes it.
@export var modifier: HealthModifier
## Seconds the [member modifier] lasts. [code]0[/code] keeps it until removed.
@export var modifier_duration: float = 0.0

@export_group("Targets")
## When to hit an actor.
@export var mode: Hitbox.Mode = Hitbox.Mode.ON_ENTER:
	set(value):
		mode = value
		notify_property_list_changed()
		update_configuration_warnings()
## Seconds between hits while an actor stays inside.
@export var interval: float = 1.0
## Also hit physics bodies with a [HealthComponent], e.g. a player without a
## hurtbox. Turn it off to only hit hurtboxes.
@export var hit_bodies: bool = true
## Only hit actors in this group, e.g. [code]player[/code]. Empty hits everyone.
@export var target_group: StringName = &""
## Remove this hitbox after its first hit, e.g. for potions and projectiles.
@export var free_on_hit: bool = false
## Passed as the source of every hit, e.g. for experience on kill. Empty uses
## the actor this hitbox belongs to.
@export var source: Node

var _logic := Hitbox.new(self)


func _ready() -> void:
	if Engine.is_editor_hint():
		set_physics_process(false)
		return

	_logic.start()


func _physics_process(delta: float) -> void:
	_logic.tick(delta)


func _validate_property(property: Dictionary) -> void:
	match property.name:
		"interval":
			if mode != Hitbox.Mode.WHILE_INSIDE:
				property.usage = PROPERTY_USAGE_NO_EDITOR
		"damage_type":
			HealthSystemSettings.suggest_damage_types(property)
		"heal_type":
			HealthSystemSettings.suggest_heal_types(property)


func _get_configuration_warnings() -> PackedStringArray:
	return Hitbox.get_warnings(self)


## Hits [param health] right away, e.g. from an attack animation, regardless of
## overlap. Returns the same result as the [signal hit] signal.
func apply_to(health: HealthComponent) -> DamageResult:
	return _logic.hit(health)


## The node passed as the source of every hit.
func get_source() -> Node:
	return source if is_instance_valid(source) else Hurtbox.actor_of(self)


## The components currently inside this hitbox.
func get_targets() -> Array[HealthComponent]:
	return _logic.get_targets()
