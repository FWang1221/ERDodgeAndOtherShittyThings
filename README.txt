This file should be in your Game folder (usually C:\Program Files (x86)\Steam\steamapps\common\ELDEN RING\Game) + quickDodge.

This file path should be C:\Program Files (x86)\Steam\steamapps\common\ELDEN RING\Game\quickDodge\README.txt

quickDodge.lua should also be in the same directory, so C:\Program Files (x86)\Steam\steamapps\common\ELDEN RING\Game\quickDodge\quickDodge.lua

Settings can be changed in quickDodge.lua, just set them to TRUE or FALSE.

How to Merge:

Take your player HKS of another overhaul or whatever and put this:

pcall(loadfile("quickDodge//quickDodge.lua"))

Right above the global list.

It should look like:

pcall(loadfile("quickDodge//quickDodge.lua"))

------------------------------------------
-- Must be last for the global variables to be read
------------------------------------------
global = {}

function dummy()
end

global.__index = function(table, element)
    return dummy
end

setmetatable(_G, global)