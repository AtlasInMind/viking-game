extends Control

## Remap-keys / text-size settings screen (issue #32), reachable from the
## title screen before any save exists (see title_screen.gd's
## _on_settings_pressed()). Keybind rows are built from Settings.get_actions()
## rather than hand-authored per action, so a future action added to
## Settings._ACTIONS shows up here automatically.

@onready var _rows: VBoxContainer = $Panel/ScrollContainer/VBoxContainer
@onready var _text_scale_value: Label = $Panel/TextScaleRow/ValueLabel
@onready var _text_scale_minus: Button = $Panel/TextScaleRow/MinusButton
@onready var _text_scale_plus: Button = $Panel/TextScaleRow/PlusButton
@onready var _reset_button: Button = $Panel/ResetButton
@onready var _back_button: Button = $Panel/BackButton

var _listening_action := ""
var _key_buttons: Dictionary = {}


func _ready() -> void:
	_text_scale_minus.pressed.connect(_on_text_scale_minus)
	_text_scale_plus.pressed.connect(_on_text_scale_plus)
	_reset_button.pressed.connect(_on_reset_pressed)
	_back_button.pressed.connect(_on_back_pressed)
	_build_rows()
	_refresh_text_scale_label()


func _build_rows() -> void:
	for action in Settings.get_actions():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		var label := Label.new()
		label.text = Settings.get_action_label(action)
		label.custom_minimum_size = Vector2(150, 0)
		label.add_theme_color_override("font_color", Color(1, 1, 1))
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		label.add_theme_constant_override("outline_size", 3)
		row.add_child(label)

		var key_button := Button.new()
		key_button.custom_minimum_size = Vector2(110, 0)
		key_button.text = OS.get_keycode_string(Settings.get_binding(action))
		key_button.pressed.connect(_on_rebind_pressed.bind(action))
		row.add_child(key_button)
		_key_buttons[action] = key_button

		_rows.add_child(row)


func _on_rebind_pressed(action: String) -> void:
	_listening_action = action
	_key_buttons[action].text = "Press a key..."


## Captures the next physical key press while listening, rather than using
## _input()'s normal action-dispatch path - rebinding has to see the raw key
## itself (including keys not yet bound to anything), so it can't go through
## Input.is_action_pressed() the rest of the game uses.
func _unhandled_key_input(event: InputEvent) -> void:
	if _listening_action == "":
		return
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	if key_event.physical_keycode == KEY_ESCAPE:
		_key_buttons[_listening_action].text = OS.get_keycode_string(Settings.get_binding(_listening_action))
		_listening_action = ""
		return

	var action := _listening_action
	var conflict := Settings.find_conflicting_action(key_event.physical_keycode, action)
	if conflict != "":
		_reject_rebind(action, conflict)
		get_viewport().set_input_as_handled()
		return

	Settings.set_binding(action, key_event.physical_keycode)
	_key_buttons[action].text = OS.get_keycode_string(key_event.physical_keycode)
	_listening_action = ""
	get_viewport().set_input_as_handled()


## Shows why the rebind was refused instead of silently doing nothing or
## letting two actions share a key (see Settings.find_conflicting_action()) -
## then reverts the button to its actual current binding after a beat, so
## the message reads as a rejection rather than a new (fake) one.
func _reject_rebind(action: String, conflicting_action: String) -> void:
	_listening_action = ""
	_key_buttons[action].text = "In use by %s" % Settings.get_action_label(conflicting_action)
	await get_tree().create_timer(1.2).timeout
	_key_buttons[action].text = OS.get_keycode_string(Settings.get_binding(action))


func _on_text_scale_minus() -> void:
	Settings.set_text_scale(Settings.get_text_scale() - Settings.TEXT_SCALE_STEP)
	_refresh_text_scale_label()


func _on_text_scale_plus() -> void:
	Settings.set_text_scale(Settings.get_text_scale() + Settings.TEXT_SCALE_STEP)
	_refresh_text_scale_label()


func _refresh_text_scale_label() -> void:
	_text_scale_value.text = "%d%%" % int(round(Settings.get_text_scale() * 100))


func _on_reset_pressed() -> void:
	Settings.reset_all()
	for action in _key_buttons:
		_key_buttons[action].text = OS.get_keycode_string(Settings.get_binding(action))
	_refresh_text_scale_label()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
