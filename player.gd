extends CharacterBody3D
func _physics_process(delta):
	var input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = Vector3(input.x, 0, input.y) * 5.0
	move_and_slide()
