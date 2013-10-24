#!/usr/bin/lua5.1

require 'editor'
require 'console.screen'
require 'console.InteractionMode'

console.init()
local ok, err = pcall(console.run, console.InteractionMode:new{})
console.finish()

assert(ok, err)
