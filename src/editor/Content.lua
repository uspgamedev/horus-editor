
module ('editor', package.seeall)

local obj = require 'lux.object'

Content = obj.new {}

function Content.open (path)
  local content = Content:new{}
  fs.loadContent(content, path.."/project.content")
  content.path = path
  return content
end

function Content:save (path)
  fs.saveContent(self, (path or self.path).."/project.content")
  return self
end
