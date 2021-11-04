extends Area

# Utility class to setup collision layer and mask
# Set up in project/settings/autoload.
# Node name : CollisionManager.

# Player : layer 1 - mask 2, 3 = 6
# Terrain : layer 2 - mask 0
# Mobs : layer 3 - mask 1, 2,  = 3
# Weapons : layer 4 - mask 1, 2, 3 = 7
# Pickups / traps : layer 5 - mask 1 = 1
# Wall for mobs only : layer 8 - mask 3 = 4

func setup_player_layer_mask(_ob):
	_ob.set_collision_layer(1)
	_ob.set_collision_mask(6)
	
	
func setup_terrain_layer_mask(_ob):
	_ob.set_collision_layer(2)
	_ob.set_collision_mask(0)
	
	
func setup_mob_layer_mask(_ob):
	_ob.set_collision_layer(3)
	_ob.set_collision_mask(3)
	
	
func setup_weapon_layer_mask(_ob):
	_ob.set_collision_layer(4)
	_ob.set_collision_mask(7)
	
	
func setup_pickuptrap_layer_mask(_ob):
	_ob.set_collision_layer(5)
	_ob.set_collision_mask(1)

func setup_mobwall_layer_mask(_ob):
	_ob.set_collision_layer(8)
	_ob.set_collision_mask(0b10)


func setup_terrain_mask(_ob):
	_ob.set_collision_mask(2)


func setup_weapon_mask(_ob):
	_ob.set_collision_mask(0b111)

# Collide only with mob
func setup_mob_mask(_ob):
	_ob.set_collision_mask(0b100)

# Collide only with player
func setup_player_mask(_ob):
	_ob.set_collision_mask(0)
