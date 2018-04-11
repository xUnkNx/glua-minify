-- Luacheck configuration
-- (see http://luacheck.readthedocs.io/en/stable/config.html)

codes = true
ignore = {
	"11[13]",	-- ignore setting globals (namespace pollution) and "undefined variable" warnings
	"21[123]",	-- unused [loop] variables and (function) arguments
	"241",		-- variable is mutated but never accessed
	"311",		-- value assigned to variable is overwritten before use
	"4[23][12]",-- shadowing upvalues and definitions of variables / arguments
	"542",		-- empty if branch
	"61[24]",	-- ignore whitespace issues
}