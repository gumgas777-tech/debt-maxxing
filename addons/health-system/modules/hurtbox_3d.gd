@tool
@icon("res://addons/health-system/icons/hurtbox_3d.svg")
class_name Hurtbox3D
extends Area3D
## Receives hits for the actor and passes them to its [HealthComponent].
##
## Hits arrive from a [Hitbox3D], from code through [method receive_damage], or
## from any area or body with a [code]damage[/code] entry (and optionally
## [code]damage_type[/code]) under [b]Node > Metadata[/b].
## [br][br]
## The hurtbox finds the component of its actor on its own, also from a bone or a
## sub-node. Several hurtboxes with different [member damage_multiplier] values
## make headshots.

## The component that takes the damage. Empty finds the one of the actor.
@export var health_component: HealthComponent
## Factor for every hit on this hurtbox, e.g. [code]2.0[/code] for a head.
@export var damage_multiplier: float = 1.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	area_entered.connect(_on_entered)
	body_entered.connect(_on_entered)


func _get_configuration_warnings() -> PackedStringArray:
	return Hurtbox.get_missing_health_warnings(self, health_component)


## Deals [param amount] damage to the actor. Returns [code]null[/code] and warns
## when no [HealthComponent] is found.
func receive_damage(
	amount: float, source: Node = null, type: StringName = &"generic"
) -> DamageResult:
	var info := DamageInfo.new(amount, source, type)
	Hurtbox.set_hit_position(info, self)
	return receive_hit(info)


## Applies [param info], multiplied by [member damage_multiplier]. [param info]
## itself stays unchanged.
func receive_hit(info: DamageInfo) -> DamageResult:
	return Hurtbox.receive_hit(get_health(), info, damage_multiplier)


## The [HealthComponent] this hurtbox passes hits to.
func get_health() -> HealthComponent:
	health_component = Hurtbox.resolve_health(self, health_component)
	return health_component


func _on_entered(node: Node) -> void:
	Hurtbox.receive_from_meta(self, node)
