class_name HitEffect extends RigidBody2D

func play_sound(sound: AudioStream, sound_position: Vector2, sound_volume: float):
	var audio_stream_player = AudioStreamPlayer2D.new()
	get_tree().get_root().add_child(audio_stream_player)
	audio_stream_player.stream = sound
	audio_stream_player.position = sound_position
	audio_stream_player.volume_db = sound_volume
	audio_stream_player.play()

func play_animation(impact_animation, animation_position: Vector2):
	var impact_instance = impact_animation.instantiate()
	impact_instance.position = animation_position
	impact_instance.play("bulletimpact")
	get_tree().get_root().add_child(impact_instance)
