extends SubViewport


@onready var rig: Node3D = $Rig
@onready var inventory: Control = $"../../../../.."


func _process(delta: float) -> void:
	character_rotate(delta)


func character_rotate(delta: float) -> void:
	if inventory.visible:
		var joy_x := Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)

		# Add a deadzone to prevent slight drifting
		var deadzone := 0.1
		if abs(joy_x) > deadzone:
			var rotation_speed := 2.0 
			rig.rotate_y(joy_x * rotation_speed * delta)
	if inventory.visible == false:
		rig.rotation = Vector3.ZERO
