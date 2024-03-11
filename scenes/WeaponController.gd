class_name Weapon extends Sprite2D


@export_category("Weapon Stats")
@export var damage: float = float(1)
@export var projectile_speed: float = float(550)
@export var fire_rate: float = float(0.3)
@export var reload_time: float = float(1)
@export var magazine_size: int = int(30)
@export var reserve_ammo: int = int(90)

@export_category("Misc")
@export var is_hitscan: bool = false

@export_category("Resources")
@export var projectile: PackedScene

var can_fire = true :
	get:
		return can_fire
	set(value):
		if(magazine_count == 0 or is_reloading):
			can_fire = false
		else:
			can_fire = bool(value)

var fire_rate_timer: Timer
var reload_timer: Timer
var is_reloading = false
var magazine_count: int = magazine_size

func _ready():
	fire_rate_timer = Timer.new()
	get_tree().get_root().add_child.call_deferred(fire_rate_timer)
	fire_rate_timer.one_shot = true
	fire_rate_timer.timeout.connect(_fire_rate_timer_finished)

	reload_timer = Timer.new()
	get_tree().get_root().add_child.call_deferred(reload_timer)
	reload_timer.one_shot = true
	reload_timer.timeout.connect(_reload_timer_finished)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	check_firing()
	check_reloading()

func check_reloading():
	if Input.is_action_just_pressed("reload") and reserve_ammo > 0 and magazine_count < magazine_size and is_reloading == false:
		reload_timer.start(reload_time)
		is_reloading = true
		can_fire = false

func check_firing():
	if Input.is_action_pressed("primary_action") and can_fire == true:
		if(is_hitscan == false):
			fire_projectile(projectile_speed)
		else:
			fire_hitscan()

		can_fire = false
		fire_rate_timer.start(fire_rate)

func fire_projectile(speed: float):
	magazine_count -= 1

	var projectile_instance = projectile.instantiate()
	projectile_instance.position = $BulletInstancePoint.get_global_position()
	projectile_instance.rotation = global_rotation
	projectile_instance.apply_impulse(Vector2(speed, 0).rotated(global_rotation), Vector2())
	get_tree().get_root().add_child(projectile_instance)

	projectile_instance.enemy_hit.connect(on_enemy_hit)
	print("fire", magazine_count, "/", magazine_size)

func fire_hitscan():
	var space_state = get_world_2d().direct_space_state

	# Draw raycast from end of gun to mouse
	var bullet_raycast = PhysicsRayQueryParameters2D.create($BulletInstancePoint.get_global_position(), get_global_mouse_position())
	var result = space_state.intersect_ray(bullet_raycast)

func on_enemy_hit(hit_position: Vector2, enemy: Node, projectile: Projectile):
	enemy.take_damage(damage)

func _fire_rate_timer_finished():
	can_fire = true

func _reload_timer_finished():
	var amount_to_reload = magazine_size - magazine_count

	if(amount_to_reload > reserve_ammo):
		magazine_count += reserve_ammo
		reserve_ammo = 0
	else:
		magazine_count += amount_to_reload
		reserve_ammo -= amount_to_reload

	is_reloading = false
	can_fire = true

	print("reloaded", magazine_count, "/", magazine_size)
	print("reserve ammo", reserve_ammo)
