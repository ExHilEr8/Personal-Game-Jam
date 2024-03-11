extends Sprite2D

@export var bullet_speed = 550
@export var fire_rate = 0.3
@export var is_hitscan: bool = false

var bullet = preload("res://scenes/tempbullet.tscn")
var can_fire = true

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_pressed("primary_action") and can_fire == true:
		if(is_hitscan == false):
			fire_projectile(bullet_speed)
		else:
			fire_hitscan()

		can_fire = false
		await(get_tree().create_timer(fire_rate).timeout)
		can_fire = true

func fire_projectile(speed: float):
	var bullet_instance = bullet.instantiate()
	bullet_instance.position = $BulletInstancePoint.get_global_position()
	bullet_instance.rotation = global_rotation
	bullet_instance.apply_impulse(Vector2(speed, 0).rotated(global_rotation), Vector2())
	get_tree().get_root().add_child(bullet_instance)

	bullet_instance.enemy_hit.connect(on_enemy_hit)

func fire_hitscan():
	var space_state = get_world_2d().direct_space_state
	var bullet_raycast = PhysicsRayQueryParameters2D.create($BulletInstancePoint.get_global_position(), get_global_mouse_position())
	var result = space_state.intersect_ray(bullet_raycast)

func on_enemy_hit(hit_position: Vector2, enemy: Node):
	pass

