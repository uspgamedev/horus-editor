
module ('console', package.seeall)

require 'curses'
require 'console.InteractionMode'

local stdscr

function init ()
  curses.initscr()
  curses.cbreak()
  curses.echo(false)
  curses.nl(false)
  stdscr = curses.stdscr()
  stdscr:keypad(true)
  stdscr:clear()
end

function screen ()
  return stdscr
end

function run ()
  InteractionMode:new{}:resume()
end

function finish ()
  stdscr = nil
  curses.endwin()
end
