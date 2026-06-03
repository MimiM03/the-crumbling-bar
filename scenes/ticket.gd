extends Area3D

var _header_label: Label
var _orders_box: VBoxContainer
var _label_template: Label


func _ready() -> void:
	_bind_ui()
	if _label_template:
		_label_template.visible = false


func set_orders(header: String, drinks: Array) -> void:
	_bind_ui()
	if _header_label == null or _orders_box == null or _label_template == null:
		push_warning("Ticket: UI nodes not found.")
		return
	_header_label.text = header
	for child in _orders_box.get_children():
		if child != _label_template:
			child.queue_free()
	for drink in drinks:
		if drink is Dictionary:
			_add_order_line(OrderGen.get_name_drink(drink))


func _bind_ui() -> void:
	if _header_label != null:
		return
	_header_label = get_node_or_null(
		"MeshInstance3D/SubViewport/PanelContainer/MarginContainer2/Label"
	) as Label
	_orders_box = get_node_or_null(
		"MeshInstance3D/SubViewport/PanelContainer/MarginContainer/VBoxContainer"
	) as VBoxContainer
	_label_template = get_node_or_null(
		"MeshInstance3D/SubViewport/PanelContainer/MarginContainer/VBoxContainer/Label"
	) as Label


func _add_order_line(text: String) -> void:
	var label := _label_template.duplicate() as Label
	label.visible = true
	label.text = text
	_orders_box.add_child(label)
