extends Node2D



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var mouse_position = get_global_mouse_position()

	# If mouse is left of player and sprite is facing right (unflipped)
	# OR mouse is right of player and sprite is facing left (flipped)
	if ((mouse_position.x < global_position.x and scale.y > 0) or 
		(mouse_position.x > global_position.x and scale.y < 0)):
			
		scale.y *= -1


	look_at(mouse_position)