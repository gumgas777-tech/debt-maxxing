@tool
extends EditorPlugin
## Registers the project settings of the health system.
## The nodes and resources themselves are global classes and need no registration.


func _enter_tree() -> void:
	HealthSystemSettings.register()
