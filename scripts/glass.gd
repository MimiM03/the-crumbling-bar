extends Area3D

@onready var markerLeft: Marker3D = $LeftMarker
@onready var markerRight: Marker3D = $RightMarker
@onready var raycast: RayCast3D = $RayCast3D

@export var liquid_mesh_path: NodePath
@export var max_liquid_ml := 375.0

var liquid: LiquidVolume


func _ready() -> void:
	liquid = LiquidVolume.new()
	liquid.max_ml = max_liquid_ml
	liquid.fill_capacity_ml = max_liquid_ml
	liquid.setup(get_node_or_null(liquid_mesh_path) as MeshInstance3D, true)


func pour(delta: float) -> void:
	liquid.pour(delta, raycast)


func get_liquid(amount, composition) -> void:
	liquid.receive(amount, composition)
