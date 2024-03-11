class_name Weapon extends Sprite2D

@export var projectile_speed: float = float(550)
@export var fire_rate: float = float(0.3)

@export var is_hitscan: bool = false
@export var projectile: PackedScene

var can_fire = true :
	get:
		return can_fire
	set(value):
		can_fire = bool(value)

var fire_rate_timer: Timer

func _ready():
	fire_rate_timer = Timer.new()
	get_tree().get_root().add_child.call_deferred(fire_rate_timer)
	fire_rate_timer.one_shot = true
	fire_rate_timer.timeout.connect(_timer_set_can_fire)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	check_firing()

func check_firing():
	if Input.is_action_pressed("primary_action") and can_fire == true:
		if(is_hitscan == false):
			fire_projectile(projectile_speed)
		else:
			fire_hitscan()

		can_fire = false
		fire_rate_timer.start(fire_rate)

func fire_projectile(speed: float):
	var projectile_instance = projectile.instantiate()
	projectile_instance.position = $BulletInstancePoint.get_global_position()
	projectile_instance.rotation = global_rotation
	projectile_instance.apply_impulse(Vector2(speed, 0).rotated(global_rotation), Vector2())
	get_tree().get_root().add_child(projectile_instance)

	projectile_instance.enemy_hit.connect(on_enemy_hit)

func fire_hitscan():
	var space_state = get_world_2d().direct_space_state
	var bullet_raycast = PhysicsRayQueryParameters2D.create($BulletInstancePoint.get_global_position(), get_global_mouse_position())
	var result = space_state.intersect_ray(bullet_raycast)

func on_enemy_hit(hit_position: Vector2, enemy: Node):
	pass

func _timer_set_can_fire():
	can_fire = true

