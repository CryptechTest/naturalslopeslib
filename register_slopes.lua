
-- Table of replacement from solid block to slopes.
-- Populated on slope node registration with add_replacement
local replacements = {}
local replacement_ids = {}
local function add_replacement(source_name, update_chance, fixed_replacements)
	local subname = string.sub(source_name, string.find(source_name, ':') + 1)
	local straight_name = nil
	local ic_name = nil
	local oc_name = nil
	local pike_name = nil
	if fixed_replacements then
		straight_name = fixed_replacements[1]
		ic_name = fixed_replacements[2]
		oc_name = fixed_replacements[3]
		pike_name = fixed_replacements[4]
	else
		straight_name = naturalslopeslib.get_straight_slope_name(subname)
		ic_name = naturalslopeslib.get_inner_corner_slope_name(subname)
		oc_name = naturalslopeslib.get_outer_corner_slope_name(subname)
		pike_name = naturalslopeslib.get_pike_slope_name(subname)
	end
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
function naturalslopeslib.get_replacement(source_node_name)
	return replacements[source_node_name]
end
--- Get replacement description of a node by content id for VoxelManip.
-- Contains replacement ids in either source or (straight, inner, outer)
-- and chance.
function naturalslopeslib.get_replacement_id(source_id)
	return replacement_ids[source_id]
end

function naturalslopeslib.get_all_shapes(source_node_name)
	if replacements[source_node_name] then
		local rp = replacements[source_node_name]
		return {rp.source, rp.straight, rp.inner, rp.outer, rp.pike}
	else
		return {source_node_name}
	end
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

--- {Private} Register a straight slope and link to the original node.
local function register_slope_straight(base_node_name, node_desc, update_chance)
	-- Register slope node
	local subname = string.sub(base_node_name, string.find(base_node_name, ':') + 1)
	if naturalslopeslib.setting_smooth_rendering() then
		node_desc.drawtype = 'mesh'
		node_desc.mesh = 'naturalslopeslib_straight.obj'
	else
		node_desc.drawtype = 'nodebox'
		node_desc.node_box = slope_straight_box
	end
	node_desc.selection_box = slope_straight_box
	node_desc.collision_box = slope_straight_box
	node_desc.paramtype = 'light'
	node_desc.paramtype2 = 'facedir'
	if not node_desc.groups then node_desc.groups = {} end
	node_desc.groups.natural_slope = 1
	if not node_desc.groups["family:" .. base_node_name] then
		node_desc.groups["family:" .. base_node_name] = 1
	end
	local slope_name = naturalslopeslib.get_straight_slope_name(subname)
	minetest.register_node(slope_name, node_desc)
	-- Register stomp
	if naturalslopeslib.setting_enable_shape_on_walk() then
		poschangelib.register_stomp(slope_name,
			naturalslopeslib.update_shape_on_walk,
			{name = slope_name .. '_upd_shape',
			chance = update_chance, priority = 500})
	end
	return slope_name
end

--- {Private} Register an inner corner and link to the original node.
local function register_slope_inner(base_node_name, node_desc, update_chance)
	local subname = string.sub(base_node_name, string.find(base_node_name, ':') + 1)
	if naturalslopeslib.setting_smooth_rendering() then
		node_desc.drawtype = 'mesh'
		node_desc.mesh = 'naturalslopeslib_inner.obj'
	else
		node_desc.drawtype = 'nodebox'
		node_desc.node_box = slope_inner_corner_box
	end
	node_desc.selection_box = slope_inner_corner_box
	node_desc.collision_box = slope_inner_corner_box
	node_desc.paramtype = 'light'
	node_desc.paramtype2 = 'facedir'
	if not node_desc.groups then node_desc.groups = {} end
	node_desc.groups.natural_slope = 2
	if not node_desc.groups["family:" .. base_node_name] then
		node_desc.groups["family:" .. base_node_name] = 1
	end
	local slope_name = naturalslopeslib.get_inner_corner_slope_name(subname)
	minetest.register_node(slope_name, node_desc)

	-- Register walk listener
	if naturalslopeslib.setting_enable_shape_on_walk() then
		poschangelib.register_stomp(slope_name,
			naturalslopeslib.update_shape_on_walk,
			{name = slope_name .. '_upd_shape',
			chance = update_chance, priority = 500})

	end
	return slope_name
end

--- {Private} Register an outer corner and link to the original node.
local function register_slope_outer(base_node_name, node_desc, update_chance)
	local subname = string.sub(base_node_name, string.find(base_node_name, ':') + 1)
	if naturalslopeslib.setting_smooth_rendering() then
		node_desc.drawtype = 'mesh'
		node_desc.mesh = 'naturalslopeslib_outer.obj'
	else
		node_desc.drawtype = 'nodebox'
		node_desc.node_box = slope_outer_corner_box
	end
	node_desc.selection_box = slope_outer_corner_box
	node_desc.collision_box = slope_outer_corner_box
	node_desc.paramtype = 'light'
	node_desc.paramtype2 = 'facedir'
	if not node_desc.groups then node_desc.groups = {} end
	node_desc.groups.natural_slope = 3
	if not node_desc.groups["family:" .. base_node_name] then
		node_desc.groups["family:" .. base_node_name] = 1
	end
	local slope_name = naturalslopeslib.get_outer_corner_slope_name(subname)
	minetest.register_node(slope_name, node_desc)

	-- Register walk listener
	if naturalslopeslib.setting_enable_shape_on_walk() then
		poschangelib.register_stomp(slope_name,
			naturalslopeslib.update_shape_on_walk,
			{name = slope_name .. '_upd_shape',
			chance = update_chance, priority = 500})
	end
	return slope_name
end

--- {Private} Register a pike and link to the original node.
local function register_slope_pike(base_node_name, node_desc, update_chance)
	local subname = string.sub(base_node_name, string.find(base_node_name, ':') + 1)
	if naturalslopeslib.setting_smooth_rendering() then
		node_desc.drawtype = 'mesh'
		node_desc.mesh = 'naturalslopeslib_pike.obj'
	else
		node_desc.drawtype = 'nodebox'
		node_desc.node_box = slope_pike_box
	end
	node_desc.selection_box = slope_pike_box
	node_desc.collision_box = slope_pike_box
	node_desc.paramtype = 'light'
	node_desc.paramtype2= 'facedir'
	if not node_desc.groups then node_desc.groups = {} end
	node_desc.groups.natural_slope = 4
	if not node_desc.groups["family:" .. base_node_name] then
		node_desc.groups["family:" .. base_node_name] = 1
	end
	local slope_name = naturalslopeslib.get_pike_slope_name(subname)
	minetest.register_node(slope_name, node_desc)
	-- Register walk listener
	if naturalslopeslib.setting_enable_shape_on_walk() then
		poschangelib.register_stomp(slope_name,
			naturalslopeslib.update_shape_on_walk,
			{name = slope_name .. '_upd_shape',
			chance = update_chance, priority = 500})
	end
	return slope_name
end

--- Register slopes from a full block node.
-- @param base_node_name: The full block node name.
-- @param node_desc: base for slope node descriptions.
-- @param update_chance: inverted chance for the node to be updated.
-- @return Table of slope names: [straight, inner, outer, pike] or nil on error.
function naturalslopeslib.register_slope(base_node_name, def_changes, update_chance)
	if not update_chance then
		minetest.log('error', 'Natural slopes: chance is not set for node ' .. base_node_name)
		return
	end
	local base_node_def = minetest.registered_nodes[base_node_name]
	if not base_node_def then
		minetest.log("error", "Trying to register slopes for an unknown node " .. (base_node_name or "nil"))
		return
	end
	local full_copy = table.copy(base_node_def)
	for key, value in pairs(def_changes) do
		if value == "nil" then
			full_copy[key] = nil
		else
			full_copy[key] = value
		end
	end
	-- Use a copy because tables are passed by reference. Otherwise the node
	-- description is shared and updated even after minetest.register_node
	local str_name = register_slope_straight(base_node_name, table.copy(full_copy), update_chance)
	local ic_name = register_slope_inner(base_node_name, table.copy(full_copy), update_chance)
	local oc_name = register_slope_outer(base_node_name, table.copy(full_copy), update_chance)
	local pk_name = register_slope_pike(base_node_name, table.copy(full_copy), update_chance)
	add_replacement(base_node_name, update_chance)
	-- Enable on walk update
	if naturalslopeslib.setting_enable_shape_on_walk() then
		poschangelib.register_stomp(base_node_name,
			naturalslopeslib.update_shape_on_walk,
			{name = base_node_name .. '_upd_shape',
			chance = update_chance, priority = 500})
	end
	-- Enable surface update
	if naturalslopeslib.setting_enable_surface_update() then
		twmlib.register_twm({
			nodenames = {base_node_name, str_name, ic_name, oc_name, pk_name},
			chance = update_chance,
			action = naturalslopeslib.update_shape
		})
	end
	return naturalslopeslib.get_replacement(base_node_name)
end

--- Add a slopping behaviour to existing nodes.
function naturalslopeslib.set_slopes(base_node_name, straight_name, inner_name, outer_name, pike_name, update_chance)
	-- Defensive checks
	if not minetest.registered_nodes[base_node_name] then
		if not base_node_name then
			minetest.log('error', 'naturalslopeslib.set_slopes failed: base node_name is nil.')
		else
			minetest.log('error', 'naturalslopeslib.set_slopes failed: ' .. base_node_name .. ' is not registered.')
		end
		return
	end
	if not minetest.registered_nodes[straight_name]
	or not minetest.registered_nodes[inner_name]
	or not minetest.registered_nodes[outer_name]
	or not minetest.registered_nodes[pike_name] then
		minetest.log('error', 'naturalslopeslib.set_slopes failed: one of the slopes for ' .. base_node_name .. ' is not registered.')
		return
	end
	if not update_chance then
		minetest.log('error', 'Natural slopes: chance is not set for node ' .. base_node_name)
		return
	end
	-- Set shape update data
	local slope_names = {straight_name, inner_name, outer_name, pike_name}
	add_replacement(base_node_name, update_chance, slope_names)
	-- Set surface update
	if naturalslopeslib.setting_enable_surface_update() then
		twmlib.register_twm({
			nodenames = {base_node_name, straight_name, inner_name, outer_name, pike_name},
			chance = update_chance,
			action = naturalslopeslib.update_shape
		})
	end
	-- Set walk listener for the 5 nodes
	if naturalslopeslib.setting_enable_shape_on_walk() then
		local stomp_desc = {name = base_node_name .. '_upd_shape',
			chance = update_chance, priority = 500}
		poschangelib.register_stomp(base_node_name, naturalslopeslib.update_shape_on_walk, stomp_desc)
		for i, name in pairs(slope_names) do
			poschangelib.register_stomp(name, naturalslopeslib.update_shape_on_walk, stomp_desc)
		end
	end
	return naturalslopeslib.get_replacement(base_node_name)
end

