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

--- {Private} Place node upward or downward according to the pointer position
-- inside the target.
local function rotate_and_place(itemstack, placer, pointed_thing)
	if pointed_thing.type ~= "node" then
		return itemstack
	end
	local p0 = pointed_thing.under
	local p1 = pointed_thing.above
	local param2 = 0

	local placer_pos = placer:getpos()
	if placer_pos then
		param2 = minetest.dir_to_facedir(vector.subtract(p1, placer_pos))
	end

	local finepos = minetest.pointed_thing_to_face_pos(placer, pointed_thing)
	local fpos = finepos.y % 1

	if p0.y - 1 == p1.y or (fpos > 0 and fpos < 0.5)
			or (fpos < -0.5 and fpos > -0.999999999) then
		param2 = param2 + 20
		if param2 == 21 then
			param2 = 23
		elseif param2 == 23 then
			param2 = 21
		end
	end
	return minetest.item_place(itemstack, placer, pointed_thing, param2)
end

--- {Private} Register a straight slope and link to the original node.
-- @param subname: The name passed to natural_slopes.get_straigth_slope_name
-- @param base_node_name: The full block node name.
-- @param groups: The groups that the slope node will have.
-- @param images:
-- @param descriptions: Description of the new slope node.
-- @param sounds:
function natural_slopes.register_slope_straight(subname, base_node_name, groups, images, description, sounds, update_chance)
	local stair_images = {}
	for i, image in ipairs(images) do
		if type(image) == "string" then
			stair_images[i] = {
				name = image,
				backface_culling = true,
			}
		elseif image.backface_culling == nil then -- override using any other value
			stair_images[i] = table.copy(image)
			stair_images[i].backface_culling = true
		end
	end
	groups.stair = 1
	groups.natural_slope = 1
	local node_data = {
		description = description,
		drawtype = "mesh",
		mesh = SLOPE_MESH,
		tiles = stair_images,
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = true,
		groups = groups,
		sounds = sounds,
		selection_box = slope_straight_box,
		collision_box = slope_straight_box,
	}
	if groups.falling_node == nil then
		node_data.on_place = rotate_and_place
	else
		node_data.groups.falling_natural_slope = 1
	end
	local slope_name = natural_slopes.get_straight_slope_name(subname)
	minetest.register_node(slope_name, node_data)
	if base_node_name then
		natural_slopes.straight_replacements[base_node_name] = slope_name
		natural_slopes.rebuild_replacements[slope_name] = base_node_name
		natural_slopes.all_nodes[base_node_name] = update_chance
		natural_slopes.all_nodes[slope_name] = update_chance
		if _G.poschangelib then
			poschangelib.add_player_walk_listener('natural_slopes:update_on_walk',
				natural_slopes.update_shape_on_walk,
				{slope_name})
		end
		-- Recipe matches appearence in inventory
		minetest.register_craft({
			output = slope_name .. ' 6',
			recipe = {
				{"", "", base_node_name},
				{"", base_node_name, base_node_name},
				{base_node_name, base_node_name, base_node_name},
			},
		})

		-- Use stairs to craft full blocks again (1:1)
		minetest.register_craft({
			output = base_node_name .. ' 4',
			recipe = {
				{slope_name, slope_name},
				{slope_name, slope_name},
			},
		})
	end
end

--- {Private} Register an inner corner and link to the original node.
-- @param subname: The name passed to natural_slopes.get_straigth_inner_corner_name
-- @param base_node_name: The full block node name.
-- @param groups: The groups that the slope node will have.
-- @param images:
-- @param descriptions: Description of the new slope node.
-- @param sounds:
function natural_slopes.register_slope_inner(subname, base_node_name, groups, images, description, sounds, update_chance)
	local stair_images = {}
	for i, image in ipairs(images) do
		if type(image) == "string" then
			stair_images[i] = {
				name = image,
				backface_culling = true,
			}
		elseif image.backface_culling == nil then -- override using any other value
			stair_images[i] = table.copy(image)
			stair_images[i].backface_culling = true
		end
	end
	groups.stair = 1
	groups.natural_slope = 1
	node_data = {
		description = description .. " Inner",
		drawtype = "mesh",
		mesh = INNER_CORNER_MESH,
		tiles = stair_images,
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = false,
		groups = groups,
		sounds = sounds,
		selection_box = slope_inner_corner_box,
		collision_box = slope_inner_corner_box,
	}
	if groups.falling_node == nil then
		node_data.on_place = rotate_and_place
	else
		node_data.groups.falling_natural_slope = 1
	end
	local slope_name = natural_slopes.get_inner_corner_slope_name(subname)
	minetest.register_node(slope_name, node_data)
	if base_node_name then
		natural_slopes.inner_corner_replacements[base_node_name] = slope_name
		natural_slopes.rebuild_replacements[slope_name] = base_node_name
		natural_slopes.all_nodes[base_node_name] = update_chance
		natural_slopes.all_nodes[slope_name] = update_chance
		if _G.poschangelib then
			poschangelib.add_player_walk_listener('natural_slopes:update_on_walk',
				natural_slopes.update_shape_on_walk,
				{slope_name})
		end
		minetest.register_craft({
			output = slope_name .. ' 6',
			recipe = {
				{ "", base_node_name, ""},
				{ base_node_name, "", base_node_name},
				{base_node_name, base_node_name, base_node_name},
			},
		})
		-- Use stairs to craft full blocks again (1:1)
		minetest.register_craft({
			output = base_node_name .. ' 4',
			recipe = {
				{slope_name, slope_name},
				{slope_name, slope_name},
			},
		})
	end
end

--- {Private} Register an outer corner and link to the original node.
-- @param subname: The name passed to natural_slopes.get_straigth_inner_corner_name
-- @param base_node_name: The full block node name.
-- @param groups: The groups that the slope node will have.
-- @param images:
-- @param descriptions: Description of the new slope node.
-- @param sounds:
function natural_slopes.register_slope_outer(subname, base_node_name, groups, images, description, sounds, update_chance)
	local stair_images = {}
	for i, image in ipairs(images) do
		if type(image) == "string" then
			stair_images[i] = {
				name = image,
				backface_culling = true,
			}
		elseif image.backface_culling == nil then -- override using any other value
			stair_images[i] = table.copy(image)
			stair_images[i].backface_culling = true
		end
	end
	groups.stair = 1
	groups.natural_slope = 1
	node_data = {
		description = description .. " Outer",
		drawtype = "mesh",
		mesh = OUTER_CORNER_MESH,
		tiles = stair_images,
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = false,
		groups = groups,
		sounds = sounds,
		selection_box = slope_outer_corner_box,
		collision_box = slope_outer_corner_box,
	}
	if groups.falling_node == nil then
		node_data.on_place = rotate_and_place
	else
		node_data.groups.falling_natural_slope = 1
	end
	local slope_name = natural_slopes.get_outer_corner_slope_name(subname)
	minetest.register_node(slope_name, node_data)
	if base_node_name then
		natural_slopes.outer_corner_replacements[base_node_name] = slope_name
		natural_slopes.rebuild_replacements[slope_name] = base_node_name
		natural_slopes.all_nodes[base_node_name] = update_chance
		natural_slopes.all_nodes[slope_name] = update_chance
		if _G.poschangelib then
			poschangelib.add_player_walk_listener('natural_slopes:update_on_walk',
				natural_slopes.update_shape_on_walk,
				{slope_name})
		end
		minetest.register_craft({
			output = slope_name .. ' 4',
			recipe = {
				{ "", "", ""},
				{ "", base_node_name, ""},
				{base_node_name, base_node_name, base_node_name},
			},
		})
		-- Use stairs to craft full blocks again (1:1)
		minetest.register_craft({
			output = base_node_name .. ' 4',
			recipe = {
				{slope_name, slope_name},
				{slope_name, slope_name},
			},
		})
	end
end

--- Register slopes from a full block node.
-- @param subname: The name passed to natural_slopes.get_*_name
-- @param base_node_name: The full block node name.
-- @param groups: The groups that the slope nodes will have.
-- @param images:
-- @param descriptions: Description of the new slope node.
-- @param sounds:
function natural_slopes.register_slope(subname, base_node_name, groups, images, description, sounds, update_chance)
	natural_slopes.register_slope_straight(subname, base_node_name, groups, images, description, sounds, update_chance)
	natural_slopes.register_slope_inner(subname, base_node_name, groups, images, description, sounds, update_chance)
	natural_slopes.register_slope_outer(subname, base_node_name, groups, images, description, sounds, update_chance)
	if _G.poschangelib then
		poschangelib.add_player_walk_listener('natural_slopes:update_on_walk',
			natural_slopes.update_shape_on_walk,
			{base_node_name})
	end

end
