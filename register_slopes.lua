
-- Table of replacement from solid block to slopes.
-- Populated on slope node registration with add_replacement
local replacements = {}
local replacement_ids = {}
local function add_replacement(source_name, update_chance)
	local subname = string.sub(source_name, string.find(source_name, ':') + 1)
	local straight_name = natural_slopes.get_straight_slope_name(subname)
	local ic_name = natural_slopes.get_inner_corner_slope_name(subname)
	local oc_name = natural_slopes.get_outer_corner_slope_name(subname)
	local source_id = minetest.get_content_id(source_name)
	local straight_id = minetest.get_content_id(straight_name)
	local ic_id = minetest.get_content_id(ic_name)
	local oc_id = minetest.get_content_id(oc_name)
	-- Full to slopes
	replacements[source_name] = {
		straight = straight_name,
		inner = ic_name,
		outer = oc_name,
		chance = update_chance
	}
	replacement_ids[source_id] = {
		straight = straight_id,
		inner = ic_id,
		outer = oc_id,
		chance = update_chance
	}
	-- Straight to full
	replacements[straight_name] = {
		source = source_name,
		chance = update_chance
	}
	replacement_ids[straight_id] = {
		source = source_id,
		chance = update_chance
	}
	-- Inner to full
	replacements[ic_name] = {
		source = source_name,
		chance = update_chance
	}
	replacement_ids[ic_id] = {
		source = source_id,
		chance = update_chance
	}
	-- Outer to full
	replacements[oc_name] = {
		source = source_name,
		chance = update_chance
	}
	replacement_ids[oc_id] = {
		source = source_id,
		chance = update_chance
	}
end

--- Get replacement description of a node.
-- Contains replacement names in either source or (straight, inner, outer)
-- and chance.
function natural_slopes.get_replacement(source_node_name)
	return replacements[source_node_name]
end
--- Get replacement description of a node by content id for VoxelManip.
-- Contains replacement ids in either source or (straight, inner, outer)
-- and chance.
function natural_slopes.get_replacement_id(source_id)
	return replacement_ids[source_id]
end

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
local function register_slope_straight(base_node_name, node_desc, update_chance)
	-- Register slope node
	local subname = string.sub(base_node_name, string.find(base_node_name, ':') + 1)
	node_desc.drawtype = "mesh"
	node_desc.mesh = SLOPE_MESH
	node_desc.selection_box = slope_straight_box
	node_desc.collision_box = slope_straight_box
	node_desc.paramtype2 = 'facedir'
	node_desc.is_ground_content = true
	if not node_desc.groups then node_desc.groups = {} end
	node_desc.groups.natural_slope = 1
	local slope_name = natural_slopes.get_straight_slope_name(subname)
	minetest.register_node(slope_name, node_desc)
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
local function register_slope_inner(base_node_name, node_desc, update_chance)
	local subname = string.sub(base_node_name, string.find(base_node_name, ':') + 1)
	node_desc.drawtype = "mesh"
	node_desc.mesh = INNER_CORNER_MESH
	node_desc.selection_box = slope_inner_corner_box
	node_desc.collision_box = slope_inner_corner_box
	node_desc.paramtype2 = 'facedir'
	node_desc.is_ground_content = true
	if not node_desc.groups then node_desc.groups = {} end
	node_desc.groups.natural_slope = 1
	local slope_name = natural_slopes.get_inner_corner_slope_name(subname)
	minetest.register_node(slope_name, node_desc)
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
local function register_slope_outer(base_node_name, node_desc, update_chance)
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

local function table_copy(table)
	local orig_type = type(table)
	local copy = {}
	if orig_type ~= 'table' then return table end
	for orig_key, orig_value in next, table, nil do
		copy[orig_key] = table_copy(orig_value)
	end
	return copy
end

--- Register slopes from a full block node.
-- @param subname: The name passed to natural_slopes.get_*_name
-- @param base_node_name: The full block node name.
-- @param groups: The groups that the slope nodes will have.
-- @param images:
-- @param descriptions: Description of the new slope node.
-- @param sounds:
function natural_slopes.register_slope(base_node_name, node_desc, update_chance)
	if not update_chance then
		minetest.log('error', 'Natural slopes: chance is not set for node ' .. base_node_name)
		return
	end
	-- Use a copy because tables are passed by reference. Otherwise the node
	-- description is shared and updated even after minetest.register_node
	local local_desc = table_copy(node_desc)
	register_slope_straight(base_node_name, local_desc, update_chance)
	local_desc = table_copy(node_desc)
	register_slope_inner(base_node_name, local_desc, update_chance)
	local_desc = table_copy(node_desc)
	register_slope_outer(base_node_name, local_desc, update_chance)
	add_replacement(base_node_name, update_chance)
	-- Enable on walk update
	if natural_slopes.setting_enable_shape_on_walk() then
		poschangelib.add_player_walk_listener('natural_slopes:update_on_walk',
			natural_slopes.update_shape_on_walk,
			{base_node_name})
	end
end

