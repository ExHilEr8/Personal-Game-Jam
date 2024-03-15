class_name Projectile extends Node2D

@export_category("Projectile Stats")
@export var damage: float = float(1)
@export var ammo_per_shot: int = int(1)

@export_category("Animation")
@export var impact_animator: PackedScene
@export var animation_name: String = "default"
@export var rotate_animation_with_bullet: bool = true

@export_category("Audio")
@export var impact_sound: AudioStream
@export var sound_volume : float = 0.0
@export var sound_attenuation: float = float(1)

var impact_effect: ImpactEffect = ImpactEffect.new()

signal enemy_hit(position: Vector2, enemy: Node, projectile)

func determine_projectile_interaction(parent, body: Node, bullet_global_position: Vector2, bullet_global_rotation: float):
	if not body.is_in_group("Player") and body.is_in_group("Enemy"):
		on_enemy_hit(parent, body, bullet_global_position, bullet_global_rotation)

# parent variable is included to allow instantiating animations and sounds under
#	a preferred node. Gives more control over both if desired
func on_enemy_hit(parent, enemy: Node, hit_position: Vector2, hit_rotation: float):
	if(impact_animator != null):
		impact_effect.play_animation(parent, impact_animator, animation_name, hit_position, hit_rotation)

	if(impact_sound != null):	
		impact_effect.play_sound(parent, impact_sound, hit_position, sound_volume, sound_attenuation)

	enemy_hit.emit(hit_position, enemy, self)
