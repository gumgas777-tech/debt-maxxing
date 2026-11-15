@tool
@icon("res://addons/health-system/icons/play_animation_action.svg")
class_name PlayAnimationAction
extends HealthAction
## Plays an animation on an [AnimationPlayer], [AnimatedSprite2D] or
## [AnimatedSprite3D] of the actor, e.g. a hurt flash or a death animation.

## The player, relative to the actor. Empty uses the first [AnimationPlayer],
## [AnimatedSprite2D] or [AnimatedSprite3D] found inside the actor.
@export var player: NodePath = ^""
## Name of the animation to play.
@export var animation: StringName = &""
## Start from the beginning if the animation is already playing, so every hit flashes.
@export var restart: bool = true


func _init() -> void:
	trigger = Trigger.ON_DAMAGED


func execute(health: HealthComponent, _context: Dictionary) -> void:
	var node := _find_player(health.get_actor())

	if node == null:
		push_warning("PlayAnimationAction: no AnimationPlayer or AnimatedSprite found.")
		return

	if restart:
		node.stop()

	node.play(animation)


func _find_player(actor: Node) -> Node:
	if not player.is_empty():
		var node := actor.get_node_or_null(player)
		return node if _is_player(node) else null

	var queue: Array[Node] = [actor]

	while not queue.is_empty():
		var current: Node = queue.pop_front()

		for child in current.get_children():
			if _is_player(child):
				return child

		queue.append_array(current.get_children())

	return null


static func _is_player(node: Node) -> bool:
	return node is AnimationPlayer or node is AnimatedSprite2D or node is AnimatedSprite3D
