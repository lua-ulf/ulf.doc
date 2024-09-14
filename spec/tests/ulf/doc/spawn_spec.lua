local Config = require("ulf.doc.gendocs.config")
local Util = require("ulf.doc.util")
local function assign(key, value)
	return "--" .. key .. "=" .. "'" .. value .. "'"
end

local uv = vim and vim.uv or require("luv")

local validator = {}
---comment
---@param got any
---@param expect {[string]:any}
---@param opts {max_wait_time_ms:integer}
validator.counter_output_line = function(got, expect, opts)
	---@type string
	local line = got
	assert.String(line, "validator.counter_output_line: expect line to be a string")

	-- Match the line against the expected format
	local num, wait_time = line:match("^%s*(%d+):%s*(%d+)%s*ms$")
	assert(num, "validator.counter_output_line: expect num not to be nil")
	assert(wait_time, "validator.counter_output_line: expect wait_time not to be nil")

	-- Convert captured strings to numbers
	local num_val = tonumber(num)
	local wait_time_val = tonumber(wait_time)

	assert.Number(num_val, "validator.counter_output_line: expect num_val to be a number")
	assert.Number(wait_time_val, "validator.counter_output_line: expect wait_time_val to be a number")

	-- Assertions
	assert(num_val >= 1 and num_val <= 10, "Number out of range: " .. num_val)
	assert(wait_time_val >= 1 and wait_time_val <= opts.max_wait_time_ms, "Wait time out of range: " .. wait_time_val)

	-- Print success for each line (optional)
	print(string.format("Line '%s' passed all assertions.", line))
end

---comment
---@param got any
---@param expect {[string]:any}
---@param opts {max_wait_time_ms:integer}
validator.counter_output = function(got, expect, opts)
	---@type string
	local output = got
	for line in output:gmatch("[^\r\n]+") do
		validator.counter_output_line(line, expect, opts)
	end
end

local error_parse_stdout = function(data)
	local code, msg = data:match("(E%d+):%s*(.*)") ---@diagnostic disable-line: no-unknown
	if code and msg then
		return {
			code = 2,
			msg = data,
		}
	end
end
---comment
---@param s string
---@return string
local function q(s)
	return '"' .. s .. '"'
end
describe("#ulf", function()
	describe("#ulf.doc.util.core", function()
		describe("run_command", function()
			if false then
				describe("counter.sh", function()
					local GenDocs = require("ulf.doc.gendocs")

					it("returns numbers from 1 to 10", function()
						assert(Util.core.has_executable("ulf-gendocs"))

						-- Example output provided
						-- local output = [[
						--  1:  202 ms
						--  2:   55 ms
						--  3:   57 ms
						--  4:  187 ms
						--  5:   75 ms
						--  6:   45 ms
						--  7:  103 ms
						--  8:  177 ms
						--  9:  183 ms
						-- 10:  154 ms
						-- ]]
						local cmd =
							Util.fs.joinpath(Util.fs.project_root(), "spec", "fixtures", "async-stdout", "counter.sh")
						local args = {
							"1",
							"10",
							"250",
						}
						assert.has_no_error(function()
							local result = Util.core.run_command(cmd, args, {
								error_parser = error_parse_stdout,
							})
							validator.counter_output(result, {}, { max_wait_time_ms = 1000 })
						end)
					end)
				end)
				describe("nvim", function()
					it("executes a simple lua statement", function()
						local vim_init = Util.fs.joinpath(Util.fs.project_root(), "scripts", "minimal_init.lua")
						local cmd = "nvim"
						local args = {
							-- "--clean",
							"-u",
							vim_init,
							"--headless",
							"-c",
							-- q([[lua print('done');vim.cmd('qall!')]]),
							q(
								[[lua for i=1,10 do local wait_time = math.random(45, 202); print(string.format('%2d: %4d ms', i, wait_time)); os.execute('sleep ' .. wait_time / 1000); end]]
							),
							"-c",
							q([[wq]]),
						}

						assert.has_no_error(function()
							local result = Util.core.run_command(cmd, args, {
								error_parser = error_parse_stdout,
							})
							-- validator.counter_output(result, {}, { max_wait_time_ms = 1000 })
						end)
					end)
				end)
			end
			describe("nvim via shell", function()
				it("executes a simple lua statement", function()
					local vim_init = Util.fs.joinpath(Util.fs.project_root(), "scripts", "minimal_init.lua")
					local cmd = "sh"
					local args = {
						"-c",
						"nvim",
						"-u",
						vim_init,
						"--headless",
						"-c",
						q([[lua print('done');vim.cmd('qall!')]]),
						-- q(
						-- 	[[lua for i=1,10 do local wait_time = math.random(45, 202); print(string.format('%2d: %4d ms', i, wait_time)); os.execute('sleep ' .. wait_time / 1000); end]]
						-- ),
						"-c",
						q([[wq]]),
					}

					assert.has_no_error(function()
						local result = Util.core.run_command(cmd, args, {
							error_parser = error_parse_stdout,
						})
						-- validator.counter_output(result, {}, { max_wait_time_ms = 1000 })
					end)
				end)
			end)
		end)
	end)
end)
