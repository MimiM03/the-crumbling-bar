extends Node

@export var json_file_path: String = "res://scripts/recipies.json"


var drinks: Array = []
var rng := RandomNumberGenerator.new()
var amount = 3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rng.randomize()
	if load_json(json_file_path):
		var picks := pick_random_drinks(amount)
		for i in picks.size():
			print(" [%d] %s" % [i +1, picks[i]])

## Loads json into the file
func load_json(path: String) -> bool:
	if not FileAccess.file_exists(path):
		push_error("OrderGen: File not found — %s" % path)
		return false
 
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("OrderGen: Could not open file — %s" % path)
		return false
 
	var raw := file.get_as_text()
	file.close()
 
	var parsed = JSON.parse_string(raw)
	if parsed == null:
		push_error("OrderGen: Invalid JSON in — %s" % path)
		return false
 
	if not parsed is Array:
		push_error("OrderGen: JSON root must be an Array of drink objects.")
		return false
 
	drinks = parsed
 
	if drinks.is_empty():
		push_warning("OrderGen: Drink list is empty.")
		return false
 
	#print("OrderGen: Loaded %d drink(s) from %s" % [drinks.size(), path])
	return true


## Pick drinks from list
func pick_random_drinks(count: int) -> Array:
	if drinks.is_empty():
		push_warning("OrderGen: No drinks loaded.")
		return []
 
	var result: Array = []
	var pool: Array = drinks.duplicate()
 
	for _i in count:
		var index := rng.randi_range(0, pool.size() - 1)
		result.append(pool[index])
 
	return result
 
 
## Prints a single drink entry cleanly to the console.
func print_drink(number: int, drink: Dictionary) -> void:
	print("[%d] %s  (%s)" % [number, drink.get("name", "Unknown"), drink.get("glass", "Unknown glass")])
	var ingredients: Array = drink.get("ingredients", [])
	for ing in ingredients:
		print("     - %s: %.1f" % [ing.get("item", "?"), ing.get("amount", 0.0)])
	print("")
 
 
## Call this at runtime to re-pick without reloading the file.
## Returns the array of picked drink Dictionaries.
func repick(count: int) -> Array:
	var picks := pick_random_drinks(count)
	print("Re-picked %d drink(s):\n" % picks.size())
	for i in picks.size():
		print_drink(i + 1, picks[i])
	return picks
 
 
func get_name_drink(drink: Dictionary) -> String:
	return drink.get("name", "Unknown")
 
 
## Returns a flat list of ingredient strings for a given drink, ["vodka 2.5", "mixer 60"]
func get_ingredient_strings(drink: Dictionary) -> Array:
	var result: Array = []
	for ing in drink.get("ingredients", []):
		result.append("%s %.1f" % [ing.get("item", "?"), ing.get("amount", 0.0)])
	return result
