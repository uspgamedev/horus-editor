
require 'console.elements.TextField'

console.elements.TextField:new {
  i = 15, j = 20,
  text = "Console mode! Resolution is "..curses.lines().."x"..curses.cols(),
  attribute = 'BOLD'
} :display(console.screen())

local cmd_line = console.elements.TextField:new { i = 25, j = 5 }

repeat 
  cmd_line:display(console.screen())
  console.screen():refresh()
  local input = event 'cmd:input' ()
  cmd_line.text = cmd_line.text..input
until input == 'q'
