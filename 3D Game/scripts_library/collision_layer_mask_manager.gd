extends Area

# Copy and paste functions to relevant scripts. 2D and  3D.

# Player : layer 1 - mask 2, 3, 4, 5
# Terrain : layer 2 - mask 1, 3, 4
# Mobs : layer 3 - mask 1, 2, 3, 4
# Weapons : layer 4 - mask 1, 2, 3
# Pickups / traps : layer 5 - mask 1

func setup_player_layer_mask(_ob):
	_ob.set_collision_layer(1)
	_ob.set_collision_mask(30)
	
	
func setup_terrain_layer_mask(_ob):
	_ob.set_collision_layer(2)
	_ob.set_collision_mask(13)
	
	
func setup_mob_layer_mask(_ob):
	_ob.set_collision_layer(4)
	_ob.set_collision_mask(15)
	
	
func setup_weapon_layer_mask(_ob):
	_ob.set_collision_layer(8)
	_ob.set_collision_mask(7)
	
	
func setup_pickuptrap_layer_mask(_ob):
	_ob.set_collision_layer(16)
	_ob.set_collision_mask(1)
