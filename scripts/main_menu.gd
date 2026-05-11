extends Control
@onready var panel: Panel = $Panel
@onready var main_buttons: VBoxContainer = $MainButtons
@onready var label: Label = $Label
@onready var options: Control = $Options

func _on_start_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_settings_pressed() -> void:
	panel.visible = false
	main_buttons.visible = false
	label.visible = false
	options.visible = true


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_options_back_pressed() -> void:
	panel.visible = true
	main_buttons.visible = true
	label.visible = true
	options.visible = false
