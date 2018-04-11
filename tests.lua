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

-- Test invalid syntax and some corner cases, mainly to improve code coverage
function test_errors()
	lu.assertErrorMsgContains('Bad symbol `$` in source.',
		LuaMinify.CreateLuaParser, '$')
	lu.assertErrorMsgContains('1:1: Unexpected symbol',
		LuaMinify.CreateLuaParser, '/')
	lu.assertErrorMsgContains('Unfinished long string.',
		LuaMinify.CreateLuaParser, '\n[[')
	lu.assertErrorMsgContains('Invalid Escape Sequence `?`.',
		LuaMinify.CreateLuaParser, '"\\?"')
	lu.assertErrorMsgContains('`=` expected.',
		LuaMinify.CreateLuaParser, 'foobar 4')
	lu.assertErrorMsgContains('Ident expected.',
		LuaMinify.CreateLuaParser, 'local function 2')
end

lu.LuaUnit:run(...)
