
require "component"
require "map"
require "constants"
require "ugdk.math"
require "pyramidworks.geometry"
require "event"

local vec2 = ugdk_math.Vector2D
local rect = pyramidworks_geometry.Rect

width = $=map.width=$
height = $=map.height=$
start_position = { "$=hero_pos.room=$", $=hero_pos.x=$, $=hero_pos.y=$ }
music = "$=map.music=$"

rooms = {
  $:for _, room in pairs(rooms) do
    { $=room.x=$, $=room.y=$, "$=room.name=$" },
  $:end
}

$:for _, room in pairs(rooms) do

  $=room.name=$ = {
    width = $=room.width=$,
    height = $=room.height=$,
    matrix = $="[[\n"..room.matrix.."]]"=$,
    neighborhood = {
      $:for _,n in ipairs(room.neighborhood) do
        "$=n=$",
      $:end:$
    },

    recipes = {
      $:for name, recipe in pairs(room.recipes or {}) do
        ["$=name=$"] = {
          property = "$=recipe.property=$",
          params = { $=recipe.params=$ }
        },
      $:end
    },

    collision_classes = {
      $:for _, class in ipairs(room.collision_classes or {}) do
        { "$=class.class=$", "$=class.extends=$" },
      $:end
    },

    setup = function(self)
      $:for var, val in pairs(room.vars or {}) do
        local $=var=$ = $=val=$
      $:end
      $:for _, obj in ipairs(room.objects or {}) do
        self:MakeRecipe("$=obj.recipe=$", vec2($=obj.x=$, $=obj.y=$), "$=obj.tag or ''=$")
      $:end
      $:for trigger, event in pairs(room.events or {}) do
        event.Register(
          "$=trigger=$",
          function ()
            $:for _, action in ipairs(event) do
              $=make_action(action)=$
            $:end
            $:if not event.repeats then
              event.Clear "$=trigger=$"
            $:end
          end
        )
      $:end
    end,
  }

$:end
