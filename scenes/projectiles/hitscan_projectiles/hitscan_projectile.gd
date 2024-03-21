class_name HitscanProjectile extends Projectile

func on_collision(body:Node, collision_point: Vector2, collision_rotation: float):
	if rotate_animation_with_bullet:
		collision_rotation = collision_rotation
	else:
		collision_rotation = 0

	determine_projectile_interaction(get_tree().get_root(), body, collision_point, collision_rotation) 
