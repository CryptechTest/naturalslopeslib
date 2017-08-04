--[[
This is where all the new nodes are registered.
The group natural_slope will be added to all of the new nodes.
The group falling_natural_slope will be added to the new nodes that have falling_node.
--]]

-- Dirt slopes

natural_slopes.register_slope("default:dirt", {
	groups = {crumbly = 3},
	tiles = {"default_dirt.png"},
	description = "Dirt slope",
	sounds = default.node_sound_dirt_defaults({
		footstep = {['name'] = "default_grass_footstep", ['gain'] = 0.25},
	})},
	10)
natural_slopes.register_slope("default:dirt_with_grass", {
	groups = {crumbly = 3, soil = 1, spreading_dirt_type = 1},
	tiles = {"default_grass.png", "default_dirt.png",
		{name = "default_dirt.png^default_grass_side.png",
			tileable_vertical = false}},
	sounds = default.node_sound_dirt_defaults({
		footstep = {name = "default_grass_footstep", gain = 0.25},
	})},
	50
)


-- Sand slopes

natural_slopes.register_slope("default:sand", {
	groups = {crumbly = 3, falling_node = 1, sand = 1},
	tiles = {"default_sand.png"},
	description = "Sand slope",
	sounds = default.node_sound_sand_defaults()},
	5
)
natural_slopes.register_slope("default:desert_sand", {
	groups = {crumbly = 3, falling_node = 1, sand = 1},
	tiles = {"default_desert_sand.png"},
	description = "Desert sand slope",
	sounds = default.node_sound_sand_defaults()},
	5
)
natural_slopes.register_slope("default:silver_sand", {
	groups = {crumbly = 3, falling_node = 1, sand = 1},
	tiles = {"default_silver_sand.png"},
	description = "Silver sand slope",
	sounds = default.node_sound_sand_defaults()},
	5
)
natural_slopes.register_slope("default:gravel", {
	groups = {crumbly = 2, falling_node = 1},
	tiles = {"default_gravel.png"},
	description = "Gravel slope",
	sounds = default.node_sound_sand_defaults()},
	7
)

