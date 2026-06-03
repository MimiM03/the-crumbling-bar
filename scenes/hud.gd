extends Control

@onready var unhappy_label: Label = $UnhappyCustomers
@onready var controls_overlay: VBoxContainer = $VBoxContainer
@onready var tab_label: Label = $HBoxContainer/Label

var show_controls := false

func _ready() -> void:
	GameState.unhappy_customers_changed.connect(_update_label)
	_update_label(GameState.unhappy_customers)
	

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("show_controls"):
		show_controls = !show_controls
		controls_overlay.visible = show_controls
		if show_controls:
			tab_label.text = "Hide Controls"
		else:
			tab_label.text = "Show Controls"
			

func _update_label(count: int) -> void:
	unhappy_label.text = "Unhappy: %d / %d" % [count, GameState.MAX_UNHAPPY_CUSTOMERS]
	if count >= 0.8 * GameState.MAX_UNHAPPY_CUSTOMERS:
		unhappy_label.add_theme_color_override("font_color", Color.RED)
