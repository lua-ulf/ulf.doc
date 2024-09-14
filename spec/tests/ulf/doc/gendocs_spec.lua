local Util = require("ulf.doc.util")
local function assign(key, value)
	return "--" .. key .. "=" .. "'" .. value .. "'"
end

local uv = vim and vim.uv or require("luv")
if false then
	describe("#ulf", function()
		describe("#ulf.doc.gendocs", function()
			describe("ulf-gendocs", function()
				local GenDocs = require("ulf.doc.gendocs")

				it("creates documentation without a config", function()
					assert(Util.core.has_executable("ulf-gendocs"))

					local root = Util.fs.project_root()
					local paths = {
						path_output = Util.fs.joinpath(root, "/spec/fixtures/testapp1/doc"),
						files = {
							Util.fs.joinpath(root, "/spec/fixtures/testapp1/init.lua"),
						},
					}

					local args = {
						-- "ulf-gendocs",
						assign("app", "testapp1"),
						assign("path_output", paths.path_output),
						assign("files", table.concat(paths.files, ",")),
						assign("config", "nil"),

						-- ".ulf-gendocs.json",
					}

					local error_parse_stdout = function(data)
						local code, msg = data:match("(E%d+):%s*(.*)")
						P({
							"SSSSSSSSSSSSSSSAAAAAAAAAAAAAAAAAAA",
							data = data,
							code = code,
							msg = msg,
						})

						if code and msg then
							return {
								code = 2,
								msg = data,
							}
						end
					end
					assert.has_no_error(function()
						-- local out = Util.core.run_command(args)
						-- P(args)
						-- P(out)
						local result = Util.core.run_command("ulf-gendocs", args, {
							error_parser = error_parse_stdout,
						})
						print(result)
					end)

					assert(1)
				end)
			end)
		end)
	end)
end
