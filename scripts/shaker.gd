extends Area3D

@onready var markerLeft := $LeftBottleMarker
@onready var markerRight := $RightBottleMarker
@onready var raycast:= $RayCast3D

@export var liquid_mesh_path: NodePath
@export var max_liquid_ml := 750.0
var current_ml = 0.0
var pour_rate = 15.0 # ~~ ml per sec
var amount_per_drink_type = {}
var liquid_material: ShaderMaterial

func _ready() -> void:
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
				hit.get_liquid(amount, null, amount_per_drink_type)
		current_ml -= amount
		update_visual()
		

func normalized_fill() -> float:
	return clamp(current_ml / max_liquid_ml, 0.0, 1.0)

func update_visual() -> void:
	if liquid_material:
		liquid_material.set_shader_parameter("fill_percent", normalized_fill())
		
		
func get_liquid(amount, drink_type, amount_per_alc) -> void:
	if current_ml < max_liquid_ml:
		print(current_ml)
		current_ml += amount
		if drink_type:
			if drink_type in amount_per_drink_type:
				amount_per_drink_type[drink_type] += amount
			else:
				amount_per_drink_type[drink_type] = amount
		if amount_per_alc:
			for alc in amount_per_alc:
				if alc in amount_per_drink_type:
					amount_per_drink_type[alc] += amount_per_alc[alc]
				else:
					amount_per_drink_type[alc] = amount_per_alc[alc]
		update_visual()
