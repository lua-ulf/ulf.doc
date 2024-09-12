---@class ulf.doc.util.core
local M = {}
local fs = require("ulf.doc.util.fs")
local uv = vim and vim.uv or require("luv")

---@param s string
---@param len integer
function M.trim(s, len)
	if #s >= len then
		---@type string
		s = s:sub(1, len)
	end

	return s
end

function M.root(root)
	local f = debug.getinfo(1, "S").source:sub(2)
	return vim.fn.fnamemodify(f, ":p:h:h") .. "/" .. (root or "")
end

---comment
---@param command string[]
---@return string?
function M.run_command(command)
	command[#command + 1] = "2>&1"
	local cmd = table.concat(command, " ")
	-- returns stdout
	local pipe = io.popen(cmd)
	if not pipe then
		return
	end
	local stdout = pipe:read("*a")

	pipe:close()
	return stdout
end

function M.pattern_escape(str)
	return str:gsub("([%(%)%.%/%%%+%-%*%?%[%^%$])", "%%%1")
end

function M.shell_escape(str)
	return str:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "\\%1")
end

---@param plugin string
---@param package_root string
function M.load(plugin, package_root)
	local name = plugin:match(".*/(.*)")
	fs.mkdir(package_root)
	M.run_command({
		"git",
		"clone",
		"--depth=1",
		"https://github.com/" .. plugin .. ".git",
		package_root,
	})
end

return M
