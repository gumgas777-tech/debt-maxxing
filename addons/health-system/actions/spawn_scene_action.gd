@tool
@icon("res://addons/health-system/icons/spawn_scene_action.svg")
class_name SpawnSceneAction
extends HealthAction
## Instantiates a scene next to the actor, e.g. loot or an explosion on death.
## Node2D and Node3D instances are placed at the actor's position.

## The scene to spawn.
@export var scene: PackedScene
## How many instances to spawn.
@export var spawn_count := 1
## Spreads the instances randomly within this radius around the actor, in pixels
## (2D) or meters on the ground plane (3D). [code]0[/code] stacks them on the actor.
@export var scatter_radius: float = 0.0


func _init() -> void:
	trigger = Trigger.ON_DEATH


func execute(health: HealthComponent, _context: Dictionary) -> void:
	if scene == null:
		push_warning("SpawnSceneAction: no scene set, nothing is spawned.")
		return

	var actor := health.get_parent()

	if actor == null:
		return

	var parent := actor.get_parent()

	if parent == null:
		return

	var spawn_position: Variant = null

	if actor is Node2D:
		spawn_position = actor.global_position
	elif actor is Node3D:
		spawn_position = actor.global_position

	_spawn.call_deferred(parent, spawn_position)


func _spawn(parent: Node, spawn_position: Variant) -> void:
	if not is_instance_valid(parent):
		return

	for _index in spawn_count:
		var instance := scene.instantiate()
		parent.add_child(instance)
		_place(instance, spawn_position)


func _place(instance: Node, spawn_position: Variant) -> void:
	var offset := Vector2.from_angle(randf() * TAU) * sqrt(randf()) * scatter_radius

	if spawn_position is Vector2 and instance is Node2D:
		instance.global_position = spawn_position + offset
	elif spawn_position is Vector3 and instance is Node3D:
		instance.global_position = spawn_position + Vector3(offset.x, 0.0, offset.y)
