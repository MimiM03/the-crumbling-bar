class_name Hotkey
extends Control

@onready var label: Label = $HBoxContainer/Label as Label
@onready var button: Button = $HBoxContainer/Button as Button

@export var action_name: String = "left"

var _listening: bool = false


func _ready() -> void:
	set_process_input(false)
	set_process_unhandled_input(false)
	set_process_unhandled_key_input(false)
	set_action_name()
	set_text_for_key()


func set_action_name() -> void:
	label.text = "Unassigned"
	match action_name:
		"left":
			label.text = "Move Left"
		"right":
			label.text = "Move Right"
		"forward":
			label.text = "Move Forward"
		"back":
			label.text = "Move Back"
		"pick":
			label.text = "Interact"
		"pour_left":
			label.text = "Pour - Left"
		"pour_right":
			label.text = "Pour - Right"


func set_text_for_key() -> void:
	var action_events := InputMap.action_get_events(action_name)
	if action_events.is_empty():
		button.text = "—"
		return
	var action_event := action_events[0]
	var action_key_code: String
	if action_event is InputEventKey:
		action_key_code = OS.get_keycode_string(action_event.physical_keycode)
	elif action_event is InputEventMouseButton:
		action_key_code = "MB%s" % action_event.button_index
	else:
		action_key_code = str(action_event.as_text())
	button.text = action_key_code


func _on_button_toggled(button_pressed: bool) -> void:
	if button_pressed:
		# Defer so the click / key that opened listen is not consumed as the bind.
		_listening = false
		button.text = "Key or mouse…"
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		call_deferred("_begin_listen")
	else:
		_listening = false
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		set_process_input(false)
		for i in get_tree().get_nodes_in_group("hotkey_button"):
			if i.action_name != self.action_name:
				i.button.toggle_mode = true
				i.set_process_input(false)
				i.set_process_unhandled_key_input(false)
				i.set_process_unhandled_input(false)
		set_text_for_key()


func _begin_listen() -> void:
	if not button.button_pressed:
		return
	_listening = true
	set_process_input(true)
	for i in get_tree().get_nodes_in_group("hotkey_button"):
		if i.action_name != self.action_name:
			i.button.toggle_mode = false
			i.set_process_input(false)
			i.set_process_unhandled_key_input(false)
			i.set_process_unhandled_input(false)


func _input(event: InputEvent) -> void:
	if not _listening:
		return
	if event is InputEventKey:
		if not event.pressed or event.echo:
			return
		if event.physical_keycode == KEY_ESCAPE:
			button.button_pressed = false
			get_viewport().set_input_as_handled()
			return
		_apply_rebind(event)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		if not event.pressed:
			return
		_apply_rebind(event)
		get_viewport().set_input_as_handled()


func _apply_rebind(event: InputEvent) -> void:
	_listening = false
	set_process_input(false)
	var bound := event.duplicate(true) as InputEvent
	if bound is InputEventKey:
		bound.echo = false
	InputMap.action_erase_events(action_name)
	InputMap.action_add_event(action_name, bound)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.button_pressed = false
	set_text_for_key()
	set_action_name()
