-- Global namespace for functions
natural_slopes = {}

-- Table of replacement from solid block to eroded slopes.
-- Populated on slope node registration
natural_slopes.straight_replacements = {}
natural_slopes.inner_corner_replacements = {}
natural_slopes.outer_corner_replacements = {}
natural_slopes.rebuild_replacements = {}
-- Table of all node names managed by this mod. Name as key, inverted chance
-- of update as values. Populated with register_slope.
natural_slopes.all_nodes = {}

--- Get node name for slopes from a subname.
-- For example 'dirt' will be named 'natural_slopes:slope_dirt'
function natural_slopes.get_straight_slope_name(subname)
	return 'natural_slopes:slope_' .. subname
end
function natural_slopes.get_inner_corner_slope_name(subname)
	return 'natural_slopes:slope_inner_' .. subname
end
function natural_slopes.get_outer_corner_slope_name(subname)
	return 'natural_slopes:slope_outer_' .. subname
end

-- Set functions to get configuration and default values
function natural_slopes.setting_rendering_mode()
	local mode = tonumber(minetest.setting_get('natural_slopes.rendering_mode')) or 0
	if mode == 1 and not _G.stairs then mode = 0 end
	return mode
end
function natural_slopes.setting_enable_shape_abm()
	local value = minetest.setting_getbool('natural_slopes.enable_shape_abm')
	if value == nil then return true end
	return value
end
function natural_slopes.setting_update_shape_abm_interval()
	return tonumber(minetest.setting_get('natural_slopes.update_shape_abm_interval')) or 30
end
function natural_slopes.setting_enable_shape_on_walk()
	if not _G.poschangelib then return false end
	local value = minetest.setting_getbool('natural_slopes.enable_shape_on_walk')
	if value == nil then return true end
	return value
end
function natural_slopes.setting_register_default_nodes()
	local value = minetest.setting_getbool('natural_slopes.register_default_slopes')
	if not _G.default then value = false end
	return value
end

dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/update_shape.lua")
-- Include registration methods
dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/register_slopes.lua")

-- Define new nodes
if natural_slopes.setting_register_default_nodes() then
	dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/nodes/default.lua")
end
