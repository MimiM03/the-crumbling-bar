extends Area3D

@onready var raycast:= $RayCast3D
@export var liquid_mesh_path: NodePath
@export var bottle_capacity := 900.0
@export var max_liquid_ml := 750.0
var current_ml := 750.0
var pour_rate = 15.0 # ~~ ml per sec
var group = null
var liquid_material: ShaderMaterial

func _ready() -> void:
	group = get_drink_type()
	if liquid_mesh_path != NodePath():
		var mesh_instance := get_node_or_null(liquid_mesh_path) as MeshInstance3D
		if mesh_instance:
			var mat := mesh_instance.material_override
			if mat is ShaderMaterial:
				liquid_material = mat
	update_visual()

func pour(delta):
	if current_ml > 0.001:
		var amount_requested = pour_rate * delta
		var amount = clamp(amount_requested, 0.0, current_ml)
		if raycast.is_colliding():
			var hit = raycast.get_collider()
			if hit.has_method("get_liquid"):
				hit.get_liquid(amount, group)
		current_ml -= amount
		update_visual()
		

func normalized_fill() -> float:
	#print(clamp(current_ml / max_liquid_ml, 0.0, 1.0))
	return clamp(current_ml / bottle_capacity, 0.0, 1.0)

func update_visual() -> void:
	if liquid_material:
		liquid_material.set_shader_parameter("fill_percent", normalized_fill())
		
func get_drink_type():
	var group_list = get_groups()
	for g in group_list:
		if g != "juice" and g != "pickables":
			return g as String
	
	return null
