class_name Hitbox
extends RefCounted
## Shared logic of [Hitbox2D] and [Hitbox3D]: tracks which actors are inside and hits them.

enum Mode {
	## Hit once when an actor enters.
	ON_ENTER,
	## Hit when an actor enters and then every [code]interval[/code] seconds while it stays.
	WHILE_INSIDE,
}

## The [Hitbox2D] or [Hitbox3D] this logic belongs to.
var area: Node

# HealthComponent -> Target. Untyped, because freed components can stay as keys
# for a moment until their exit signal arrives.
var _targets: Dictionary = {}
var _own_health: HealthComponent
var _spent: bool = false


class Target:
	extends RefCounted

	var nodes: Array[Node] = []
	var hurtbox: Node
	var time: float = 0.0


func _init(p_area: Node) -> void:
	area = p_area


## Connects the area signals. Call from [code]_ready()[/code].
func start() -> void:
	_own_health = HealthComponent.resolve(area)
	area.area_entered.connect(on_entered)
	area.body_entered.connect(on_entered)
	area.area_exited.connect(on_exited)
	area.body_exited.connect(on_exited)


func on_entered(node: Node) -> void:
	if _spent:
		return

	var hurtbox: Node = node if node is Hurtbox2D or node is Hurtbox3D else null
	var health: HealthComponent

	if hurtbox:
		health = hurtbox.get_health()
	elif area.hit_bodies and (node is PhysicsBody2D or node is PhysicsBody3D):
		health = HealthComponent.resolve(node)

	if health == null or not accepts(health):
		return

	var target: Target = _targets.get(health)

	if target:
		target.nodes.append(node)
		if target.hurtbox == null:
			target.hurtbox = hurtbox
		return

	target = Target.new()
	target.nodes.append(node)
	target.hurtbox = hurtbox
	_targets[health] = target
	hit(health, hurtbox)


func on_exited(node: Node) -> void:
	for health: Variant in _targets.keys():
		var target: Target = _targets[health]

		if not target.nodes.has(node):
			continue

		target.nodes.erase(node)

		if target.nodes.is_empty():
			_targets.erase(health)
		elif target.hurtbox == node:
			target.hurtbox = null
			for other in target.nodes:
				if other is Hurtbox2D or other is Hurtbox3D:
					target.hurtbox = other
					break


## Advances [constant Mode.WHILE_INSIDE] hits. Call from [code]_physics_process()[/code].
func tick(delta: float) -> void:
	if area.mode != Mode.WHILE_INSIDE or area.interval <= 0.0:
		return

	for health: Variant in _targets.keys():
		if not is_instance_valid(health):
			_targets.erase(health)
			continue

		var target: Target = _targets[health]
		target.time += delta

		while target.time >= area.interval and not _spent and _targets.has(health):
			target.time -= area.interval
			hit(health, target.hurtbox)


## [code]false[/code] for the hitbox's own actor and for actors outside
## [code]target_group[/code].
func accepts(health: HealthComponent) -> bool:
	if health == _own_health:
		return false

	if area.target_group == &"":
		return true

	var actor := health.get_actor()
	return actor.is_in_group(area.target_group) or health.is_in_group(area.target_group)


## Applies everything the hitbox is configured for to [param health]. Hits go
## through [param hurtbox] when given, so its multiplier counts.
func hit(health: HealthComponent, hurtbox: Node = null) -> DamageResult:
	if _spent or not is_instance_valid(health) or not health.is_alive:
		return null

	var source: Node = area.get_source()
	var result: DamageResult

	if area.damage > 0.0:
		var info := DamageInfo.new(area.damage, source, area.damage_type)
		Hurtbox.set_hit_position(info, area)
		if is_instance_valid(hurtbox):
			result = hurtbox.receive_hit(info)
		else:
			result = health.apply_damage(info)

	if area.heal > 0.0:
		var heal_result := health.apply_heal(HealInfo.new(area.heal, source, area.heal_type))
		if result == null:
			result = heal_result

	if area.status_effect:
		StatusEffectModule.get_or_create(health).apply_effect(area.status_effect)

	if area.modifier:
		health.add_modifier(area.modifier, area.modifier_duration)

	area.hit.emit(health, result)

	if area.free_on_hit:
		_spent = true
		area.queue_free()

	return result


## The components currently inside the hitbox.
func get_targets() -> Array[HealthComponent]:
	var targets: Array[HealthComponent] = []

	for health: Variant in _targets.keys():
		if is_instance_valid(health):
			targets.append(health)

	return targets


## Editor warnings shared by both hitboxes.
static func get_warnings(hitbox: Node) -> PackedStringArray:
	var warnings := PackedStringArray()

	if (
		hitbox.damage <= 0.0
		and hitbox.heal <= 0.0
		and hitbox.status_effect == null
		and hitbox.modifier == null
	):
		warnings.append("This hitbox does nothing. Set damage, heal, status_effect or modifier.")

	if hitbox.mode == Mode.WHILE_INSIDE and hitbox.interval <= 0.0:
		warnings.append("WHILE_INSIDE needs an interval above 0.")

	return warnings
