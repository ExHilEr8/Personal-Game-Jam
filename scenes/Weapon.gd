class_name Weapon extends Sprite2D


@export_category("Weapon Stats")
@export var fire_rate: float = float(0.3)
@export var reload_time: float = float(1)
@export var magazine_size: int = int(30)
@export var reserve_ammo: int = int(90)
@export var is_burst_fire: bool = false
@export var burst_amount: int = int(1)
@export var burst_fire_rate: float = float(0.1)

@export_category("Misc")
@export var is_hitscan: bool = false
@export var hitscan_ray_length: float = float(2000)
@export var hitscan_collision_mask: int = int(1)
@export var hitscan_custom_instance_point: Vector2 = Vector2(0,0)

@export_category("Resources")
@export var physics_projectile: PackedScene
@export var hitscan_projectile: PackedScene

var hitscan_raycast: RayCast2D
var hitscan_projectile_instance

var burst_timer: Timer
var is_bursting = false

# reload_timer is used to set the state of is_reloading
# is_reloading is used to determine times when can_fire = false
var reload_timer: Timer
var is_reloading = false

var fire_rate_timer: Timer

var magazine_count: int :
	get:
		return magazine_count
	set(value):
		magazine_count = clamp(value, 0, 9223372036854775807)

var can_fire = true :
	get:
		return can_fire
	set(value):
		can_fire = bool(value)

func _ready():
	fire_rate_timer = initialize_general_timer()
	burst_timer = initialize_general_timer()
	reload_timer = initialize_general_timer()

	reload_timer.timeout.connect(_reload_timer_finished)

	magazine_count = magazine_size 

	if is_hitscan == true:
		hitscan_raycast = initialize_raycast()

		# Hitscan instance position is relative to parent node
		if(hitscan_custom_instance_point != Vector2(0,0)):
			hitscan_raycast.position = hitscan_custom_instance_point
		else:
			hitscan_raycast.position = $BulletInstancePoint.get_position()

		add_child.call_deferred(hitscan_raycast)
	
	if(hitscan_projectile != null):
		hitscan_projectile_instance = hitscan_projectile.instantiate()
		add_child(hitscan_projectile_instance)
		hitscan_projectile_instance.enemy_hit.connect(_on_enemy_hit)
		
		
func initialize_raycast() -> RayCast2D:
	var raycast = RayCast2D.new()
	raycast.hit_from_inside = true
	raycast.exclude_parent = true 
	raycast.collision_mask = hitscan_collision_mask
	raycast.enabled = true
	raycast.exclude_parent = true

	return raycast

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	check_attempt_fire()
	check_attempt_reload()

func _physics_process(delta):
	if is_hitscan == true:
		hitscan_raycast.target_position = Vector2(hitscan_ray_length, 0)

func check_attempt_reload():
	if Input.is_action_just_pressed("reload") and reserve_ammo > 0 and magazine_count < magazine_size and is_reloading == false:
		start_reload()

func start_reload():
	reload_timer.start(reload_time)
	is_reloading = true

func check_attempt_fire():
	if Input.is_action_pressed("primary_action"):
		fire()

func fire():
	determine_can_fire()

	if(can_fire == true):
		if(is_burst_fire == true):
			is_bursting = true

			for n in (burst_amount):
				determine_can_fire()

				if is_hitscan == false:
					fire_projectile(physics_projectile, $BulletInstancePoint.get_global_position())
				else:
					fire_hitscan(hitscan_raycast)

				burst_timer.start(burst_fire_rate)
				await burst_timer.timeout
			
			is_bursting = false

		elif(is_hitscan == true):
			fire_hitscan(hitscan_raycast)

		else:
			fire_projectile(physics_projectile, $BulletInstancePoint.get_global_position())

		fire_rate_timer.start(fire_rate)
		print("fire", magazine_count, "/", magazine_size)

# fire_projectile() uses the physics_projectile: PackedScene which is generally provided
#	in the editor per gun. See PhysicsProjectilePrefab.tscn for more info
func fire_projectile(projectile_scene: PackedScene, projectile_start_point: Vector2):
	var projectile_instance = projectile_scene.instantiate()
	projectile_instance.position = projectile_start_point
	projectile_instance.rotation = global_rotation
	projectile_instance.apply_impulse(Vector2(projectile_instance.projectile_speed, 0).rotated(global_rotation), Vector2())
	get_tree().get_root().add_child(projectile_instance)

	projectile_instance.enemy_hit.connect(_on_enemy_hit)

	magazine_count -= projectile_instance.ammo_per_shot

# fire_hitscan() uses the hitscan_projectile: PackedScene which is generally provided
#	in the editor per gun. See HitscanProjectilePrefab.tscn for more info
func fire_hitscan(ray: RayCast2D):
	if ray.is_colliding():
		var collider = ray.get_collider()
		var collision_point = ray.get_collision_point()
		var collision_rotation = get_global_rotation()
		hitscan_projectile_instance.on_collision(collider, collision_point, collision_rotation)
		print(collider)
		
	magazine_count -= hitscan_projectile_instance.ammo_per_shot

func _reload_timer_finished():
	reload()

func reload() -> void:
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

func initialize_general_timer() -> Timer:
	var timer = Timer.new()
	get_tree().get_root().add_child.call_deferred(timer)
	timer.one_shot = true
	return timer
	
func _on_enemy_hit(hit_position: Vector2, enemy: Node, projectile):
	damage_enemy(enemy, projectile.damage)

	if is_hitscan == false:
		projectile.queue_free()

func damage_enemy(enemy, damage) -> void:
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


