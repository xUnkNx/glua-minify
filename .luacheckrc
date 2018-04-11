-- Luacheck configuration
-- (see http://luacheck.readthedocs.io/en/stable/config.html)

codes = true
ignore = {
	"21[23]",	-- unused [loop] variables and (function) arguments
	"241",		-- variable is mutated but never accessed
	"4[23][12]",-- shadowing upvalues and definitions of variables / arguments
	"542",		-- empty if branch
	"61[24]",	-- ignore whitespace issues
}

files = {
	["minify.lua"] = {
		ignore = {"EscapeForCharacter", "GlobalRenameIgnore"},
	},
}