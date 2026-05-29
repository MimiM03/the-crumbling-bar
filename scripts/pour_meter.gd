extends Sprite3D

@onready var _viewport: SubViewport = $SubViewport
@onready var _bar: ProgressBar = $SubViewport/VBoxContainer/ProgressBar
@onready var _label: Label = $SubViewport/VBoxContainer/Label


func _ready() -> void:
	texture = _viewport.get_texture()
	hide_meter()


func show_for_liquid(liquid: LiquidVolume) -> void:
	if liquid == null:
		hide_meter()
		return
	visible = true
	_bar.max_value = maxf(liquid.fill_capacity_ml, 1.0)
	_bar.value = liquid.current_ml
	_label.text = "%d / %d ml" % [int(round(liquid.current_ml)), int(round(liquid.fill_capacity_ml))]


func hide_meter() -> void:
	visible = false
