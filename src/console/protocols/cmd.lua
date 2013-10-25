
require 'console.screen'

function input (screen)
  while true do
    local ch = console.screen():getch()
    if ch >= 32 and ch <= 126 then
      return string.char(ch)
    end
  end
end
