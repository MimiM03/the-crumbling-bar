extends Control

const INGREDIENT_NAMES := {
	"vodka": "Vodka",
	"whiskey": "Whiskey",
	"tequila": "Tequila",
	"tripleSec": "Triple Sec",
	"sweetSour": "Sweet & Sour",
	"juiceOrange": "Orange juice",
	"juiceCranberry": "Cranberry juice",
	"juiceGrapefruit": "Grapefruit juice",
	"juiceLime": "Lime juice",
	"juicePineapple": "Pineapple juice",
}

@onready var recipe_list: VBoxContainer = $Panel/ScrollContainer/VBoxContainer


func _ready() -> void:
	visible = false
	recipe_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	OrderGen.load_json(OrderGen.json_file_path)
	_build_recipe_list()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("recipe_book"):
		if visible:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			get_tree().paused = false
			visible = false
		elif !get_tree().paused:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_tree().paused = true
			visible = true


func _build_recipe_list() -> void:
	for child in recipe_list.get_children():
		child.queue_free()

	var drinks: Array = OrderGen.drinks.duplicate()
	drinks.sort_custom(_sort_by_glass_then_name)

	var last_glass := ""
	for drink in drinks:
		if not drink is Dictionary:
			continue
		var glass: String = str(drink.get("glass", ""))
		if glass != last_glass:
			recipe_list.add_child(_make_section_header(glass))
			last_glass = glass
		recipe_list.add_child(_make_recipe_card(drink))


func _sort_by_glass_then_name(a: Dictionary, b: Dictionary) -> bool:
	var glass_a: String = str(a.get("glass", ""))
	var glass_b: String = str(b.get("glass", ""))
	if glass_a != glass_b:
		return glass_a.naturalnocasecmp_to(glass_b) < 0
	return str(a.get("name", "")).naturalnocasecmp_to(str(b.get("name", ""))) < 0


func _make_section_header(glass: String) -> Label:
	var label := Label.new()
	label.text = glass if glass else "Other"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.35, 0.22, 0.12))
	return label


func _make_recipe_card(drink: Dictionary) -> MarginContainer:
	var wrapper := MarginContainer.new()
	wrapper.add_theme_constant_override("margin_bottom", 10)

	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 0.96, 0.88, 0.55)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", style)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 3)
	card.add_child(body)

	var title := Label.new()
	title.text = str(drink.get("name", "Unknown"))
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.08, 0.04, 0.02))
	body.add_child(title)

	for ing in drink.get("ingredients", []):
		if ing is Dictionary:
			body.add_child(_make_ingredient_line(ing))

	wrapper.add_child(card)
	return wrapper


func _make_ingredient_line(ing: Dictionary) -> Label:
	var label := Label.new()
	label.text = "• " + _format_ingredient(ing)
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.2, 0.15, 0.1))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _format_ingredient(ing: Dictionary) -> String:
	var id: String = str(ing.get("item", "?"))
	var display_name: String = INGREDIENT_NAMES.get(id, _humanize_id(id))
	var amount: float = float(ing.get("amount", 0.0))
	if is_equal_approx(amount, round(amount)):
		return "%s — %d ml" % [display_name, int(round(amount))]
	return "%s — %.1f ml" % [display_name, amount]


func _humanize_id(id: String) -> String:
	if id.begins_with("juice") and id.length() > 5:
		return id.substr(5, id.length() - 5).capitalize() + " juice"
	return id.capitalize()
