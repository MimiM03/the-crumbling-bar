class_name OrderGen
extends Node

static var json_file_path: String = "res://scripts/recipes.json"
static var drinks: Array = []
static var rng := RandomNumberGenerator.new()

## Loads json into the file
static func load_json(path: String) -> bool:
	if not drinks.is_empty():
		return true # Already loaded
		
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
static func pick_random_drinks(count: int) -> Array:
	rng.randomize()
	load_json(json_file_path)
	
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
static func print_drink(number: int, drink: Dictionary) -> void:
	print("[%d] %s  (%s)" % [number, drink.get("name", "Unknown"), drink.get("glass", "Unknown glass")])
	var ingredients: Array = drink.get("ingredients", [])
	for ing in ingredients:
		print("     - %s: %.1f" % [ing.get("item", "?"), ing.get("amount", 0.0)])
	print("")
 
 
## Call this at runtime to re-pick without reloading the file.
## Returns the array of picked drink Dictionaries.
static func repick(count: int) -> Array:
	var picks := pick_random_drinks(count)
	print("Re-picked %d drink(s):\n" % picks.size())
	for i in picks.size():
		print_drink(i + 1, picks[i])
	return picks

static func get_name_drink(drink: Dictionary) -> String:
	return drink.get("name", "Unknown")
 
## Returns a flat list of ingredient strings for a given drink, ["vodka 2.5", "mixer 60"]
static func get_ingredient_strings(drink: Dictionary) -> Array:
	var result: Array = []
	for ing in drink.get("ingredients", []):
		result.append("%s %.1f" % [ing.get("item", "?"), ing.get("amount", 0.0)])
	return result
