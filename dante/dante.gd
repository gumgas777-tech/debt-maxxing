extends CharacterBody2D

enum DIRECTION { UP, LEFT, DOWN, RIGHT }

const SPEED = 30000.0

func input_to_int(name):
	return int(Input.is_action_pressed(name))

func _physics_process(delta: float) -> void:

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Vector2(
		input_to_int("right") - input_to_int("left"),
		input_to_int("down") - input_to_int("up")
	);
		
		
	velocity = direction.normalized() * delta * SPEED
	move_and_slide()
	
	
