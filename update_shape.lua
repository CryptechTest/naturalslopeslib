--[[
Describes the falling/eroding effect for slopes
--]]

--- {Private} Pick a replacement node and set it at pos.
-- @param from The replacement table to pick replacement from.
-- @param name The name of the node to replace.
-- @param pos The position of the node to replace
-- @param pointing Optional vector to orient the new node.
-- @return True if the node is replaced, false otherwise.
function natural_slopes.select_and_replace(from, name, pos, pointing)
	local replacement = from[name]
	if not replacement then
		replacement = from[natural_slopes.rebuild_replacements[name]]
	end
	if replacement and pointing then
		minetest.set_node(pos, {name=replacement, paramtype2='facedir', param2=minetest.dir_to_facedir(pointing)})
		return true
	elseif replacement then
		minetest.set_node(pos, {name=replacement})
		return true
	end
	return false
end

--- Check if a node is considered empty to switch shape.
-- @param pos The position to check
function natural_slopes.is_free_for_erosion(pos)
	if minetest.get_node(pos).name == 'air' then return true end
	-- TODO add water for canditates
	return false
end

-- Do shape update when random roll passes.
function natural_slopes.chance_update_shape(pos, node)
	local chance = natural_slopes.all_nodes[node.name]
	if chance and (math.random() * chance) < 1.0 then
		natural_slopes.update_shape(pos, node)
	end
end

--- Try to update the shape of a node according to it's surroundings.
-- @param pos The position of the node.
-- @param node The node at that position.
-- @return True if the node was updated, false otherwise.
function natural_slopes.update_shape(pos, node)
	-- If there's something above, get back to full block
	if not natural_slopes.is_free_for_erosion({x=pos.x, y=pos.y+1, z=pos.z}) then
		return natural_slopes.select_and_replace(natural_slopes.rebuild_replacements, node.name, pos)
	end
	-- Check blocks around
	local airXP = natural_slopes.is_free_for_erosion({x=pos.x+1, y=pos.y, z=pos.z})
	local airXM = natural_slopes.is_free_for_erosion({x=pos.x-1, y=pos.y, z=pos.z})
	local airZP = natural_slopes.is_free_for_erosion({x=pos.x, y=pos.y, z=pos.z-1})
	local airZM = natural_slopes.is_free_for_erosion({x=pos.x, y=pos.y, z=pos.z+1})
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
		return natural_slopes.select_and_replace(natural_slopes.straight_replacements, node.name, pos, dir)
	-- For two free neighbors
	elseif free_neighbors == 2 then
		-- at opposite sides, check diagonals and attach to the more
		if (airXP and airXM and not airZP and not airZM) then
			local XPWeight = 0
			if minetest.get_node({x=pos.x+1, y=pos.y, z=pos.z+1}) == 'air' then XPWeight = XPWeight + 1 end
			if minetest.get_node({x=pos.x+1, y=pos.y, z=pos.z-1}) == 'air' then XPWeight = XPWeight + 1 end
			if minetest.get_node({x=pos.x-1, y=pos.y, z=pos.z+1}) == 'air' then XPWeight = XPWeight - 1 end
			if minetest.get_node({x=pos.x-1, y=pos.y, z=pos.z-1}) == 'air' then XPWeight = XPWeight - 1 end
			if XPWeight ~= 0 then
				return natural_slopes.select_and_replace(natural_slopes.straight_replacements, node.name, pos)
			end
		elseif (not airXP and not airXM and airZP and airZM) then
			local ZPWeight = 0
			if minetest.get_node({x=pos.x+1, y=pos.y, z=pos.z+1}) == 'air' then ZPWeight = ZPWeight + 1 end
			if minetest.get_node({x=pos.x-1, y=pos.y, z=pos.z+1}) == 'air' then ZPWeight = ZPWeight + 1 end
			if minetest.get_node({x=pos.x+1, y=pos.y, z=pos.z-1}) == 'air' then ZPWeight = ZPWeight - 1 end
			if minetest.get_node({x=pos.x-1, y=pos.y, z=pos.z-1}) == 'air' then ZPWeight = ZPWeight - 1 end
			if ZPWeight ~= 0 then
				return natural_slopes.select_and_replace(natural_slopes.straight_replacements, node.name, pos) end
		-- side by side, outer corner
		elseif (airXP and not airXM and airZP and not airZM) then
			return natural_slopes.select_and_replace(natural_slopes.outer_corner_replacements, node.name, pos, {x=0, y=0, z=1})
		elseif (airXP and not airXM and not airZP and airZM) then
			return natural_slopes.select_and_replace(natural_slopes.outer_corner_replacements, node.name, pos, {x=-1, y=0, z=0})
		elseif (not airXP and airXM and airZP and not airZM) then
			return natural_slopes.select_and_replace(natural_slopes.outer_corner_replacements, node.name, pos, {x=1, y=0, z=0})
		elseif (not airXP and airXM and not airZP and airZM) then
			return natural_slopes.select_and_replace(natural_slopes.outer_corner_replacements, node.name, pos, {x=0, y=0, z=-1})
		end
	-- For one free neighbor, straight slope
	elseif free_neighbors == 1 then
		local dir = 0
		if airXP then dir = {x=-1, y=0, z=0}
		elseif airXM then dir = {x=1, y=0, z=0}
		elseif airZP then dir = {x=0, y=0, z=1}
		elseif airZM then dir = {x=0, y=0, z=-1}
		end
		return natural_slopes.select_and_replace(natural_slopes.straight_replacements, node.name, pos, dir)
	-- For no free neighbor check for a free diagonal for an inner corner
	-- or fully surrounded for a rebuild
	else
		local airXPZP = natural_slopes.is_free_for_erosion({x=pos.x+1, y=pos.y, z=pos.z+1})
		local airXPZM = natural_slopes.is_free_for_erosion({x=pos.x+1, y=pos.y, z=pos.z-1})
		local airXMZP = natural_slopes.is_free_for_erosion({x=pos.x-1, y=pos.y, z=pos.z+1})
		local airXMZM = natural_slopes.is_free_for_erosion({x=pos.x-1, y=pos.y, z=pos.z-1})
		if airXPZP and not airXPZM and not airXMZP and not airXMZM then
			return natural_slopes.select_and_replace(natural_slopes.inner_corner_replacements, node.name, pos, {x=-1, y=0, z=0})
		elseif not airXPZP and airXPZM and not airXMZP and not airXMZM then
			return natural_slopes.select_and_replace(natural_slopes.inner_corner_replacements, node.name, pos, {x=0, y=0, z=1})
		elseif not airXPZP and not airXPZM and airXMZP and not airXMZM then
			return natural_slopes.select_and_replace(natural_slopes.inner_corner_replacements, node.name, pos, {x=0, y=0, z=-1})
		elseif not airXPZP and not airXPZM and not airXMZP and airXMZM then
			return natural_slopes.select_and_replace(natural_slopes.inner_corner_replacements, node.name, pos, {x=1, y=0, z=0})
		else
			return natural_slopes.select_and_replace(natural_slopes.rebuild_replacements, node.name, pos)
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
		if minetest.get_node_group(node.name, 'falling_node') ~= nil then
			return true, natural_slopes.update_shape(node_pos, node)
		end
		return false, node.name .. " cannot have it's shape updated."
	end,
})
