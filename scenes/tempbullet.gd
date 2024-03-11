extends HitEffect

@export var sound_volume : float = 0.0

signal enemy_hit(position: Vector2, enemy: Node)

var impact_animation = preload("res://scenes/bullet_effect_animation.tscn")
var sound = preload("res://assets/audio/hitmarker.wav")

func _on_body_entered(body:Node):
	if not body.is_in_group("Player") and body.is_in_group("Enemy"):
		var bullet_global_position = get_global_position()

		play_animation(impact_animation, bullet_global_position)
		play_sound(sound, bullet_global_position, sound_volume)
		enemy_hit.emit(bullet_global_position, body)
		
		queue_free()
