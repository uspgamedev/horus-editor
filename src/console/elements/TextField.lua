
module ('console.elements', package.seeall)

require 'console.Element'
require 'console.screen'

TextField = console.Element:new {
  text = '',
  attribute = 'NORMAL'
}

function TextField:display (screen)
  screen:attron(curses["A_"..self.attribute])
  screen:mvaddstr(self.i, self.j, self.text)
  screen:attroff(curses["A_"..self.attribute])
end
