core.log("info", "Initializing asynchronous environment (game)")

local function pack2(...)
	return {n=select('#', ...), ...}
end

-- Entrypoint to run async jobs, called by C++
function core.job_processor(func, params)
	local retval = pack2(func(unpack(params, 1, params.n)))

	return retval
end

-- Import a bunch of individual files from builtin/game/
local gamepath = core.get_builtin_path() .. "game" .. DIR_DELIM

dofile(gamepath .. "constants.lua")
dofile(gamepath .. "item_s.lua")
dofile(gamepath .. "misc_s.lua")
dofile(gamepath .. "features.lua")
dofile(gamepath .. "voxelarea.lua")

-- Transfer of globals
do
	local all = assert(core.transferred_globals)
	core.transferred_globals = nil

	all.registered_nodes = {}
	all.registered_craftitems = {}
	all.registered_tools = {}
	for k, v in pairs(all.registered_items) do
		-- Disable further modification
		setmetatable(v, {__newindex = {}})
		-- Reassemble the other tables
		if v.type == "node" then
			all.registered_nodes[k] = v
		elseif v.type == "craftitem" then
			all.registered_craftitems[k] = v
		elseif v.type == "tool" then
			all.registered_tools[k] = v
		end
	end

	for k, v in pairs(all) do
		core[k] = v
	end
end

-- For tables that are indexed by item name:
-- If table[X] does not exist, default to table[core.registered_aliases[X]]
local alias_metatable = {
	__index = function(t, name)
		return rawget(t, core.registered_aliases[name])
	end
}
setmetatable(core.registered_items, alias_metatable)
setmetatable(core.registered_nodes, alias_metatable)
setmetatable(core.registered_craftitems, alias_metatable)
setmetatable(core.registered_tools, alias_metatable)