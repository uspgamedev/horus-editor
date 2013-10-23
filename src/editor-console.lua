
require 'editor'
require 'console.core'

console.core.init()

local stdscr = curses.stdscr()
stdscr:keypad(true)
stdscr:clear()
stdscr:attron(curses.A_BOLD)
stdscr:mvaddstr(15, 20, "Console mode! Resolution is "..curses.lines().."x"..curses.cols())
stdscr:attroff(curses.A_BOLD)
stdscr:getch()

curses.endwin()
