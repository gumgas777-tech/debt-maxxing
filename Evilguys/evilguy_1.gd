extends CharacterBody2D

var health = 3
var dante:Node2D
var speed = 300.0
func _ready():
	dante = get_node("/root/Node2D/dante")


func _physics_process(delta: float):
	var direction = global_position.direction_to(dante.global_position)
	velocity = direction * speed
	$AnimatedSprite2D.play("chase")
	move_and_slide()

func take_damage():
	health -= 1
	
	if health == 0:
		$AnimatedSprite2D.play("death")
		speed = 0
		queue_free()
