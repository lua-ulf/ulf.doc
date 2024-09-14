local M = {}

--- @param cmd string
--- @param opts uv.spawn.options
--- @param on_exit fun(code: integer, signal: integer)
--- @param on_error fun()
--- @return uv.uv_process_t, integer
local function spawn(cmd, opts, on_exit, on_error)
	local handle, pid_or_err = uv.spawn(cmd, opts, on_exit)
	if not handle then
		on_error()
		error(pid_or_err)
	end
	return handle, pid_or_err --[[@as integer]]
end

return M
