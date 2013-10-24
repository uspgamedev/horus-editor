
require 'editor'
require 'console.core'


console.core.init()

local stdscr = curses.stdscr()
stdscr:attron(curses.A_BOLD)
stdscr:mvaddstr(15, 20, "Console mode! Resolution is "..curses.lines().."x"..curses.cols())
stdscr:attroff(curses.A_BOLD)

while true do
  stdscr:refresh()
  local ch = stdscr:getch()
  if ch < 256 and string.char(ch) == 'q' then break end
end

curses.endwin()
