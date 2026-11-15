@tool
@icon("res://addons/health-system/icons/health_component.svg")
class_name HealthComponent
extends Node
## Stores the health of one actor and runs every hit and heal through the modifier pipeline.
##
## Add it as a child of the actor. Everything else, such as armor, loot drops and
## i-frames, is configured through a [HealthProfile] in the inspector.
## [br][br]
## The component works before it enters the tree as well: the first call that needs
## the health value sets it up from the profile.

signal tag_added(tag: StringName)
signal tag_removed(tag: StringName)
signal modifier_added(modifier: HealthModifier)
signal modifier_removed(modifier: HealthModifier)
signal action_added(action: HealthAction)
signal action_removed(action: HealthAction)
## Sent by [EmitEventAction]. Connect your event bus here.
signal action_event(event_name: StringName, context: Dictionary)
signal threshold_crossed(threshold: float, going_down: bool)
signal health_changed(old_value: float, new_value: float)
signal max_health_changed(old_value: float, new_value: float)
signal damaged(info: DamageInfo, result: DamageResult)
signal healed(info: HealInfo, result: DamageResult)
signal died(info: DamageInfo)
signal revived

## Tag that is set while [method grant_invincibility] protects the actor.
const INVINCIBLE_TAG := &"invincible"

## Describes this actor type: max health, start health, thresholds, default
## modifiers and actions. Takes precedence over [member max_health].
@export var health_profile: HealthProfile:
	set(value):
		health_profile = value
		notify_property_list_changed()

## Maximum health, used when no [member health_profile] is set. Lowering it at
## runtime also lowers the current health.
@export var max_health: float = 100.0:
	set(value):
		var old_max := max_health
		max_health = maxf(value, 0.0)

		if old_max == max_health:
			return

		max_health_changed.emit(old_max, max_health)

		if _initialized and _health > max_health:
			current_health = max_health

## The current health. Setting it follows the same rules as a hit: reaching 0
## kills the actor, and a value above 0 revives a dead one.
var current_health: float:
	get:
		_ensure_initialized()
		return _health
	set(value):
		_ensure_initialized()

		if not is_alive and value > 0.0:
			_revive_to(value)
			return

		_set_health(value)

		if _death_pending:
			_die(DamageInfo.new())

## [code]false[/code] after death until [method revive].
var is_alive: bool = true

var _health: float = 0.0
var _initialized: bool = false
var _initializing: bool = false
var _death_pending: bool = false

var _tags: Dictionary[StringName, int] = {}
var _modifiers: Array[HealthModifier] = []
var _modifier_timers: Dictionary[HealthModifier, SceneTreeTimer] = {}
var _pending_durations: Dictionary[HealthModifier, float] = {}
var _invincibility: BlockAllDamageModifier

var _actions: Array[HealthAction] = []


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_ensure_initialized()

	for modifier in _pending_durations:
		if _modifiers.has(modifier):
			_start_modifier_timer(modifier, _pending_durations[modifier])

	_pending_durations.clear()


func _validate_property(property: Dictionary) -> void:
	if property.name == "max_health" and health_profile:
		property.usage = PROPERTY_USAGE_NO_EDITOR


## Deals [param amount] damage of [param type]. Shortcut for [method apply_damage].
func damage(amount: float, source: Node = null, type: StringName = &"generic") -> DamageResult:
	return apply_damage(DamageInfo.new(amount, source, type))


## Heals [param amount] of [param type]. Shortcut for [method apply_heal].
func heal(amount: float, source: Node = null, type: StringName = &"generic") -> DamageResult:
	return apply_heal(HealInfo.new(amount, source, type))


## Runs a copy of [param info] through the modifiers and subtracts the result.
## [param info] itself stays unchanged, so it can be reused for several targets.
## The signals and actions receive the modified copy.
func apply_damage(info: DamageInfo) -> DamageResult:
	_ensure_initialized()
	var result := DamageResult.new()

	if info == null or not is_alive:
		result.was_blocked = true
		return result

	var hit := info.copy()
	var incoming := hit.amount

	for modifier in _modifiers.duplicate():
		modifier.modify_damage(hit, self)

	hit.amount = maxf(hit.amount, 0.0)

	result.final_amount = hit.amount
	result.blocked_amount = maxf(incoming - hit.amount, 0.0)
	result.overkill = maxf(hit.amount - _health, 0.0)

	_set_health(_health - hit.amount)

	damaged.emit(hit, result)
	_run_actions(HealthAction.Trigger.ON_DAMAGED, {"info": hit, "result": result})

	if _death_pending:
		result.was_lethal = true
		_die(hit)

	return result


## Runs a copy of [param info] through the modifiers and adds the result.
## Dead actors cannot be healed, use [method revive].
func apply_heal(info: HealInfo) -> DamageResult:
	_ensure_initialized()
	var result := DamageResult.new()

	if info == null or not is_alive:
		result.was_blocked = true
		return result

	var heal_info := info.copy()
	var incoming := heal_info.amount

	for modifier in _modifiers.duplicate():
		modifier.modify_heal(heal_info, self)

	heal_info.amount = maxf(heal_info.amount, 0.0)

	result.final_amount = heal_info.amount
	result.blocked_amount = maxf(incoming - heal_info.amount, 0.0)
	result.overkill = maxf(_health + heal_info.amount - max_health, 0.0)

	_set_health(_health + heal_info.amount)

	healed.emit(heal_info, result)
	_run_actions(HealthAction.Trigger.ON_HEALED, {"info": heal_info, "result": result})

	return result


## Sets health to 0 and runs the death, regardless of modifiers.
func kill() -> void:
	_ensure_initialized()

	if not is_alive:
		return

	_set_health(0.0)

	if _death_pending:
		_die(DamageInfo.new())


## Brings a dead actor back with [param health_percent] of [member max_health].
## Does nothing while the actor is alive or when the percentage is 0.
func revive(health_percent := 100.0) -> void:
	_ensure_initialized()

	if is_alive:
		return

	_revive_to(max_health / 100 * health_percent)


## The node this component belongs to: its parent, or the component itself when
## it has none. Actions use it to find the nodes they work on.
func get_actor() -> Node:
	var actor := get_parent()
	return actor if actor else self


## Health in percent of [member max_health], from 0 to 100.
func get_health_percent() -> float:
	_ensure_initialized()

	if max_health <= 0.0:
		return 0.0

	return 100 / max_health * _health


## Blocks all damage for [param duration] seconds and sets the [code]invincible[/code]
## tag while it lasts. Granting it again while active extends it when the new
## duration is longer.
func grant_invincibility(duration: float) -> void:
	if duration <= 0.0:
		return

	if _invincibility == null:
		_invincibility = BlockAllDamageModifier.new()
		_invincibility.resource_name = "Invincibility"

	if _modifiers.has(_invincibility):
		add_modifier(_invincibility, duration)
		return

	add_tag(INVINCIBLE_TAG)
	add_modifier(_invincibility, duration)


## [code]true[/code] while [method grant_invincibility] protects the actor.
func is_invincible() -> bool:
	return _invincibility != null and _modifiers.has(_invincibility)


func add_tag(tag: StringName) -> void:
	_tags[tag] = _tags.get(tag, 0) + 1

	if _tags[tag] == 1:
		tag_added.emit(tag)


func remove_tag(tag: StringName) -> void:
	if not _tags.has(tag):
		return

	_tags[tag] -= 1

	if _tags[tag] <= 0:
		_tags.erase(tag)
		tag_removed.emit(tag)


func has_tag(tag: StringName) -> bool:
	return _tags.has(tag)


func get_tags() -> Array[StringName]:
	var tags: Array[StringName] = []
	tags.assign(_tags.keys())
	return tags


## Adds [param modifier] to the pipeline. With a [param duration] it removes
## itself after that many seconds; the timer stops while the game is paused.
## [br][br]
## Adding a modifier that is already active refreshes it: a timed one runs for
## [param duration] again if that ends later, and [code]0[/code] makes it permanent.
func add_modifier(modifier: HealthModifier, duration: float = 0.0) -> void:
	if modifier == null:
		return

	if _modifiers.has(modifier):
		_refresh_modifier(modifier, duration)
		return

	_modifiers.append(modifier)
	_sort_modifiers()

	if duration > 0.0:
		_start_modifier_timer(modifier, duration)

	modifier_added.emit(modifier)


func remove_modifier(modifier: HealthModifier) -> void:
	if not _modifiers.has(modifier):
		return

	_modifiers.erase(modifier)
	_modifier_timers.erase(modifier)
	_pending_durations.erase(modifier)
	modifier_removed.emit(modifier)

	if modifier == _invincibility:
		remove_tag(INVINCIBLE_TAG)


func get_modifiers() -> Array[HealthModifier]:
	return _modifiers.duplicate()


func add_action(action: HealthAction) -> void:
	if action == null or _actions.has(action):
		return

	_actions.append(action)
	action_added.emit(action)


func remove_action(action: HealthAction) -> void:
	if not _actions.has(action):
		return

	_actions.erase(action)
	action_removed.emit(action)


## All actions of this component, including the copies made from the profile.
func get_actions() -> Array[HealthAction]:
	_ensure_initialized()
	return _actions.duplicate()


## @deprecated: Use [method get_actions].
func get_action() -> Array[HealthAction]:
	return get_actions()


## Creates a [SceneTreeTimer] that stops while the game is paused, unless this
## component keeps running during pause ([constant Node.PROCESS_MODE_ALWAYS]).
## Actions and modules use it for every delay.
func create_timer(duration: float) -> SceneTreeTimer:
	return get_tree().create_timer(duration, _runs_while_paused())


## Finds the [HealthComponent] inside [param node]: first among its children,
## then further down the tree, nearest first. Use it on the actor you hit.
## With [param recursive] set to [code]false[/code] only direct children count.
static func find(node: Node, recursive: bool = true) -> HealthComponent:
	if node == null:
		return null

	var queue: Array[Node] = [node]

	while not queue.is_empty():
		var current: Node = queue.pop_front()

		for child in current.get_children():
			if child is HealthComponent:
				return child

		if not recursive:
			return null

		queue.append_array(current.get_children())

	return null


## Finds the [HealthComponent] of the actor that [param node] belongs to, e.g.
## from a hurtbox on a bone or a module next to the component.
## [br][br]
## Walks up from [param node] and checks the children of every ancestor. It stops
## at the actor: the first physics body, or the root of the scene [param node]
## belongs to. There it also looks into plain [Node] folders such as
## [code]Components[/code].
static func resolve(node: Node) -> HealthComponent:
	var current := node

	while current:
		var found := find(current, false)

		if found:
			return found

		if current is PhysicsBody2D or current is PhysicsBody3D or current == node.owner:
			return _find_in_folders(current)

		current = current.get_parent()

	return null


func _ensure_initialized() -> void:
	if _initialized or _initializing or Engine.is_editor_hint():
		return

	_initializing = true
	var start_percent := 100.0

	if health_profile:
		max_health = health_profile.max_health
		start_percent = health_profile.start_health_percent

		var profile_modifiers: Array[HealthModifier] = []
		for modifier in health_profile.default_modifiers:
			if modifier:
				profile_modifiers.append(modifier.duplicate(true))

		_modifiers.append_array(profile_modifiers)
		_sort_modifiers()

		var profile_actions: Array[HealthAction] = []
		for action in health_profile.actions:
			if action:
				profile_actions.append(action.duplicate(true))

		_actions = profile_actions + _actions

	_set_health(max_health / 100 * start_percent)
	is_alive = _health > 0.0
	_initialized = true
	_initializing = false


func _set_health(value: float) -> void:
	var old_health := _health
	_health = clampf(value, 0.0, max_health)

	# is_alive flips before health_changed, so listeners already see the death.
	# The caller emits died afterwards through _die().
	if _health <= 0.0 and is_alive and _initialized:
		is_alive = false
		_death_pending = true

	if old_health == _health:
		return

	health_changed.emit(old_health, _health)
	_check_thresholds(old_health, _health)


func _die(info: DamageInfo) -> void:
	_death_pending = false
	is_alive = false
	died.emit(info)
	_run_actions(HealthAction.Trigger.ON_DEATH, {"info": info})


func _revive_to(value: float) -> void:
	if value <= 0.0:
		return

	_death_pending = false
	is_alive = true
	_set_health(value)
	revived.emit()
	_run_actions(HealthAction.Trigger.ON_REVIVE, {})


func _check_thresholds(old_health: float, new_health: float) -> void:
	if not health_profile or not _initialized or max_health <= 0.0:
		return

	var old_percent := 100 / max_health * old_health
	var new_percent := 100 / max_health * new_health

	for threshold in health_profile.thresholds:
		if old_percent > threshold and new_percent <= threshold:
			threshold_crossed.emit(threshold, true)
			_run_actions(
				HealthAction.Trigger.ON_THRESHOLD, {"threshold": threshold, "going_down": true}
			)
		elif old_percent <= threshold and new_percent > threshold:
			threshold_crossed.emit(threshold, false)
			_run_actions(
				HealthAction.Trigger.ON_THRESHOLD, {"threshold": threshold, "going_down": false}
			)


func _refresh_modifier(modifier: HealthModifier, duration: float) -> void:
	if _pending_durations.has(modifier):
		if duration <= 0.0:
			_pending_durations.erase(modifier)
		else:
			_pending_durations[modifier] = maxf(_pending_durations[modifier], duration)
		return

	var timer: SceneTreeTimer = _modifier_timers.get(modifier)

	if timer == null:
		return

	if duration <= 0.0:
		_modifier_timers.erase(modifier)
	elif duration > timer.time_left:
		_start_modifier_timer(modifier, duration)


func _start_modifier_timer(modifier: HealthModifier, duration: float) -> void:
	if not is_inside_tree():
		_pending_durations[modifier] = duration
		return

	var timer := create_timer(duration)
	_modifier_timers[modifier] = timer
	timer.timeout.connect(_on_modifier_expired.bind(modifier, timer))


func _on_modifier_expired(modifier: HealthModifier, timer: SceneTreeTimer) -> void:
	if _modifier_timers.get(modifier) != timer:
		return

	remove_modifier(modifier)


func _sort_modifiers() -> void:
	_modifiers.sort_custom(
		func(a: HealthModifier, b: HealthModifier): return a.priority < b.priority
	)


func _run_actions(trigger: HealthAction.Trigger, context: Dictionary) -> void:
	if _actions.is_empty():
		return

	for action in _actions.duplicate():
		if action.trigger == trigger and action.should_execute(self, context):
			action.execute(self, context)


func _runs_while_paused() -> bool:
	var node: Node = self

	while node:
		match node.process_mode:
			PROCESS_MODE_ALWAYS, PROCESS_MODE_WHEN_PAUSED:
				return true
			PROCESS_MODE_PAUSABLE, PROCESS_MODE_DISABLED:
				return false

		node = node.get_parent()

	return false


static func _find_in_folders(node: Node) -> HealthComponent:
	var queue: Array[Node] = [node]

	while not queue.is_empty():
		var current: Node = queue.pop_front()

		for child in current.get_children():
			if child is HealthComponent and current != node:
				return child
			if not (child is CanvasItem or child is Node3D):
				queue.append(child)

	return null
