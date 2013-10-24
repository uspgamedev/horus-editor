#!/usr/bin/lua5.1

require 'editor'
require 'console.screen'

console.init()
local ok, err = pcall(console.run)
console.finish()

assert(ok, err)
