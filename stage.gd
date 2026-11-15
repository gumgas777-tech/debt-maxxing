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
		
