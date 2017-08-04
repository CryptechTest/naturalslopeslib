--[[ Bounding boxes
Even with a slope model, we use a stair bounding box because it is less costly
and is more bugproof that a precise box (sometime the player get stuck while trying
to climb the slope).
Moreover it can be sufficient.
--]]

local slope_straight_box = {
	type = "fixed",
	fixed = {
		{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
		{-0.5, 0, 0, 0.5, 0.5, 0.5},
	},
}
local slope_inner_corner_box = {
	type = "fixed",
	fixed = {
		{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
		{-0.5, 0, 0, 0.5, 0.5, 0.5},
		{-0.5, 0, -0.5, 0, 0.5, 0},
	},
}
local slope_outer_corner_box = {
	type = "fixed",
	fixed = {
		{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
		{-0.5, 0, 0, 0, 0.5, 0.5},
	},
}

-- Set mesh constants according to settings
local SLOPE_MESH = "twelve-twelve.obj"
local INNER_CORNER_MESH = "twelve-twelve-ic.obj"
local OUTER_CORNER_MESH = "twelve-twelve-oc.obj"
if natural_slopes.setting_rendering_mode() == 1 then
	SLOPE_MESH = "stairs_stair.obj"
	INNER_CORNER_MESH = "stairs_stair_inner.obj"
	OUTER_CORNER_MESH = "stairs_stair_outer.obj"
end

--- {Private} Register a straight slope and link to the original node.
-- @param subname: The name passed to natural_slopes.get_straigth_slope_name
-- @param base_node_name: The full block node name.
-- @param groups: The groups that the slope node will have.
-- @param images:
-- @param descriptions: Description of the new slope node.
-- @param sounds:
function natural_slopes.register_slope_straight(base_node_name, node_desc, update_chance)
	-- Register slope node
	local subname = string.sub(base_node_name, string.find(base_node_name, ':') + 1)
	node_desc.drawtype = "mesh"
	node_desc.mesh = SLOPE_MESH
	node_desc.selection_box = slope_straight_box
	node_desc.collision_box = slope_straight_box
	node_desc.paramtype = 'light'
	node_desc.paramtype2 = 'facedir'
	node_desc.is_ground_content = true
	if not node_desc.groups then node_desc.groups = {} end
	node_desc.groups.natural_slope = 1
	local slope_name = natural_slopes.get_straight_slope_name(subname)
	minetest.register_node(slope_name, node_desc)
	-- Set shape update data
	natural_slopes.straight_replacements[base_node_name] = slope_name
	natural_slopes.rebuild_replacements[slope_name] = base_node_name
	natural_slopes.all_nodes[base_node_name] = update_chance
	natural_slopes.all_nodes[slope_name] = update_chance
	-- Set recipes
	minetest.register_craft({
			output = slope_name .. ' 6',
			recipe = {
				{"", "", base_node_name},
				{"", base_node_name, base_node_name},
				{base_node_name, base_node_name, base_node_name},
		},
	})
	minetest.register_craft({
		output = base_node_name .. ' 4',
		recipe = {
			{slope_name, slope_name},
			{slope_name, slope_name},
		},
	})
	-- Register walk listener
	if natural_slopes.setting_enable_shape_on_walk() then
		poschangelib.add_player_walk_listener('natural_slopes:update_on_walk',
			natural_slopes.update_shape_on_walk,
			{slope_name})
	end
end

--- {Private} Register an inner corner and link to the original node.
-- @param subname: The name passed to natural_slopes.get_straigth_inner_corner_name
-- @param base_node_name: The full block node name.
-- @param groups: The groups that the slope node will have.
-- @param images:
-- @param descriptions: Description of the new slope node.
-- @param sounds:
function natural_slopes.register_slope_inner(base_node_name, node_desc, update_chance)
	local subname = string.sub(base_node_name, string.find(base_node_name, ':') + 1)
	node_desc.drawtype = "mesh"
	node_desc.mesh = INNER_CORNER_MESH
	node_desc.selection_box = slope_inner_corner_box
	node_desc.collision_box = slope_inner_corner_box
	node_desc.paramtype = 'light'
	node_desc.paramtype2 = 'facedir'
	node_desc.is_ground_content = true
	if not node_desc.groups then node_desc.groups = {} end
	node_desc.groups.natural_slope = 1
	local slope_name = natural_slopes.get_inner_corner_slope_name(subname)
	minetest.register_node(slope_name, node_desc)
	natural_slopes.inner_corner_replacements[base_node_name] = slope_name
	natural_slopes.rebuild_replacements[slope_name] = base_node_name
	natural_slopes.all_nodes[base_node_name] = update_chance
	natural_slopes.all_nodes[slope_name] = update_chance
	-- Set recipes
	minetest.register_craft({
			output = slope_name .. ' 6',
			recipe = {
				{"", base_node_name, ""},
				{base_node_name, "", base_node_name},
				{base_node_name, base_node_name, base_node_name},
		},
	})
	minetest.register_craft({
		output = base_node_name .. ' 4',
		recipe = {
			{slope_name, slope_name},
			{slope_name, slope_name},
		},
	})
	-- Register walk listener
	if natural_slopes.setting_enable_shape_on_walk() then
		poschangelib.add_player_walk_listener('natural_slopes:update_on_walk',
			natural_slopes.update_shape_on_walk,
			{slope_name})
	end
end

--- {Private} Register an outer corner and link to the original node.
-- @param subname: The name passed to natural_slopes.get_straigth_inner_corner_name
-- @param base_node_name: The full block node name.
-- @param groups: The groups that the slope node will have.
-- @param images:
-- @param descriptions: Description of the new slope node.
-- @param sounds:
function natural_slopes.register_slope_outer(base_node_name, node_desc, update_chance)
	local subname = string.sub(base_node_name, string.find(base_node_name, ':') + 1)
	node_desc.drawtype = "mesh"
	node_desc.mesh = OUTER_CORNER_MESH
	node_desc.selection_box = slope_outer_corner_box
	node_desc.collision_box = slope_outer_corner_box
	node_desc.paramtype2 = 'facedir'
	node_desc.is_ground_content = true
	if not node_desc.groups then node_desc.groups = {} end
	node_desc.groups.natural_slope = 1
	local slope_name = natural_slopes.get_outer_corner_slope_name(subname)
	minetest.register_node(slope_name, node_desc)
	natural_slopes.outer_corner_replacements[base_node_name] = slope_name
	natural_slopes.rebuild_replacements[slope_name] = base_node_name
	natural_slopes.all_nodes[base_node_name] = update_chance
	natural_slopes.all_nodes[slope_name] = update_chance
	-- Set recipes
	minetest.register_craft({
			output = slope_name .. ' 4',
			recipe = {
				{"", "", ""},
				{"", base_node_name, ""},
				{base_node_name, base_node_name, base_node_name},
		},
	})
	minetest.register_craft({
		output = base_node_name .. ' 4',
		recipe = {
			{slope_name, slope_name},
			{slope_name, slope_name},
		},
	})
	-- Register walk listener
	if natural_slopes.setting_enable_shape_on_walk() then
		poschangelib.add_player_walk_listener('natural_slopes:update_on_walk',
			natural_slopes.update_shape_on_walk,
			{slope_name})
	end
end

--- Register slopes from a full block node.
-- @param subname: The name passed to natural_slopes.get_*_name
-- @param base_node_name: The full block node name.
-- @param groups: The groups that the slope nodes will have.
-- @param images:
-- @param descriptions: Description of the new slope node.
-- @param sounds:
function natural_slopes.register_slope(base_node_name, node_desc, update_chance)
	natural_slopes.register_slope_straight(base_node_name, node_desc, update_chance)
	natural_slopes.register_slope_inner(base_node_name, node_desc, update_chance)
	natural_slopes.register_slope_outer(base_node_name, node_desc, update_chance)
	if _G.poschangelib then
		poschangelib.add_player_walk_listener('natural_slopes:update_on_walk',
			natural_slopes.update_shape_on_walk,
			{base_node_name})
	end

end
