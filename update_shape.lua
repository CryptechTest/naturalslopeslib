--[[
Describes the falling/eroding effect for slopes
--]]

--- {Private} Pick a replacement node and set it at pos.
-- @param type The replacement shape. Either 'block', 'straight', 'ic' or 'oc'
-- @param name The name of the node to replace.
-- @param pos The position of the node to replace
-- @param pointing Optional vector to orient the new node.
-- @return True if the node is replaced, false otherwise.
function natural_slopes.select_and_replace(slope_type, name, pos, pointing)
	local replacement = natural_slopes.get_replacement(name)
	if not replacement then return false end
	local dest_node_name = nil
	if slope_type == 'block' and replacement.source then
		minetest.set_node(pos, {name=replacement.source})
		return true
	elseif slope_type == 'straight' and replacement.straight then
		dest_node_name = replacement.straight
	elseif slope_type == 'ic' and replacement.inner then
		dest_node_name = replacement.inner
	elseif slope_type == 'oc' and replacement.outer then
		dest_node_name = replacement.outer
	end
	if dest_node_name then
		minetest.set_node(pos, {name = dest_node_name, paramtype2='facedir',
			param2=minetest.dir_to_facedir(pointing)})
		return true
	end
	return false
end
function natural_slopes.area_select_and_replace(slope_type, data, param2_data, id, index, pointing)
	local replacement = natural_slopes.get_replacement_id(id)
	if not replacement then return false end
	local dest_node_id = nil
	if slope_type == 'block' and replacement.source then
		data[index] = replacement.source
		return true
	elseif slope_type == 'straight' and replacement.straight then
		dest_node_id = replacement.straight
	elseif slope_type == 'ic' and replacement.inner then
		dest_node_id = replacement.inner
	elseif slope_type == 'oc' and replacement.outer then
		dest_node_id = replacement.outer
	end
	if dest_node_id then
		data[index] = dest_node_id
		param2_data[index] = minetest.dir_to_facedir(pointing)
		return true
	end
	return false
end

--- Check if a node is considered empty to switch shape.
-- @param pos The position to check
function natural_slopes.is_free_for_erosion(pos)
	if not pos then return false end
	if minetest.get_node(pos).name == 'air' then return true end
	-- TODO add water for canditates
	return false
end
local air_id = minetest.get_content_id('air')
function natural_slopes.area_is_free_for_erosion(area, data, index)
	if not area:containsi(index) then return false end
	if data[index] == air_id then return true end
	return false
end

-- Do shape update when random roll passes.
function natural_slopes.chance_update_shape(pos, node, factor)
	if factor == nil then factor = 1 end
	local replacement = natural_slopes.get_replacement(node.name)
	if not replacement then return false end
	if (math.random() * (replacement.chance * factor)) < 1.0 then
		return natural_slopes.update_shape(pos, node)
	end
	return false
end
--- Massive shape update with VoxelManip.
-- @param minp Lower boundary of area.
-- @param mapx Higher boundary of area.
-- @param factor Factor for chance (0.1 means 10 times more likely to update)
function natural_slopes.area_chance_update_shape(minp, maxp, factor)
	-- Run on every block
	local vm, emin, emax = minetest.get_voxel_manip()
	local e1, e2 = vm:read_from_map(minp, maxp)
	local area = VoxelArea:new{MinEdge = e1, MaxEdge = e2}
	local data = vm:get_data()
	local param2_data = vm:get_param2_data()
	for i in area:iterp(vector.add(minp, 1), vector.add(maxp, -1)) do
		local replacement = natural_slopes.get_replacement_id(data[i])
		if replacement and (math.random() * (replacement.chance * factor)) < 1.0 then
			natural_slopes.update_shape(i, data[i], area, data, param2_data)
		end
	end
	vm:set_data(data)
	vm:set_param2_data(param2_data)
	vm:write_to_map()
end

--- Try to update the shape of a node according to it's surroundings.
-- @param pos The position of the node or index with VoxelArea.
-- @param node The node at that position or content id with VoxelArea.
-- @param area The VoxelArea, nil for single position update.
-- @param data Data from VoxelManip, nil for single position update.
-- @param param2_data Param2 data from VoxelManip, nil for single position update.
-- @return True if the node was updated, false otherwise.
function natural_slopes.update_shape(pos, node, area, data, param2_data)
	-- Set functions and data according to update mode: single or VoxelManip
	local is_free = nil
	local new_pos = nil
	local select_replace = nil
	local node_name = nil -- Either name or id
	if area then
		is_free = function (at_index) -- always use with new_pos
			return natural_slopes.area_is_free_for_erosion(area, data, at_index)
		end
		new_pos = function(add) -- Get new index from current with add position
			local area_pos = area:position(pos)
			return area:indexp(vector.add(area_pos, add))
		end
		select_replace = function(slope_type, name, pos, pointing)
			return natural_slopes.area_select_and_replace(slope_type,
				data, param2_data, name, pos, pointing)
		end
		node_name = node
	else
		is_free = natural_slopes.is_free_for_erosion
		new_pos = function(add) return vector.add(pos, add) end
		select_replace = natural_slopes.select_and_replace
		node_name = node.name
	end
	-- If there's something above, get back to full block
	if not is_free(new_pos({x=0, y=1, z=0})) then
		return select_replace('block', node_name, pos)
	end
	-- Check blocks around
	local airXP = is_free(new_pos({x=1, y=0, z=0}))
	local airXM = is_free(new_pos({x=-1, y=0, z=0}))
	local airZP = is_free(new_pos({x=0, y=0, z=-1}))
	local airZM = is_free(new_pos({x=0, y=0, z=1}))
	local free_neighbors = 0
	for index, free in next, {airXP, airXM, airZP, airZM} do
		if free then free_neighbors = free_neighbors + 1 end
	end
	-- For four free neighbors, poof (spread so much it disappear)
	if free_neighbors == 4 then -- minetest.set_node(pos, {name = 'air'})
	-- For three free neighbors, put a straight slope
	elseif free_neighbors == 3 then
		local dir = 0
		if not airXP then dir = {x=1, y=0, z=0}
		elseif not airXM then dir = {x=-1, y=0, z=0}
		elseif not airZP then dir = {x=0, y=0, z=-1}
		elseif not airZM then dir = {x=0, y=0, z=1}
		end
		return select_replace('straight', node_name, pos, dir)
	-- For two free neighbors
	elseif free_neighbors == 2 then
		-- at opposite sides, block
		if (airXP and airXM and not airZP and not airZM)
			or (not airXP and not airXM and airZP and airZM) then
			return select_replace('block', node_name, pos)
		-- side by side, outer corner
		elseif (airXP and not airXM and airZP and not airZM) then
			return select_replace('oc', node_name, pos, {x=0, y=0, z=1})
		elseif (airXP and not airXM and not airZP and airZM) then
			return select_replace('oc', node_name, pos, {x=-1, y=0, z=0})
		elseif (not airXP and airXM and airZP and not airZM) then
			return select_replace('oc', node_name, pos, {x=1, y=0, z=0})
		elseif (not airXP and airXM and not airZP and airZM) then
			return select_replace('oc', node_name, pos, {x=0, y=0, z=-1})
		end
	-- For one free neighbor, straight slope
	elseif free_neighbors == 1 then
		local dir = 0
		if airXP then dir = {x=-1, y=0, z=0}
		elseif airXM then dir = {x=1, y=0, z=0}
		elseif airZP then dir = {x=0, y=0, z=1}
		elseif airZM then dir = {x=0, y=0, z=-1}
		end
		return select_replace('straight', node_name, pos, dir)
	-- For no free neighbor check for a free diagonal for an inner corner
	-- or fully surrounded for a rebuild
	else
		local airXPZP = is_free(new_pos({x=1, y=0, z=1}))
		local airXPZM = is_free(new_pos({x=1, y=0, z=-1}))
		local airXMZP = is_free(new_pos({x=-1, y=0, z=1}))
		local airXMZM = is_free(new_pos({x=-1, y=0, z=-1}))
		if airXPZP and not airXPZM and not airXMZP and not airXMZM then
			return select_replace('ic', node_name, pos, {x=-1, y=0, z=0})
		elseif not airXPZP and airXPZM and not airXMZP and not airXMZM then
			return select_replace('ic', node_name, pos, {x=0, y=0, z=1})
		elseif not airXPZP and not airXPZM and airXMZP and not airXMZM then
			return select_replace('ic', node_name, pos, {x=0, y=0, z=-1})
		elseif not airXPZP and not airXPZM and not airXMZP and airXMZM then
			return select_replace('ic', node_name, pos, {x=1, y=0, z=0})
		else
			return select_replace('block', node_name, pos)
		end
	end
end


if natural_slopes.setting_enable_shape_abm() then
	minetest.register_abm({
		label = 'slope sliding',
		nodenames = {'group:falling_node', 'group:falling_natural_slope'},
		interval = natural_slopes.setting_update_shape_abm_interval(),
		chance = 1,
		action = natural_slopes.chance_update_shape,
	})
end


--- Player movement callback, try to update shape on walk
function natural_slopes.update_shape_on_walk(player, pos, node, node_desc)
	natural_slopes.chance_update_shape(pos, node)
end

minetest.register_chatcommand('updshape', {
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then return false, 'Player not found' end
		if not minetest.check_player_privs(player, {server=true}) then return false, 'Update shape requires server privileges' end
		local pos = player:getpos()
		local node_pos = {['x'] = pos.x, ['y'] = pos.y - 1, ['z'] = pos.z}
		local node = minetest.get_node(node_pos)
		if natural_slopes.update_shape(node_pos, node) then
			return true, 'Shape updated.'
		end
		return false, node.name .. " cannot have it's shape updated."
	end,
})

-- On generation big update
if natural_slopes.setting_enable_shape_on_generation() then
	minetest.register_on_generated(function(minp, maxp, seed)
		natural_slopes.area_chance_update_shape(minp, maxp, natural_slopes.setting_generation_factor())
	end)
end

--- On place neighbor update
local function on_place_or_dig(pos, force_below)
	local function update(pos, x, y, z, factor)
		local new_pos = vector.add(pos, vector.new(x, y, z))
		natural_slopes.chance_update_shape(new_pos, minetest.get_node(new_pos), factor)
	end
	-- Update 8 neighbors plus above and below
	update(pos, 0, 0, 0)
	update(pos, 1, 0, 0)
	update(pos, 0, 0, 1)
	update(pos, -1, 0, 0)
	update(pos, 0, 0, -1)
	update(pos, 1, 0, 1)
	update(pos, 1, 0, -1)
	update(pos, -1, 0, 1)
	update(pos, -1, 0, -1)
	if force_below then update(pos, 0, -1, 0, 0)
	else update(pos, 0, -1, 0)
	end
	update(pos, 0, 1, 0)
end

if natural_slopes.setting_enable_shape_on_dig_place() then
	minetest.register_on_placenode(function(pos, new_node, placer, old_node, item_stack, pointed_thing)
		on_place_or_dig(pos, true)
	end)
	minetest.register_on_dignode(function(pos, old_node, digger)
		on_place_or_dig(pos)
	end)
end

