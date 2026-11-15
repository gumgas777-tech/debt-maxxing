@tool
@icon("res://addons/health-system/icons/status_effect_module.svg")
class_name StatusEffectModule
extends Node
## Runs [StatusEffect]s such as poison on an actor. Place it inside the actor.
##
## A [Hitbox2D], [Hitbox3D] or [ApplyStatusEffectAction] adds one on its own when
## the actor has none. All effects end when the actor dies.

signal effect_applied(id: StringName, stacks: int)
signal effect_removed(id: StringName)

## The component the effects work on. Empty finds the one of the actor.
@export var health_component: HealthComponent

var _effects: Dictionary[StringName, ActiveEffect] = {}


class ActiveEffect:
	extends RefCounted

	var effect: StatusEffect
	var stacks: int = 1
	var remaining_time: float
	var time_since_tick: float = 0.0

	func _init(template: StatusEffect) -> void:
		effect = template.duplicate(true)
		remaining_time = effect.duration


func _ready() -> void:
	if Engine.is_editor_hint():
		set_physics_process(false)
		return

	if not get_health():
		push_warning("StatusEffectModule: no HealthComponent found.")
		set_physics_process(false)
		return

	health_component.died.connect(_on_died)


func _get_configuration_warnings() -> PackedStringArray:
	return Hurtbox.get_missing_health_warnings(self, health_component)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(health_component) or not health_component.is_alive:
		return

	for id: StringName in _effects.keys():
		var active: ActiveEffect = _effects.get(id)

		if active == null:
			continue

		var effect := active.effect
		var active_delta := delta

		if effect.duration > 0.0:
			active_delta = minf(delta, active.remaining_time)
			active.remaining_time -= active_delta

		if effect.tick_interval > 0.0:
			active.time_since_tick += active_delta

			while active.time_since_tick >= effect.tick_interval:
				active.time_since_tick -= effect.tick_interval
				effect._on_tick(health_component, active.stacks)

				if _effects.get(id) != active:
					break

		if _effects.get(id) == active and effect.duration > 0.0 and active.remaining_time <= 0.0:
			remove_effect(id)


## Starts [param effect], or refreshes it and adds a stack if it is already active.
## Effects without an id are tracked by [method StatusEffect.get_key].
func apply_effect(effect: StatusEffect) -> void:
	if effect == null or not get_health() or not health_component.is_alive:
		return

	var id := effect.get_key()
	var active: ActiveEffect = _effects.get(id)

	if active == null:
		active = ActiveEffect.new(effect)
		_effects[id] = active

		if active.effect.tag != &"":
			health_component.add_tag(active.effect.tag)
	else:
		active.stacks = mini(active.stacks + 1, maxi(1, active.effect.max_stacks))
		active.remaining_time = active.effect.duration

	active.effect._on_applied(health_component, active.stacks)

	if _effects.get(id) == active:
		effect_applied.emit(id, active.stacks)


## Ends an effect. Takes the id, or the [StatusEffect] that was applied.
func remove_effect(id: Variant) -> void:
	var key := _key_of(id)
	var active: ActiveEffect = _effects.get(key)
	if active == null:
		return

	_effects.erase(key)

	if active.effect.tag != &"":
		health_component.remove_tag(active.effect.tag)

	active.effect._on_removed(health_component)
	effect_removed.emit(key)


## Takes the id, or the [StatusEffect] that was applied.
func has_effect(id: Variant) -> bool:
	return _effects.has(_key_of(id))


## Takes the id, or the [StatusEffect] that was applied. [code]0[/code] if inactive.
func get_stacks(id: Variant) -> int:
	var active: ActiveEffect = _effects.get(_key_of(id))
	return active.stacks if active != null else 0


## The [HealthComponent] the effects work on.
func get_health() -> HealthComponent:
	if not is_instance_valid(health_component):
		health_component = HealthComponent.resolve(self)
	return health_component


## Finds the module that works on [param health] inside its actor.
static func find_for(health: HealthComponent) -> StatusEffectModule:
	var queue: Array[Node] = [health.get_actor()]

	while not queue.is_empty():
		var current: Node = queue.pop_front()

		for child in current.get_children():
			if child is StatusEffectModule and child.get_health() == health:
				return child
			queue.append(child)

	return null


## Finds the module of [param health], or adds one as its child.
static func get_or_create(health: HealthComponent) -> StatusEffectModule:
	var module := find_for(health)

	if module:
		return module

	module = StatusEffectModule.new()
	module.name = "StatusEffects"
	module.health_component = health
	health.add_child(module)
	return module


func _on_died(_info: DamageInfo) -> void:
	for id: StringName in _effects.keys():
		remove_effect(id)


static func _key_of(id: Variant) -> StringName:
	if id is StatusEffect:
		return id.get_key()
	return id
