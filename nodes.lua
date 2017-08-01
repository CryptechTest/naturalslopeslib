--[[
This is where all the new nodes are registered.
The group natural_slope will be added to all of the new nodes.
The group falling_natural_slope will be added to the new nodes that have falling_node.
--]]

-- Dirt slopes

natural_slopes.register_slope(
	"dirt",
	"default:dirt",
	{crumbly = 3},
	{"default_dirt.png"},
	"Dirt slope",
	default.node_sound_dirt_defaults({
		footstep = {['name'] = "default_grass_footstep", ['gain'] = 0.25},
	}),
	10
)


-- Sand slopes

natural_slopes.register_slope(
	"sand",
	"default:sand",
	{crumbly = 3, falling_node = 1, sand = 1},
	{"default_sand.png"},
	"Sand slope",
	default.node_sound_sand_defaults(),
	5
)
natural_slopes.register_slope(
	"desert_sand",
	"default:desert_sand",
	{crumbly = 3, falling_node = 1, sand = 1},
	{"default_desert_sand.png"},
	"Silver sand slope",
	default.node_sound_sand_defaults(),
	5
)
natural_slopes.register_slope(
	"silver_sand",
	"default:silver_sand",
	{crumbly = 3, falling_node = 1, sand = 1},
	{"default_silver_sand.png"},
	"Desert sand slope",
	default.node_sound_sand_defaults(),
	5
)
natural_slopes.register_slope(
	"gravel",
	"default:gravel",
	{crumbly = 2, falling_node = 1},
	{"default_gravel.png"},
	"Gravel slope",
	default.node_sound_sand_defaults(),
	7
)
