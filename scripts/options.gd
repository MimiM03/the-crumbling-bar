extends Control

@onready var mouse_sens_slider: HSlider = $VBoxContainer/VBoxContainer2/HBoxContainer/HSlider
@onready var master_slider: HSlider = $VBoxContainer/VBoxContainer/MasterVolume/HSlider
@onready var music_slider: HSlider = $VBoxContainer/VBoxContainer/MusicVolume/HSlider
@onready var sfx_slider: HSlider = $VBoxContainer/VBoxContainer/SFXVolume/HSlider
@onready var button: Button = $Button3
@onready var label: Label = $Label2
@onready var v_box_container: VBoxContainer = $VBoxContainer
@onready var controls: Panel = $Controls

signal back_pressed
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mouse_sens_slider.value = Settings.mouse_sens
	
	master_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")))
	sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))
	
	controls.visible = false

func _on_master_slider_value_changed(value: float) -> void:
	print("master slider changed: ", value)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))

func _on_music_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))

func _on_sfx_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(value))

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
