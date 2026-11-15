@tool
@icon("res://addons/health-system/icons/lives_component.svg")
class_name LivesComponent
extends Node
## Manages lives and respawning. Place it inside the actor next to its [HealthComponent].
##
## Every death costs a life. With lives left it emits [signal life_lost] and
## respawns after [member respawn_delay], at [member respawn_point] if one is set.
## At zero lives it emits [signal game_over] and the actor stays dead.

signal life_lost(lives_remaining: int)
## Emitted whenever [member current_lives] changes, including at startup.
## Connect a lives display here.
signal lives_changed(current: int, maximum: int)
signal respawned
signal game_over

## Lives at the start and after [method reset].
@export var max_lives: int = 3
## Seconds between death and respawn. Stops while the game is paused.
@export var respawn_delay: float = 1.0
## Respawn on its own. Turn it off to call [method respawn] from game code.
@export var auto_respawn: bool = true
## Health after a respawn, in percent of max health.
@export_range(0.0, 100.0) var respawn_health_percent: float = 100.0
## Seconds of invincibility after a respawn. [code]0[/code] disables it.
@export var respawn_invincibility: float = 2.0
## Where the actor reappears. Its global position and rotation are copied to the
## actor ([Node2D] or [Node3D]). Empty respawns where the actor died.
@export var respawn_point: Node
## The component to watch. Empty finds the one of the actor.
@export var health: HealthComponent

## Lives left. Setting it emits [signal lives_changed].
var current_lives: int:
	set(value):
		var old_lives := current_lives
		current_lives = maxi(value, 0)

		if old_lives != current_lives:
			lives_changed.emit(current_lives, max_lives)


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	if not is_instance_valid(health):
		health = HealthComponent.resolve(self)

	if not is_instance_valid(health):
		push_warning("LivesComponent: no HealthComponent found.")
		set_process(false)
		return

	current_lives = max_lives
	health.died.connect(_on_died)


func _get_configuration_warnings() -> PackedStringArray:
	return Hurtbox.get_missing_health_warnings(self, health)


## Brings the actor back if it is dead and has lives left: moves it to
## [member respawn_point], revives it and grants the respawn invincibility.
func respawn() -> void:
	if not is_instance_valid(health) or health.is_alive or current_lives <= 0:
		return

	_move_to_respawn_point()
	health.revive(respawn_health_percent)
	health.grant_invincibility(respawn_invincibility)
	respawned.emit()


func add_life(count := 1) -> void:
	current_lives += count


## Restores [member max_lives]. Does not revive the actor or cancel a pending respawn.
func reset() -> void:
	current_lives = max_lives


func _on_died(_info: DamageInfo) -> void:
	if current_lives <= 0:
		return

	current_lives -= 1

	if current_lives == 0:
		game_over.emit()
		return

	life_lost.emit(current_lives)

	if auto_respawn:
		health.create_timer(respawn_delay).timeout.connect(respawn)


func _move_to_respawn_point() -> void:
	var actor := health.get_parent()

	if not is_instance_valid(respawn_point) or actor == null:
		return

	if actor is Node2D and respawn_point is Node2D:
		actor.global_position = respawn_point.global_position
		actor.global_rotation = respawn_point.global_rotation
	elif actor is Node3D and respawn_point is Node3D:
		actor.global_position = respawn_point.global_position
		actor.global_rotation = respawn_point.global_rotation

	if actor is CharacterBody2D:
		actor.velocity = Vector2.ZERO
	elif actor is CharacterBody3D:
		actor.velocity = Vector3.ZERO
