extends Sprite2D

@export var bullet_speed = 550
@export var fire_rate = 0.3

var bullet = preload("res://scenes/tempbullet.tscn")
var can_fire = true

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_pressed("primary_action") and can_fire == true:
		var bullet_instance = bullet.instantiate()
		bullet_instance.position = $BulletInstancePoint.get_global_position()
		bullet_instance.rotation = global_rotation
		bullet_instance.apply_impulse(Vector2(bullet_speed, 0).rotated(global_rotation), Vector2())
		get_tree().get_root().add_child(bullet_instance)

		can_fire = false
		await(get_tree().create_timer(fire_rate).timeout)
		can_fire = true
