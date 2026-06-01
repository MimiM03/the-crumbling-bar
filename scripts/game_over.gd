extends Control

@onready var summary_label: Label = $SummaryLabel


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	summary_label.text = "Too many customers left unhappy (%d / %d)." % [
		GameState.unhappy_customers,
		GameState.MAX_UNHAPPY_CUSTOMERS,
	]


func _on_main_menu_pressed() -> void:
	GameState.reset()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
