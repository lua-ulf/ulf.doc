---@diagnostic disable:lowercase-global

rockspec_format = "3.0"
package = "ulf.doc"
version = "scm-1"
source = {
	url = "https://github.com/lua-ulf/ulf.doc/archive/refs/tags/scm-1.zip",
}

description = {
	summary = "ulf.doc is a documentation module for the ULF framework.",
	detailed = "ulf.doc is a documentation module for the ULF framework.",
	labels = { "docgen", "neovim", "ulf" },
	homepage = "http://github.com/lua-ulf/ulf.doc",
	license = "MIT",
}

dependencies = {
	"lua >= 5.1",
	"inspect",
	"lua_cliargs",
	-- "cjson",
	"dkjson",
	"tabular",
}
build = {
	type = "builtin",
	modules = {},
	copy_directories = {},
	platforms = {},
}
test_dependencies = {
	"busted",
	"busted-htest",
	"luacov",
	"luacov-html",
	"luacov-multiple",
	"luacov-console",
	"luafilesystem",
}
test = {
	type = "busted",
}
