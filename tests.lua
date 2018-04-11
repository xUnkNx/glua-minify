local lu, LuaMinify = require("luaunit"), require("minify")

-- mimick the minify() function, but without printing out the AST
local function minify(ast, global_scope, root_scope)
	LuaMinify.MinifyVariables(global_scope, root_scope)
	LuaMinify.StripAst(ast)
end

-- mimick the beautify() function, but without printing out the AST
local function unminify(ast, global_scope, root_scope)
	LuaMinify.BeautifyVariables(global_scope, root_scope)
	LuaMinify.FormatAst(ast)
end

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

	-- a basic minify() example
	source = [[function foo(bar)
		return bar
	end]]
	ast = LuaMinify.CreateLuaParser(source)
	lu.assertEquals(LuaMinify.AstToString(ast), source)

	local global_scope, root_scope = LuaMinify.AddVariableInfo(ast)
	minify(ast, global_scope, root_scope)
	lu.assertEquals(LuaMinify.AstToString(ast), "function a(b)return b end")

	-- now unminify() again
	unminify(ast, global_scope, root_scope)
	lu.assertEquals(LuaMinify.AstToString(ast), [[

function G_1(L_1_arg1)
	return L_1_arg1
end]])
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
