
module ('console.core', package.seeall)

require 'curses'

function init ()
  curses.initscr()
  curses.cbreak()
  curses.echo(0)
end
