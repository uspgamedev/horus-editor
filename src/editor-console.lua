#!/usr/bin/lua5.1

require 'editor'
require 'console.screen'

console.init()
local ok, err = pcall(
  function ()
    assert(loadfile 'console/main.lua') ()
  end
)
console.finish()

assert(ok, err)
