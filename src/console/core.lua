
module ('console.core', package.seeall)

require 'curses'

function init ()
  curses.initscr()
  curses.cbreak()
  curses.echo(false)
  --curses.nl(false)
  curses.stdscr():keypad(true)
  curses.stdscr():clear()
end
