
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

function is_special_name (name)
  if string.char(name:byte(1)) == '%' then
    return name:match "^%%(.+)$"
  end
end

function get_horus_pos (obj)
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

