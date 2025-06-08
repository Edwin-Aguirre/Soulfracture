extends CenterContainer

@export var inventory: Inventory

@onready var grid_container: GridContainer = $PanelContainer/VBoxContainer/GridContainer
@onready var title_label: Label = $PanelContainer/VBoxContainer/TitleTexture/TitleLabel

var current_container: LootContainer
var using_controller: bool = false

func _ready() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadMotion or event is InputEventJoypadButton:
		using_controller = true
		if visible:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	elif event is InputEventMouse or event is InputEventKey:
		using_controller = false
		if visible:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		# Clear focus when switching back to mouse/keyboard
		var focus_owner = get_viewport().gui_get_focus_owner()
		if focus_owner:
			focus_owner.release_focus()

func close() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if is_instance_valid(current_container):
		for item in grid_container.get_children():
			var interact_callable = Callable(self, "pickup_item")
			if item.is_connected("interact", interact_callable):
				item.interact.disconnect(interact_callable)
			grid_container.remove_child(item)
			current_container.add_child(item)
			item.visible = false

func open(loot: LootContainer) -> void:
	if visible:
		close()
		return

	current_container = loot
	title_label.text = loot.name.capitalize()

	for item in loot.get_items():
		current_container.remove_child(item)
		grid_container.add_child(item)
		item.visible = true

		if item is TextureButton:
			if using_controller:
				item.focus_mode = Control.FOCUS_ALL
			else:
				item.focus_mode = Control.FOCUS_NONE

			item.self_modulate = Color.WHITE

			var interact_callable = Callable(self, "pickup_item")
			if item.is_connected("interact", interact_callable):
				item.interact.disconnect(interact_callable)
			item.interact.connect(interact_callable)

			var focus_entered_callable = Callable(self, "_on_button_focus_entered")
			if item.is_connected("focus_entered", focus_entered_callable):
				item.disconnect("focus_entered", focus_entered_callable)
			item.connect("focus_entered", focus_entered_callable)

			var focus_exited_callable = Callable(self, "_on_button_focus_exited")
			if item.is_connected("focus_exited", focus_exited_callable):
				item.disconnect("focus_exited", focus_exited_callable)
			item.connect("focus_exited", focus_exited_callable)

	if using_controller and grid_container.get_child_count() > 0:
		var first_button = grid_container.get_child(0)
		if first_button is Control:
			first_button.grab_focus()

	visible = true
	if not using_controller:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func pickup_item(icon: ItemIcon) -> void:
	var interact_callable = Callable(self, "pickup_item")
	if icon.is_connected("interact", interact_callable):
		icon.interact.disconnect(interact_callable)

	var buttons := grid_container.get_children().filter(func(btn):
		return btn is TextureButton and btn.visible
	)

	var idx := buttons.find(icon)

	if icon is CurrencyIcon:
		inventory.add_currency(icon.value)
		icon.queue_free()
	else:
		inventory.add_item(icon)

	if icon.get_parent() == grid_container:
		grid_container.remove_child(icon)

	await get_tree().process_frame

	buttons = grid_container.get_children().filter(func(btn):
		return btn is TextureButton and btn.visible
	)

	if buttons.size() > 0:
		var new_focus_index := idx - 1
		if new_focus_index < 0:
			new_focus_index = 0
		if new_focus_index >= buttons.size():
			new_focus_index = buttons.size() - 1

		buttons[new_focus_index].grab_focus()
	else:
		get_viewport().set_input_as_handled()

func _on_button_focus_entered() -> void:
	var btn := get_viewport().gui_get_focus_owner()
	if btn and btn is TextureButton:
		btn.self_modulate = Color(2, 2, 2, 1)  # Highlight color

func _on_button_focus_exited() -> void:
	for button in grid_container.get_children():
		if button is TextureButton:
			button.self_modulate = Color.WHITE  # Reset color
