
module ('editor.fs', package.seeall)

function loadContent (content, filepath)
  local chunk = assert(loadfile(filepath))
  setfenv(chunk, content) ()
  return content
end

local dumpdata = {}

local function dump (value, ident)
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

function saveContent (content, filepath)
  local file = io.open(filepath, 'w')
  if not file then return end
  local contentdump = content:clone()
  for k,v in pairs(content) do 
    file:write(k.." = "..dump(v).."\n")
  end
  file:close()
end
