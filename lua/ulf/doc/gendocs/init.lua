---@brief [[
--- ulf.doc.gendocs is a documentation tool for Lua/Neovim for generating documentation.
---
--- It currently uses tree-sitter-lua (https://github.com/tjdevries/tree-sitter-lua)
---
--- Example usage (see gendocs -h)
--- <pre>
---   gendocs --files="lua/ulf/doc/init.lua,lua/ulf/doc/gendocs/init.lua" --app="ulf.doc"
--- </pre>
---
---@brief ]]
---@tag ulf.doc.gendocs
---@config { ["name"] = "Gendocs" }
---
---@class ulf.doc.gendocs.exports
local M = {}

local Config = require("ulf.doc.gendocs.config")

---@type ulf.doc.ConfigOptions
---@return ulf.doc.ConfigOptions
function M.setup(opts)
	opts = opts or {}
	local config = Config.setup(opts)
	return config
end

function M.run()
	require("ulf.doc.gendocs.cli").run()
end
return M
