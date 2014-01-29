
local actions = {}

function actions.kill (action)
  local code = ""
  for _,tag in ipairs(action) do
    code = code .. [[self:WorldObjectByTag("]]..tag..[["):Die()]]
  end
  return code
end

function actions.create (action)
  local code = ""
  for _,obj in ipairs(action) do
    code = code ..[[self:MakeRecipe("]]..
      obj.recipe..[[",
      vec2(]]..obj.x..[[, ]]..obj.y..[[),
      "]]..(obj.tag or '')..[["
    )]]
  end
  return code
end


function make_action (action)
  return actions[action.type] (action)
end
