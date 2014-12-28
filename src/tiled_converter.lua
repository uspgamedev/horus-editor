#!/usr/bin/lua

-- Libs
package.path = package.path..";./lib/?.lua;src/?.lua"

require 'lux.macro.Processor'
require 'lux.stream'
require 'macros'
require 'helper'
require 'special_handlers'

-- Expected values
horus_height = 54
horus_width = 106
lua_version = "5.1"

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

local function check_triggers (layer, room)
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
    return 'NOT_YET'
  end
  return 'CARRY_ON'
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
  if check_triggers(layer, room) == 'NOT_YET' then
    return
  end

  for _, obj in ipairs(layer.objects) do
    assert(obj.shape == "rectangle" or obj.shape == "polygon", "Unsupported object shape: " .. obj.shape)

    local special = is_special_name(obj.type)
    if special then
      special_handlers[special] (layer, layer_name, room, obj)
    elseif room.recipes[obj.type] then
      local x, y, w, h = get_horus_pos(obj)
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

local function are_neighbors(room, other)
  if (room.x + room.width == other.x or
      other.x + other.width == room.x) and
     (room.y + room.height  > other.y  and
      room.y < other.y + other.height)
     or
     (room.y + room.height == other.y or
      other.y + other.height == room.y) and
     (room.x + room.width > other.x  and
      room.x < other.x + other.width) then
     return true
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


--QUADRATIC STUFF
--Shouldn't matter because # of rooms should never be high enough for this
--to be unnaceptably slow
for _, room in pairs(rooms) do
  for _, other in pairs(rooms) do
    if are_neighbors(room, other) then
      table.insert(room.neighborhood, other.name)
    end
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
