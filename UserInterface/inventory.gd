extends Control
class_name Inventory

const MIN_ARMOR_RATING := 0.0
const MAX_ARMOR_RATING := 80.0

signal armor_changed(protection: float)

@onready var level_label: Label = %LevelLabel
@onready var strength_value: Label = %StrengthValue
@onready var agility_value: Label = %AgilityValue
@onready var speed_value: Label = %SpeedValue
@onready var endurance_value: Label = %EnduranceValue
@onready var attack_value: Label = %AttackValue
@onready var item_grid: GridContainer = %ItemGrid
@onready var gold_label: Label = %GoldLabel
@onready var weapon_slot: CenterContainer = %WeaponSlot
@onready var shield_slot: CenterContainer = %ShieldSlot
@onready var armor_slot: CenterContainer = %ArmorSlot
@onready var armor_value: Label = %ArmorValue

@onready var player: Player = get_parent().player

@onready var gold := 0:
	set(value):
		gold = value
		gold_label.text = str(gold) + "g"

var using_controller := false


func _ready() -> void:
	update_stats()
	load_items_from_persistent_data()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadMotion or event is InputEventJoypadButton:
		using_controller = true
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	elif event is InputEventMouse or event is InputEventKey:
		using_controller = false
		#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		var focus_owner = get_viewport().gui_get_focus_owner()
		if focus_owner:
			focus_owner.release_focus()

func update_stats() -> void:
	level_label.text = "\nLevel  %s" % player.stats.level
	strength_value.text = str(player.stats.strength.ability_score)
	agility_value.text = str(player.stats.agility.ability_score)
	speed_value.text = str(player.stats.speed.ability_score)
	endurance_value.text = str(player.stats.endurance.ability_score)

func update_gear_stats() -> void:
	attack_value.text = str(get_weapon_value())
	armor_value.text = str(int(get_armor_value()))
	armor_changed.emit(get_armor_value())

func get_weapon_value() -> int:
	var damage = 0
	if get_weapon():
		damage += get_weapon().power
	damage += player.stats.get_damage_modifier()
	return damage

func get_armor_value() -> float:
	var armor = 0.0
	if get_armor():
		armor += get_armor().protection
	if get_shield():
		armor += get_shield().protection
	armor = clampf(armor, MIN_ARMOR_RATING, MAX_ARMOR_RATING)
	return armor

func _on_back_button_pressed() -> void:
	get_parent().close_menu()

func add_item(icon: ItemIcon) -> void:
	for connection in icon.interact.get_connections():
		icon.interact.disconnect(connection.callable)

	if icon.get_parent():
		icon.get_parent().remove_child(icon)

	item_grid.add_child(icon)

	# Enable focus and visual feedback
	if icon is TextureButton:
		icon.focus_mode = Control.FOCUS_ALL if using_controller else Control.FOCUS_NONE
		icon.self_modulate = Color.WHITE

		var interact_callable = Callable(self, "interact")
		if icon.is_connected("interact", interact_callable):
			icon.interact.disconnect(interact_callable)
		icon.interact.connect(interact_callable)

		var focus_entered_callable = Callable(self, "_on_button_focus_entered")
		if icon.is_connected("focus_entered", focus_entered_callable):
			icon.disconnect("focus_entered", focus_entered_callable)
		icon.connect("focus_entered", focus_entered_callable)

		var focus_exited_callable = Callable(self, "_on_button_focus_exited")
		if icon.is_connected("focus_exited", focus_exited_callable):
			icon.disconnect("focus_exited", focus_exited_callable)
		icon.connect("focus_exited", focus_exited_callable)

func _on_button_focus_entered() -> void:
	var btn := get_viewport().gui_get_focus_owner()
	if btn and btn is TextureButton:
		btn.self_modulate = Color(2, 2, 2, 1)  # Highlight color

func _on_button_focus_exited() -> void:
	for button in item_grid.get_children():
		if button is TextureButton:
			button.self_modulate = Color.WHITE

func add_currency(currency_in: int) -> void:
	gold += currency_in

func equip_item(item: ItemIcon, item_slot: CenterContainer) -> void:
	for child in item_slot.get_children():
		add_item(child)
	item.get_parent().remove_child(item)
	item_slot.add_child(item)
	focus_first_item()

func interact(item: ItemIcon) -> void:
	if item is WeaponIcon:
		equip_item(item, weapon_slot)
		get_tree().call_group("PlayerRig", "replace_weapon", item.item_model)
	if item is ShieldIcon:
		equip_item(item, shield_slot)
		get_tree().call_group("PlayerRig", "replace_shield", item.item_model)
	if item is ArmorIcon:
		equip_item(item, armor_slot)
		get_tree().call_group("PlayerRig", "replace_armor", item.armor)
	update_gear_stats()

func get_weapon() -> WeaponIcon:
	if weapon_slot.get_child_count() != 1:
		return null
	return weapon_slot.get_child(0)

func get_shield() -> ShieldIcon:
	if shield_slot.get_child_count() != 1:
		return null
	return shield_slot.get_child(0)

func get_armor() -> ArmorIcon:
	if armor_slot.get_child_count() != 1:
		return null
	return armor_slot.get_child(0)

func load_items_from_persistent_data() -> void:
	for item in PersistentData.get_inventory():
		add_item(item)
	for item in PersistentData.get_equipped_items():
		add_item(item)
		interact(item)
	gold = PersistentData.gold
	
	# --- Fix focus after loading ---
	refresh_focus_mode()

	# Delay focus grab to ensure UI is ready
	await get_tree().process_frame
	focus_first_item()

func focus_first_item() -> void:
	if not using_controller:
		return

	var current_focus := get_viewport().gui_get_focus_owner()
	if current_focus != null and item_grid.is_ancestor_of(current_focus):
		return  # Don't override already-focused item

	for child in item_grid.get_children():
		if child is TextureButton:
			child.focus_mode = Control.FOCUS_ALL
			child.grab_focus()
			break


func refresh_focus_mode() -> void:
	for child in item_grid.get_children():
		if child is TextureButton:
			child.focus_mode = Control.FOCUS_ALL if using_controller else Control.FOCUS_NONE
