#!/usr/bin/env luajit
local root = os.getenv("PWD")
if not root:match("ulf%.doc$") then
	root = root .. "/deps/ulf.doc"
end
package.path = package.path .. ";" .. root .. "/lua/?.lua;" .. root .. "/lua/init/?.lua;"

require("ulf.doc.gendocs.loader").init(true)
local Config = require("ulf.doc.gendocs.config")
local Util = require("ulf.doc.util")

---comment
---@param s string
---@return string
local function q(s)
	return '"' .. s .. '"'
end
local cmd = Util.fs.joinpath(Util.fs.project_root(), "spec", "fixtures", "async-stdout", "counter.sh")
cmd = "./spec/fixtures/async-stdout/counter.sh"
local args = {
	"1",
	"10",
	"250",
}
local result = Util.core.run_command(cmd, args, {
	error_parser = function(...) end,
})
print(result)
local vim_init = "/Users/al/dev/projects/ulf/deps/ulf.doc/scripts/minimal_init.lua"
-- local vim_init = "/Users/al/dev/projects/ulf/scripts/minimal_init.lua"
cmd = "nvim"
args = {

	"--clean",
	-- "-u",
	-- vim_init,
	"--headless",
	-- "-n",
	[[-c "lua print('done'); os.exit(0)"]],
	-- q([[lua print('done\n'); io.flush(); vim.cmd("checktime"); os.exit(0)]]),
	-- q(
	-- 	[[lua for i=1,10 do local wait_time = math.random(45, 202); print(string.format('%2d: %4d ms', i, wait_time)); os.execute('sleep ' .. wait_time / 1000); end]]
	-- ),
	-- "-c",
	-- q([[q!]]),
	-- "tmp.txt",
}

local result = Util.core.run_command_simple(cmd, args, {
	error_parser = function(...) end,
})
-- P(result)
-- validator.counter_output(result, {}, { max_wait_time_ms = 1000 })
