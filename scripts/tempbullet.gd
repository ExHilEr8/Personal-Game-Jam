extends RigidBody2D

@export var sound_volume : float = 0.0

var bullet_impact_animation = preload("res://scenes/bullet_effect_animation.tscn")
var sound = preload("res://assets/audio/hitmarker.wav")

func _on_body_entered(body:Node):
	if not body.is_in_group("Player"):
		var bullet_impact_instance = bullet_impact_animation.instantiate()
		bullet_impact_instance.position = get_global_position()
		bullet_impact_instance.play("bulletimpact")
		get_tree().get_root().add_child(bullet_impact_instance)
		play_sound()

		queue_free()

# Instantiates a new AudioStreamPlayer2D to play the preloaded sound at the 
#	bullet location.
func play_sound():
	var audio_stream_player = AudioStreamPlayer2D.new()
	get_tree().get_root().add_child(audio_stream_player)
	audio_stream_player.position = get_global_position()
	audio_stream_player.stream = sound
	audio_stream_player.volume_db = sound_volume
	audio_stream_player.play()
