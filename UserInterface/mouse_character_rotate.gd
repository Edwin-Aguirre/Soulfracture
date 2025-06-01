extends SubViewportContainer


var dragging := false
var last_mouse_pos := Vector2.ZERO


@onready var sub_viewport: SubViewport = $SubViewport
@onready var rig: Node3D = $SubViewport/Rig
@onready var inventory: Control = $"../../../.."


func _gui_input(event: InputEvent) -> void:
	if inventory.visible:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
			last_mouse_pos = event.position

		elif event is InputEventMouseMotion and dragging:
			var delta: Vector2  = event.relative
			var rotation_speed := 0.01
			rig.rotate_y(delta.x * rotation_speed)
	if inventory.visible == false:
		rig.rotation = Vector3.ZERO
