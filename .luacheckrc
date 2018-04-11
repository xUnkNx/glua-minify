-- Luacheck configuration
-- (see http://luacheck.readthedocs.io/en/stable/config.html)

codes = true
ignore = {
	"61[24]",	-- ignore whitespace issues
}

files = {
	["minify.lua"] = {
		ignore = {"EscapeForCharacter", "GlobalRenameIgnore"},
	},
}