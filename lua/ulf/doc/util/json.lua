---@class ulf.doc.util.json.exports:ulf.doc.util.Json
---@field setup fun():ulf.doc.util.json.exports
local M = {}

---@class ulf.doc.util.Json
---@field encode fun(t:table,opts:table?)
---@field decode fun(s:string,opts:table?):table

---@alias ulf.doc.util.json_mod_loader fun():ulf.doc.util.Json?

---@type {dkjson:ulf.doc.util.json_mod_loader?,cjson:ulf.doc.util.json_mod_loader?}
local loader = {}
---
loader.dkjson = function()
	---@type boolean
	local ok
	---@type table
	local json
	ok, json = pcall(require, "dkjson") ---@diagnostic disable-line: no-unknown
	if ok then
		return json
	end
end

-- loader.cjson = function()
-- 	---@type boolean
-- 	local ok
-- 	---@type table
-- 	local json
-- 	ok, json = pcall(require, "cjson") ---@diagnostic disable-line: no-unknown
-- 	print(ok, json)
-- 	if ok then
-- 		return json
-- 	end
-- end

---@type ulf.doc.util.Json?
local json

---comment
---@return ulf.doc.util.json.exports
function M.setup()
	if vim then
		return vim.json
	end

	for mod_name, load_fn in pairs(loader) do ---@diagnostic disable-line: no-unknown
		---@type ulf.doc.util.Json?
		local mod = load_fn()
		if mod then
			json = mod
			print("[ulf.doc.util.json]: using " .. mod_name .. " for json support")
			break
		end
	end
	return M
end

return setmetatable(M, {
	__index = function(t, k)
		if type(json) == "table" then
			---@type function
			local v = json[k]
			if type(v) == "function" then
				rawset(t, k, v)
				return v
			end
		end
	end,
})
