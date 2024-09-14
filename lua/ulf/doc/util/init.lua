---@class ulf.log.util
---@field async ulf.doc.util.async.exports
---@field core ulf.doc.util.core.exports
---@field debug ulf.doc.util.debug.exports
---@field fs ulf.doc.util.fs.exports
---@field json ulf.doc.util.json.exports
---@field string ulf.doc.util.string.exports
---@field table ulf.doc.util.table.exports
local M = {}

local mods = {
	-- table = require("ulf.log.util.table"),
	-- log = require("ulf.log.util.log"),
	-- fs = require("ulf.log.util.fs"),
	async = true,
	core = true,
	debug = true,
	fs = true,
	json = true,
	string = true,
	table = true,
}

setmetatable(M, {
	__index = function(t, k)
		---@type any
		local v

		v = mods[k]

		if v then
			local ok, mod = pcall(require, "ulf.doc.util." .. k) ---@diagnostic disable-line: no-unknown
			if ok then
				rawset(t, k, mod)
				return mod
			end
		end
	end,
})

return M
