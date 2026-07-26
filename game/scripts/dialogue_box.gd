class_name DialogueBox
extends Panel

## Panel height at the default 100% text scale, exactly matching the
## .tscn's original fixed offsets - grown beyond this only as
## Settings.get_text_scale() rises above 1.0 (issue #32), so a player who
## never touches the text-size setting sees the exact same panel as before.
## Without growth, a bigger font at this fixed height spills dialogue text
## out past the panel's own background/border - confirmed empirically with
## one of the game's longer real lines at max (160%) scale, which needed
## _GROWTH_PER_SCALE_UNIT tuned up once before it stopped clipping the
## line's third wrapped row. Anchored to the bottom edge (see the .tscn's
## anchor_top/anchor_bottom = 1.0), so growing only offset_top keeps the
## panel's bottom edge fixed and extends it upward instead of resizing in
## both directions.
const _BASE_HEIGHT := 62.0
const _GROWTH_PER_SCALE_UNIT := 90.0
const _BOTTOM_MARGIN := -8.0

@onready var _label: Label = $Label
@onready var _sfx: AudioStreamPlayer = $SFX

var _is_open := false


func _ready() -> void:
	visible = false
	_label.add_theme_font_size_override("font_size", Settings.scaled_font_size())
	var extra_scale := maxf(0.0, Settings.get_text_scale() - 1.0)
	offset_bottom = _BOTTOM_MARGIN
	offset_top = _BOTTOM_MARGIN - (_BASE_HEIGHT + _GROWTH_PER_SCALE_UNIT * extra_scale)


func open(text: String) -> void:
	_label.text = text
	visible = true
	_is_open = true
	_sfx.play()


func close() -> void:
	visible = false
	_is_open = false


func is_open() -> bool:
	return _is_open
