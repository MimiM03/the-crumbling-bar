extends Control

@onready var main_buttons: VBoxContainer = $MainButtons
@onready var label: Label = $Label
@onready var options: Control = $Options

func _input(event):
	# Handle mouse visibility in game
	if event.is_action_pressed("mouse_vis"):
		if get_tree().paused:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			get_tree().paused = false
			visible = false
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_tree().paused = true
			visible = true
			
func _on_resume_pressed() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().paused = false
	visible = false


func _on_settings_pressed() -> void:
	main_buttons.visible = false
	label.visible = false
	options.visible = true


func _on_back_to_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_options_back_pressed() -> void:
	main_buttons.visible = true
	label.visible = true
	options.visible = false
