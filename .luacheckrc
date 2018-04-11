-- Luacheck configuration
-- (see http://luacheck.readthedocs.io/en/stable/config.html)

codes = true
ignore = {
	"4[23][12]",-- shadowing upvalues and definitions of variables / arguments
	"542",		-- empty if branch
	"61[24]",	-- ignore whitespace issues
}

files = {
	["minify.lua"] = {
		ignore = {"EscapeForCharacter", "GlobalRenameIgnore"},
	},
}