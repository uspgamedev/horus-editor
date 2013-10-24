
module ('console', package.seeall)

require 'curses'
require 'lux.functional'

local stdscr

function init ()
  -- General curses init
  curses.initscr()
  curses.cbreak()
  curses.echo(false)
  curses.nl(false)
  -- Screen init
  stdscr = curses.stdscr()
  stdscr:keypad(true)
  stdscr:clear()
  -- Handlers init
  handlers = {}
end

function screen ()
  return stdscr
end

local function handle (message, ...)
  if message == 'done' then return end
  assert(message and handlers[message], 'unexpected message "'..message..'"')
  return lux.functional.bindleft(handlers[message], ...)
end

function run (mode)
  local result = function () return end
  repeat
    result = handle(mode:resume(result()))
  until not result
end

function finish ()
  stdscr = nil
  curses.endwin()
end
