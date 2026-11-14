extends CharacterBody2D


var dante:Node2D

func _ready():
	dante = get_node("/root/Node2D/dante")


func _physics_process(delta: float):
	var direction = global_position.direction_to(dante.global_position)
	velocity = direction * 300.0
	move_and_slide()
