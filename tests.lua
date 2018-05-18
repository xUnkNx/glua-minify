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

	----- tokenizer -----

	lu.assertErrorMsgContains('<1:1>: Bad symbol `$` in source.',
		LuaMinify.CreateLuaTokenStream, '$')
	lu.assertErrorMsgContains('<2:2>: Unfinished long string.',
		LuaMinify.CreateLuaTokenStream, '\n[[')
	lu.assertErrorMsgContains('<1:4>: Invalid Escape Sequence `?`.',
		LuaMinify.CreateLuaTokenStream, '"\\?"')

	----- syntax parser -----

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

	-- incomplete statement (block body missing terminator)
	lu.assertErrorMsgContains('1:3: end expected.',
		LuaMinify.CreateLuaParser, 'do')

	-- method call with missing arguments
	lu.assertErrorMsgContains('Function arguments expected.',
		LuaMinify.CreateLuaParser, 'foo:bar')

	-- invalid assignment
	lu.assertErrorMsgContains('Bad left hand side of assignment',
		LuaMinify.CreateLuaParser, 'foo, bar(3) = "no deal", true')

	-- invalid numeric "for"
	lu.assertErrorMsgContains('expected 2 or 3 values for range bounds',
		LuaMinify.CreateLuaParser, 'for foo = 1 do end')
	lu.assertErrorMsgContains('expected 2 or 3 values for range bounds',
		LuaMinify.CreateLuaParser, 'for bar = 2, 3, 4, 5 do end')
	-- bad "for" syntax
	lu.assertErrorMsgContains('`=` or in expected',
		LuaMinify.CreateLuaParser, 'for foo bar')

	-- invalid "local" syntax
	lu.assertErrorMsgContains('`function` or ident expected',
		LuaMinify.CreateLuaParser, 'local 42')
	-- local function declarations shouldn't have a "name chain"
	lu.assertErrorMsgContains('1:19: `(` expected.',
		LuaMinify.CreateLuaParser, 'local function foo.bar() end')
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

	-- number formats
	local tokens = LuaMinify.CreateLuaTokenStream('0x7b') -- hex
	lu.assertIsTable(tokens)
	lu.assertIsTable(tokens[1])
	lu.assertEquals(tokens[1].Type, 'Number')
	tokens = LuaMinify.CreateLuaTokenStream('4e-3') -- negative exponent
	lu.assertIsTable(tokens)
	lu.assertIsTable(tokens[1])
	lu.assertEquals(tokens[1].Type, 'Number')

	-- something that starts like a 'long' comment, but is a normal one
	local source = '--[=== looks fishy'
	tokens = LuaMinify.CreateLuaTokenStream(source)
	lu.assertIsTable(tokens)
	lu.assertIsTable(tokens[1])
	lu.assertEquals(tokens[1].LeadingWhite, source)
	lu.assertEquals(tokens[1].Source, '') -- empty
	lu.assertEquals(tokens[1].Type, 'Eof')
end

function test_CountTable()
	lu.assertEquals(LuaMinify.CountTable{}, 0)
	lu.assertEquals(LuaMinify.CountTable{'foobar'}, 1)
	lu.assertEquals(LuaMinify.CountTable{'foo', 'bar'}, 2)
	lu.assertEquals(LuaMinify.CountTable{'a', 'b', 'c'}, 3)
	lu.assertEquals(LuaMinify.CountTable({'a', 'b', 'c'}, 2), 2) -- with limit
	lu.assertEquals(LuaMinify.CountTable{one=1, three=3, two=2}, 3)
end

function test_FormatTable()
	-- Note: loadstring is deprecated for Lua 5.2+, and was replaced with load
	local _load = loadstring or load -- luacheck: ignore 113

	local function test(t)
		local str = LuaMinify.FormatTable(t)
		-- We expect the return value to be a suitable Lua representation of
		-- the original table. So let's parse it to a second table (evaluating
		-- the string expression) and see if they match...
		local chunk = _load("return " .. str)
			or error("MALFORMED table expression: " .. str)
		local success, t2 = pcall(chunk)
		if not success then
			error('FAILED to execute chunk: ' .. t2)
		end
		lu.assertEquals(t2, t)
	end

	test {}
	-- list-type tables
	test {'foobar'}
	test {'foo', 'bar'}
	test {'a', 'b', 'c'}
	test {one=1, three=3, two=2}
	-- keys that require brackets and/or quoting
	test {[true]=1, [false]=0}
	test {['the answer'] = 42}
	-- non-consecutive numeric indices
	test {[9]='foo', [0]='bar'}
	-- recursion on nested tables
	test {{}}
	test {{{}}}
	test {{},{}}
end

lu.LuaUnit:run(...)
