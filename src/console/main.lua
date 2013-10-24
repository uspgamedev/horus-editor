
require 'console.elements.TextField'

console.elements.TextField:new {
  i = 15, j = 20,
  text = "Console mode! Resolution is "..curses.lines().."x"..curses.cols(),
  attribute = 'BOLD'
} :display(console.screen())

while true do
  console.screen():refresh()
  local ch = console.screen():getch()
  if ch < 256 and string.char(ch) == 'q' then break end
end
