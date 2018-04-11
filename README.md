This is NiteHawk's fork of https://github.com/stravant/lua-minify.  
[![Build Status](https://travis-ci.org/n1tehawk/lua-minify.svg?branch=nitehawk)](https://travis-ci.org/n1tehawk/lua-minify)
[![Coverage Status](https://coveralls.io/repos/n1tehawk/lua-minify/badge.svg?branch=nitehawk)](https://coveralls.io/r/n1tehawk/lua-minify?branch=nitehawk)
[![License](http://img.shields.io/badge/License-MIT-green.svg)](LICENSE.md)

---

## A Lua tool for minifying and reverse engineering minified Lua code

Usage:

    lua minify.lua minify INPUTFILE > OUTPUTFILE 

    lua minify.lua unminify INPUTFILE > OUTPUTFILE

The purpose of the unminifier is to reverse engineer minified code. It both beautifies the code and renames the variables to descriptive names like "L_42_arg2" which can be easily find-replaced while trying to reverse engineer minified code.