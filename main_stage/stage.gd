extends Node2D

var level_progress = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

@export var evil_guy:PackedScene

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	level_progress += 0.1 * delta
	$Timer.wait_time = 1 * pow(2/3, round(level_progress))
		
var rand = RandomNumberGenerator.new()

func _on_timer_timeout() -> void:
	var new_guy = evil_guy.instantiate()
	var ran_pos = Vector2(rand.randf_range(100, 1700), rand.randf_range(150, 1650))
	new_guy.global_position = ran_pos
	new_guy.dante = $Dante
	get_tree().current_scene.add_child(new_guy)
