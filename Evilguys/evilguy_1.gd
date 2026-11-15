extends CharacterBody2D

var health = 3
var dante:Node2D

func _ready():
	dante = get_node("/root/Node2D/dante")


func _physics_process(delta: float):
	var direction = global_position.direction_to(dante.global_position)
	velocity = direction * 300.0
	
	var collided: bool = move_and_slide();
	if collided:
		var collision = get_last_slide_collision();
		var collider: Node2D = collision.get_collider();
		
		if collider.is_in_group("player"):
			Global.player_health -= 3.4
			queue_free()

@export var shop:PackedScene

func take_damage():
	health -= 1
	
	if health == 0:
		Global.kills += 1
		if Global.kills == Global.kill_req:
			get_tree().change_scene_to_packed(shop)
		queue_free()
	
