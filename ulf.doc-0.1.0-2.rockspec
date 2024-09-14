rockspec_format = "3.0"
package = "ulf.doc"
version = "0.1.0-2"
source = {
	url = "https://github.com/lua-ulf/ulf.doc/archive/refs/tags/0.1.0-1.zip",
}
description = {
	summary = "ulf.doc is a documentation module for the ULF framework.",
	detailed = "ulf.doc is a documentation module for the ULF framework.",
	homepage = "http://github.com/lua-ulf/ulf.doc",
	license = "MIT",
	labels = {
		"docgen",
		"neovim",
		"ulf",
	},
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
	platforms = {},
	-- modules = {
	-- 	["ulf"] = "deps/ulf.core/lua/ulf/core",
	-- 	["ulf.doc"] = "deps/ulf.log/lua/ulf/doc",
	-- 	["ulf.log"] = "deps/ulf.log/lua/ulf/log",
	-- },
	install = {
		bin = {
			["ulf-gendocs"] = "bin/gendocs",
		},
	},
}

test_dependencies = {
	"busted",
	"busted-htest",
	"nlua",
	"luacov",
	"luacov-html",
	"luacov-multiple",
	"luacov-console",
	"luafilesystem",
}
test = {
	type = "busted",
}
