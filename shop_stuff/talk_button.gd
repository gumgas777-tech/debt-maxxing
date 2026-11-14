extends Button

@onready var textDialog = $"../TextEdit"
var urutan = 0

func _ready():
	urutan = 0
	var button = $"."
	
	button.text = "Talk"
	button.pressed.connect(_button_pressed)

func _button_pressed():
	print(urutan)
	urutan += 1
	if urutan == 1:
		textDialog.text = "Hey there! Care for some items?"
	if urutan == 2:
		textDialog.text = "I remember when I was still in the game... 
the good old days..."
	if urutan == 3:
		textDialog.text = "Spare an old man some change?"
		urutan = 0
