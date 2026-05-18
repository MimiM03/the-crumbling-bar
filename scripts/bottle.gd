extends Area3D

@export var liquid_mesh_path: NodePath
@export var bottle_capacity := 900.0
@export var max_liquid_ml := 750.0

@onready var raycast: RayCast3D = $RayCast3D

var liquid: LiquidVolume


func _ready() -> void:
	liquid = LiquidVolume.new()
	liquid.max_ml = max_liquid_ml
	liquid.fill_capacity_ml = bottle_capacity
	liquid.current_ml = max_liquid_ml
	var drink_id := _get_drink_id()
	if drink_id != "":
		liquid.amount_per_drink_type[drink_id] = max_liquid_ml
	liquid.setup(get_node_or_null(liquid_mesh_path) as MeshInstance3D, false)


func pour(delta: float) -> void:
	liquid.pour(delta, raycast)


func get_liquid(amount, composition) -> void:
	liquid.receive(amount, composition)


func _get_drink_id() -> String:
	for g in get_groups():
		if g != "juice" and g != "pickables":
			return g
	return ""
