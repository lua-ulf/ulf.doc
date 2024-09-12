---@class ulf.doc.util.string
local M = {}

--- @class ulf.string.gsplit_opts
---
--- Use `sep` literally (as in string.find).
--- @field plain? boolean
---
--- Discard empty segments at start and end of the sequence.
--- @field trimempty? boolean

--- Gets an |iterator| that splits a string at each instance of a separator, in "lazy" fashion
--- (as opposed to |vim.split()| which is "eager").
---
--- Example:
---
--- ```lua
--- for s in vim.gsplit(':aa::b:', ':', {plain=true}) do
---   print(s)
--- end
--- ```
---
--- If you want to also inspect the separator itself (instead of discarding it), use
--- string.gmatch(). Example:
---
--- ```lua
--- for word, num in ('foo111bar222'):gmatch('([^0-9]*)(%d*)') do
---   print(('word: %s num: %s'):format(word, num))
--- end
--- ```
---
--- @see string.gmatch()
--- @see split()
--- @see lua-patterns
--- @see https://www.lua.org/pil/20.2.html
--- @see http://lua-users.org/wiki/StringLibraryTutorial
---
--- @param s string String to split
--- @param sep string Separator or pattern
--- @param opts? ulf.string.gsplit_opts Keyword arguments |kwargs|:
--- @return fun():string? : Iterator over the split components
function M.gsplit(s, sep, opts)
	local plain --- @type boolean?
	local trimempty = false
	if type(opts) == "boolean" then
		plain = opts -- For backwards compatibility.
	else
		assert(type(s) == "string", "M.gsplit: expect s to be a string")
		assert(type(sep) == "string", "M.gsplit: expect sep to be a string")
		opts = opts or {}
		plain, trimempty = opts.plain, opts.trimempty
	end

	local start = 1
	local done = false

	-- For `trimempty`: queue of collected segments, to be emitted at next pass.
	local segs = {}
	local empty_start = true -- Only empty segments seen so far.

	--- @param i integer?
	--- @param j integer
	--- @param ... unknown
	--- @return string
	--- @return ...
	local function _pass(i, j, ...)
		if i then
			assert(j + 1 > start, "Infinite loop detected")
			local seg = s:sub(start, i - 1)
			start = j + 1
			return seg, ...
		else
			done = true
			return s:sub(start)
		end
	end

	return function()
		if trimempty and #segs > 0 then
			-- trimempty: Pop the collected segments.
			return table.remove(segs)
		elseif done or (s == "" and sep == "") then
			return nil
		elseif sep == "" then
			if start == #s then
				done = true
			end
			return _pass(start + 1, start)
		end

		local seg = _pass(s:find(sep, start, plain))

		-- Trim empty segments from start/end.
		if trimempty and seg ~= "" then
			empty_start = false
		elseif trimempty and seg == "" then
			while not done and seg == "" do
				table.insert(segs, 1, "")
				seg = _pass(s:find(sep, start, plain))
			end
			if done and seg == "" then
				return nil
			elseif empty_start then
				empty_start = false
				segs = {}
				return seg
			end
			if seg ~= "" then
				table.insert(segs, 1, seg)
			end
			return table.remove(segs)
		end

		return seg
	end
end

--- Splits a string at each instance of a separator and returns the result as a table (unlike
--- M.gsplit()).
---
--- Examples:
---
--- ```lua
--- split(":aa::b:", ":")                   --> {'','aa','','b',''}
--- split("axaby", "ab?")                   --> {'','x','y'}
--- split("x*yz*o", "*", {plain=true})      --> {'x','yz','o'}
--- split("|x|y|z|", "|", {trimempty=true}) --> {'x', 'y', 'z'}
--- ```
---
---@see M.gsplit()
---@see string.gmatch()
---
---@param s string String to split
---@param sep string Separator or pattern
---@param opts? ulf.string.gsplit_opts Keyword arguments |kwargs|:
---@return string[] : List of split components
function M.split(s, sep, opts)
	local t = {}
	for c in M.gsplit(s, sep, opts) do
		table.insert(t, c)
	end
	return t
end

--- Trim whitespace (Lua pattern "%s") from both sides of a string.
---
---@see lua-patterns
---@see https://www.lua.org/pil/20.2.html
---@param s string String to trim
---@return string String with whitespace removed from its beginning and end
function M.trim(s)
	assert(type(s) == "string", "M.trim: expect s to be a string")
	return s:match("^%s*(.*%S)") or ""
end

---comment
---@param s string
---@return integer
function M.strlen(s)
	assert(type(s) == "string", "M.strlen: expect s to be a string")
	return #s
end

return M
