
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
local map = {}
local horus_objects = {}
local rooms = {}
local hero_pos = {}

-- Converts tileset names into horus matrix elements
local magic_glue = {
    ["wall-shortened"] = "%",
    ["ground"] = ".",
    ["stairs"] = "D",
    ["wall-burnt"] = "&",
}


--Functions that shalt be used

local dumpdata = {}

function dump (value, ident)
  ident = ident or ''
  local t = type(value)
  if dumpdata['type'..t] then
    return dumpdata['type'..t](value, ident)
  end
  return tostring(value)
end

function dumpdata.typestring (value)
  return "[["..value.."]]"
end
function dumpdata.typetable (value, ident)
  if value['__dumpfunction'] then
    return value['__dumpfunction'](value, ident)
  end
  local str = (value.__type or "").."{".."\n"
  for k,v in pairs(value) do
    if type(k) == 'string' then
      if k[1] ~= '_' then
        str = str..ident..'  '..'["'..k..'"] = '..dump(v, ident .. '  ')..",\n"
      end
    else
      str = str..ident..'  '.."["..k.."] = "..dump(v, ident .. '  ')..",\n"
    end
  end
  return str..ident.."}"
end
function dumpdata.typefunction (value)
  return '"*FUNCTION*"'
end

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

local function handle_objectlayer (layer)
  local room = rooms[layer.name]
  assert(room, "Object layer with no matching tiles layer: " .. layer.name)
  assert(not room.objects, "Each room should have only one object layer! (for now). Bad guy: " .. room.name)
  room.objects = {}

  for _, obj in ipairs(layer.objects) do
    assert(obj.shape == "rectangle" or obj.shape == "polygon", "Unsupported object shape: " .. obj.shape)

    --Trying to deduce grid x and y coordiantes out of Tiled's pixel-based approach
    --x and y are reversed due to differences in Tiled's orientation and Horus orientation
    ---0.5 are gambs
    local x = map.width - (obj.y/horus_height) -0.5
    local y = map.height - (obj.x/horus_height) -0.5
    if obj.name == "hero" then
      hero_pos.room = layer.name
      hero_pos.x = x
      hero_pos.y = y
    elseif obj.gid then
      assert(horus_objects[obj.gid], "Unknown gid: " .. obj.gid)
      table.insert(room.objects, { type = horus_objects[obj.gid], x = x - room.x, y = y - room.y })
      
    else
      assert(obj.shape == "rectangle", "Polygons are NYI in horus.")
      assert(false, "Regions are NYI in the converter.")
    end
  end
end

--Stuff starts here


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


out = io.open(output, "w")
out:write("rooms = {\n")
for _, room in ipairs(rooms) do
  out:write("  { " .. room.x .. ", " .. room.y .. ', "' .. room.name .. '"},\n')
end
out:write("}\n")

out:write('start_position = {"'..hero_pos.room..'" , '..hero_pos.x..' , '..hero_pos.y..' }\n')

out:write("width = " .. map.width .. "\n")
out:write("height = " .. map.height .. "\n")

for _, room in pairs(rooms) do
  out:write(room.name .. " = \n" .. dump(room) .. "\n")
  --out:write("  neighborhood = {}, -- NYI\n")
  --out:write("  width = " .. room.width .. ",\n")
  --out:write("  height = " .. room.height .. ",\n")
  --out:write("  matrix = \[\[\n" .. room.matrix .. "]],\n")
  --out:write("}\n")
end
