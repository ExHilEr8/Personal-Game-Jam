class_name Weapon extends Sprite2D

###############################
#####   EXPORT VARIABLES  #####
###############################

@export_group("Weapon Stats")
@export var fire_rate: float = float(0.3)
@export var reload_time: float = float(1)
@export var initial_accuracy: float = float(1) :
	get:
		return initial_accuracy
	set(value):
		initial_accuracy = clamp(value, 0, 1)
		
@export var magazine_size: int = int(30)
@export var reserve_ammo: int = int(90)
@export var projectile_count: int = int(1)

@export_subgroup("Projectile Options")
@export var projectile_even_spread: bool = false
@export var is_hitscan: bool = false
@export_subgroup("Hitscan Misc Options")
@export var hitscan_ray_length: float = float(2000)
@export var hitscan_collision_mask: int = CollisionConstants.get_final_layer([CollisionConstants.ENEMY, CollisionConstants.WALL])
@export var hitscan_custom_instance_point: Vector2 = Vector2(0,0)


@export_group("Firemode Options")
@export_subgroup("Full Auto Options")
@export var is_full_auto: bool = true

@export_subgroup("Burst Options")
@export var is_burst_fire: bool = false
@export var burst_amount: int = int(1)
@export var burst_fire_rate: float = float(0.1)

@export_subgroup("Charge Options")
@export var is_charge_fire: bool = false
@export var charge_time_seconds: float = float(1)
@export var minimum_charge: float = float(0)


@export_group("Misc")
@export var allow_queued_firing: bool = true
@export var time_left_to_queue: float = float(0.2) :
	get:
		return time_left_to_queue
	set(value):
		time_left_to_queue = clamp(float(value), float(0), float(fire_rate))

@export_category("Resources")
@export var physics_projectile: PackedScene
@export var hitscan_projectile: PackedScene


###############################
#####   CLASS VARIABLES   #####
###############################

var hitscan_raycasts = []
var hitscan_projectile_instances = []

var burst_timer: Timer
var reload_timer: Timer
var fire_rate_timer: Timer
var is_bursting: bool = false
var is_reloading: bool = false

var can_fire: bool = true 
var is_fire_queued: bool = false
var charge_full_autod_previously: bool = false

var current_charge: float = float(0) :
	get:
		return current_charge
	set(value):
		current_charge = clamp(float(value), float(0), float(1))

var magazine_count: int :
	get:
		return magazine_count
	set(value):
		magazine_count = clamp(value, 0, 9223372036854775807)


###############################
#####      FUNCTIONS      #####
###############################

func _ready():
	fire_rate_timer = initialize_general_timer()
	burst_timer = initialize_general_timer()
	reload_timer = initialize_general_timer()

	fire_rate_timer.timeout.connect(_attempt_queue_fire)
	reload_timer.timeout.connect(_reload_timer_finished)

	magazine_count = magazine_size 

	if is_hitscan == true:
		for n in projectile_count:
			var temp_ray = initialize_raycast()
			temp_ray.name = ("Hitscan Raycast%s") % [n]

			# Hitscan instance position is relative to parent node
			if(hitscan_custom_instance_point != Vector2(0,0)):
				temp_ray.position = hitscan_custom_instance_point
			else:
				temp_ray.position = $BulletInstancePoint.get_position()

			hitscan_raycasts.append(temp_ray)
			add_child.call_deferred(temp_ray)
	
			var temp_projectile = hitscan_projectile.instantiate()
			temp_projectile.name = ("Hitscan Projectile%s" % [n])

			hitscan_projectile_instances.append(temp_projectile)
			add_child(temp_projectile)
			temp_projectile.enemy_hit.connect(_on_enemy_hit)

func _process(delta):
	if is_charge_fire == true:
		check_attempt_charge_fire(delta)

	else:
		if is_full_auto == true:
			check_attempt_full_fire()
		else:
			check_attempt_single_fire()

	check_attempt_reload()


func _physics_process(delta):
	if is_hitscan == true:
		for ray in hitscan_raycasts:
			ray.target_position = get_default_ray_target()

func check_attempt_reload():
	if Input.is_action_just_pressed("reload") and reserve_ammo > 0 and magazine_count < magazine_size and is_reloading == false:
		start_reload()

func check_attempt_full_fire():
	if Input.is_action_pressed("primary_action"):
		try_fire()

func check_attempt_single_fire():
	if Input.is_action_just_pressed("primary_action"):
		try_fire()

func check_attempt_charge_fire(delta):
	if Input.is_action_pressed("primary_action"):
		current_charge += float((1 * delta) / charge_time_seconds)

		if current_charge == 1 and is_full_auto == true:
			try_fire()
			current_charge = 0
			charge_full_autod_previously = true
	
	elif Input.is_action_just_released("primary_action"):
		if current_charge >= minimum_charge and charge_full_autod_previously == false:
			try_fire()
		elif charge_full_autod_previously == true:
			charge_full_autod_previously = false
		
		current_charge = 0

func _attempt_queue_fire():
	if is_fire_queued == true:
		try_fire()
		is_fire_queued = false

func try_fire():
	determine_can_fire()

	if can_fire == true:
		fire_rate_timer.start(fire_rate)

		if is_burst_fire == true:
			burst_fire()
		else:
			regular_fire()
		

	elif can_fire == false and allow_queued_firing == true:
		if Input.is_action_just_pressed("primary_action") and fire_rate_timer.time_left <= time_left_to_queue:
			is_fire_queued = true

func burst_fire():
	is_bursting = true

	for n in (burst_amount):
		shoot()
		burst_timer.start(burst_fire_rate)
		await burst_timer.timeout

	is_bursting = false

func regular_fire():
	shoot()

func shoot():
	var spread_increment = (PI * (1 - initial_accuracy)) / projectile_count
	var initial_rotation

	if is_hitscan == true:
		# Uses the first hitscan_raycast in the array since they should all be aligned,
		#	circumstantial to the _physics_process() function
		initial_rotation = hitscan_raycasts[0].rotation
	else:
		initial_rotation = get_global_rotation()

	# Subtracts half of the entire width of the spread from the initial_rotation to determine
	#	the starting point for the spread, and then rotates down with each subsequent projectile.
	# (This process is just super smash n64 fox up + b move lmao)
	var rotation_param = initial_rotation - ((PI * (1 - initial_accuracy)) / 2)

	# Not sure why but the rotation_param needs to be adjusted by half of a spread increment to
	#	align properly, otherwise it shoots too far counter clockwise. Probably some basic math
	#	I'm overlooking at the time of coding
	rotation_param += spread_increment / 2

	var projectile_charge = float(1)

	if is_charge_fire == true:
		projectile_charge = current_charge

	if(is_hitscan == true):
		for n in hitscan_raycasts.size():
			if projectile_even_spread == true:
				fire_hitscan(hitscan_raycasts[n], hitscan_projectile_instances[n], rotation_param, projectile_charge)
				rotation_param += spread_increment
			else:
				fire_hitscan(hitscan_raycasts[n], hitscan_projectile_instances[n], apply_accuracy(hitscan_raycasts[n].rotation, initial_accuracy), projectile_charge)

	else:
		for n in projectile_count:
			if projectile_even_spread == true:
				fire_projectile(physics_projectile, $BulletInstancePoint.get_global_position(), rotation_param, projectile_charge)
				rotation_param += spread_increment
			else:
				fire_projectile(physics_projectile, $BulletInstancePoint.get_global_position(), apply_accuracy(get_global_rotation(), initial_accuracy), projectile_charge)

	print("fire", magazine_count, "/", magazine_size)

# fire_projectile() uses the physics_projectile: PackedScene which is generally provided
#	in the editor per gun. See PhysicsProjectilePrefab.tscn for more info
func fire_projectile(projectile_scene: PackedScene, projectile_start_point: Vector2, projectile_rotation: float, projectile_charge: float = float(1)):
	var projectile_instance = projectile_scene.instantiate()
	projectile_instance.position = projectile_start_point
	projectile_instance.rotation = projectile_rotation
	projectile_instance.charge = projectile_charge
	get_tree().get_root().add_child(projectile_instance)

	projectile_instance.apply_impulse(Vector2(projectile_instance.projectile_speed, 0).rotated(projectile_instance.rotation), Vector2())

	projectile_instance.enemy_hit.connect(_on_enemy_hit)
	projectile_instance.enemy_exit.connect(_on_enemy_exit)
	projectile_instance.wall_hit.connect(_on_wall_hit)
	projectile_instance.wall_exit.connect(_on_wall_exit)

	magazine_count -= projectile_instance.ammo_per_shot

# fire_hitscan() uses the hitscan_projectile: PackedScene which is generally provided
#	in the editor per gun. See HitscanProjectilePrefab.tscn for more info
func fire_hitscan(ray: RayCast2D, projectile, projectile_rotation: float, projectile_charge: float = float(1)):
	projectile.charge = projectile_charge

	if(initial_accuracy < 1):
		ray.target_position = ray.target_position.rotated(projectile_rotation)

	var check_next = true
	while check_next == true:
		ray.force_raycast_update()

		if ray.is_colliding():
			var collider = ray.get_collider()
			var collision_point = ray.get_collision_point()
			var collision_rotation = ray.get_global_rotation()
			projectile.on_collision(collider, collision_point, collision_rotation)
		
			if (collider.is_in_group("Enemy") and projectile.is_enemy_piercing == true) or (collider.is_in_group("Wall") and projectile.is_wall_piercing == true):
				check_next = true
				ray.add_exception(collider)
				
			else:
				check_next = false

		else:
			check_next = false
	
	ray.clear_exceptions()
	magazine_count -= projectile.ammo_per_shot

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

func damage_enemy(enemy, damage) -> void:
	enemy.take_damage(damage)

func apply_accuracy(initial_rotation, accuracy: float) -> float:
	var rad_offset = PI * (1 - accuracy) 
	return randf_range(initial_rotation - rad_offset, initial_rotation + rad_offset)

func start_reload():
	reload_timer.start(reload_time)
	is_reloading = true

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
	timer.autostart = false
	return timer

func initialize_raycast() -> RayCast2D:
	var raycast = RayCast2D.new()
	raycast.hit_from_inside = true
	raycast.exclude_parent = true 
	raycast.collision_mask = hitscan_collision_mask
	raycast.enabled = true

	return raycast

func get_default_ray_target() -> Vector2:
	return Vector2(hitscan_ray_length, 0)


###############################
# EXTERNAL SIGNAL CONNECTIONS #
###############################

func _on_enemy_hit(hit_position: Vector2, enemy: Node, projectile):
	damage_enemy(enemy, projectile.damage)

	if is_hitscan == false:
		if projectile.is_enemy_piercing == false:
			projectile.queue_free()
		elif projectile.is_enemy_piercing == true:
			projectile.collider.add_collision_exception_with(enemy)
			projectile.collider.linear_velocity = Vector2(projectile.projectile_speed, 0).rotated(projectile.get_global_rotation())

func _on_enemy_exit(hit_position: Vector2, enemy: Node, projectile):
	if is_hitscan == false and projectile.is_enemy_piercing == true:
		projectile.collider.remove_collision_exception_with(enemy)

func _on_wall_hit(hit_position: Vector2, wall: Node, projectile):
	if is_hitscan == false:
		if projectile.is_wall_piercing == false:
			projectile.queue_free()
		elif projectile.is_wall_piercing == true:
			projectile.collider.add_collision_exception_with(wall)
			projectile.collider.linear_velocity = Vector2(projectile.projectile_speed, 0).rotated(projectile.get_global_rotation())
	
func _on_wall_exit(hit_position: Vector2, wall: Node, projectile):
	if is_hitscan == false and projectile.is_wall_piercing == true:
		projectile.collider.remove_collision_exception_with(wall)


