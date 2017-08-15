Natural slopes

Version 0.6
Licence LGPLv2 or any later, CC-0 and WTFPL, see LICENSE for the details.
Dependencies: default
Optional dependencies:
  default: to enable slopes for Minetest Game
  stairs: to enable blockish rendering
  poschangelib: to enable shape update on walk

This mod add the ability for given nodes to turn into slopes and back to full block
shape by itself according to the surroundings and the material hardness. It creates
natural landscape and smoothes movements.

Slopes can be generated in various ways. Those events can be turned on or off in
settings. The shape is updated on generation, with time, by stepping on edges or
when digging and placing nodes.

It can be used either with Minetest Game or as a library for other games.

As Minetest main unit is the block, having half-sized blocks can break a lot of things.
Thus half-blocks like slopes are still considered as a single block. A single slop can turn back to a full node and vice-versa and
half-blocks are not considered buildable upon (they will transform back into full block)


How to define new slopes
------------------------

Call natural_slopes.register_slope to declare new slope nodes and bind shape update
events on the original node and the newly created slopes.

It takes 3 arguments
  base_node_name: The name of the original node
  node_desc: The basic description of the node. Some properties will be overwriten
             for the new nodes.
  update_chance: inverted chance to the node to update it's shape when an update event
                 occurs on it.

node_desc can accept a dedicated tiles definition which holds top, bottom, front, back
and side instead of the default list.

Top refers to the top faces, where the player walks.
Bottom to the opposite faces. When not set it is the same as top.
Front refers to the vertical faces between the horizontal ones. When not set it is the
same as top. Those are always visible except the lower ones.
Side refers to the vertical faces at the boundaries on the sides of the node. When not
set it is the same as front. Those are often hidden by neighbor blocks
Back refers to the vertical face at the back of the node. When not set is it the same
as side. Those are hidden most of the time.
