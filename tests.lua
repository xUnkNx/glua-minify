local lu, LuaMinify = require("luaunit"), require("minify")

-- Test basic functionality: parse Lua code snippet (into AST) and reformat it
function test_basics()
	-- two keywords
	local source = 'return true'
	local ast = LuaMinify.CreateLuaParser(source)
	lu.assertEquals(LuaMinify.AstToString(ast), source)
	-- function call (identifier and string literal)
	source = 'print("Hello world")'
	ast = LuaMinify.CreateLuaParser(source)
	lu.assertEquals(LuaMinify.AstToString(ast), source)
end

lu.LuaUnit:run(...)
