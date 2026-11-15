extends Node2D

enum WEAPON { GUN, BOW }
var projectile_texture:Texture2D

@export var type:WEAPON
@export var GUN_TEXTURE:Texture2D
@export var GUN_PROJECTILE_TEXTURE:Texture2D
@export var BOW_TEXTURE:Texture2D
@export var BOW_PROJECTILE_TEXTURE:Texture2D

@export var PROJECTILE:PackedScene

func _ready() -> void:
	if (type == WEAPON.GUN):
		$TextureRect.texture = GUN_TEXTURE
		projectile_texture = GUN_PROJECTILE_TEXTURE
	if (type == WEAPON.BOW):
		$TextureRect.texture = BOW_TEXTURE
		projectile_texture = BOW_PROJECTILE_TEXTURE

var lock_time = 40

func _process(delta:float):
	rotation = 0
	position = Vector2.ZERO
	rotation = -get_local_mouse_position().angle()
	position = Vector2.RIGHT.rotated(rotation) * (50 - lock_time )
	
	if lock_time > 0:
		lock_time -= 1
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		lock_time = 40
		var new_proj = PROJECTILE.instantiate()
		new_proj.get_node("TextureRect").texture = projectile_texture
		new_proj.global_transform = global_transform
		get_tree().current_scene.add_child(new_proj)
