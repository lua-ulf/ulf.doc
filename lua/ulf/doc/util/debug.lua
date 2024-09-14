---@class ulf.doc.util.debug.exports
local M = {}

---comment
---@param ... any
function M.inspect(...)
	---@param ... any
	local inspect = function(...)
		local argv = { ... }
		---@type string[]
		local out = {}
		for index, value in ipairs(argv) do
			out[#out + 1] = tostring(index) .. " " .. tostring(value)
		end
		io.write(table.concat(out, " ") .. "\n")
		io.flush()
		error("inspect module not found")
	end
	if vim then
		inspect = vim.inspect
	else
		local ok, mod = pcall(require, "inspect") ---@diagnostic disable-line: no-unknown
		if ok then
			---@type fun(...)
			inspect = mod
		end
	end
	return inspect(...)
end

---comment
---@param kind? 'path'|'cpath'|'all'
function M.dump_lua_path(kind)
	kind = kind or "path"

	local path_kinds = kind == "all" and { "path", "cpath" } or { kind }

	local _dump = function(k)
		---@type string[]
		local out = {}
		local i = 1
		for str in string.gmatch(package[k], "([^" .. ";" .. "]+)") do
			out[#out + 1] = string.format("%02d: %s", i, str)
		end

		print(table.concat(out, "\n"))
	end

	print(string.rep(">", 80))
	for _, k in ipairs(path_kinds) do
		print(string.format("[ulf.doc.util.debug] dump_lua_path: %05s", k))
		_dump(k)
		print("\n")
	end
	print(string.rep("<", 80))
end

function M.debug_print(...)
	---@type string[]
	local out = {}
	local argv = { ... }
	local offset = 0

	---@type fun(...)
	local inspect = M.inspect
	if #argv == 0 then
		return
	end

	if type(argv[1]) == "string" then
		out[#out + 1] = argv[1]
		offset = offset + 1
	end

	for i = 1 + offset, #argv, 1 do
		local v = argv[i] ---@diagnostic disable-line: no-unknown
		out[#out + 1] = tostring(i) .. " (" .. type(v) .. ") " .. inspect(v)
	end
	io.write(table.concat(out, " ") .. "\n")
	io.flush()
end

function M._dump(value, result)
	local t = type(value)
	if t == "number" or t == "boolean" then
		table.insert(result, tostring(value))
	elseif t == "string" then
		table.insert(result, ("%q"):format(value))
	elseif t == "table" and value._raw then
		table.insert(result, value._raw)
	elseif t == "table" then
		table.insert(result, "{")
		for _, v in ipairs(value) do ---@diagnostic disable-line: no-unknown
			M._dump(v, result)
			table.insert(result, ",")
		end
		---@diagnostic disable-next-line: no-unknown
		for k, v in pairs(value) do
			if type(k) == "string" then
				if k:match("^[a-zA-Z]+$") then
					table.insert(result, ("%s="):format(k))
				else
					table.insert(result, ("[%q]="):format(k))
				end
				M._dump(v, result)
				table.insert(result, ",")
			end
		end
		table.insert(result, "}")
	else
		error("Unsupported type " .. t)
	end
end

function M.dump(value)
	local result = {}
	M._dump(value, result)
	return table.concat(result, "")
end

return M
