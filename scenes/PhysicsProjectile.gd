class_name PhysicsProjectile extends Projectile

@export_category("Misc")
@export var collider: RigidBody2D
@export var area_collider: Area2D

var enemy_mask_val: bool = true
var wall_mask_val: bool = true

# TODOOOOO
# OVERHAUL mask consts into a class or find out where to get them from, then add their values to enable/disable them rather than doing each mask individually. This will help
#	with setting the hitscan mask too as thats currently broken
#
# Implement the forward raycasting check functionality from Weapon.gd to fix tunneling on piercing physical projectiles (i.e. when using Area2D object to detect collisions
#   when the collision mask for the RigidBody2D is disabled)

const ENEMY_MASK = int(1)
const WALL_MASK = int(16) 

func _ready():
	if is_enemy_piercing or is_wall_piercing:
		if is_enemy_piercing == true:
			enemy_mask_val = false
		
		if is_wall_piercing == true:
			wall_mask_val = false
		
		invert_collision(ENEMY_MASK, enemy_mask_val)
		invert_collision(WALL_MASK, wall_mask_val)

# invert_collision is used to invert the collisions between the RigidBody2D and
#	Area2D such that they detect the opposite of eachother. This is used so that
#	collisions can occur with normal physics functionality on things it shouldn't
#	pierce through.
func invert_collision(mask: int, mask_val: int):
	collider.set_collision_mask_value(mask, mask_val)
	area_collider.set_collision_mask_value(mask, !mask_val)

func _on_body_entered(body:Node):
	var bullet_global_position = get_global_position()
	var bullet_global_rotation

	if rotate_animation_with_bullet:
		bullet_global_rotation = get_global_rotation()
	else:
		bullet_global_rotation = 0

	determine_projectile_interaction(get_tree().get_root(), body, bullet_global_position, bullet_global_rotation)
