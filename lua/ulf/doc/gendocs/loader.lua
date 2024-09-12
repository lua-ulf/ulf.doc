---@class ulf.doc.gendocs.loader.exports
local M = {}

local function split(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t = {}
	for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
		table.insert(t, str)
	end
	return t
end
---comment
---@param kind 'path'|'cpath'
local function print_package_path(kind)
	kind = kind or "path"
	print(string.format("-------------------- ulf.doc.gendocs.loader: %05s --------------------\n", kind))
	local path_list = split(package[kind], ";")
	for index, path in
		ipairs(path_list --[[@as string[] ]])
	do
		print(string.format("%02d: %s", index, path))
	end
	print("-----------------------------------------------------------------------\n\n")
end

---@param dev boolean
function M.init(dev)
	if not dev then
		dev = false
	end

	local root = os.getenv("PWD")
	local path = function(s)
		return root .. s
	end
	local package_paths = {

		lpath = {
			path("/lua"),
			path("/lua/ulf/doc"),
			path("/build/2.1.0-beta3/share/lua/5.1"),
		},
		cpath = {
			path("./?.so"),
			path("build/2.1.0-beta3/lib/lua/5.1/?.so"),
			path("build/2.1.0-beta3/lib/lua/5.1/loadall.so"),
			os.getenv("HOME") .. "/.luarocks/lib/lua/5.1/?.so",
		},
	}

	for _, dir in
		ipairs(package_paths.lpath --[[@as string[]  ]])
	do
		package.path = package.path .. ";" .. dir .. "/?.lua"
		package.path = package.path .. ";" .. dir .. "/?/init.lua"
	end

	for _, dir in
		ipairs(package_paths.cpath --[[@as string[]   ]])
	do
		package.cpath = package.cpath .. ";" .. dir
	end

	-- print_package_path("cpath")
end

---@type ulf.doc.ConfigOptions
function M.load(config)
	local core = require("ulf.doc.util.core")
	local uv = vim and vim.uv or require("luv")
	local Config = require("ulf.doc.gendocs.config")

	for _, plugin_spec in
		ipairs(config.plugins --[[@as table[]  ]])
	do
		---@type string
		local plugin = plugin_spec[1]
		local name = plugin:match(".*/(.*)")
		---@type fun(...)
		local config_fn = plugin_spec.config
		---@type string
		local package_root = Config.package_root(name)
		if not uv.fs_stat(package_root) then
			print("[ulf.doc.gendocs.loader ]: cloaning plugin: " .. plugin_spec[1])
			core.load(plugin, package_root)
			if type(config_fn) == "function" then
				config_fn({
					name = name,
					package_root = package_root,
				}, Config.options)
			end
		end
		if vim then
			print("[ulf.doc.gendocs.loader ]: adding path: " .. package_root)
			package.path = package.path .. ";" .. package_root .. "/lua/?.lua;" .. package_root .. "/lua/?/init.lua;"
			-- 			vim.opt.rtp:append(package_root)
			-- 			vim.cmd([[
			-- runtime! plugin/plenary.vim
			-- runtime! plugin/tree-sitter-lua
			--   ]])
		end
	end
end

_G.P = require("ulf.doc.util.debug").debug_print
return M
