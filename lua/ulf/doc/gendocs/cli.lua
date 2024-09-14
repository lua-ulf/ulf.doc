---@brief [[
--- ulf.doc.gendocs.cli is the command line interface for the gendocs module.
---
--- Example usage (see gendocs -h)
--- <pre>
---   gendocs --files="lua/ulf/doc/init.lua,lua/ulf/doc/gendocs/init.lua" --app="ulf.doc"
--- </pre>
---
---@brief ]]
---@tag ulf.doc.gendocs.cli
---@config { ["name"] = "Client" }
---
---@class ulf.doc.gendocs.cli.exports
local M = {}
local Config = require("ulf.doc.gendocs.config")

-- this is called when the flag -v or --version is set
local function print_version()
	print("ulf.doc: version NOT-IMPLEMENTED")
	os.exit(0)
end

---comment
---@param cli table
---@param file_path? string
---@return ulf.doc.ConfigOptions?
function M.load_config_file(cli, file_path)
	local config = Config.load(file_path)

	if config and config.gendocs then
		cli:load_defaults(config.gendocs)
		return config
	end
end

---@class ulf.doc.gendocs.cliargs
---@field path_output? string
---@field files string
---@field app string
---@field d? boolean
---@field config? string
---@field backend? 'vim'|'lua'
---
---@param args ulf.doc.gendocs.cliargs
local function main(args)
	require("ulf.doc.gendocs.backend").runner[args.backend].entrypoint(args)
end

function M.run()
	local cli = require("cliargs") ---@diagnostic disable-line: no-unknown
	cli:set_name("gendocs")
	cli:set_description("generate Lua documentation")
	cli:option("--app=APP", "name of the app")
	cli:option("--config=FILEPATH", "path to a config file", Config.filename())
	cli:option("--path_output=FILEPATH", "path to the generated documentation files", "doc")
	cli:option("--backend=BACKEND", "backend to use for generating docs: vim (default) or lua", "vim")
	cli:option("--files=FILES", "list of files to process")

	cli:flag("-d", "script will run in DEBUG mode")
	cli:flag("-v, --version", "prints the program's version and exits", print_version)
	-- M.load_config_file(cli, Config.filename())

	local args, err = cli:parse() ---@diagnostic disable-line: no-unknown

	-- something wrong happened, we print the error and exit
	if not args then
		print(string.format("%s: %s; re-run with help for usage", cli.name, err))
		os.exit(1)
	end

	-- finally, let's check if the user passed in a config file using --config:
	if args.config then
		---@type ulf.doc.ConfigOptions?
		local custom_config = M.load_config_file(cli, args.config)

		if custom_config then
			args.files = custom_config.gendocs.files or args.files
			args.app = custom_config.gendocs.app or args.app
		end

		if args.d then
			P(args)
		end
	end
	if args.files and args.app then
		main(args)
	else
		print(string.format("%s: files and app missing, run with help for usage", cli.name))
		os.exit(1)
	end
end

return M
