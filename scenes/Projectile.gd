class_name Projectile extends ImpactEffect

@export_category("Animation")
@export var impact_animator: PackedScene
@export var animation_name: String = "bulletimpact"

@export_category("Audio")
@export var impact_sound: AudioStream
@export var sound_volume : float = 0.0
@export var sound_attenuation: float = float(1)

signal enemy_hit(position: Vector2, enemy: Node)

func _on_body_entered(body:Node):
	determine_projectile_interaction(body)

func determine_projectile_interaction(body: Node):
	if not body.is_in_group("Player") and body.is_in_group("Enemy"):
		on_enemy_hit(body)

func on_enemy_hit(enemy: Node):
	var bullet_global_position = get_global_position()

	play_animation(impact_animator, animation_name, bullet_global_position, get_global_rotation())
	play_sound(impact_sound, bullet_global_position, sound_volume, sound_attenuation)
	enemy_hit.emit(bullet_global_position, enemy, self)
	
	queue_free()
