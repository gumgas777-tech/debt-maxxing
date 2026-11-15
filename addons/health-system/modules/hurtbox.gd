class_name Hurtbox
extends RefCounted
## Shared logic of [Hurtbox2D], [Hurtbox3D], [Hitbox2D] and [Hitbox3D].

const META_DAMAGE := &"damage"
const META_DAMAGE_TYPE := &"damage_type"


## Returns [param cached] if it is still valid, otherwise the [HealthComponent]
## of the actor [param hurtbox] belongs to.
static func resolve_health(hurtbox: Node, cached: Variant) -> HealthComponent:
	if is_instance_valid(cached):
		return cached

	return HealthComponent.resolve(hurtbox)


static func receive_damage(
	health: HealthComponent, amount: float, source: Node, type: StringName
) -> DamageResult:
	return receive_hit(health, DamageInfo.new(amount, source, type))


## Multiplies the damage of [param info] by [param multiplier] and applies it.
## [param info] itself stays unchanged.
static func receive_hit(
	health: HealthComponent, info: DamageInfo, multiplier: float = 1.0
) -> DamageResult:
	if health == null:
		push_warning("Hurtbox: no HealthComponent found.")
		return null

	if is_equal_approx(multiplier, 1.0):
		return health.apply_damage(info)

	var hit := info.copy()
	hit.amount *= multiplier
	return health.apply_damage(hit)


## Deals the damage stored in the [code]damage[/code] metadata of [param node].
static func receive_from_meta(hurtbox: Node, node: Node) -> void:
	if not node.has_meta(META_DAMAGE):
		return

	var info := DamageInfo.new(
		node.get_meta(META_DAMAGE), actor_of(node), node.get_meta(META_DAMAGE_TYPE, &"generic")
	)
	set_hit_position(info, node)
	hurtbox.receive_hit(info)


## The actor [param node] belongs to: the nearest physics body or node with a
## [HealthComponent], going up from [param node] but not past the root of its
## scene. Falls back to [param node] itself, e.g. for a projectile.
static func actor_of(node: Node) -> Node:
	var current := node

	while current:
		if current is PhysicsBody2D or current is PhysicsBody3D:
			return current
		if HealthComponent.find(current, false):
			return current
		if current == node.owner:
			break
		current = current.get_parent()

	return node


## Stores the global position of [param node] as the hit position.
static func set_hit_position(info: DamageInfo, node: Node) -> void:
	if node is Node2D:
		info.position_2d = node.global_position
	elif node is Node3D:
		info.position = node.global_position


## Editor warning for a hurtbox or hitbox that cannot find its health component.
static func get_missing_health_warnings(node: Node, assigned: HealthComponent) -> PackedStringArray:
	if assigned or HealthComponent.resolve(node):
		return PackedStringArray()

	return PackedStringArray(
		[
			(
				"No HealthComponent found. Add one to the actor, next to this node or above "
				+ "it, or assign it in the inspector."
			)
		]
	)
