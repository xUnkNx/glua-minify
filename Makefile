# Makefile
LUA ?= lua

selftest:
	# Run various transformations on the program itself.
	# They should all represent the same AST, and thus end up
	# as identical output. We also execute some of the transformed
	# programs, to make sure their functionality remained intact.

	@echo
	@echo Running self test:

	$(LUA) minify.lua minify minify.lua > minify1.out
	$(LUA) minify.lua minify minify1.out > minify2.out
	diff -u minify1.out minify2.out

	$(LUA) minify1.out minify minify.lua > minify3.out
	diff -u minify1.out minify3.out

	$(LUA) minify.lua unminify minify.lua > unminify1.out
	$(LUA) minify.lua unminify minify1.out > unminify2.out

	$(LUA) unminify1.out minify minify.lua > minify4.out
	diff -u minify1.out minify4.out
	$(LUA) unminify2.out unminify minify.lua > unminify3.out
	$(LUA) unminify2.out unminify minify1.out > unminify4.out
	diff -u unminify1.out unminify3.out
	diff -u unminify2.out unminify4.out

	$(LUA) minify.lua minify unminify1.out > minify5.out
	$(LUA) minify.lua minify unminify2.out > minify6.out
	diff -u minify1.out minify5.out
	diff -u minify1.out minify6.out

	rm minify*.out unminify*.out
