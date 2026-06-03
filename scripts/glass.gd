extends Area3D

const POUR_METER_SCENE := preload("res://scenes/pour_meter.tscn")

@onready var markerLeft: Marker3D = $LeftMarker
@onready var markerRight: Marker3D = $RightMarker
@onready var raycast: RayCast3D = $RayCast3D

@export var liquid_mesh_path: NodePath
@export var max_liquid_ml := 375.0
@export var pour_meter_offset := Vector3(0, 0.45, 0)

var liquid: LiquidVolume
var _pour_meter: Sprite3D


func _ready() -> void:
	liquid = LiquidVolume.new()
	liquid.max_ml = max_liquid_ml
	liquid.fill_capacity_ml = max_liquid_ml
	liquid.setup(get_node_or_null(liquid_mesh_path) as MeshInstance3D, true)
	_pour_meter = POUR_METER_SCENE.instantiate()
	add_child(_pour_meter)
	_pour_meter.position = pour_meter_offset
	_pour_meter.hide_meter()


func pour(delta: float) -> void:
	liquid.pour(delta, raycast)


func get_liquid(amount, composition) -> void:
	liquid.receive(amount, composition)
	refresh_pour_meter()


func show_pour_meter() -> void:
	if _pour_meter:
		_pour_meter.show_for_liquid(liquid)


func hide_pour_meter() -> void:
	if _pour_meter:
		_pour_meter.hide_meter()


func refresh_pour_meter() -> void:
	if _pour_meter and _pour_meter.visible:
		_pour_meter.show_for_liquid(liquid)
