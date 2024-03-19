class_name PhysicsProjectile extends Projectile

@export_category("Projectile Stats")
@export var projectile_speed: float = float(550)
# TODOOOOO
# OVERHAUL mask consts into a class or find out where to get them from, then add their values to enable/disable them rather than doing each mask individually. This will help
#	with setting the hitscan mask too as thats currently broken
#
# Implement the forward raycasting check functionality from Weapon.gd to fix tunneling on piercing physical projectiles (i.e. when using Area2D object to detect collisions
#   when the collision mask for the RigidBody2D is disabled)

func _on_body_entered(body:Node):
	var bullet_global_position = get_global_position()
	var bullet_global_rotation

	if rotate_animation_with_bullet:
		bullet_global_rotation = get_global_rotation()
	else:
		bullet_global_rotation = 0

	determine_projectile_interaction(get_tree().get_root(), body, bullet_global_position, bullet_global_rotation)
