This is UnkN's fork of https://github.com/n1tehawk/lua-minify and https://github.com/stravant/lua-minify.  

Just added support for Garry's Mod lua syntax: continue (go to next 'for' condition), && (and), || (or), != (not equal), /* */ (CPP comment)
Also disabled renaming globals, because its useless for gmod i think.

---

## A Lua tool for minifying and reverse engineering minified GMod Lua code

Usage:

    lua minify.lua minify INPUTFILE > OUTPUTFILE 

    lua minify.lua unminify INPUTFILE > OUTPUTFILE

The purpose of the unminifier is to reverse engineer minified code. It both beautifies the code and renames the variables to descriptive names like "L_42_arg2" which can be easily find-replaced while trying to reverse engineer minified code.