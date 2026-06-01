extends Node

signal unhappy_customers_changed(count: int)
signal game_over

const MAX_UNHAPPY_CUSTOMERS := 10

var unhappy_customers := 0
var is_game_over := false


func reset() -> void:
	unhappy_customers = 0
	is_game_over = false


func register_unhappy_customers(count: int = 1) -> void:
	if is_game_over or count <= 0:
		return

	unhappy_customers += count
	unhappy_customers_changed.emit(unhappy_customers)
	print("Unhappy customers: %d / %d" % [unhappy_customers, MAX_UNHAPPY_CUSTOMERS])

	if unhappy_customers > MAX_UNHAPPY_CUSTOMERS:
		_trigger_game_over()


func _trigger_game_over() -> void:
	if is_game_over:
		return

	is_game_over = true
	game_over.emit()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/game_over.tscn")
