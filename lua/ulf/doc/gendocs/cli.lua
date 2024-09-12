---@class ulf.doc.gendocs.cli.exports
local M = {}
local _string = require("ulf.doc.util.string")
local split = _string.split
local fs = require("ulf.doc.util.fs")
local core = require("ulf.doc.util.core")
-- this is called when the flag -v or --version is set
local function print_version()
	print("ulf.doc: version NOT-IMPLEMENTED")
	os.exit(0)
end

-- ---comment
-- ---@param cli table
-- ---@param file_path? string
-- ---@return unknown
-- function M.load_config_file(cli, file_path)
-- 	local fs = require("apipe.lib.fs")
-- 	local config = require("loom.config")
-- 	local from_json = require("cliargs.config_loader").from_json
--
-- 	file_path = file_path or fs.joinpath(fs.git_root(), ".ulf.doc.json")
-- 	local data
-- 	local success = pcall(function()
-- 		data = from_json(file_path)
-- 	end)
--
-- 	if data then
-- 		cli:load_defaults(data)
--
-- 		config.setup({
-- 			config = file_path,
-- 			path_output = data.path_output,
-- 		})
-- 	end
--
-- 	-- log.debug("Cli.load_config_file", config)
-- 	if success then
-- 		return data
-- 	end
-- end

---@class ulf.doc.cliargs
---@field path_output string
---@field files string
---@field app string
---@field d boolean
---@field config string
---@field backend 'vim'|'lua'
---
---@param args ulf.doc.cliargs
local function main(args)
	require("ulf.doc.gendocs.backend").runner[args.backend].entrypoint(args)
end

function M.run()
	local cli = require("cliargs") ---@diagnostic disable-line: no-unknown
	cli:set_name("gendocs")
	cli:set_description("generate Lua documentation")
	cli:option("--app=APP", "name of the app", "app")
	cli:option("--config=FILEPATH", "path to a config file", ".gendocs.json")
	cli:option("--path_output=FILEPATH", "path to the generated documentation files", "doc")
	cli:option("--backend=BACKEND", "backend to use for generating docs: vim (default) or lua", "vim")
	cli:option("--files=FILES", "list of files to process")

	cli:flag("-d", "script will run in DEBUG mode")
	cli:flag("-v, --version", "prints the program's version and exits", print_version)

	-- Parses from _G['arg']
	local args, err = cli:parse() ---@diagnostic disable-line: no-unknown

	-- something wrong happened, we print the error and exit
	if not args then
		print(err)
		os.exit(1)
	end
	main(args)
end

return M
