
module('special_handlers', package.seeall)

function hero (layer, layer_name, room, obj)
  local x, y, w, h = get_horus_pos(obj)
  hero_pos.room = layer_name
  hero_pos.x = x
  hero_pos.y = y
end

-- Random spawn regions of objects
function spawnregion (layer, layer_name, room, obj)
  local x, y, w, h = get_horus_pos(obj)
  for i = 1, (obj.properties.amount or 1) + 0 do
  local newx, newy = x - math.random() * w, y - math.random() * h
    table.insert(
      room.objects,
      {
        recipe = obj.properties.what,
        x = newx - room.x,
        y = newy - room.y,
        tag = 'generated:'..obj.properties.what
      }
    )
    end
end

function counter (layer, layer_name, room, obj)
  room.vars[obj.name] = tonumber(obj.properties.start)
  if obj.properties["trigger-up"] then
    local triggerup = obj.properties["trigger-up"]
    room.events[triggerup] = room.events[triggerup] or {}
    room.events[triggerup].repeats = true
    local actionup = {
      type = "countup",
      var = obj.name,
      max = tonumber(obj.properties.max),
      event = triggerup,
      triggers = obj.properties["max-triggers"],
    }
    table.insert(room.events[triggerup], actionup)
  end
  if obj.properties["trigger-down"] then
    local triggerdown = obj.properties["trigger-down"]
    room.events[triggerdown] = room.events[triggerdown] or {}
    room.events[triggerdown].repeats = true
    local actiondown = {
      type = "countdown",
      var = obj.name,
      min = tonumber(obj.properties.min),
      event = triggerdown,
      triggers = obj.properties["min-triggers"],
    }
    table.insert(room.events[triggerdown], actiondown)
  end
end
