@tool
@icon("res://addons/health-system/icons/play_sound_action.svg")
class_name PlaySoundAction
extends HealthAction
## Plays a sound, e.g. a hit or death sound.
##
## The player is added next to the actor, not inside it, so a death sound keeps
## playing when a [QueueFreeAction] removes the actor. It frees itself afterwards.

## The sound to play.
@export var stream: AudioStream
## Audio bus to play on.
@export var bus: StringName = &"Master"
## Volume in decibel.
@export var volume_db := 0.0
## Random pitch change per play, e.g. [code]0.1[/code] plays between 0.9 and 1.1.
## Keeps repeated hit sounds from sounding the same.
@export_range(0.0, 1.0, 0.01) var pitch_variation: float = 0.0
## Play at the actor's position with [AudioStreamPlayer2D] or [AudioStreamPlayer3D]
## when the actor is a [Node2D] or [Node3D].
@export var positional: bool = true


func execute(health: HealthComponent, _context: Dictionary) -> void:
	if stream == null:
		push_warning("PlaySoundAction: no stream set, nothing is played.")
		return

	var actor := health.get_actor()
	var audio := _create_player(actor)
	audio.stream = stream
	audio.bus = bus
	audio.volume_db = volume_db
	audio.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)

	var parent := actor.get_parent() if actor != health else null
	if parent == null:
		parent = health

	parent.add_child(audio)

	if actor is Node2D and audio is Node2D:
		audio.global_position = actor.global_position
	elif actor is Node3D and audio is Node3D:
		audio.global_position = actor.global_position

	audio.finished.connect(audio.queue_free)
	audio.play()


func _create_player(actor: Node) -> Node:
	if positional and actor is Node2D:
		return AudioStreamPlayer2D.new()
	if positional and actor is Node3D:
		return AudioStreamPlayer3D.new()
	return AudioStreamPlayer.new()
