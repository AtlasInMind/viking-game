extends Control

## Basic on-screen movement/interact controls for mobile browsers (issue
## #32) - a D-pad plus one interact button, both driving the exact same
## Godot input actions (game/scripts/settings.gd) keyboard/remapping already
## use, via Input.action_press()/action_release(). player.gd/main.gd/
## ship.gd never need to know whether an action came from a key or a touch.
##
## Only shown when a touchscreen is actually present
## (DisplayServer.is_touchscreen_available()) - desktop/mouse-only play
## never sees this overlay.

@onready var _up: Button = $DPad/Up
@onready var _down: Button = $DPad/Down
@onready var _left: Button = $DPad/Left
@onready var _right: Button = $DPad/Right
@onready var _interact: Button = $InteractButton


func _ready() -> void:
	visible = DisplayServer.is_touchscreen_available()
	_wire(_up, "move_up")
	_wire(_down, "move_down")
	_wire(_left, "move_left")
	_wire(_right, "move_right")
	_wire(_interact, "interact")


## button_down/button_up (not the "pressed" signal, which only fires once on
## release-inside-bounds) mirror a physical key's own press/release timing,
## so holding a D-pad button moves continuously the same way holding an
## arrow key does.
func _wire(button: Button, action: String) -> void:
	button.button_down.connect(func(): Input.action_press(action))
	button.button_up.connect(func(): Input.action_release(action))
