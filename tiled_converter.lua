
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
    }
       
    local s = ""
    for y = room.height,1,-1 do
        for x = room.width,1,-1 do
            s = s .. (magic_glue[horus_objects[columns[x + first_col - 1][y + first_row - 1]]] or ' ')
        end
        s = s .. "\n"
    end
    room.matrix = s
    table.insert(rooms, room)
end

local function handle_objectlayer (layer)
    for _, obj in ipairs(layer.objects) do
        if obj.name == "hero" then
            hero_pos.room = layer.name
            local hero_room
            for _, room in ipairs(rooms) do
                if room.name == hero_pos.room then
                    hero_room = room
                end
            end
            --Trying to deduce grid x and y coordiantes out of Tiled's pixel-based approach
            --x and y are reversed due to differences in Tiled's orientation and Horus orientation
            ---0.5 are gambs
            hero_pos.x = map.width - (obj.y/horus_height) -0.5
            hero_pos.y = map.height - (obj.x/horus_height) -0.5
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

for _, room in ipairs(rooms) do
  out:write(room.name .. " = {\n")
  out:write("  neighborhood = {}, -- NYI\n")
  out:write("  width = " .. room.width .. ",\n")
  out:write("  height = " .. room.height .. ",\n")
  out:write("  matrix = \[\[\n" .. room.matrix .. "]],\n")
  out:write("}\n")
end
