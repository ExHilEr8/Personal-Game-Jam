class_name Weapon extends Sprite2D


@export_category("Weapon Stats")
@export var damage: float = float(1)
@export var projectile_speed: float = float(550)
@export var fire_rate: float = float(0.3)
@export var reload_time: float = float(1)
@export var magazine_size: int = int(30)
@export var reserve_ammo: int = int(90)
@export var is_burst_fire: bool = false
@export var burst_amount: int = int(1)
@export var burst_fire_rate: float = float(0.1)

@export_category("Misc")
@export var is_hitscan: bool = false

@export_category("Resources")
@export var projectile: PackedScene

var burst_timer: Timer
var fire_rate_timer: Timer
var reload_timer: Timer
var is_bursting = false
var is_reloading = false
var magazine_count: int

var can_fire = true :
	get:
		return can_fire
	set(value):
		can_fire = bool(value)

func _ready():
	fire_rate_timer = initialize_general_timer(fire_rate_timer)

	reload_timer = initialize_general_timer(reload_timer)
	reload_timer.timeout.connect(_reload_timer_finished)

	burst_timer = initialize_general_timer(burst_timer)

	magazine_count = magazine_size 

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	check_attempt_fire()
	check_attempt_reload()

func check_attempt_reload():
	if Input.is_action_just_pressed("reload") and reserve_ammo > 0 and magazine_count < magazine_size and is_reloading == false:
		reload()

func reload():
	reload_timer.start(reload_time)
	is_reloading = true

func check_attempt_fire():
	if Input.is_action_pressed("primary_action"):
		fire()

func fire():
	determine_can_fire()

	if(can_fire == true):
		if(is_hitscan == true):
			fire_hitscan()
		elif(is_burst_fire == true):
			is_bursting = true

			for n in (burst_amount):
				determine_can_fire()
				fire_projectile(projectile_speed)
				burst_timer.start(burst_fire_rate)
				await burst_timer.timeout
			
			is_bursting = false
		else:
			fire_projectile(projectile_speed)

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

# TODO ZOMBIE CODE DEFO NOT WORKING BRO WATCH OUT
func fire_hitscan():
	var space_state = get_world_2d().direct_space_state

	# Draw raycast from end of gun to mouse
	var bullet_raycast = PhysicsRayQueryParameters2D.create($BulletInstancePoint.get_global_position(), get_global_mouse_position())
	var result = space_state.intersect_ray(bullet_raycast)

func _reload_timer_finished():
	var amount_to_reload = magazine_size - magazine_count

	if(amount_to_reload > reserve_ammo):
		magazine_count += reserve_ammo
		reserve_ammo = 0
	else:
		magazine_count += amount_to_reload
		reserve_ammo -= amount_to_reload

	is_reloading = false

	print("reloaded", magazine_count, "/", magazine_size)
	print("reserve ammo", reserve_ammo)

func initialize_general_timer(timer) -> Timer:
	timer = Timer.new()
	get_tree().get_root().add_child.call_deferred(timer)
	timer.one_shot = true
	return timer
	
func on_enemy_hit(hit_position: Vector2, enemy: Node, projectile: Projectile):
	enemy.take_damage(damage)

func determine_can_fire():
	can_fire = true

	if(is_reloading == true):
		can_fire = false
		return
	elif(is_bursting == true):
		can_fire = false
		return
	elif(magazine_count == 0):
		can_fire = false
		return
	elif(fire_rate_timer.time_left > 0):
		can_fire = false
		return
