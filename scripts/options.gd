extends Control

@onready var mouse_sens_slider: HSlider = $VBoxContainer/VBoxContainer2/HBoxContainer/HSlider
@onready var button: Button = $Button3
@onready var label: Label = $Label2
@onready var v_box_container: VBoxContainer = $VBoxContainer
@onready var controls: Panel = $Controls

signal back_pressed
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mouse_sens_slider.value = Settings.mouse_sens
	controls.visible = false


func _on_back_pressed() -> void:
	back_pressed.emit()

func _on_mouse_sens_changed(value: float) -> void:
	Settings.mouse_sens = value


func _on_controls_pressed() -> void:
	button.visible = false
	label.visible = false
	v_box_container.visible = false
	controls.visible = true


func _on_back_controls_pressed() -> void:
	button.visible = true
	label.visible = true
	v_box_container.visible = true
	controls.visible = false
