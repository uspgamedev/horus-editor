
module ('console', package.seeall)

require 'lux.object'

Element = lux.object.new {
  i = 0,
  j = 0
}

function Element:setPosition (i, j)
  self.i = i or self.i
  self.j = j or self.j
end

function Element:display (screen)
  screen:mvaddstr(self.i, self.j, "<Unknown element>")
end
