@tool
@icon("res://addons/health-system/icons/health_bar.svg")
class_name HealthBar
extends ProgressBar
## Shows the health of a [HealthComponent].
##
## Assign [member health], or leave it empty: the bar then uses the component of
## the actor it sits in, or the one of the first node in [member target_group].
## So a HUD in its own scene shows the player's health with
## [code]target_group = "player"[/code] and no script.
## [br][br]
## Styles come from your theme. The damage trail uses the theme type variation
## [code]HealthBarDamageDelay[/code], based on [ProgressBar].

## The component to show. Can be changed at runtime.
@export var health: HealthComponent:
	set(value):
		if health == value:
			return

		_unbind()
		health = value

		if _started:
			_bind()

## Group to take the component from when [member health] is empty, e.g.
## [code]player[/code]. The bar waits until a member exists and moves on to the
## next one when the current one is freed.
@export var target_group: StringName = &""

## Animate health changes over [member animation_duration].
@export var animate: bool = true:
	set(enabled):
		animate = enabled
		if _started and not enabled:
			_sync_health()

## Show a trail that follows damage after [member damage_delay].
@export var show_damage_delay: bool = false:
	set(enabled):
		show_damage_delay = enabled
		if _started:
			_update_delay_enabled()

## Hide the bar while health is full.
@export var hide_when_full: bool = false:
	set(enabled):
		hide_when_full = enabled
		if _started:
			if enabled:
				_update_visibility()
			else:
				show()

## Seconds the fill takes to reach a new value.
@export_range(0.0, 5.0, 0.01) var animation_duration: float = 0.2
## Seconds the damage trail waits before it follows.
@export_range(0.0, 5.0, 0.01) var damage_delay: float = 0.35
## Seconds the damage trail takes to catch up.
@export_range(0.0, 5.0, 0.01) var damage_delay_duration: float = 0.6

var _delay_bar: ProgressBar
var _tween: Tween
var _saved_background: StyleBox
var _started: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(false)
		return

	min_value = 0.0
	step = 0.0
	_started = true

	if is_instance_valid(health):
		_bind()
	else:
		health = _find_health()

	if not is_instance_valid(health) and target_group == &"":
		push_warning("HealthBar: no HealthComponent found.")
		set_process(false)


func _get_configuration_warnings() -> PackedStringArray:
	if health or target_group != &"" or HealthComponent.resolve(self):
		return PackedStringArray()

	return PackedStringArray(
		["No HealthComponent found. Assign health, set target_group or place the bar in the actor."]
	)


func _process(_delta: float) -> void:
	if not is_instance_valid(health):
		_stop_animation()

		if target_group == &"":
			set_process(false)
			return

		health = _find_in_group()
		return

	if _delay_bar:
		_delay_bar.fill_mode = fill_mode
		_delay_bar.layout_direction = layout_direction


func _bind() -> void:
	if not is_instance_valid(health):
		return

	health.health_changed.connect(_on_health_changed)
	health.max_health_changed.connect(_on_max_health_changed)
	health.revived.connect(_sync_health)

	if not health.is_node_ready():
		health.ready.connect(_sync_health, CONNECT_ONE_SHOT)

	_update_delay_enabled()


func _unbind() -> void:
	if not is_instance_valid(health):
		return

	for connection in [
		[health.health_changed, _on_health_changed],
		[health.max_health_changed, _on_max_health_changed],
		[health.revived, _sync_health],
		[health.ready, _sync_health],
	]:
		var health_signal: Signal = connection[0]
		if health_signal.is_connected(connection[1]):
			health_signal.disconnect(connection[1])


func _find_health() -> HealthComponent:
	if target_group != &"":
		return _find_in_group()

	return HealthComponent.resolve(self)


func _find_in_group() -> HealthComponent:
	if not is_inside_tree():
		return null

	for node in get_tree().get_nodes_in_group(target_group):
		var found: HealthComponent = node if node is HealthComponent else HealthComponent.find(node)
		if found:
			return found

	return null


func _sync_health() -> void:
	if not is_instance_valid(health):
		return

	_stop_animation()

	max_value = health.max_health
	value = health.current_health

	if _delay_bar:
		_delay_bar.max_value = max_value
		_delay_bar.value = value

	_update_visibility()


func _update_visibility() -> void:
	if hide_when_full and is_instance_valid(health):
		visible = health.current_health < health.max_health


func _on_max_health_changed(_old_value: float, _new_value: float) -> void:
	_sync_health()


func _on_health_changed(old_value: float, new_value: float) -> void:
	_stop_animation()
	max_value = health.max_health

	if animate and health.is_node_ready() and animation_duration > 0.0:
		_tween = create_tween().set_parallel(true)
		_tween.tween_property(self, "value", new_value, animation_duration)
	else:
		value = new_value

	_update_visibility()

	if not _delay_bar:
		return

	var took_damage := new_value < old_value
	var wait_time := animation_duration if animate else 0.0

	_delay_bar.max_value = max_value

	if took_damage:
		_delay_bar.value = maxf(_delay_bar.value, maxf(old_value, value))
		wait_time = maxf(damage_delay, wait_time)
	else:
		_delay_bar.value = maxf(new_value, value)

	if not _tween:
		_tween = create_tween()

	_tween.tween_property(_delay_bar, "value", new_value, damage_delay_duration).set_delay(
		wait_time
	)


func _stop_animation() -> void:
	if _tween:
		_tween.kill()
		_tween = null


func _update_delay_enabled() -> void:
	if not is_instance_valid(health):
		return

	if show_damage_delay and not _delay_bar:
		_delay_bar = ProgressBar.new()
		_delay_bar.name = "DamageDelay"
		_delay_bar.show_percentage = false
		_delay_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_delay_bar.show_behind_parent = true
		_delay_bar.step = 0.0
		_delay_bar.theme_type_variation = &"HealthBarDamageDelay"
		add_child(_delay_bar)

		_delay_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

		if has_theme_stylebox_override("background"):
			_saved_background = get_theme_stylebox("background")
			_delay_bar.add_theme_stylebox_override("background", _saved_background)

		add_theme_stylebox_override("background", StyleBoxEmpty.new())
	elif not show_damage_delay and _delay_bar:
		if _saved_background:
			add_theme_stylebox_override("background", _saved_background)
		else:
			remove_theme_stylebox_override("background")

		_saved_background = null
		remove_child(_delay_bar)

		_delay_bar.queue_free()
		_delay_bar = null

	_sync_health()
