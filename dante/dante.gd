extends CharacterBody2D

enum DIRECTION { UP, LEFT, DOWN, RIGHT }
var direction:Vector2

var health = 100.0
const SPEED = 30000.0

func _ready() -> void:
	$AnimatedSprite2D.play()


func input_to_int(name):
	return int(Input.is_action_pressed(name))

func _physics_process(delta: float) -> void:

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	direction = Vector2(
		input_to_int("right") - input_to_int("left"),
		input_to_int("down") - input_to_int("up")
	);

	velocity = direction.normalized() * delta * SPEED
	move_and_slide()
	
func _process(delta: float) -> void:
	if Input.is_action_pressed("right"):
		$AnimatedSprite2D.animation = "movement_right"
	elif Input.is_action_pressed("left"):
		$AnimatedSprite2D.animation = "movement_left"
	elif Input.is_action_pressed("down"):
		$AnimatedSprite2D.animation = "movement_front"
	elif Input.is_action_pressed("up"):
		$AnimatedSprite2D.animation = "movement_back"
	elif direction == Vector2.ZERO:
		$AnimatedSprite2D.animation = "idle"
