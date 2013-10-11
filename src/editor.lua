
module ('editor', package.seeall)

print "Welcome to Horus Eye's content editor."

require 'editor.info'
require 'editor.fs'
require 'editor.Content'

function open (path)
  return Content.open(path)
end