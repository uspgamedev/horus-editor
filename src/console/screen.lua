
module ('console', package.seeall)

require 'curses'
require 'posix'
require 'lux.functional'
require 'lux.common'

local stdscr
local protocols

function init ()
  -- Protocols init
  loadProtocols()
  -- General curses init
  curses.initscr()
  curses.cbreak()
  curses.echo(false)
  curses.nl(false)
  -- Screen init
  stdscr = curses.stdscr()
  stdscr:keypad(true)
  stdscr:clear()
end

function loadProtocols ()
  protocols = {}
  local dir = "console/protocols"
  local datafile = lux.common.datafile
  local files, errstr, errno = posix.dir(dir)
  if files then
    for _,filename in pairs(files) do
      local check, _, name = string.find(filename, "(.+)%.lua")
      if check then
        protocols[name] = datafile(dir.."/"..filename, loadfile)
      end
    end
  else
    return error("["..errno.."] "..errstr)
  end
end

function screen ()
  return stdscr
end

local function unexpectedProtocol (name)
  return 'unexpected protocol "'..name..'"'
end

local function unexpectedMethod (method)
  return 'unexpected protocol method "'..method..'"'
end

local function handle (message, ...)
  if not message or message == 'done' then return end
  local name, method = select(3, assert(string.find(message, '(%w+):(%w+)')))
  local protocol = assert(protocols[name], unexpectedProtocol(name))
  return lux.functional.bindleft(
    assert(setfenv(protocol[method], _G), unexpectedMethod(message)),
    ...
  )
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
