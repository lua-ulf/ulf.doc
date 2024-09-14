-- see luvit/luvit/deps/timer.lua

---@type uv
local uv = vim and vim.uv or require("luv")

---@class ulf.doc.util.async.exports
local M = {}
M.default_interval = 50

local function assert_resume(thread, ...)
	local success, err = coroutine.resume(thread, ...)
	if not success then
		error(debug.traceback(thread, err), 0)
	end
end

-- clear_interval
---comment
---@param timer uv_timer_t
function M.clear_timeout(timer)
	if uv.is_closing(timer) then
		return
	end
	uv.timer_stop(timer)
	uv.close(timer)
end

-- set_timeout
---comment
---@param timeout integer
---@param callback function
---@param ... any
---@return uv_timer_t
function M.set_timeout(timeout, callback, ...)
	assert(type(timeout) == "number", "ulf.async.util.set_timeout: timeout must be a number")
	assert(type(callback) == "function", "ulf.async.util.set_timeout: callback must be a function")
	local timer = uv.new_timer()
	local args = { ... }
	timer:start(timeout, 0, function()
		timer:stop()
		timer:close()
		callback(unpack(args))
	end)
	return timer
end

---comment
---@param fn function
---@param self table
---@param ... any
---@return function
function M.bind(fn, self, ...)
	assert(type(fn) == "function", "ulf.async.util.bind: fn must be a function")
	local argc = select("#", ...)

	-- Simple binding, just inserts self (or one arg or any kind)
	if argc == 0 then
		return function(...)
			return fn(self, ...)
		end
	end

	-- More complex binding inserts arbitrary number of args into call.
	local argv = { ... }
	return function(...)
		local _argc = select("#", ...)
		local args = { ... }
		local arguments = {}
		for i = 1, argc do
			---@type any
			arguments[i] = argv[i]
		end
		for i = 1, _argc do
			---@type any
			arguments[i + argc] = args[i]
		end
		return fn(self, unpack(arguments, 1, argc + _argc))
	end
end

-- set_interval
---comment
---@param interval integer
---@param callback function
---@param ... any
---@return uv_timer_t
function M.set_interval(interval, callback, ...)
	assert(type(interval) == "number", "ulf.async.util.set_interval: interval must be a number")
	assert(type(callback) == "function", "ulf.async.util.set_interval: callback must be a function")
	local tm = uv.new_timer()
	uv.timer_start(tm, interval, interval, M.bind(callback, ...))
	return tm
end

local checker = uv.new_check()
local idler = uv.new_idle()
local immediate_queue = {}

local function on_check()
	local queue = immediate_queue
	immediate_queue = {}
	for i = 1, #queue do
		queue[i]()
	end
	-- If the queue is still empty, we processed them all
	-- Turn the check hooks back off.
	if #immediate_queue == 0 then
		uv.check_stop(checker)
		uv.idle_stop(idler)
	end
end

---comment
---@param callback function
---@param ... any
function M.set_immediate(callback, ...)
	assert(type(callback) == "function", "ulf.async.util.set_immediate: callback must be a function")
	-- If the queue was empty, the check hooks were disabled.
	-- Turn them back on.
	if #immediate_queue == 0 then
		uv.check_start(checker, on_check)
		uv.idle_start(idler, on_check)
	end

	---@type function
	immediate_queue[#immediate_queue + 1] = M.bind(callback, ...)
end
--- Defers calling {fn} until {timeout} ms passes.
---
--- Use to do a one-shot timer that calls {fn}
---@param fn function Callback to call once `timeout` expires
---@param timeout integer Number of milliseconds to wait before calling `fn`
---@return table timer luv timer object
function M.defer_fn(fn, timeout)
	assert(type(fn) == "function", "nvl.async.modules.utils: fn must be a function")
	assert(type(timeout) == "number", "nvl.async.modules.utils: fn must be a number")

	local timer = assert(uv.new_timer())
	timer:start(timeout, 0, function()
		fn()
		if not timer:is_closing() then
			timer:close()
		end
	end)

	return timer
end

---@param delay number
---@param thread? thread
---@async
local function sleep(delay, thread)
	thread = thread or coroutine.running()
	local timer = uv.new_timer()
	uv.timer_start(timer, delay, 0, function()
		uv.timer_stop(timer)
		uv.close(timer)
		return assert_resume(thread)
	end)
	return coroutine.yield()
end

function M.sleep(ms)
	---@async
	local sleeper = function()
		sleep(ms)
	end
	local co = coroutine.create(sleeper)
	coroutine.resume(co)
end

--- Calls fn() until it succeeds, up to `max` times or until `max_ms`
--- milliseconds have passed.
--- @param max integer?
--- @param max_ms integer?
--- @param fn function
--- @return any
function M.retry(max, max_ms, fn)
	assert(max == nil or max > 0)
	assert(max_ms == nil or max_ms > 0)
	local tries = 1
	local timeout = (max_ms and max_ms or 10000)
	local start_time = uv.now()
	while true do
		--- @type boolean, any
		local status, result = pcall(fn)
		if status then
			return result
		end
		uv.update_time() -- Update cached value of luv.now() (libuv: uv_now()).
		if (max and tries >= max) or (uv.now() - start_time > timeout) then
			error(string.format("retry() attempts: %d\n%s", tries, tostring(result)), 2)
		end
		tries = tries + 1
		uv.sleep(20) -- Avoid hot loop...
	end
end

local function pack_len(...)
	return { n = select("#", ...), ... }
end

local function unpack_len(t)
	return unpack(t, 1, t.n)
end

--- @param time integer Number of milliseconds to wait
--- @param callback? fun(): boolean Optional callback. Waits until {callback} returns true
--- @param interval? integer (Approximate) number of milliseconds to wait between polls
--- @param fast_only? boolean If true, only |api-fast| events will be processed.
--- @return boolean, integer?
---     - If {callback} returns `true` during the {time}: `true, nil`
---     - If {callback} never returns `true` during the {time}: `false, -1`
---     - If {callback} is interrupted during the {time}: `false, -2`
---     - If {callback} errors, the error is raised.
function M.wait(time, callback, interval, fast_only)
	assert(type(time == "number"), "[ulf.async.util] wait(): time must be a number")
	if interval then
		assert(type(interval == "number"), "[ulf.async.util] wait(): interval must be a number")
	end
	if fast_only then
		assert(type(fast_only == "boolean"), "[ulf.async.util] wait(): fast_only must be a boolean")
	end
	interval = interval or time -- Default interval to time if not provided
	local start_time = uv.now() -- Get current time in milliseconds
	local elapsed = 0
	local result, code = false, nil -- Default result and code

	if fast_only then
		error("fast_only option is not implemented")
	end

	-- Error handling for the callback
	local function safe_call()
		if type(callback) == "function" then
			local ok, res = pcall(callback)
			if not ok then
				error(res) -- Re-raise the error if callback fails
			end
			return res, true
		else
			return true, false
		end
	end

	-- Function to check the condition and manage timing
	local function check_condition(timer)
		local result, ext_callback = safe_call()
		uv.update_time() -- Update cached value of luv.now() (libuv: uv_now()).
		elapsed = uv.now() - start_time
		if elapsed < time then
			if result then
				-- CASE 1
				-- we have a truthy value 'in time'
				-- if no callback was given wait remaining time and return
				-- if a callback was given return
				uv.timer_stop(timer) -- Stop the timer
				uv.close(timer) -- Close the timer
				if ext_callback then
					code = nil -- Condition met
					return
				else
					local wait_time = (time - elapsed)

					M.sleep(wait_time)
					code = -2
					return
				end
			else
				-- CASE 2
				-- we have not a truthy value 'in time'
				-- repeat timer
			end
		elseif elapsed >= time then
			-- CASE 3
			-- time is up
			-- return
			code = -1 -- Timeout without condition being met
			uv.timer_stop(timer) -- Stop the timer
			uv.close(timer) -- Close the timer
			return
		end
	end

	-- Start a timer to repeatedly check the condition
	local timer = uv.new_timer()
	uv.timer_start(timer, 0, interval, function()
		check_condition(timer)
	end)

	if not vim then
		uv.run()
	end
	-- Since we're not running the loop here, we rely on the caller's event loop.
	return result, code
end

function M.schedule(fn)
	if type(fn) ~= "function" then
		error("[ulf.async.util] schedule(...): fn must be a function")
	end

	M.set_immediate(fn)
end

function M.schedule_wrap(fn)
	return function(...)
		local args = pack_len(...)
		M.schedule(function()
			fn(unpack_len(args))
		end)

		if not vim then
			uv.run()
		end
	end
end

---@param o any
---@param expected_type string
function M.assert_type(o, expected_type)
	local got_type = type(o)
	local fmt = "%s expected, got %s"
	return assert(got_type == expected_type, fmt:format(expected_type, got_type))
end

---@param o any
---@param typ? string
---@return boolean, function|table|any
function M.get_callable(o, typ)
	---@type boolean
	local ok
	---@type function|table
	local f
	local t = typ or type(o)
	if t == "function" then
		ok, f = true, o
	elseif t ~= "table" then
		ok, f = false, o
	else
		---@type {__call:function}
		local meta = getmetatable(o)
		ok = meta and type(meta.__call) == "function"
		if ok then
			f = meta.__call
		end
	end
	return ok, f
end

return M
