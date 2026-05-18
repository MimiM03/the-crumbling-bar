extends Area3D

@onready var markerLeft: Marker3D = $LeftBottleMarker
@onready var markerRight: Marker3D = $RightBottleMarker
@onready var raycast: RayCast3D = $RayCast3D

@export var liquid_mesh_path: NodePath
@export var max_liquid_ml := 750.0

var liquid: LiquidVolume


func _ready() -> void:
	liquid = LiquidVolume.new()
	liquid.max_ml = max_liquid_ml
	liquid.fill_capacity_ml = max_liquid_ml
	liquid.setup(get_node_or_null(liquid_mesh_path) as MeshInstance3D, false)


func pour(delta: float) -> void:
	liquid.pour(delta, raycast)


func get_liquid(amount, composition) -> void:
	liquid.receive(amount, composition)
