---@class ulf.doc.gendocs.loader.exports
local M = {}
local Debug = require("ulf.doc.util.debug")

---@param dev boolean
function M.init(dev)
	if not dev then
		dev = false
	end

	local ulf_debug = os.getenv("ULF_DOC_DEBUG") or false
	local root = os.getenv("PWD")

	if not root:match("ulf%.doc$") then
		root = root .. "/deps/ulf.doc"
	end
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

	if ulf_debug then
		Debug.dump_lua_path("all")
	end
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
