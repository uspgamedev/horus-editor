
module ('console', package.seeall)

require 'lux.object'

InteractionMode = lux.object.new {
  source = 'console/modes/bootstrap.lua'
}

local env = {}

function env.event (type)
  return function (...)
    return coroutine.yield(type, ...)
  end
end

function env.error (msg, ...)
  return error(debug.traceback('\n'..msg, 2))
end

function InteractionMode:__construct ()
  local routine = assert(loadfile(self.source))
  setfenv(routine, setmetatable(env, { __index = getfenv(0) }))
  self.routine = coroutine.create(routine)
end

function InteractionMode:resume (...)
  assert(
    coroutine.status(self.routine) ~= 'dead',
    "cannot resume dead routine."
  )
  return select(2, assert(coroutine.resume(self.routine, ...)))
end
