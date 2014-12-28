
local actions = {}

function actions.kill (action)
  local code = ""
  for _,tag in ipairs(action) do
    code = code .. string.format(
      [[self:WorldObjectByTag("%s"):Die()
      ]],
      tag
    )
  end
  return code
end

function actions.create (action)
  local code = ""
  for _,obj in ipairs(action) do
    code = code .. string.format(
      [[self:MakeRecipe("%s", vec2(%f, %f), "%s")
      ]],
      obj.recipe, obj.x, obj.y, obj.tag
    )
  end
  return code
end

function actions.countup (action)
  local code = string.format(
    [[
    %s = %s + 1
    if %s >= %d then
      event.Activate(%q)
      event.Clear(%q)
    end
    ]],
    action.var, action.var, action.var, action.max, action.triggers,
    action.event
    )
  return code
end

function actions.countdown (action)
  local code = string.format(
    [[
    %s = %s - 1
    if %s <= %d then
      event.Activate(%q)
      event.Clear(%q)
    end
    ]],
    action.var, action.var, action.var, action.min, action.triggers,
    action.event
    )
  return code
end

function make_action (action)
  return actions[action.type] (action)
end
