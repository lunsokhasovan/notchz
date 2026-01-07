@icon("./Notchz.svg")
@tool
class_name Notchz
extends Control

## Safe area node
##
## Is safe area node that set offsets by manually or
## automatically to ensure fit within safe area or without cutout areas.
## It's useful for build fullscreen mobile games or apps.
## [br][br]
## To use it, just create as a root node or add as a main UI.

enum EXTERNAL_CUTOUTS_PROFILE {
	NONE, ## No cutouts.
	TOP_NOTCH, ## Top screen notch.
	LEFT_SIDE_NOTCH, ## Left side screen notch.
	LEFT_SIDE_CORNER_CUTOUT, ## Left side corner screen cutout.
}

enum SET_FROM_CUTOUTS_MODE {
	OFF, ## Never set by automatically.
	ONCE, ## Set once when node start.
	ALWAYS, ## Always set by automatically.
}

## Set mode for automatic set offsets from cutout areas.
## @deprecated: It was renamed to [member set_from_cutouts_mode]. Use this instead.
var set_from_cutouts: SET_FROM_CUTOUTS_MODE:
	get():
		return set_from_cutouts_mode
	set(x):
		set_from_cutouts_mode = x
		set_from_cutouts = set_from_cutouts_mode

## Set mode for automatic set offsets from cutout areas.
@export var set_from_cutouts_mode: SET_FROM_CUTOUTS_MODE = 2:
	set(x):
		set_from_cutouts_mode = x
		if is_node_ready():
			refresh(set_from_cutouts_mode >= SET_FROM_CUTOUTS_MODE.ONCE)

@export_group("Offsets")

## Set left offset if more than automatically set from cutout areas.
@export_custom(PROPERTY_HINT_NONE, "suffix:px")
var left: float = 0:
	set(x):
		left = maxf(0, x)
		_curret_offsets[0] = left
		refresh()

## Set top offset if more than automatically set from cutout areas.
@export_custom(PROPERTY_HINT_NONE, "suffix:px")
var top: float = 0:
	set(x):
		top = maxf(0, x)
		_curret_offsets[1] = top
		refresh()

## Set right offset if more than automatically set from cutout areas.
@export_custom(PROPERTY_HINT_NONE, "suffix:px")
var right: float = 0:
	set(x):
		right = maxf(0, x)
		_curret_offsets[2] = right
		refresh()

## Set buttom offset if more than automatically set from cutout areas.
@export_custom(PROPERTY_HINT_NONE, "suffix:px")
var buttom: float = 0:
	set(x):
		buttom = maxf(0, x)
		_curret_offsets[3] = buttom
		refresh()

@export_group("External Cutouts")

## Create virtual cutouts of choice for self. Not for any other nodes.
@export
var external_cutouts_profile: EXTERNAL_CUTOUTS_PROFILE \
	= EXTERNAL_CUTOUTS_PROFILE.NONE:
	set(x):
		external_cutouts_profile = x
		if is_node_ready():
			refresh(set_from_cutouts_mode >= SET_FROM_CUTOUTS_MODE.ONCE)

## Create custom virtual cutouts for self. Not for any other nodes.
@export var custom_cutouts: Array[Rect2] = []

## Property for set base [Control]'s offsets.
## Can set by contain [left, top, right, buttom].
## @deprecated: It was private. This old property is unusable.
@onready var curret_offsets: Array = [left, top, right, buttom]

var _curret_offsets: Array = [0, 0, 0, 0]:
	set(x):
		_curret_offsets.resize(3)
		_curret_offsets = x
		offset_left = _curret_offsets[0]
		offset_top = _curret_offsets[1]
		offset_right = - _curret_offsets[2]
		offset_bottom = - _curret_offsets[3]

func _init() -> void:
	layout_mode = 1
	_set_anchors_layout_preset(-1)
	anchor_right = 1
	anchor_bottom = 1
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	mouse_filter = Control.MOUSE_FILTER_PASS

func _ready() -> void:
	refresh(set_from_cutouts_mode >= SET_FROM_CUTOUTS_MODE.ONCE)

func _get_configuration_warnings() -> PackedStringArray:
	var warning: PackedStringArray
	if get_parent() is Container:
		warning.append("Self can't work with Container as parent")
	return warning

func _process(delta: float) -> void:
	if set_from_cutouts_mode == SET_FROM_CUTOUTS_MODE.ALWAYS:
		refresh(true)

## Method of setting offsets.
## It's used by [member set_from_cutouts_mode].
## Can use it rather than set mode of [member set_from_cutouts_mode].
func refresh(able_set_from_cutout: bool = false) -> void:
	
	var new_offsets = [left, top, right, buttom]
	var cutouts: Array[Rect2] = (
		DisplayServer.get_display_cutouts()
		+ custom_cutouts
		+ get_external_cutouts()
	)
	
	if !Engine.is_editor_hint() and able_set_from_cutout:
		for cutout in cutouts:
			# When screen is landscape and not for macOS
			if _is_screen_landscape() and not (OS.get_name() == "macOS"):
				if cutout.position.x >= DisplayServer.window_get_size().x / 3 \
				and cutout.end.x <= DisplayServer.window_get_size().x / 3 * 2:
					if cutout.end.y < DisplayServer.window_get_size().y / 2:
						if cutout.end.y > new_offsets[1]:
							new_offsets[1] = cutout.end.y
					if cutout.end.y > DisplayServer.window_get_size().y / 2:
						var re = DisplayServer.window_get_size().x - cutout.position.x
						if re > new_offsets[3]:
							new_offsets[3] = re
				elif cutout.end.x < DisplayServer.window_get_size().x / 2:
					if cutout.end.x > new_offsets[0]:
						new_offsets[0] = cutout.end.x
				elif cutout.end.x > DisplayServer.window_get_size().x / 2:
					var re = DisplayServer.window_get_size().x - cutout.position.x
					if re > new_offsets[2]:
						new_offsets[2] = re
			# When screen is portrail
			else:
				if cutout.position.y >= DisplayServer.window_get_size().y / 3 \
				and cutout.end.y <= DisplayServer.window_get_size().y / 3 * 2:
					if cutout.end.x < DisplayServer.window_get_size().x / 2:
						if cutout.end.x > new_offsets[0]:
							new_offsets[0] = cutout.end.x
					if cutout.end.x > DisplayServer.window_get_size().x / 2:
						var re = DisplayServer.window_get_size().y - cutout.position.y
						if re > new_offsets[2]:
							new_offsets[2] = re
				elif cutout.end.y < DisplayServer.window_get_size().y / 2:
					if cutout.end.y > new_offsets[1]:
						new_offsets[1] = cutout.end.y
				elif cutout.end.y > DisplayServer.window_get_size().y / 2:
					var re = DisplayServer.window_get_size().y - cutout.position.y
					if re > new_offsets[3]:
						new_offsets[3] = re
	
	_curret_offsets = new_offsets
	
## Return virtual cutouts' [Array][[Rect2]].
## It's used by [member external_cutouts_profile].
func get_external_cutouts(
	profile: EXTERNAL_CUTOUTS_PROFILE = external_cutouts_profile
) -> Array[Rect2]:
	var notch_lenght: float = maxi(
		DisplayServer.window_get_size().x,
		DisplayServer.window_get_size().y,
	) / 20
	match profile:
		EXTERNAL_CUTOUTS_PROFILE.TOP_NOTCH:
			return [Rect2(
				# Position
				Vector2(
					(DisplayServer.window_get_size().x - notch_lenght) / 2,
					0,
				),
				# Size
				Vector2(notch_lenght * 3, notch_lenght)
			)]
		EXTERNAL_CUTOUTS_PROFILE.LEFT_SIDE_NOTCH:
			return [Rect2(
				# Position
				Vector2(
					0,
					(DisplayServer.window_get_size().y - notch_lenght) / 2,
				),
				# Size
				Vector2(notch_lenght, notch_lenght * 3)
			)]
		EXTERNAL_CUTOUTS_PROFILE.LEFT_SIDE_CORNER_CUTOUT:
			return [Rect2(
				# Position
				Vector2(0, 0),
				# Size
				Vector2(notch_lenght, notch_lenght)
			)]
		_:
			return []

func _is_screen_landscape() -> bool:
	return DisplayServer.window_get_size().x > DisplayServer.window_get_size().y
