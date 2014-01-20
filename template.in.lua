
require "component"
require "map"
require "constants"
require "ugdk.math"
require "pyramidworks.geometry"
require "event"

width = $=map.width=$
height = $=map.height=$
start_position = { "$=hero_pos.room=$", $=hero_pos.x=$, $=hero_pos.y=$ }

rooms = {
$:for _, room in pairs(rooms) do
  { $=room.x=$, $=room.y=$, $=dump(room.name)=$ },
$:end
}

$:for _, room in pairs(rooms) do

$=room.name=$ = {
  width = $=room.width=$,
  height = $=room.height=$,
  matrix = $=dump(room.matrix)=$,
  neighborhood = $=dump(room.neighborhood)=$,
  
  recipes = {
$:for _, obj in pairs(horus_objects) do
    ["$=obj=$"] = { property = "$=obj=$" },
$:end 
  },
  
  setup = function(self)
$:for _, obj in ipairs(room.objects or {}) do
    self:MakeRecipe("$=obj.type=$", ugdk_math.Vector2D($=obj.x=$, $=obj.y=$))
$:end
    
  end,
}

$:end
