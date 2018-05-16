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

-- wrappers that work with only the AST (at the cost of reparsing the var info)
local function _minify(ast)
	minify(ast, LuaMinify.AddVariableInfo(ast))
end
local function _unminify(ast)
	unminify(ast, LuaMinify.AddVariableInfo(ast))
end

-- assert that the string representation of an AST matches a given value
local function _assertAstStringEquals(ast, value)
	lu.assertEquals(LuaMinify.AstToString(ast), value)
end

-- Validate a token table against a list of strings. This attempts to match
-- each token's (.Source) content against the corresponding list element.
-- Note: The terminating "Eof" token always gets checked implicitly.
local function assertTokenSequence(tokens, list)
	lu.assertIsTable(list)
	local len = #list
	lu.assertIsTable(tokens)
	lu.assertEquals(#tokens, len + 1, 'assertTokenSequence: token count mismatch')
	for i = 1, len do
		lu.assertEquals(tokens[i].Source, list[i], 'token #'..i..' mismatches')
	end
	-- check "Eof"
	lu.assertEquals(tokens[len + 1].Type, 'Eof', 'last token isn\'t "Eof"')
	lu.assertEquals(tokens[len + 1].Source, '', 'last token isn\'t empty')
end

-- Test basic functionality: parse Lua code snippet (into AST) and reformat it
function test_basics()
	-- two keywords
	local source = 'return true'
	local ast = LuaMinify.CreateLuaParser(source)
	_assertAstStringEquals(ast, source)
	-- function call (identifier and string literal)
	source = 'print("Hello world")'
	ast = LuaMinify.CreateLuaParser(source)
	_assertAstStringEquals(ast, source)

	-- a basic minify() example
	source = [[function foo(bar)
		return bar
	end]]
	ast = LuaMinify.CreateLuaParser(source)
	_assertAstStringEquals(ast, source)
	_minify(ast)
	_assertAstStringEquals(ast, "function a(b)return b end")

	-- now unminify() again
	_unminify(ast)
	_assertAstStringEquals(ast, [[

function G_1(L_1_arg1)
	return L_1_arg1
end]])
end

-- Test invalid syntax and some corner cases, mainly to improve code coverage
function test_errors()
	-- tokenizer
	lu.assertErrorMsgContains('<1:1>: Bad symbol `$` in source.',
		LuaMinify.CreateLuaTokenStream, '$')
	lu.assertErrorMsgContains('<2:2>: Unfinished long string.',
		LuaMinify.CreateLuaTokenStream, '\n[[')
	lu.assertErrorMsgContains('<1:4>: Invalid Escape Sequence `?`.',
		LuaMinify.CreateLuaTokenStream, '"\\?"')

	-- syntax parser
	local tokens = LuaMinify.CreateLuaTokenStream('/')
	assertTokenSequence(tokens, {'/'})
	lu.assertErrorMsgContains('1:1: Unexpected symbol',
		LuaMinify.CreateLuaParser, tokens)

	tokens = LuaMinify.CreateLuaTokenStream('foobar 4')
	assertTokenSequence(tokens, {'foobar', '4'})
	lu.assertErrorMsgContains('1:8: `=` expected.',
		LuaMinify.CreateLuaParser, tokens)

	tokens = LuaMinify.CreateLuaTokenStream('local function 2')
	assertTokenSequence(tokens, {'local', 'function', '2'})
	lu.assertErrorMsgContains('1:16: Ident expected.',
		LuaMinify.CreateLuaParser, tokens)
end

-- Test if parser can handle vararg functions
function test_varargs()
	-- pure vararg function, anonymous
	local source = 'return function(...) end'
	local ast = LuaMinify.CreateLuaParser(source)
	_assertAstStringEquals(ast, source)
	_minify(ast)
	_assertAstStringEquals(ast, 'return function(...)end')
	-- vararg function that has additional arguments, anonymous
	source = 'return function(a, b, ...) end'
	ast = LuaMinify.CreateLuaParser(source)
	_assertAstStringEquals(ast, source)
	_minify(ast)
	_assertAstStringEquals(ast, 'return function(a,b,...)end')
	-- pure vararg function, named
	source = 'function foo(...) end'
	ast = LuaMinify.CreateLuaParser(source)
	_assertAstStringEquals(ast, source)
	_minify(ast)
	_assertAstStringEquals(ast, 'function a(...)end')
	-- vararg function that has additional arguments, named
	source = 'function bar(c, d, ...) end'
	ast = LuaMinify.CreateLuaParser(source)
	_assertAstStringEquals(ast, source)
	_minify(ast)
	_assertAstStringEquals(ast, 'function a(b,c,...)end')
end

-- Test if tokenizer handles escape sequences
function test_escapes()
	for _, source in ipairs{
		[["Hello\nworld"]],
		[["Hello\tworld"]],
		[["Hello\32world"]],
		[["\t\9\0\9\t"]],
		[["don\'t \"quote\" me"]],
	} do
		local tokens = LuaMinify.CreateLuaTokenStream(source)
		assertTokenSequence(tokens, {source})
	end
end

-- Test "string call" function invocation
function test_stringcall()

	local function assertExprIsStringCall(expr) -- expression is string call?
		lu.assertIsTable(expr)
		lu.assertEquals(expr.Type, "CallExpr")
		lu.assertIsTable(expr.FunctionArguments)
		lu.assertEquals(expr.FunctionArguments.CallType, "StringCall")
	end
	local function assertStmtIsStringCall(stmt) -- statement is string call?
		lu.assertIsTable(stmt)
		lu.assertEquals(stmt.Type, "CallExprStat")
		assertExprIsStringCall(stmt.Expression)
	end

	local ast = LuaMinify.CreateLuaParser('print "Hello world"')
	assertStmtIsStringCall(ast.StatementList[1])

	ast = LuaMinify.CreateLuaParser('require "math"')
	assertStmtIsStringCall(ast.StatementList[1])

	ast = LuaMinify.CreateLuaParser('M = require[[mymodule]]')
	local stmt = ast.StatementList[1]
	lu.assertEquals(stmt.Type, "AssignmentStat")
	assertExprIsStringCall(stmt.Rhs[1]) -- right-hand side should be string call
end

-- Test some corner cases that aren't covered by running the "self test" sequence
function test_corner_cases()
	-- do .. end block / statement
	-- (see e.g. https://stackoverflow.com/questions/23895406/why-use-a-do-end-block-in-lua)
	local ast = LuaMinify.CreateLuaParser('do --[[ nothing ]] end')
	local stmt = ast.StatementList[1]
	lu.assertIsTable(stmt)
	lu.assertEquals(stmt.Type, "DoStat")
	_minify(ast)
	_assertAstStringEquals(ast, 'do end')
end

lu.LuaUnit:run(...)
