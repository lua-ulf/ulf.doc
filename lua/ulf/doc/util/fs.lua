---@class ulf.doc.util.fs.exports
local M = {}

local uv = vim and vim.uv or require("luv")

M.is_windows = package.config:find("\\") and true or false
M.pathsep = M.is_windows and "\\" or "/"
M.pathsep_pattern = M.is_windows and [[%\%\]] or "%/"

---@param ... string
---@return string?
function M.joinpath(...)
	return (table.concat({ ... }, M.pathsep):gsub(M.pathsep .. M.pathsep .. "+", M.pathsep))
end

--- @param path string
--- @return string?
function M.basename(path)
	return path:match(".*" .. M.pathsep_pattern .. "(.+)$")
end

--- @param path string
--- @return string?
function M.dirname(path)
	return path:match("(.*)" .. M.pathsep_pattern .. ".+$")
end

--- @param path string
--- @return boolean?
function M.mkdir(path)
	-- 493 is 0755 in decimal
	local err, res = uv.fs_mkdir(path, 493)

	if err and type(err) ~= "boolean" then
		error(err)
	end
	return true
end

---@param path string
function M.rmdir(path)
	assert(uv.fs_rmdir(path))
end

--- @param path string
--- @return boolean?
function M.dir_exists(path)
	local stat = uv.fs_stat(path)

	if not stat then
		return false
	end
	if type(stat) == "table" then
		return stat.type == "directory"
	end
end

function M.file_exists(file)
	return uv.fs_stat(file) ~= nil
end

--- @param kind "config"|"data"|"cache"|"state"
--- @param ... string
--- @return string?
function M.stdpath(kind, ...)
	---@type string?
	local env_var
	if kind == "config" then
		env_var = "XDG_CONFIG_HOME"
	elseif kind == "data" then
		env_var = "XDG_DATA_HOME"
	elseif kind == "state" then
		env_var = "XDG_STATE_HOME"
	elseif kind == "cache" then
		env_var = "XDG_CACHE_HOME"
	end
	if env_var then
		return M.joinpath(os.getenv(env_var), ...)
	end
end

function M.logfile_path(app_name, config)
	return M.joinpath(M.stdpath("data") --[[@as string]], "ulf", "log", app_name)
end

---comment
---@param fname string
---@return string
function M.read_file(fname)
	local fd = assert(io.open(fname, "r"))
	---@type string
	local data = fd:read("*a")
	fd:close()
	return data
end

-- Function to get the git root directory
---@return string|nil
function M.git_root()
	---@type string
	local git_root
	---@type file*
	local handle = io.popen("git rev-parse --show-toplevel 2>/dev/null")
	if handle then
		---@type string
		git_root = handle:read("*a"):gsub("\n", "")
		handle:close()
	end
	return git_root
end

---@alias ulf.doc.FileType "file"|"directory"|"link"

---@param path string
---@param fn fun(path: string, name:string, type:ulf.doc.FileType):boolean?
function M.ls(path, fn)
	local handle = uv.fs_scandir(path)
	while handle do
		local name, t = uv.fs_scandir_next(handle)
		if not name then
			break
		end

		local fname = path .. "/" .. name

		-- HACK: type is not always returned due to a bug in luv,
		-- so fecth it with fs_stat instead when needed.
		-- see https://github.com/folke/lazy.nvim/issues/306
		if fn(fname, name, t or uv.fs_stat(fname).type) == false then
			break
		end
	end
end

---comment
---@param path string
---@return string[]
function M.list_directories(path)
	---@type string[]
	local ret = {}
	M.ls(path, function(p, name, kind)
		if kind == "directory" then
			ret[#ret + 1] = name
		end
	end)
	return ret
end

--- Returns the project root of the current module.
--- This function respects git subtrees when querying for the
--- root path (monorepo). Each subtree coresponds to a separate lua module
--- and is mounted at deps/<project>.
---
---
--- 1. The function uses Util.fs.git_root() to get the git root path.
--- 2. It then looks for <git-root>/deps
---   2.1 If deps is found then we are on the monorepo.
---     2.1.1 It then compares the suffix of the current's lua script path
---     to find the corresponding subtree in deps. If a match is found
---     it appends the path deps/<project> to the returend git root.
---   2.2 If deps is not found then we are NOT on the monorepo.
---     2.2.1 Return the git root path unmodified
---@return string?
function M.project_root()
	-- 1. Use Util.fs.git_root() to get the git root path.
	local git_root = M.git_root()
	if not git_root then
		return nil -- or handle the error as appropriate
	end
	-- 2. Check for <git-root>/deps to determine if we are in a monorepo.
	local deps_path = M.joinpath(git_root, "deps")
	local is_monorepo = M.dir_exists(deps_path) -- Assuming Util.fs.exists checks for the existence of a path
	if is_monorepo then
		-- 2.1 We are in the monorepo.
		local script_path = debug.getinfo(1, "S").source:sub(2) -- Get the current script path without the leading '@'

		-- Iterate over the directories in deps to construct the full path and check for a match
		local dirs = M.list_directories(deps_path) -- Assuming Util.fs.list_directories returns a list of directory names
		for _, dir in ipairs(dirs) do
			local potential_project_path = M.joinpath(deps_path, dir, script_path)
			if M.file_exists(potential_project_path) then
				-- A matching full path is found, return the project path within deps.
				return M.joinpath(deps_path, dir)
			end
		end
	end
	return git_root
end

return M
