
module ('console', package.seeall)

require 'lux.object'

InteractionMode = lux.object.new {
  source = 'console/modes/bootstrap.lua'
}

function InteractionMode:__construct ()
  local routine = assert(loadfile(self.source))
  setfenv(
    routine,
    setmetatable({ request = coroutine.yield }, { __index = getfenv(0) })
  )
  self.routine = coroutine.create(routine)
end

function InteractionMode:resume (...)
  assert(
    coroutine.status(self.routine) ~= 'dead',
    "cannot resume dead routine."
  )
  local _, message = assert(coroutine.resume(self.routine, ...))
  return message
end
