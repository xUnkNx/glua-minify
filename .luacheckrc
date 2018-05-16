-- Luacheck configuration
-- (see http://luacheck.readthedocs.io/en/stable/config.html)

codes = true
ignore = {
	"614",	-- trailing whitespace in comments
}

files = {
	["minify.lua"] = {
		ignore = {"EscapeForCharacter", "GlobalRenameIgnore"},
	},
	["tests.lua"] = {
		ignore = {"test[%a_]+"}
	}
}
