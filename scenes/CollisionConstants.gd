class_name CollisionConstants

# These constants give an easy way to changing collision layers and masks.
# By adding constants, you can enable or disable a set of collision layers with one command
#	rather than using multiple to enable/disable each layer individually.
const ENEMY = int(2 ** ENEMY_BIT)
const ENEMYPROJECTILE = int(2 ** ENEMYPROJECTILE_BIT) 
const PLAYER = int(2 ** PLAYER_BIT) 
const PLAYERPROJECTILE = int(2 ** PLAYERPROJECTILE_BIT)
const WALL = int(2 ** WALL_BIT)


const ENEMY_LAYER = int(1)
const ENEMYPROJECTILE_LAYER = int(2)
const PLAYER_LAYER = int(3)
const PLAYERPROJECTILE_LAYER = int(4)
const WALL_LAYER = int(5)

const ENEMY_BIT = int(ENEMY_LAYER - 1)
const ENEMYPROJECTILE_BIT = int(ENEMYPROJECTILE_LAYER - 1)
const PLAYER_BIT = int(PLAYER_LAYER - 1)
const PLAYERPROJECTILE_BIT = int(PLAYERPROJECTILE_LAYER - 1)
const WALL_BIT = int(WALL_LAYER - 1)

static func get_final_layer(const_list: Array) -> int:
	var result = int(0)

	for item in const_list:
		result += int(item)
	
	return result