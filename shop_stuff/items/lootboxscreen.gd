extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

var probabilities = [0, 0, 0, 0]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if $Timer.time_left > 0:
		var display_time = round($Timer.time_left * 10)/10
		$Label.text = "Opening in " + str(display_time) + "s..."
	
func cinematic() -> void:
	$"../Control".visible = false
	visible = true
	$Timer.start()

@export var common_texture:Texture2D
func _on_common_pressed() -> void:
	$TextureRect.texture = common_texture
	probabilities = [0.8, 0.15, 0.05, 0]
	cinematic()

@export var rare_texture:Texture2D
func _on_rare_pressed() -> void:
	$TextureRect.texture = rare_texture
	probabilities = [0.6, 0.25, 0.1, 0.05]
	cinematic()

@export var epic_texture:Texture2D
func _on_epic_pressed() -> void:
	$TextureRect.texture = epic_texture
	probabilities = [0.3, 0.4, 0.2, 0.1]
	cinematic()

@export var legendary_texture:Texture2D
func _on_legendary_pressed() -> void:
	$TextureRect.texture = legendary_texture
	probabilities = [0.05, 0.3, 0.4, 0.25]
	cinematic()

func _on_timer_timeout() -> void:
	var rng = RandomNumberGenerator.new()
	var rarity = ["common", "rare", "epic", "legendary"][rng.rand_weighted(probabilities)]
	var options = Global.loot_table[rarity]
	
