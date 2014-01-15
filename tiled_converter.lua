
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

local map = {}

-- Tiled orientation is inverted
map.width = data.height
map.height = data.width

local horus_objects = {}

for _, tileset in ipairs(data.tilesets) do
    horus_objects[tileset.firstgid] = tileset.name
    -- We only use one image per tileset.
    print(tileset.name)
end

-- Converts tileset names into horus matrix elements
local magic_glue = {
    ["wall-shortened"] = "%",
    ["ground"] = ".",
    ["stairs"] = "D",
    ["wall-burnt"] = "&",
}

for _, layer in ipairs(data.layers) do
    assert(layer.type == "tilelayer", "Other types are NYI.")

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
    for y = 1,room.height do
        for x = room.width,1,-1 do
            s = s .. (magic_glue[horus_objects[columns[x + first_col - 1][y + first_row - 1]]] or ' ')
        end
        s = s .. "\n"
    end
    
    print(room.name, room.x, room.y, room.width, room.height)
    print(s)
end
