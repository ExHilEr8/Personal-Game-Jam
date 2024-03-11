class_name Enemy extends CharacterBody2D

@export_category("Stats")
@export var max_health: float = float(100)
@export var health: float = float(100):
	get:
		return health
	set(value):
		health = value
		health = clamp(health, 0, max_health)

@export var despawn_on_death: bool = true

signal took_damage(damage: float)
signal took_lethal_damage()

# Called when the node enters the scene tree for the first time.
func _ready():
	_update_floating_health(0)
	took_damage.connect(_update_floating_health)
	took_lethal_damage.connect(_on_lethal_damage)

func take_damage(damage: float) -> void:
	health -= damage
	took_damage.emit(damage)

	if(health - damage < 0):
		took_lethal_damage.emit()

func _on_lethal_damage():
	if despawn_on_death == true:
		queue_free()

func _update_floating_health(damage: float):
	$FloatingUIContainer.get_node("Label").text = (str(health).pad_decimals(0) + "/" + str(max_health).pad_decimals(0))
