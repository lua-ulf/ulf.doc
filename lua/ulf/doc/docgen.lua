-- Setup telescope with defaults
local docgen = require("docgen")

local M = {}

M.run = function()
	-- TODO: Fix the other files so that we can add them here.
	local input_files = {
		"/Users/al/dev/projects/ulf/deps/ulf.log/lua/ulf/log/init.lua",
	}

	local output_file = "/Users/al/dev/projects/ulf/deps/ulf.log/doc/ulf.log.txt"
	local output_file_handle = io.open(output_file, "w")
	if not output_file_handle then
		error("error opening output file")
	end

	for _, input_file in ipairs(input_files) do
		docgen.write(input_file, output_file_handle)
	end

	output_file_handle:write(" vim:tw=78:ts=8:ft=help:norl:\n")
	output_file_handle:close()
	vim.cmd([[checktime]])
end

return M
