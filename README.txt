Natural slopes

Version 0.2
Licence LGPLv2 and WTFPL, see LICENSE for the details
Dependencies: default
Optional dependencies:
  stairs: to enable blockish rendering
  poschangelib: to enable shape update on walk

This mod adds some stair-like nodes from soft ground nodes (sand, dirt, gravel...)
that may update shape according their surroundings.

The aim of this mod is to make a visual improvement on the world with more curves and
smooth movement not to jump on every little height.

It is also part of a larger project that aims to bring life to the environment from
inanimate things (and without turning them into evil unfriendly mobs).

As Minetest main unit is the block, having half-sized blocks can break a lot of things.
Thus half-blocks like slopes are still considered as a single block (either for recipes
or for placing items). A single slop can turn back to a full node and vice-versa and
half-blocks are not considered buildable upon (they will transform back into full block)


How to define new slopes
------------------------

Call natural_slopes.register_slope to declare new slope nodes and bind shape update
events on the original node and the newly created slopes.

It takes 7 arguments
  subname: The name without mod prefix of the original node
  base_node_name: full original node name
  groups: groups that the slope will have (generally the same as the original node)
  images: textures for the slope nodes
  description: Human friendly name
  sounds: stepping sounds for the new node (generally the same as the original node)
  update_chance: inverted chance to the node to update it's shape when an update event
      occurs on it.