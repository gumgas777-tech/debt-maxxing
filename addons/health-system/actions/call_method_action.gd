@tool
@icon("res://addons/health-system/icons/call_method_action.svg")
class_name CallMethodAction
extends HealthAction
## Calls a method on a node of the actor. The bridge to the rest of your game
## without a script: show an enrage sprite, start a camera shake, open a door.
##
## Example: [code]target = ^"EnrageSprite"[/code], [code]method = &"show"[/code].
## Properties are set with [code]method = &"set"[/code] and
## [code]arguments = ["modulate", Color.RED][/code].

## Node to call, relative to the actor (the parent of the [HealthComponent]).
## Empty calls the actor itself. Absolute paths and [code]%UniqueName[/code] work too.
@export var target: NodePath = ^""
## Method to call, e.g. [code]show[/code], [code]play[/code], [code]set[/code] or your own.
@export var method: StringName = &""
## Arguments passed to the method.
@export var arguments: Array = []
## Also pass the trigger context as the last argument.
@export var pass_context: bool = false
## Call at the end of the frame. Needed for physics changes, e.g. disabling a
## collision shape from a hit.
@export var deferred: bool = false


func execute(health: HealthComponent, context: Dictionary) -> void:
	var actor := health.get_actor()
	var node := actor if target.is_empty() else actor.get_node_or_null(target)

	if node == null:
		push_warning("CallMethodAction: node '%s' not found." % target)
		return

	if method == &"" or not node.has_method(method):
		push_warning("CallMethodAction: '%s' has no method '%s'." % [node.name, method])
		return

	var call_arguments := arguments.duplicate()
	if pass_context:
		call_arguments.append(context)

	if deferred:
		node.callv.call_deferred(method, call_arguments)
	else:
		node.callv(method, call_arguments)
