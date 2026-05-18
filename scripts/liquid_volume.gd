class_name LiquidVolume
extends RefCounted

var max_ml: float = 750.0
var fill_capacity_ml: float = 750.0
var pour_rate: float = 15.0
var liquid_color: Color = Color.WHITE
var current_ml: float = 0.0
var amount_per_drink_type: Dictionary = {}

var _liquid_material: ShaderMaterial

const COLORS := {
	# Spirits
	"vodka": Color(0.88, 0.93, 0.97, 1.0),
	"whiskey": Color(0.62, 0.42, 0.18, 1.0),
	"tequila": Color(0.94, 0.90, 0.72, 1.0),
	"tripleSec": Color(0.96, 0.91, 0.78, 1.0),
	# Mixers / juices
	"juiceLime": Color(0.17, 0.58, 0.10, 1.0),
	"juiceOrange": Color(0.85, 0.41, 0.10, 1.0),
	"juicePineapple": Color(0.89, 0.80, 0.12, 1.0),
	"juiceGrapefruit": Color(1.00, 0.55, 0.59, 1.0),
	"juiceCranberry": Color(0.71, 0.10, 0.18, 1.0),
	"sweetSour": Color(1.00, 0.94, 0.39, 1.0),
	# Optional: neutral mixed drink in shaker before you track components
	"mixed": Color(0.78, 0.73, 0.63, 1.0),
}


func setup(mesh: MeshInstance3D, duplicate_material: bool = false) -> void:
	if mesh == null:
		return
	var mat := mesh.material_override
	if mat is ShaderMaterial:
		if duplicate_material:
			mat = mat.duplicate(true) as ShaderMaterial
			mesh.material_override = mat
		_liquid_material = mat
	if fill_capacity_ml <= 0.0:
		fill_capacity_ml = max_ml
	update_visual()


func pour(delta: float, raycast: RayCast3D) -> void:
	if current_ml <= 0.001:
		return
	var amount := clampf(pour_rate * delta, 0.0, current_ml)
	var slice := _pour_slice(amount)
	if raycast != null and raycast.is_colliding():
		var hit := raycast.get_collider()
		if hit.has_method("get_liquid"):
			hit.get_liquid(amount, slice)
	current_ml -= amount
	update_visual()


func receive(amount: float, composition: Dictionary) -> void:
	var added := minf(amount, max_ml - current_ml)
	if added <= 0.0:
		return
	current_ml += added
	for key in composition:
		var portion := float(composition[key])
		if portion > 0.0:
			amount_per_drink_type[key] = amount_per_drink_type.get(key, 0.0) + portion
	update_visual()


func update_visual() -> void:
	if _liquid_material == null:
		return
	if current_ml > 0.001:
		var blended := Color(0.0, 0.0, 0.0, 0.0)
		for key in amount_per_drink_type:
			var weight := float(amount_per_drink_type[key]) / current_ml
			var sample: Color = COLORS.get(key, COLORS["mixed"])
			blended.r += sample.r * weight
			blended.g += sample.g * weight
			blended.b += sample.b * weight
			blended.a += sample.a * weight
		liquid_color = blended
		
	print(amount_per_drink_type)
	_liquid_material.set_shader_parameter("liquid_surface_color", liquid_color)
	_liquid_material.set_shader_parameter("fill_percent", clampf(current_ml / fill_capacity_ml, 0.0, 1.0))


## Build this frame's pour dict and subtract those amounts from the composition.
func _pour_slice(pour_ml: float) -> Dictionary:
	var slice := {}
	if current_ml <= 0.001:
		return slice
	var erase: Array[String] = []
	for key in amount_per_drink_type.keys():
		var portion := pour_ml * float(amount_per_drink_type[key]) / current_ml
		slice[key] = portion
		amount_per_drink_type[key] = float(amount_per_drink_type[key]) - portion
		if float(amount_per_drink_type[key]) < 0.001:
			erase.append(key)
	for key in erase:
		amount_per_drink_type.erase(key)
	return slice
