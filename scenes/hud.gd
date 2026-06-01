extends Control

@onready var unhappy_label: Label = $UnhappyCustomers


func _ready() -> void:
	GameState.unhappy_customers_changed.connect(_update_label)
	_update_label(GameState.unhappy_customers)


func _update_label(count: int) -> void:
	unhappy_label.text = "Unhappy: %d / %d" % [count, GameState.MAX_UNHAPPY_CUSTOMERS]
	if count >= 0.8 * GameState.MAX_UNHAPPY_CUSTOMERS:
		unhappy_label.add_theme_color_override("font_color", Color.RED)
