---@class ulf.doc.util.core.exports
local M = {}
local Util = require("ulf.doc.util")
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
function M.run_command2(command)
	command[#command + 1] = "2>&1"
	local cmd = table.concat(command, " ") .. "; echo $?"
	-- returns stdout
	local pipe = io.popen(cmd)
	if not pipe then
		return
	end
	local stdout = pipe:read("*a")
	local rc = { pipe:close() }
	P({
		"SSSSSSSSSSSSSSSS",
		rc = rc,
	})

	local exit_code = 0
	local out = Util.string.split(stdout, "\n")
	P(out)

	-- pipe:close()
	return stdout
end

M.signals = {
	"hup",
	"int",
	"quit",
	"ill",
	"trap",
	"abrt",
	"bus",
	"fpe",
	"kill",
	"usr1",
	"segv",
	"usr2",
	"pipe",
	"alrm",
	"term",
	"chld",
	"cont",
	"stop",
	"tstp",
	"ttin",
	"ttou",
	"urg",
	"xcpu",
	"xfsz",
	"vtalrm",
	"prof",
	"winch",
	"io",
	"pwr",
	"emt",
	"sys",
	"info",
}

---@param handle uv_process_t
---@param signals uv.aliases.signals|uv.aliases.signals[]|nil
function M.kill(handle, signals)
	if not handle or handle:is_closing() then
		return
	end
	signals = signals or { "sigterm", "sigkill" }
	-- signals = signals or { "sigkill" }
	signals = type(signals) == "table" and signals or { signals }
	---@cast signals uv.aliases.signals[]
	local timer = assert(uv.new_timer())
	timer:start(0, 1000, function()
		if handle and not handle:is_closing() and #signals > 0 then
			handle:kill(table.remove(signals, 1))
		else
			timer:stop()
		end
	end)
end

local _generic_error = "an error has occured"
---@param exception any? The exception to throw if the result is a failure.
---@param opts {code:integer,signal:integer}
function M.throw(exception, opts)
	-- assert(type(exception) == "string", "[ulf.doc.util.core] throw: exception must be a string")
	assert(type(opts) == "table", "[ulf.doc.util.core] throw: opts must be a table")

	if exception ~= nil then
		error(exception, 2)
	else
		error(_generic_error, 2)
	end
end

---comment
---@param proc uv_process_t
---@param timeout integer
---@param fn fun()
---@return uv_timer_t
function M.guard(proc, timeout, fn)
	---@type uv_timer_t
	local to_timer
	local timedout = false
	to_timer = assert(uv.new_timer())
	to_timer:start(timeout, 0, function()
		timedout = true
		print("process timed out, terminating")
		M.kill(proc)
		fn()
	end)
	return to_timer
end

M.pipe_reader = function(handle, fn, is_stderr)
	---@param err string
	---@param chunk string
	return function(err, chunk)
		if is_stderr then
			print("reading stderr!")
		else
			print("reading stdout")
		end
		assert(not err, err)

		if not chunk then
			print("no chunk closing handle")
			uv.read_stop(handle)
			fn()
			return
		else
			print("chunk valid calling callback")
			---@type string
			chunk = chunk:gsub("\r\n", "\n")
			fn(Util.string.trim(chunk))
		end
	end
end

---@alias ulf.doc.util.run_command_error_type {code:integer,msg:string}
---@alias ulf.doc.util.run_command_error_parse fun(data:string):ulf.doc.util.run_command_error_type?

---comment
---@param cmd string
---@param args string[]
---@param opts? {error_parser:ulf.doc.util.run_command_error_parse}
function M.run_command(cmd, args, opts)
	print(string.format("[ulf.doc.util.core] run_command: args=%s", table.concat(args, " ")))
	opts = opts or {}
	---@type uv_process_t
	local proc

	---@type uv_pipe_t
	local stdout = assert(uv.new_pipe())
	---@type uv_pipe_t
	local stderr = assert(uv.new_pipe())

	---@type string
	local lines_stdout = ""
	---@type string
	local lines_stderr = ""

	local timeout_handler = function()
		print("process was terminated")
		stdout:close()
		stderr:close()
		print(string.format("sighup: %s", assert(proc:kill("sighup"))))
		print(string.format("is_active: %s", proc:is_active()))
		print(string.format("is_closing: %s", proc:is_closing()))
		print(string.format("pid: %s", proc:get_pid()))
		proc:close()
	end
	---@type uv_timer_t
	local guard = M.guard(proc, 3000, timeout_handler)
	proc = uv.spawn(cmd, {
		args = args,
		stdio = { nil, stdout, stderr },
		hide = true,
	}, function(code, signal)
		-- stdout:close()
		-- stderr:close()
		proc:close()
		if guard then
			guard:stop()
		end
		P("spawn callback", code, signal)
		if code ~= 0 then
			M.throw("run_command: errored" .. tostring(cmd), {
				code = code,
				signal = signal,
			})
		else
			print(lines_stderr)
			print(lines_stdout)
		end
	end)

	local on_data = M.pipe_reader(
		stdout,
		---comment
		---@param data string
		function(data)
			if type(data) == "string" then
				lines_stdout = lines_stdout .. data .. "\n"
			end
		end
	)
	local on_error = M.pipe_reader(
		stderr,
		---comment
		---@param data string
		function(data)
			if type(data) == "string" then
				lines_stderr = lines_stderr .. data .. "\n"
				print(data)
			else
				print("no data on stderr, closing")
			end
		end,
		true
	)

	uv.read_start(stdout, on_data)
	uv.read_start(stderr, on_error)
	uv.run()
end
-- ---@alias ulf.doc.util.run_command_error_type {code:integer,msg:string}
-- ---@alias ulf.doc.util.run_command_error_parse fun(data:string):ulf.doc.util.run_command_error_type?
-- ---comment
-- ---@param cmd string
-- ---@param args string[]
-- ---@param opts? {error_parser:ulf.doc.util.run_command_error_parse}
-- function M.run_command(cmd, args, opts)
-- 	print(string.format("[ulf.doc.util.core] run_command: args=%s", table.concat(args, " ")))
-- 	opts = opts or {}
-- 	-- P({
-- 	-- 	"M.run_command called!!!!!!!!!!!!!!!",
-- 	-- 	args = args,
-- 	-- })
--
-- 	---@type uv_process_t
-- 	local proc
--
-- 	local timeout = 3000
--
-- 	---@type uv_timer_t
-- 	local to_timer
--
-- 	local timedout = false
-- 	local function guard()
-- 		to_timer = assert(uv.new_timer())
-- 		to_timer:start(timeout, 0, function()
-- 			timedout = true
-- 			M.kill(proc)
-- 		end)
-- 	end
-- 	-- guard()
--
-- 	---@type uv_pipe_t
-- 	local stdout = assert(uv.new_pipe())
-- 	---@type uv_pipe_t
-- 	local stderr = assert(uv.new_pipe())
--
-- 	---@type string
-- 	local lines_stdout = ""
-- 	---@type string
-- 	local lines_stderr = ""
--
-- 	proc = uv.spawn(
-- 		cmd,
-- 		{
-- 			args = args,
-- 			stdio = { nil, stdout, stderr },
-- 			-- hide = true,
-- 		},
-- 		-- Util.async.schedule_wrap(function(code, signal)
-- 		function(code, signal)
-- 			P("spawn callback", code, signal)
-- 			stdout:close()
-- 			stderr:close()
-- 			proc:close()
--
-- 			if code ~= 0 then
-- 				print("Process was killed with SIG" .. M.signals[signal]:upper())
--
-- 				-- P({
-- 				-- 	"M.run_command ERROR",
-- 				-- 	code = code,
-- 				-- 	signal = signal,
-- 				-- })
--
-- 				print(lines_stderr)
-- 				M.throw("run_command: error executing command " .. cmd, {
-- 					code = code,
-- 					signal = signal,
-- 				})
-- 			else
-- 				print(lines_stdout)
-- 				-- lines_stdout = Util.string.trim(lines_stdout)
-- 				-- print(lines_stdout)
-- 				-- callback(nil)
-- 			end
-- 		end
-- 	)
--
-- 	uv.read_start(stdout, function(err, chunk)
-- 		P("read_start, stdout", err, chunk)
-- 		assert(not err, err)
-- 		if not chunk then
-- 			uv.read_stop(stdout)
-- 			return
-- 		end
-- 		lines_stdout = lines_stdout .. chunk:gsub("\r\n", "\n")
-- 	end)
--
-- 	uv.read_start(stderr, function(err, chunk)
-- 		P("read_start, stderr", err, chunk)
-- 		assert(not err, err)
-- 		if not chunk then
-- 			uv.read_stop(stderr)
-- 			return
-- 		end
-- 		lines_stderr = lines_stderr .. chunk:gsub("\r\n", "\n")
-- 	end)
--
-- 	uv.run()
-- 	-- Util.async.wait(2500)
-- 	if type(opts.error_parser) == "function" then
-- 		local err = opts.error_parser(lines_stdout)
-- 		if err then
-- 			M.throw(err.msg, {
-- 				code = 2,
-- 				signal = 0,
-- 			})
-- 		end
-- 	end
-- 	-- print(res)
-- 	return lines_stdout .. lines_stderr
-- end
--

---comment
---@param cmd string
---@param args string[]
---@param opts? {error_parser:ulf.doc.util.run_command_error_parse}
---@return {lines:string[], code:integer}|nil
function M.run_command_simple(cmd, args, opts)
	-- local _cmd = cmd .. " " .. table.concat(args, " ") .. [[ 2>&1; echo "\n$?"]]
	local _cmd = cmd .. " " .. table.concat(args, " ")
	print(_cmd)
	-- returns stdout
	local pipe = io.popen(_cmd)
	if not pipe then
		return
	end
	---@type string
	local stdout = pipe:read("*a")

	if stdout then
		local exit_code = -1
		---@type string
		-- stdout = stdout:gsub("\r\n", "\n")
		-- P("stdout", stdout)
		local lines = Util.string.split(stdout, "\n")
		if type(lines) == "table" and #lines > 0 then
			for i = #lines, 1, -1 do
				local v = lines[i]

				if v:match("%d") then
					exit_code = tonumber(v)
					break
				elseif v == "" then
					table.remove(lines, i)
				end
			end
			return {
				code = exit_code,
				lines = lines,
			}
		end
	end

	pipe:close()
	return
end

function M.pattern_escape(str)
	return str:gsub("([%(%)%.%/%%%+%-%*%?%[%^%$])", "%%%1")
end

function M.shell_escape(str)
	return str:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "\\%1")
end

---comment
---@param command string
---@return boolean
function M.has_executable(command)
	---@type string
	local stdout
	local pipe = io.popen("command -v " .. command)
	if not pipe then
		return false
	end
	stdout = pipe:read("*a") -- Read the output of the command
	pipe:close()

	return stdout ~= nil and stdout:match("%S") -- Check if the output is not just whitespace
end

---@param plugin string
---@param package_root string
function M.load(plugin, package_root)
	local name = plugin:match(".*/(.*)")
	fs.mkdir(package_root)
	M.run_command("git", {
		"clone",
		"--depth=1",
		"https://github.com/" .. plugin .. ".git",
		package_root,
	})
end

return M
