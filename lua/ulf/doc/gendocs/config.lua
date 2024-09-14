---@brief [[
--- ulf.doc.gendocs.config is the config module for the gendocs module.
---
---@brief ]]
---@tag ulf.doc.gendocs.config
---@config { ["name"] = "Config" }
---
---@class ulf.doc.config
local M = {}

local uv = vim and vim.uv or require("luv")
local fs = require("ulf.doc.util.fs")
local _table = require("ulf.doc.util.table")
local tbl_deep_extend = _table.tbl_deep_extend

---@class ulf.doc.ConfigOptions
---@field package_root fun(self:ulf.doc.ConfigOptions,name:string)
---@field gendocs {files:string?,app:string?}
local Defaults = {
	gendocs = {

		files = "",
		app = "",
	},
	ulf = {
		package = "doc",
		stdpath = {
			cache = fs.stdpath("cache", "ulf", "build"),
			data = fs.stdpath("data", "ulf"),
		},
	},
	plugins = {
		{ "nvim-lua/plenary.nvim" },
		{
			"tjdevries/tree-sitter-lua",
			---comment
			---@param plugin {name:string,package_root:string}
			---@param config ulf.doc.ConfigOptions
			config = function(plugin, config)
				assert(uv.chdir(plugin.package_root))
				local result = require("ulf.doc.util.core").run_command("make", {
					"dist",
				})
				print(result)
			end,
		},
	},
}

function M.filename()
	return fs.joinpath(fs.git_root(), ".ulf-gendocs.json")
end

---comment
---@param path_config? string
---@return ulf.doc.ConfigOptions
function M.load(path_config)
	local json = require("ulf.doc.util.json").setup()
	path_config = path_config or M.filename()
	print("[ulf.doc.gendocs.config]: loading config '" .. tostring(path_config) .. "'")

	---@type ulf.doc.gendocs.cliargs
	local config = {} ---@diagnostic disable-line: missing-fields
	if fs.file_exists(path_config) then
		local data = fs.read_file(path_config)
		config = json.decode(data)
	end

	M.setup(config)

	return M.options
end

---@type ulf.doc.ConfigOptions
M.options = nil

function M.package_root(name)
	return fs.joinpath(M.options.ulf.stdpath.cache, M.options.ulf.package, name)
end

---comment
---@return string[]
function M.runtime_paths()
	---@type string[]
	local out = { "." } -- current dir
	for _, plugin_spec in ipairs(M.options.plugins) do
		local plugin = plugin_spec[1]

		out[#out + 1] = M.package_root(plugin)
	end
	return out
end

---@type ulf.doc.ConfigOptions
---@return ulf.doc.ConfigOptions
function M.setup(opts)
	M.options = tbl_deep_extend("force", Defaults, opts or {})
	return M.options
end

return M
