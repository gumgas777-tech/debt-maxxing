@tool
@icon("res://addons/health-system/icons/emit_event_action.svg")
class_name EmitEventAction
extends HealthAction
## Sends a named event through [signal HealthComponent.action_event].
## The place to connect an event bus or event channel of your game.

## Name passed to [signal HealthComponent.action_event], e.g. [code]&"boss_enraged"[/code].
@export var event_name: StringName = &""


func execute(health: HealthComponent, context: Dictionary) -> void:
	health.action_event.emit(event_name, context)
