#!/usr/bin/lua

-- Libs
package.path = package.path..";./lib/?.lua;src/?.lua"

require 'lux.macro.Processor'
require 'lux.stream'
require 'macros'

-- Expected values
local horus_height = 54
local horus_width = 106
local lua_version = "5.1"

local input, output = ...

if not input or not output then
    error "Missing arguments. See the sauce for info."
end

local source = assert(loadfile(input))
local data = assert(source())

assert(data.orientation == "isometric")
assert(data.luaversion == lua_version)
assert(data.tilewidth == horus_width)
assert(data.tileheight == horus_height)

--Globals that shalt be used
map = {
  music = data.properties.music
}
horus_objects = {}
rooms = {}
hero_pos = {}

-- Converts tileset names into horus matrix elements
local magic_glue = {
    ["wall-shortened"] = "%",
    ["ground"] = ".",
    ["stairs"] = "D",
    ["wall-burnt"] = "&",
}


--Functions that shalt be used

function table_slice (values,i1,i2) -- http://snippets.luacode.org/?p=snippets/Table_Slice_116
    local res = {}
    local n = #values
    -- default values for range
    i1 = i1 or 1
    i2 = i2 or n
    if i2 < 0 then
        i2 = n + i2 + 1
    elseif i2 > n then
        i2 = n
    end
    if i1 < 1 or i1 > n then
        return {}
    end
    local k = 1
    for i = i1,i2 do
        res[k] = values[i]
        k = k + 1
    end
    return res
end

function trim(s) -- http://lua-users.org/wiki/StringTrim
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- Compatibility: Lua-5.0
function split(str, delim, maxNb) -- http://lua-users.org/wiki/SplitJoin
    -- Eliminate bad cases...
    if string.find(str, delim) == nil then
        return { str }
    end
    if maxNb == nil or maxNb < 1 then
        maxNb = 0    -- No limit
    end
    local result = {}
    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gfind(str, pat) do
        nb = nb + 1
        result[nb] = part
        lastPos = pos
        if nb == maxNb then break end
    end
    -- Handle the last field
    if nb ~= maxNb then
        result[nb + 1] = string.sub(str, lastPos)
    end
    return result
end

function find_first_last_row(t)
    local first, last
    for i, v in ipairs(t) do
        if v ~= 0 then
            first = first or i
            last = i
        end
    end
    return first, last
end

local function handle_tilelayer (layer)
    local columns = {}
    for i = 1, map.width do
        table.insert(columns, table_slice(layer.data, (i - 1) * map.height + 1, i * map.height))
    end

    local first_col, last_col
    local first_row, last_row = map.height, 1
    for x, col in ipairs(columns) do
        local fr, lr = find_first_last_row(col)
        if fr then
            first_col = first_col or x
            last_col  = x

            first_row = math.min(first_row, fr)
            last_row = math.max(last_row, lr)
        end
    end

    local room = {
        name = layer.name,

        -- Tiled's coordinate system starts from top and horus from bottom. shenanigans
        x = map.width - last_col,
        y = map.height - last_row,

        width = last_col - first_col + 1,
        height = last_row - first_row + 1,
        neighborhood = {},

    }

    if layer.properties and layer.properties.neighborhood then
        for _, n in ipairs(split(layer.properties.neighborhood, ",")) do
            table.insert(room.neighborhood, trim(n))
        end
    else
        print("Layer '" .. layer.name .. "' missing neightborhood property.")
    end

    local s = ""
    for y = room.height,1,-1 do
        for x = room.width,1,-1 do
            s = s .. (magic_glue[horus_objects[columns[x + first_col - 1][y + first_row - 1]]] or ' ')
        end
        s = s .. "\n"
    end
    room.matrix = s
    rooms[room.name] = room
end

local function is_special_name (name)
  return string.char(name:byte(1)) == '%'
end

local function get_horus_pos (obj)
  --Trying to deduce grid x and y coordiantes out of Tiled's pixel-based approach
  --x and y are reversed due to differences in Tiled's orientation and Horus orientation
  -- fix and -0.5's are gambs
  local fix = obj.gid and 0 or 0.5
  local x = map.width - (obj.y/horus_height) - fix
  local y = map.height - (obj.x/horus_height) - fix
  local w = obj.height/horus_height
  local h = obj.width/horus_height
  return x, y, w, h
end

local function populate_recipes (layer, room)
  room.recipes = room.recipes or {}
  for name, value in pairs(layer.properties) do
    --Extracts information from property names in format Stuff:Morestuff
    local left, right = name:match("^([^:]+):(.*)$")
    if value == 'recipe' then
      room.recipes[name] = {
        property = tostring(layer.properties[name..':property'] or name),
        params = tostring(layer.properties[name..':params'])
      }
    elseif left == "collision_class" then
      --TODO: Documentation
      table.insert(room.collision_classes, {class = right, extends = value})

    end
  end

  for _, obj in ipairs(layer.objects) do
    if obj.type and obj.type ~= "" and not is_special_name(obj.type)
       and not room.recipes[obj.type] then
      local x, y, w, h = get_horus_pos(obj)
      room.recipes[obj.type] = {
        property = tostring(obj.properties['property'] or obj.type),
        params = tostring(obj.properties['params'])..
          ", shape = rect("..w..","..h..")"
      }
    end
  end
end

local function handle_objectlayer (layer)
  local layer_name, _ = layer.name:match("^([^:]+):?(.*)$")
  local room = rooms[layer_name]
  assert(room, "Object layer with no matching tiles layer: " .. layer_name)
  room.objects = room.objects or {}
  room.events = room.events or {}
  room.collision_classes = room.collision_classes or {}
  room.vars = room.vars or {}

  populate_recipes(layer, room)

  if layer.properties.killtrigger then
    local trigger = layer.properties.killtrigger
    room.events[trigger] = room.events[trigger] or {}
    local action = {
      type = 'kill'
    }
    for _,obj in ipairs(layer.objects) do
      if obj.name and not is_special_name(obj.type) then
        table.insert(action, obj.name)
      end
    end
    table.insert(room.events[trigger], action)
  end

  if layer.properties.createtrigger then
    local trigger = layer.properties.createtrigger
    room.events[trigger] = room.events[trigger] or {}
    local action = {
      type = 'create'
    }
    for _,obj in ipairs(layer.objects) do
      if obj.name and not is_special_name(obj.type) then
        local x, y, w, h = get_horus_pos(obj)
        table.insert(action, {
          recipe = obj.type, tag = obj.name,
          x = x - room.x, y = y - room.y
        })
      end
    end
    table.insert(room.events[trigger], action)
    -- exit the function here so that the layer's objects are not
    -- created at the beginning, since they have their own trigger
    -- for later creation
    return
  end

  for _, obj in ipairs(layer.objects) do
    assert(obj.shape == "rectangle" or obj.shape == "polygon", "Unsupported object shape: " .. obj.shape)

    local x, y, w, h = get_horus_pos(obj)
    -- Special case: hero
    if obj.name == "hero" then
      hero_pos.room = layer_name
      hero_pos.x = x
      hero_pos.y = y
    -- Random spawn regions of objects
    -- TODO: generalize using the '%' flag
    elseif obj.type == "%spawn-region" then
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
    elseif obj.type == "%counter" then
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
   -- Objects with registered recipes
    elseif room.recipes[obj.type] then
      print "SUCCESS"
      print(obj.type)
      local the_x, the_y = x - room.x, y - room.y
      if not obj.gid then
        the_x = the_x - w/2
        the_y = the_y - h/2
      end
      table.insert(room.objects, {
        recipe = obj.type or "",
        x = the_x, y = the_y,
        tag = obj.name
      })
    -- Unknown stuff
    else
      print("WARNING", "Something is NYI")
      print(obj.name, obj.type)
      --assert(obj.shape == "rectangle", "Polygons are NYI in horus.")
      --assert(false, "Regions are NYI in the converter.")
    end
  end
end

--Stuff starts here

math.randomseed(os.time())

--wasting random numbers
math.random()
math.random()

-- Tiled orientation is inverted
map.width = data.height
map.height = data.width

for _, tileset in ipairs(data.tilesets) do
    horus_objects[tileset.firstgid] = tileset.name
    -- We only use one image per tileset.
end

for _, layer in ipairs(data.layers) do
    if layer.type == "tilelayer" then
        handle_tilelayer(layer)
    end
end

for _, layer in ipairs(data.layers) do
    if layer.type == "objectgroup" then
        handle_objectlayer(layer)
    end
end

local proc = lux.macro.Processor:new {}

local input_stream = lux.stream.File:new {
  path = "src/template.in.lua"
}
local output_stream = lux.stream.File:new {
  path = output,
  mode = "w"
}
proc:process(input_stream, output_stream)
