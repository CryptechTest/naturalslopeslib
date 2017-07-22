-- Global namespace for functions
natural_slopes = {}

-- Table of replacement from solid block to eroded slopes.
-- Populated on slope node registration
natural_slopes.straight_replacements = {}
natural_slopes.inner_corner_replacements = {}
natural_slopes.outer_corner_replacements = {}
natural_slopes.rebuild_replacements = {}

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

-- Load default configuration values
dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/default_settings.txt")

-- Check dependencies compatibility
if natural_slopes.rendering_mode == 'cubic' and not _G.stairs then
	natural_slopes.rendering_mode = 'smooth'
end
if natural_slopes.rendering_mode ~= 'smooth' and natural_slopes.rendering_mode ~= 'cubic' then
	natural_slopes.rendering_mode = 'smooth'
end

-- Include registration methods
dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/register_slopes.lua")

-- Define new nodes
dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/nodes.lua")

dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/update_shape.lua")
