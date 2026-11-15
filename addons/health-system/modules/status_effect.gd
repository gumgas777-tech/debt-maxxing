@tool
@icon("res://addons/health-system/icons/status_effect.svg")
class_name StatusEffect
extends Resource
## Base class for timed effects such as poison or a heal over time.
##
## A [StatusEffectModule] runs them. Applying an effect that is already active
## refreshes its duration and adds a stack, up to [member max_stacks].
## Override [method _on_applied], [method _on_tick] and [method _on_removed].

## Effects with the same id count as one effect and stack. Empty treats every
## [code].tres[/code] file, or every effect created in code, as its own effect.
@export var id: StringName = &""
## Seconds the effect lasts. [code]0[/code] keeps it until it is removed.
@export var duration: float = 5.0
## Seconds between two ticks. [code]0[/code] disables ticking.
@export var tick_interval: float = 1.0
## How often the effect can stack. Damage and healing scale with the stacks.
@export var max_stacks: int = 1
## Tag set on the [HealthComponent] while the effect is active, e.g. [code]poisoned[/code].
@export var tag: StringName = &""


## The key the effect is tracked under: [member id], or the resource path when
## the id is empty, or a key unique to this instance.
func get_key() -> StringName:
	if id != &"":
		return id
	if not resource_path.is_empty():
		return StringName(resource_path)
	return StringName("effect_%d" % get_instance_id())


## Called when the effect is applied, also again for every new stack.
func _on_applied(_health: HealthComponent, _stacks: int) -> void:
	pass


## Called every [member tick_interval] seconds.
func _on_tick(_health: HealthComponent, _stacks: int) -> void:
	pass


## Called when the effect runs out, is removed or the actor dies.
func _on_removed(_health: HealthComponent) -> void:
	pass
