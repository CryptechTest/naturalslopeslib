
-- Table of replacement from solid block to slopes.
-- Populated on slope node registration with add_replacement
local replacements = {}
local replacement_ids = {}
local function add_replacement(source_name, update_chance)
	local subname = string.sub(source_name, string.find(source_name, ':') + 1)
	local straight_name = natural_slopes.get_straight_slope_name(subname)
	local ic_name = natural_slopes.get_inner_corner_slope_name(subname)
	local oc_name = natural_slopes.get_outer_corner_slope_name(subname)
	local pike_name = natural_slopes.get_pike_slope_name(subname)
	local source_id = minetest.get_content_id(source_name)
	local straight_id = minetest.get_content_id(straight_name)
	local ic_id = minetest.get_content_id(ic_name)
	local oc_id = minetest.get_content_id(oc_name)
	local pike_id = minetest.get_content_id(pike_name)
	-- Full to slopes
	local dest_data = {
		source = source_name,
		straight = straight_name,
		inner = ic_name,
		outer = oc_name,
		pike = pike_name,
		chance = update_chance
	}
	local dest_data_id = {
		source = source_id,
		straight = straight_id,
		inner = ic_id,
		outer = oc_id,
		pike = pike_id,
		chance = update_chance
	}
	-- Block
	replacements[source_name] = dest_data
	replacement_ids[source_id] = dest_data_id
	-- Straight
	replacements[straight_name] = dest_data
	replacement_ids[straight_id] = dest_data_id
	-- Inner
	replacements[ic_name] = dest_data
	replacement_ids[ic_id] = dest_data_id
	-- Outer
	replacements[oc_name] = dest_data
	replacement_ids[oc_id] = dest_data_id
	-- Pike
	replacements[pike_name] = dest_data
	replacement_ids[pike_id] = dest_data_id
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
local slope_pike_box = {
	type = "fixed",
	fixed = {
		{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
	},
}

local function tile_get(tiles, side)
	if natural_slopes.setting_smooth_rendering()
	and (side == 'front' or side == 'side' or side == 'back') then
		return tiles.top
	end
	if side == 'top' then return tiles.top end
	if side == 'bottom' then return tiles.bottom or tiles.top end
	if side == 'front' then return tiles.front or tiles.top end
	if side == 'side' then return tiles.side or tiles.front or tiles.top end
	if side == 'back' then return tiles.back or tiles.side or tiles.front or tiles.top end
end

--- {Private} Register a straight slope and link to the original node.
local function register_slope_straight(base_node_name, node_desc, update_chance)
	-- Register slope node
	local subname = string.sub(base_node_name, string.find(base_node_name, ':') + 1)
	if natural_slopes.setting_smooth_rendering() then
		node_desc.drawtype = 'mesh'
		node_desc.mesh = 'natural_slopes_straight.obj'
	else
		node_desc.drawtype = 'nodebox'
		node_desc.node_box = slope_straight_box
	end
	node_desc.selection_box = slope_straight_box
	node_desc.collision_box = slope_straight_box
	node_desc.paramtype = 'light'
	node_desc.paramtype2 = 'facedir'
	node_desc.is_ground_content = true
	if node_desc.tiles and node_desc.tiles.top then
		local tiles = {tile_get(node_desc.tiles, 'top')}
		tiles[#tiles+1] = tile_get(node_desc.tiles, 'bottom')
		tiles[#tiles+1] = tile_get(node_desc.tiles, 'side')
		tiles[#tiles+1] = tile_get(node_desc.tiles, 'side')
		tiles[#tiles+1] = tile_get(node_desc.tiles, 'back')
		tiles[#tiles+1] = tile_get(node_desc.tiles, 'front')
		node_desc.tiles = tiles
	end
	if not node_desc.groups then node_desc.groups = {} end
	node_desc.groups.natural_slope = 1
	if not node_desc.drop then
		node_desc.drop = base_node_name
	end
	local slope_name = natural_slopes.get_straight_slope_name(subname)
	minetest.register_node(slope_name, node_desc)
	-- Register stomp
	if natural_slopes.setting_enable_shape_on_walk() then
		poschangelib.register_stomp(slope_name,
			natural_slopes.update_shape_on_walk,
			{name = slope_name .. '_upd_shape',
			chance = update_chance, priority = 500})
	end
end

--- {Private} Register an inner corner and link to the original node.
local function register_slope_inner(base_node_name, node_desc, update_chance)
	local subname = string.sub(base_node_name, string.find(base_node_name, ':') + 1)
	if natural_slopes.setting_smooth_rendering() then
		node_desc.drawtype = 'mesh'
		node_desc.mesh = 'natural_slopes_inner.obj'
	else
		node_desc.drawtype = 'nodebox'
		node_desc.node_box = slope_inner_corner_box
	end
	node_desc.selection_box = slope_inner_corner_box
	node_desc.collision_box = slope_inner_corner_box
	node_desc.paramtype = 'light'
	node_desc.paramtype2 = 'facedir'
	node_desc.is_ground_content = true
	if node_desc.tiles and node_desc.tiles.top then
		local tiles = {tile_get(node_desc.tiles, 'top')}
		tiles[#tiles+1] = tile_get(node_desc.tiles, 'bottom')
		tiles[#tiles+1] = tile_get(node_desc.tiles, 'front')
		tiles[#tiles+1] = tile_get(node_desc.tiles, 'back')
		tiles[#tiles+1] = tile_get(node_desc.tiles, 'back')
		tiles[#tiles+1] = tile_get(node_desc.tiles, 'front')
		node_desc.tiles = tiles
	end
	if not node_desc.groups then node_desc.groups = {} end
	node_desc.groups.natural_slope = 1
	if not node_desc.drop then
		node_desc.drop = base_node_name
	end
	local slope_name = natural_slopes.get_inner_corner_slope_name(subname)
	minetest.register_node(slope_name, node_desc)

	-- Register walk listener
	if natural_slopes.setting_enable_shape_on_walk() then
		poschangelib.register_stomp(slope_name,
			natural_slopes.update_shape_on_walk,
			{name = slope_name .. '_upd_shape',
			chance = update_chance, priority = 500})

	end
end

--- {Private} Register an outer corner and link to the original node.
local function register_slope_outer(base_node_name, node_desc, update_chance)
	local subname = string.sub(base_node_name, string.find(base_node_name, ':') + 1)
	if natural_slopes.setting_smooth_rendering() then
		node_desc.drawtype = 'mesh'
		node_desc.mesh = 'natural_slopes_outer.obj'
	else
		node_desc.drawtype = 'nodebox'
		node_desc.node_box = slope_outer_corner_box
	end
	node_desc.selection_box = slope_outer_corner_box
	node_desc.collision_box = slope_outer_corner_box
	node_desc.paramtype = 'light'
	node_desc.paramtype2 = 'facedir'
	node_desc.is_ground_content = true
	if node_desc.tiles and node_desc.tiles.top then
		local tiles = {tile_get(node_desc.tiles, 'top')}
		tiles[#tiles+1] = tile_get(node_desc.tiles, 'bottom')
		tiles[#tiles+1] = tile_get(node_desc.tiles, 'front')
		tiles[#tiles+1] = tile_get(node_desc.tiles, 'back')
		tiles[#tiles+1] = tile_get(node_desc.tiles, 'back')
		tiles[#tiles+1] = tile_get(node_desc.tiles, 'front')
		node_desc.tiles = tiles
	end
	if not node_desc.groups then node_desc.groups = {} end
	node_desc.groups.natural_slope = 1
	if not node_desc.drop then
		node_desc.drop = base_node_name
	end
	local slope_name = natural_slopes.get_outer_corner_slope_name(subname)
	minetest.register_node(slope_name, node_desc)

	-- Register walk listener
	if natural_slopes.setting_enable_shape_on_walk() then
		poschangelib.register_stomp(slope_name,
			natural_slopes.update_shape_on_walk,
			{name = slope_name .. '_upd_shape',
			chance = update_chance, priority = 500})
	end
end

--- {Private} Register a pike and link to the original node.
local function register_slope_pike(base_node_name, node_desc, update_chance)
	local subname = string.sub(base_node_name, string.find(base_node_name, ':') + 1)
	if natural_slopes.setting_smooth_rendering() then
		node_desc.drawtype = 'mesh'
		node_desc.mesh = 'natural_slopes_pike.obj'
	else
		node_desc.drawtype = 'nodebox'
		node_desc.node_box = slope_pike_box
	end
	node_desc.selection_box = slope_pike_box
	node_desc.collision_box = slope_pike_box
	node_desc.paramtype = 'light'
	node_desc.is_ground_content = true
	if node_desc.tiles and node_desc.tiles.top then
		local tiles = {tile_get(node_desc.tiles, 'top')}
		tiles[#tiles+1] = tile_get(node_desc.tiles, 'bottom')
		tiles[#tiles+1] = tile_get(node_desc.tiles, 'front')
		tiles[#tiles+1] = tile_get(node_desc.tiles, 'front')
		tiles[#tiles+1] = tile_get(node_desc.tiles, 'front')
		tiles[#tiles+1] = tile_get(node_desc.tiles, 'front')
		node_desc.tiles = tiles
	end
	if not node_desc.groups then node_desc.groups = {} end
	node_desc.groups.natural_slope = 1
	if not node_desc.drop then
		node_desc.drop = base_node_name
	end
	local slope_name = natural_slopes.get_pike_slope_name(subname)
	minetest.register_node(slope_name, node_desc)
	-- Register walk listener
	if natural_slopes.setting_enable_shape_on_walk() then
		poschangelib.register_stomp(slope_name,
			natural_slopes.update_shape_on_walk,
			{name = slope_name .. '_upd_shape',
			chance = update_chance, priority = 500})
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
-- @param base_node_name: The full block node name.
-- @param node_desc: base for slope node descriptions.
-- @param update_chance: inverted chance for the node to be updated.
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
	local_desc = table_copy(node_desc)
	register_slope_pike(base_node_name, local_desc, update_chance)
	add_replacement(base_node_name, update_chance)
	-- Enable on walk update
	if natural_slopes.setting_enable_shape_on_walk() then
		poschangelib.register_stomp(base_node_name,
			natural_slopes.update_shape_on_walk,
			{name = base_node_name .. '_upd_shape',
			chance = update_chance, priority = 500})
	end
end

