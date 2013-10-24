
require 'console.elements.TextField'

function console.handlers.checkInput (code)
  return console.screen():getch() == code
end

console.elements.TextField:new {
  i = 15, j = 20,
  text = "Console mode! Resolution is "..curses.lines().."x"..curses.cols(),
  attribute = 'BOLD'
} :display(console.screen())

repeat  console.screen():refresh()
until   event 'checkInput' (string.byte 'q')

event 'done' ()
